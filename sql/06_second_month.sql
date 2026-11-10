-- 06_second_month.sql
-- Clock: minutes 38–43. Run ONE block at a time, in order.
-- Run this only after sql/05_continuous_aggregate.sql has been queried.
-- Do not recreate students or courses. This inserts the 30 days before
-- the month already loaded: 60 days ago through 31 days ago.
--
-- BLOCK 1 — insert the older month
-- SAY THIS
-- "Another month of the same log, the 30 days before the month we already
-- have. Everyone stays on their home course. The raw log now covers 60
-- days: 5,760 sessions, oldest day 60 days ago."
-- EXPECT THIS
-- INSERT 0 2880.
-- sessions = 5760, oldest_day is 60 days ago, newest_day is yesterday.
-- IF THIS FAILS
-- If sessions is already 5760, the insert already happened. Skip to BLOCK 3.
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

SELECT
  count(*) AS sessions,
  min((time AT TIME ZONE 'America/New_York')::date) AS oldest_day,
  max((time AT TIME ZONE 'America/New_York')::date) AS newest_day
FROM study_sessions;

-- BLOCK 2 — the summary is still the first month
-- SAY THIS
-- "The raw log has two months. The summary still has one. Reading
-- study_daily does not reach back into older raw rows. It only has the
-- days that were written into it, and the hourly schedule only looks
-- back 30 days."
-- EXPECT THIS
-- oldest_day is about 30 days ago, newest_day is yesterday,
-- summary_rows = 113.
-- IF THIS FAILS
-- If summary_rows is already 233, the older month was refreshed on an
-- earlier run. Skip to BLOCK 4.
-- Do not rerun the "earlier 23 days" query from sql/05. That label now
-- mixes two months and still prints 960, so it hides the new month.

SELECT
  min((day AT TIME ZONE 'America/New_York')::date) AS oldest_day,
  max((day AT TIME ZONE 'America/New_York')::date) AS newest_day,
  count(*) AS summary_rows
FROM study_daily;

-- BLOCK 3 — write the older month into the summary
-- SAY THIS
-- "The first refresh only stored the month that existed then. Refreshing
-- again with no dates does not go back for this older month. This call
-- names the last 70 days and forces those days to be rewritten."
-- EXPECT THIS
-- CALL, with no error.
-- IF THIS FAILS
-- If "force" is rejected, paste the rescue at the bottom, then BLOCK 4.
-- Otherwise paste this CALL again as its own statement.

CALL refresh_continuous_aggregate(
  'study_daily',
  now() - INTERVAL '70 days',
  now() + INTERVAL '1 day',
  force => true
);

-- BLOCK 4 — the summary now covers both months
-- SAY THIS
-- "Now the oldest day jumps back 30 days, and the summary grows from 113
-- rows to 233. A day in that older month is the steady pattern: Databases
-- and Data Structures at 960 minutes, Calculus and Writing at 480. The
-- cram week is still only the recent 7 days."
-- EXPECT THIS
-- Span query: oldest_day is 60 days ago, newest_day is yesterday,
-- summary_rows = 233.
-- Older-day query, four rows: Calculus 480, Data Structures 960,
-- Databases 960, Writing 480.
-- IF THIS FAILS
-- Run BLOCK 3 once more, then these two queries. If the span is still
-- about 30 days, describe the steady pattern from this comment and close.

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

-- RESCUE, only if BLOCK 3 rejects the force argument.
--
-- CALL refresh_continuous_aggregate(
--   'study_daily',
--   now() - INTERVAL '70 days',
--   now() + INTERVAL '1 day'
-- );
