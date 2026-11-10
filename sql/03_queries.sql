-- 03_queries.sql
-- Clock: minutes 25–36. Run ONE query at a time.
-- Highlight a single statement. Do not run the whole file, or the editor
-- may show only the last result.
-- Hours and days are America/New_York, so hour 10 is 10am Eastern even
-- when the cloud clock is UTC.
--
-- QUERY 1 — best hour and worst hour
-- SAY THIS
-- "I'm grouping every session into a clock hour and averaging the focus
-- score. The first row is the best hour to study. The last row is the
-- worst hour."
--
-- WHAT THE SQL DOES
-- It takes all 2,880 sessions, buckets them by the hour of the day in
-- America/New_York, and averages focus inside each hour. Highest average first.
--
-- EXPECTED RESULT
-- First row: 10 AM, avg_focus 92.7, sessions 180.
-- Last row: 11 PM, avg_focus 37.5, sessions 180.
-- Every hour has 180 sessions.
--
-- WHAT THAT RESULT MEANS
-- 10am is when these students focus best, and 11pm is when they focus
-- worst. The count stays 180 because six people logged that hour on all
-- 30 days. Only the score changes. The hours are Eastern even if the
-- cloud clock is UTC.

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

-- QUERY 2 — where focus is highest, and where it is lowest
-- SAY THIS
-- "Now I'm grouping by place instead of by hour, and taking the same
-- average. The first row is where people focus best. The last row is
-- where they focus worst."
--
-- WHAT THE SQL DOES
-- It averages focus_score for each spot across the whole month, highest
-- first. It does not filter to a single part of the day.
--
-- EXPECTED RESULT
-- Library first, avg_focus 79.1.
-- Cafe in the middle, around 74.
-- Dorm last, around 48.
-- The Cafe and Dorm tenths move a little with the weekday mix. Quote
-- Library at 79.1, and call the Dorm about 48. Do not quote the counts.
--
-- WHAT THAT RESULT MEANS
-- The Library is the most focused place and the Dorm is the least.
-- Daytime hours are mostly the Library, and the Library also adds a few
-- points. Late night is the Dorm, and the Dorm takes points off. The
-- Cafe sits between them.

SELECT
  spot,
  round(avg(focus_score), 1) AS avg_focus,
  count(*) AS sessions
FROM study_sessions
GROUP BY spot
ORDER BY avg_focus DESC;

-- QUERY 3 — where they actually spend the month
-- SAY THIS
-- "This one ignores the score and just counts how many sessions happened
-- in each place. It answers a different question, which is where they
-- actually spend their time."
--
-- WHAT THE SQL DOES
-- It counts sessions for each spot across the whole month. It does not
-- average focus.
--
-- EXPECTED RESULT
-- Library first, about 1,320 to 1,350 sessions.
-- Cafe and Dorm are each under about 810, and they can trade second place.
--
-- WHAT THAT RESULT MEANS
-- The Library is also where they spend the most time, because most of
-- the daytime hours are there. Say the Library is first. Do not lock in
-- a second-place count. That count changes with how the weekdays fall.

SELECT
  spot,
  count(*) AS sessions
FROM study_sessions
GROUP BY spot
ORDER BY sessions DESC;

-- QUERY 4 — the late hours, when the caffeine is highest
-- SAY THIS
-- "Eleven at night was the worst hour, and that is also when everyone
-- is at 160 milligrams of caffeine. This keeps only those late sessions
-- and sorts them so the lowest focus is first."
--
-- WHAT THE SQL DOES
-- It keeps the 160mg sessions, which are 9pm, 10pm, and 11pm, and
-- averages focus for each student in each of those hours. Lowest first.
--
-- EXPECTED RESULT
-- First row: Jordan Blake, 11 PM, caffeine_mg 160, avg_focus 35.0.
-- The next rows are the other late hours.
--
-- WHAT THAT RESULT MEANS
-- Point at the first row. Jordan at 11pm is the low end of the
-- high-caffeine hours. The rows under it are the same late-night pattern
-- for the other students.

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

-- QUERY 5 — the log, the students, and the courses in one database
-- SAY THIS
-- "The students and the courses are ordinary tables sitting next to the
-- log. This join puts each person's major beside the courses they
-- actually studied."
--
-- WHAT THE SQL DOES
-- It joins each session to the student's major and the course name, then
-- sums the minutes for each student and course.
--
-- EXPECTED RESULT
-- One row per student and course they logged, with a major beside it.
-- Jordan and Sam each appear twice, once for Data Structures and once
-- for Databases. Maya, Alex, Priya, and Riley appear once.
--
-- WHAT THAT RESULT MEANS
-- The history and the rest of the app are in one database, so the join
-- is normal SQL. Jordan and Sam have two rows because the last week
-- moves them onto Databases. Maya and Alex were already on Databases,
-- so they stay on one row. Priya stays on Calculus and Riley stays on
-- Writing.

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

-- QUERY 6 — the week before the deadline
-- SAY THIS
-- "For the first 23 days, everyone stays on a home course for 30 minutes
-- a session. In the last 7 days, Maya, Alex, Jordan, and Sam switch every
-- session to Databases, and those sessions go to 50 minutes. This query
-- compares those two stretches."
--
-- WHAT THE SQL DOES
-- It buckets sessions into Eastern days, sums minutes per course per day,
-- then averages those daily totals for the first 23 days and the last 7.
--
-- EXPECTED RESULT
-- Databases: earlier 23 days = 960, final 7 days = 3200
-- Data Structures: earlier 23 days = 960, and no final-week row
-- Calculus: 480, then 480
-- Writing: 480, then 480
--
-- WHAT THAT RESULT MEANS
-- Databases more than triples in the last week because four students
-- switch to it and each session gets longer. Data Structures has no
-- final-week row because Jordan and Sam left that course. A missing row
-- is the switch, not a bug. Calculus and Writing stay flat because Priya
-- and Riley do not switch. The next file asks this same question from a
-- stored summary.

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
