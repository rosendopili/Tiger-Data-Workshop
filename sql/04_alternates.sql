-- 04_alternates.sql
-- Run ONE query, and only if chat asks or you are ahead of the clock.
-- If you are at minute 30 or later, skip this file and open sql/05.
--
-- QUERY A — most caffeine, least focus
-- SAY THIS
-- "After 9pm everyone is at 160 milligrams. Jordan also focuses a bit worse
-- than the others, so the bottom of the list is Jordan at 11pm."
-- EXPECT THIS
-- First row: Jordan Blake, 11 PM, caffeine_mg 160, avg_focus 35.0
-- The next rows are other late hours. Point at the first row only.
-- IF THIS FAILS
-- Say "that one is in the repo" and go back to the plan.

SELECT
  student,
  to_char(
    time_bucket('1 hour', time, timezone => 'America/New_York') AT TIME ZONE 'America/New_York',
    'FMHH12 AM'
  ) AS hour_eastern,
  caffeine_mg,
  round(avg(focus_score), 1) AS avg_focus
FROM study_sessions
WHERE caffeine_mg = 160
GROUP BY student, hour_eastern, caffeine_mg
ORDER BY avg_focus ASC, student
LIMIT 5;

-- QUERY B — busiest spot
-- SAY THIS
-- "Count of sessions, not focus. Daytime is mostly the library, so the
-- library wins by a wide margin."
-- EXPECT THIS
-- Library first, about 1,300 to 1,350 sessions.
-- Cafe and Dorm are each under about 810 and can trade second place.
-- Say "Library is first." Do not quote an exact second-place count.
-- IF THIS FAILS
-- Skip it.

SELECT
  spot,
  count(*) AS sessions
FROM study_sessions
GROUP BY spot
ORDER BY sessions DESC;

-- QUERY C — optional join, if you want the "one database" point on screen
-- SAY THIS
-- "students and courses are ordinary tables. The log joins to them with
-- normal SQL. The history and the rest of the app live in one database."
-- EXPECT THIS
-- One row per student and course they actually logged, with a major beside it.
-- Maya, Alex, Jordan, and Sam each appear twice: home course, then Databases.
-- IF THIS FAILS
-- SELECT * FROM students; and keep talking.

SELECT
  study_sessions.student,
  students.major,
  study_sessions.course,
  sum(study_sessions.minutes) AS minutes
FROM study_sessions
JOIN students ON students.name = study_sessions.student
JOIN courses ON courses.name = study_sessions.course
GROUP BY study_sessions.student, students.major, study_sessions.course
ORDER BY study_sessions.student, minutes DESC;
