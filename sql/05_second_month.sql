-- 05_second_month.sql
-- Clock: minutes 40–44. Run ONE block at a time, in order.
-- Run this only after sql/04_continuous_aggregate.sql has been queried.
-- Do not recreate students or courses. This inserts the 30 days before
-- the month already loaded: 60 days ago through 31 days ago.
--
-- BLOCK 1 — insert the older month
-- SAY THIS
-- "This adds the 30 days before the month we already have. Everyone stays
-- on their home course. The log gets bigger, and the summary has not been
-- rewritten yet."
--
-- WHAT THE SQL DOES
-- It inserts 2,880 more sessions for the older month. It does not recreate
-- students or courses. Then it counts every session and shows the oldest
-- and newest day in the raw log.
--
-- EXPECTED RESULT
-- INSERT 0 2880.
-- sessions = 5760, oldest_day is 60 days ago, newest_day is yesterday.
--
-- WHAT THAT RESULT MEANS
-- The raw log now holds two months. This insert does not rewrite the
-- daily summary. The Databases cram is still only the most recent 7 days.
-- These older days are home courses at 30 minutes.
-- If sessions is already 5760, skip this insert and run BLOCK 3.

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
-- "The raw log has two months. The summary still has one. Reading it does
-- not reach back into those older sessions."
--
-- WHAT THE SQL DOES
-- It reads the summary, not the raw sessions, and reports the oldest day,
-- the newest day, and how many summary rows exist.
--
-- EXPECTED RESULT
-- oldest_day is about 30 days ago, newest_day is yesterday,
-- summary_rows = 113.
--
-- WHAT THAT RESULT MEANS
-- One month is still what the summary has stored. A continuous aggregate
-- does not fold older raw rows into a read. The hourly job only looks
-- back 30 days, so it will not store this older month either. Do not
-- rerun the "earlier 23 days" query from sql/04. That label mixes both
-- months and still prints 960, which hides the new month.

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
--
-- WHAT THE SQL DOES
-- It recomputes every daily bucket in the last 70 days, including the
-- month that is older than the 30-day schedule.
--
-- EXPECTED RESULT
-- CALL, with no error.
--
-- WHAT THAT RESULT MEANS
-- The older days are now saved in the summary. Left alone, the hourly
-- job would keep refreshing the recent month and leave this older month
-- unstored.
-- If "force" is rejected, run the rescue at the bottom, then BLOCK 4.

CALL refresh_continuous_aggregate(
  'study_daily',
  now() - INTERVAL '70 days',
  now() + INTERVAL '1 day',
  force => true
);

-- BLOCK 4 — the summary now covers both months
-- SAY THIS
-- "Now the oldest day jumps back a month, and the summary grows from 113
-- rows to 233. One day in that older month is a normal day, before anyone
-- started cramming."
--
-- WHAT THE SQL DOES
-- The first statement reads the oldest day, the newest day, and the row
-- count. The second reads one Eastern day from the older month, 45 days
-- ago, and shows each course's stored minutes.
--
-- EXPECTED RESULT
-- Span query: oldest_day is 60 days ago, newest_day is yesterday,
-- summary_rows = 233.
-- Older-day query, four rows: Calculus 480, Data Structures 960,
-- Databases 960, Writing 480.
--
-- WHAT THAT RESULT MEANS
-- Two months of daily totals are stored. That older day is before the
-- cram: Databases is only Maya and Alex, at 30 minutes a session. The
-- 3,200-minute week is still only the most recent 7 days.

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
