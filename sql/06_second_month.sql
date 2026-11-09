-- 06_second_month.sql
-- Clock: minutes 38–43. Run ONE block at a time, in order.
-- Run this only after sql/05_continuous_aggregate.sql has been queried.
-- Do not recreate students or courses. This inserts the 30 days before
-- the month already loaded: 60 days ago through 31 days ago.
--
-- BLOCK 1 — insert the older month
-- SAY THIS
-- "Another month of the same log, the 30 days before the month we already
-- have. Everyone stays on their home course. The raw log grows. The
-- summary has not been rewritten yet."
-- EXPECT THIS
-- INSERT 0 2880. The count grid shows sessions = 5760.
-- IF THIS FAILS
-- If sessions is 8640, this file was run twice. Say "that was a double
-- paste" and run sql/00_reset.sql only if you are rehearsing. On stream,
-- skip to the close.

INSERT INTO study_sessions (time, student, course, spot, minutes, focus_score, caffeine_mg)
SELECT
  built.session_time,
  built.student,
  built.course,
  built.spot,
  built.minutes,
  LEAST(
    98,
    GREATEST(
      35,
      built.base_focus
        + CASE built.spot WHEN 'Library' THEN 6 WHEN 'Dorm' THEN -8 ELSE 0 END
        + CASE WHEN built.student = 'Jordan Blake' THEN -8 ELSE 0 END
    )
  )::integer AS focus_score,
  built.caffeine_mg
FROM (
  SELECT
    (slot.day + make_time(slot.hour, 0, 0)) AT TIME ZONE 'America/New_York' AS session_time,
    slot.student,
    CASE
      WHEN slot.student IN ('Maya Chen', 'Alex Nguyen') THEN 'Databases'
      WHEN slot.student IN ('Jordan Blake', 'Sam Ortiz') THEN 'Data Structures'
      WHEN slot.student = 'Priya Shah' THEN 'Calculus'
      ELSE 'Writing'
    END AS course,
    CASE
      WHEN slot.hour >= 21 THEN 'Dorm'
      WHEN slot.hour <= 16 AND slot.student IN ('Priya Shah', 'Sam Ortiz') THEN 'Cafe'
      WHEN slot.hour <= 16 THEN 'Library'
      WHEN EXTRACT(ISODOW FROM slot.day) IN (6, 7) THEN 'Cafe'
      WHEN slot.student IN ('Maya Chen', 'Priya Shah', 'Riley Brooks') THEN 'Library'
      ELSE 'Dorm'
    END AS spot,
    30 AS minutes,
    slot.base_focus,
    CASE
      WHEN slot.hour >= 21 THEN 160
      WHEN slot.hour >= 17 THEN 80
      ELSE 0
    END AS caffeine_mg
  FROM (
    SELECT
      day_series.day::date AS day,
      hours.hour,
      hours.base_focus,
      students.name AS student
    FROM generate_series(
      (timezone('America/New_York', now()))::date - 60,
      (timezone('America/New_York', now()))::date - 31,
      INTERVAL '1 day'
    ) AS day_series(day)
    CROSS JOIN (
      VALUES
        (8, 72),
        (9, 84),
        (10, 90),
        (11, 82),
        (12, 68),
        (13, 66),
        (14, 74),
        (15, 73),
        (16, 71),
        (17, 76),
        (18, 75),
        (19, 70),
        (20, 64),
        (21, 58),
        (22, 52),
        (23, 46)
    ) AS hours(hour, base_focus)
    CROSS JOIN students
  ) AS slot
) AS built;

SELECT count(*) AS sessions FROM study_sessions;

-- BLOCK 2 — read the summary again
-- SAY THIS
-- "The summary query can see the new rows. The oldest day jumps back 30
-- days. The summary grows from 113 rows to 233. A day in that older month
-- is the steady pattern: Databases and Data Structures at 960 minutes,
-- Calculus and Writing at 480. The cram week is still only the recent
-- 7 days."
-- EXPECT THIS
-- Span query: oldest_day is 60 days ago, newest_day is yesterday,
-- summary_rows = 233.
-- Older-day query, four rows: Calculus 480, Data Structures 960,
-- Databases 960, Writing 480.
-- IF THIS FAILS
-- If summary_rows is still 113, real-time aggregation is off. That is not
-- a failure. Run BLOCK 3, then run these two queries again. The change
-- appears after the refresh.
-- Do not rerun the "earlier 23 days" query from sql/05. That label now
-- mixes two months.

SELECT
  min((day AT TIME ZONE 'America/New_York')::date) AS oldest_day,
  max((day AT TIME ZONE 'America/New_York')::date) AS newest_day,
  count(*) AS summary_rows
FROM study_daily;

SELECT
  course,
  total_minutes
FROM study_daily
WHERE (day AT TIME ZONE 'America/New_York')::date
      = (timezone('America/New_York', now()))::date - 45
ORDER BY course;

-- BLOCK 3 — store the older month in the summary
-- SAY THIS
-- "The hourly schedule only looks back 30 days, so it would not have
-- stored this older month on its own. This refresh writes those days
-- into the summary."
-- EXPECT THIS
-- CALL, with no error.
-- IF THIS FAILS
-- Paste the CALL again as its own statement. The span query in BLOCK 2
-- already showed the new month. You can close without this refresh.

CALL refresh_continuous_aggregate('study_daily', NULL, NULL);

-- BLOCK 4 — same span, now stored
-- SAY THIS
-- "Same oldest day, same 233 summary rows. The refresh saved what the
-- previous read already showed."
-- EXPECT THIS
-- oldest_day is 60 days ago, newest_day is yesterday, summary_rows = 233.
-- IF THIS FAILS
-- Use the BLOCK 2 result and move to the close.

SELECT
  min((day AT TIME ZONE 'America/New_York')::date) AS oldest_day,
  max((day AT TIME ZONE 'America/New_York')::date) AS newest_day,
  count(*) AS summary_rows
FROM study_daily;
