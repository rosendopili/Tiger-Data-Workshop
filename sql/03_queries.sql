-- 03_queries.sql
-- Clock: minutes 23–33. Run ONE query at a time.
-- Highlight a single statement. Do not run the whole file, or the editor
-- may show only the last result.
-- Hours and days are America/New_York, so hour 10 is 10am Eastern even
-- when the cloud clock is UTC.
--
-- QUERY A — best hour
-- SAY THIS
-- "time_bucket groups the diary into hours. We average focus inside each
-- hour of the day. Raw rows are the diary. Buckets are the summary a
-- person actually wants."
-- EXPECT THIS
-- First row: 10 AM, avg_focus 92.7, sessions 180.
-- Last row, if you sort or scroll: 11 PM, avg_focus 37.5, sessions 180.
-- Every hour has 180 sessions. The score is what changes.
-- IF THIS FAILS
-- If timezone => is rejected, replace the time_bucket call with
-- time_bucket('1 hour', time) and say the hours are UTC for this run.
-- Then move on. Do not rewrite the query live.

SELECT
  to_char(
    time_bucket('1 hour', time, timezone => 'America/New_York') AT TIME ZONE 'America/New_York',
    'FMHH12 AM'
  ) AS hour_eastern,
  round(avg(focus_score), 1) AS avg_focus,
  count(*) AS sessions
FROM study_sessions
GROUP BY hour_eastern
ORDER BY avg_focus DESC;

-- QUERY B — library vs dorm on weeknights
-- SAY THIS
-- "Same idea, now the question is where. Weeknights, 5pm to 8pm.
-- The library should beat the dorm."
-- EXPECT THIS
-- Library, avg_focus 77.3
-- Dorm, avg_focus 60.6
-- The session counts change with how many weekdays fall in this month.
-- Talk about 77.3 and 60.6, not the counts.
-- IF THIS FAILS
-- Skip to Query C. Say "the where-question is in the repo; the which-class
-- question is the one I want on screen."

SELECT
  spot,
  round(avg(focus_score), 1) AS avg_focus,
  count(*) AS sessions
FROM study_sessions
WHERE extract(isodow FROM (time AT TIME ZONE 'America/New_York')) BETWEEN 1 AND 5
  AND extract(hour FROM time_bucket('1 hour', time, timezone => 'America/New_York')) BETWEEN 17 AND 20
  AND spot IN ('Library', 'Dorm')
GROUP BY spot
ORDER BY avg_focus DESC;

-- QUERY C — the deadline
-- SAY THIS
-- "For 23 days everyone studies their home course, about 30 minutes an hour.
-- In the last 7 days Maya, Alex, Jordan, and Sam switch every session to
-- Databases and those sessions go to 50 minutes. Priya stays on Calculus.
-- Riley stays on Writing."
-- EXPECT THIS
-- Databases: earlier 23 days = 960, final 7 days = 3200
-- Data Structures: earlier 23 days = 960, and no final-week row.
--   Jordan and Sam left that course. A missing row is the story, not a bug.
-- Calculus: 480, then 480
-- Writing: 480, then 480
-- IF THIS FAILS
-- Run SELECT course, sum(minutes) FROM study_sessions GROUP BY course;
-- Say the detailed day split is in the repo, and move to the aggregate.

SELECT
  CASE
    WHEN day >= (timezone('America/New_York', now()))::date - 7
      THEN 'final 7 days'
    ELSE 'earlier 23 days'
  END AS period,
  course,
  (sum(total_minutes) / count(*))::integer AS avg_minutes_per_day
FROM (
  SELECT
    (time_bucket('1 day', time, timezone => 'America/New_York') AT TIME ZONE 'America/New_York')::date AS day,
    course,
    sum(minutes) AS total_minutes
  FROM study_sessions
  GROUP BY day, course
) AS daily
GROUP BY period, course
ORDER BY course, period;
