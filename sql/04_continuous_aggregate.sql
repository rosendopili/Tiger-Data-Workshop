-- 04_continuous_aggregate.sql
-- Clock: minutes 36–40. Run ONE block at a time, in order.
-- Do not paste the whole file. Wait for each block to finish before the next.
--
-- BLOCK 1 — create the summary page, empty on purpose
-- SAY THIS
-- "This creates a daily summary that the database can keep up to date.
-- I'm leaving it empty on purpose. The next statement fills it in."
--
-- WHAT THE SQL DOES
-- It creates study_daily as a continuous aggregate: one stored row per
-- Eastern day and course, with total minutes, average focus, and a
-- session count. WITH NO DATA means those rows are not filled yet.
--
-- EXPECTED RESULT
-- CREATE MATERIALIZED VIEW
--
-- WHAT THAT RESULT MEANS
-- The summary exists, and it is empty. Nothing is in it until the next
-- statement reads the sessions.

CREATE MATERIALIZED VIEW study_daily
WITH (timescaledb.continuous) AS
SELECT
  time_bucket('1 day', time, timezone => 'America/New_York') AS day,
  course,
  sum(minutes) AS total_minutes,
  round(avg(focus_score), 1) AS avg_focus,
  count(*) AS sessions
FROM study_sessions
GROUP BY time_bucket('1 day', time, timezone => 'America/New_York'), course
WITH NO DATA;

-- BLOCK 2 — fill the summary now
-- SAY THIS
-- "This reads the month of sessions once and writes the daily totals.
-- After this, a dashboard can read the summary instead of reading every
-- session."
--
-- WHAT THE SQL DOES
-- It fills study_daily from every session loaded so far. NULL, NULL means
-- the whole time range, which right now is the one month in the table.
--
-- EXPECTED RESULT
-- CALL, with no error. It should come back in a few seconds.
--
-- WHAT THAT RESULT MEANS
-- The daily totals are stored. The next question can read about 113
-- summary rows instead of all 2,880 sessions.

CALL refresh_continuous_aggregate('study_daily', NULL, NULL);

-- BLOCK 3 — the schedule, after the room has already seen the data
-- SAY THIS
-- "This is the part we are not going to sit here and wait for. Once an
-- hour, the database refreshes the recent days in the background."
--
-- WHAT THE SQL DOES
-- It schedules an hourly job that refreshes study_daily from 30 days ago
-- up through yesterday. The job does not run during this paste.
--
-- EXPECTED RESULT
-- One row with a job id. Any integer means it worked.
--
-- WHAT THAT RESULT MEANS
-- The summary now has a schedule. The page is already filled from the
-- refresh you just ran, so you do not wait for this job.

SELECT add_continuous_aggregate_policy(
  'study_daily',
  start_offset => INTERVAL '30 days',
  end_offset => INTERVAL '1 day',
  schedule_interval => INTERVAL '1 hour'
);

-- BLOCK 4 — read the summary page
-- SAY THIS
-- "This is the same deadline question we just asked. This time the
-- database reads the summary, instead of all 2,880 sessions."
--
-- WHAT THE SQL DOES
-- It reads study_daily, not the raw sessions, and averages the stored
-- daily minutes for the first 23 days and the last 7, by course.
--
-- EXPECTED RESULT
-- Databases: earlier 23 days = 960, final 7 days = 3200
-- Data Structures: earlier 23 days = 960, no final-week row
-- Calculus: 480, then 480
-- Writing: 480, then 480
--
-- WHAT THAT RESULT MEANS
-- The summary matches the query you just ran on the raw sessions.
-- Databases more than triples in the last week. Data Structures
-- disappears that week because Jordan and Sam left it. Calculus and
-- Writing stay flat. Use this query only while the table holds one month.
-- After the next file, the "earlier 23 days" label would mix both months.

SELECT
  CASE
    WHEN (day AT TIME ZONE 'America/New_York')::date
         >= (timezone('America/New_York', now()))::date - 7
      THEN 'final 7 days'
    ELSE 'earlier 23 days'
  END AS period,
  course,
  (sum(total_minutes) / count(*))::integer AS avg_minutes_per_day
FROM study_daily
GROUP BY period, course
ORDER BY course, period;
