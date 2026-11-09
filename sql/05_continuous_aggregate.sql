-- 05_continuous_aggregate.sql
-- Clock: minutes 33–40. Run ONE block at a time, in order.
-- Do not paste the whole file. Creating the view and refreshing it in one
-- transaction can fail. Wait for each block to succeed before the next.
--
-- BLOCK 1 — create the summary page, empty on purpose
-- SAY THIS
-- "A continuous aggregate is a summary page the database keeps current.
-- WITH NO DATA creates it immediately. We will fill it ourselves so we
-- do not wait for a schedule."
-- EXPECT THIS
-- CREATE MATERIALIZED VIEW
-- IF THIS FAILS
-- "already exists": run sql/00_reset.sql only if you are rehearsing.
-- On stream, skip to BLOCK 4 if study_daily is already filled.
-- If timezone => is rejected, use the rescue view at the bottom, then
-- tell the room the summary days are UTC for this run.

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
-- "This reads the sessions once and writes the daily totals. A dashboard
-- can read study_daily from now on instead of rereading the whole month."
-- EXPECT THIS
-- CALL, with no error. It should return in a few seconds.
-- IF THIS FAILS
-- Paste it again as its own statement. If it still fails, run the rescue
-- refresh at the bottom with explicit dates, then continue at BLOCK 4.

CALL refresh_continuous_aggregate('study_daily', NULL, NULL);

-- BLOCK 3 — the schedule, after the room has already seen the data
-- SAY THIS
-- "This is the part we are not waiting for. Once an hour, TimescaleDB
-- refreshes recent daily buckets in the background. Plain PostgreSQL
-- would need a job we operate ourselves."
-- EXPECT THIS
-- One row with a job id, an integer. Any integer is success.
-- IF THIS FAILS
-- The summary is already filled. Say "the schedule is optional; the page
-- is already there" and run BLOCK 4.

SELECT add_continuous_aggregate_policy(
  'study_daily',
  start_offset => INTERVAL '30 days',
  end_offset => INTERVAL '1 day',
  schedule_interval => INTERVAL '1 hour'
);

-- BLOCK 4 — read the summary page
-- SAY THIS
-- "Same deadline question as before. This time the database reads the
-- summary, not all 2,880 sessions. Databases jumps from 960 minutes a day
-- to 3,200. Calculus and Writing stay at 480."
-- EXPECT THIS
-- Databases: earlier 23 days = 960, final 7 days = 3200
-- Data Structures: earlier 23 days = 960, no final-week row
-- Calculus: 480, then 480
-- Writing: 480, then 480
-- IF THIS FAILS
-- SELECT * FROM study_daily ORDER BY day DESC LIMIT 12;
-- Point at the recent Databases rows and describe the jump in words.

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

-- RESCUE VIEW, only if BLOCK 1 rejects the timezone argument.
-- Drop the failed view first if it was half-created.
--
-- DROP MATERIALIZED VIEW IF EXISTS study_daily;
-- CREATE MATERIALIZED VIEW study_daily
-- WITH (timescaledb.continuous) AS
-- SELECT
--   time_bucket('1 day', time) AS day,
--   course,
--   sum(minutes) AS total_minutes,
--   round(avg(focus_score), 1) AS avg_focus,
--   count(*) AS sessions
-- FROM study_sessions
-- GROUP BY time_bucket('1 day', time), course
-- WITH NO DATA;
--
-- RESCUE REFRESH, only if CALL ... NULL, NULL fails:
--
-- CALL refresh_continuous_aggregate(
--   'study_daily',
--   now() - INTERVAL '40 days',
--   now() + INTERVAL '1 day'
-- );
