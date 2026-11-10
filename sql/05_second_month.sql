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
-- students or courses. Then it counts every session in the table.
--
-- EXPECTED RESULT
-- INSERT 0 2880. The count grid shows sessions = 5760.
--
-- WHAT THAT RESULT MEANS
-- The raw log now holds two months. This insert does not rewrite the
-- daily summary. The Databases cram is still only the most recent 7 days.
-- These older days are home courses at 30 minutes.

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

-- BLOCK 2 — how wide the summary is now
-- SAY THIS
-- "The summary can already see those new days. The oldest day jumps back
-- a month, and the number of summary rows grows from 113 to 233."
--
-- WHAT THE SQL DOES
-- It reads the summary, not the raw sessions, and reports the oldest day,
-- the newest day, and how many summary rows exist.
--
-- EXPECTED RESULT
-- oldest_day is 60 days ago, newest_day is yesterday, summary_rows = 233.
--
-- WHAT THAT RESULT MEANS
-- The summary grew because the older month arrived. 113 rows was one
-- month. 233 is two. The newest day is still yesterday, so the cram week
-- is still the end of the log. Do not rerun the "earlier 23 days" query
-- from sql/04. That label would mix both months and hide the change.

SELECT
  min((day AT TIME ZONE 'America/New_York')::date) AS oldest_day,
  max((day AT TIME ZONE 'America/New_York')::date) AS newest_day,
  count(*) AS summary_rows
FROM study_daily;

-- BLOCK 2, second query — one day in the older month
-- SAY THIS
-- "Here is one day from that older month. Everyone is still on a home
-- course, so it should look like a normal day, before anyone started
-- cramming."
--
-- WHAT THE SQL DOES
-- It reads one Eastern day from the older month, 45 days ago, and shows
-- each course's stored minutes.
--
-- EXPECTED RESULT
-- Four rows: Calculus 480, Data Structures 960, Databases 960, Writing 480.
--
-- WHAT THAT RESULT MEANS
-- That day is before the cram. Databases is only Maya and Alex, at 30
-- minutes a session. The 3,200-minute week is still only the most recent
-- 7 days.

SELECT
  course,
  total_minutes
FROM study_daily
WHERE (day AT TIME ZONE 'America/New_York')::date
      = (timezone('America/New_York', now()))::date - 45
ORDER BY course;

-- BLOCK 3 — store the older month in the summary
-- SAY THIS
-- "The hourly job only looks back 30 days, so it would have missed this
-- older month. This refresh writes those days into the summary."
--
-- WHAT THE SQL DOES
-- It rewrites the stored part of study_daily across the whole log,
-- including the month that is older than the 30-day schedule.
--
-- EXPECTED RESULT
-- CALL, with no error.
--
-- WHAT THAT RESULT MEANS
-- The older days are now saved in the summary. Left alone, the hourly
-- job would keep refreshing the recent month and leave this older month
-- unstored.

CALL refresh_continuous_aggregate('study_daily', NULL, NULL);

-- BLOCK 4 — same span, now stored
-- SAY THIS
-- "You should see the same oldest day and the same 233 rows. The refresh
-- saved the older month, and the story did not change."
--
-- WHAT THE SQL DOES
-- It reads the oldest day, the newest day, and the summary row count
-- again, after the refresh.
--
-- EXPECTED RESULT
-- oldest_day is 60 days ago, newest_day is yesterday, summary_rows = 233.
--
-- WHAT THAT RESULT MEANS
-- The numbers match the read you did before the refresh. Two months of
-- daily totals are stored, and the cram week is still at the recent end.

SELECT
  min((day AT TIME ZONE 'America/New_York')::date) AS oldest_day,
  max((day AT TIME ZONE 'America/New_York')::date) AS newest_day,
  count(*) AS summary_rows
FROM study_daily;
