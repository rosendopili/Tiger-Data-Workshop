-- 02_seed.sql
-- Clock: minutes 14–20. Paste this whole file as one run.
-- The insert is deterministic. Rehearsal and the livestream produce the
-- same focus scores, courses, and spots. Hours are America/New_York.
--
-- SAY THIS
-- "I'm loading six students, every hour from 8am to 11pm Eastern, for the
-- 30 days that end yesterday. That comes out to 2,880 study sessions.
-- I planted the patterns, so we already know what the questions should
-- find. Focus peaks at 10am and falls off by 11pm. The library is the
-- best place, and the dorm is the worst. Databases jumps in the last week."
--
-- WHAT THE SQL DOES
-- It creates the student and course tables, loads the first month of
-- sessions, counts those rows, and lists the time slices that now hold them.
--
-- EXPECTED RESULT
-- INSERT 0 6, INSERT 0 4, INSERT 0 2880.
-- The count grid shows sessions = 2880.
-- The last grid is a handful of chunks, each covering about a week.
--
-- WHAT THAT RESULT MEANS
-- The month is loaded. 2,880 is 6 students, 16 hours a day, 30 days.
-- The chunk list is the time split. Those slices were created by the
-- insert. You did not make a table for each week.

CREATE TABLE students (
  name TEXT PRIMARY KEY,
  school_year TEXT NOT NULL,
  major TEXT NOT NULL
);

CREATE TABLE courses (
  name TEXT PRIMARY KEY,
  credits INTEGER NOT NULL
);

INSERT INTO students (name, school_year, major) VALUES
  ('Maya Chen', 'junior', 'Computer Science'),
  ('Alex Nguyen', 'senior', 'Computer Science'),
  ('Jordan Blake', 'sophomore', 'Computer Science'),
  ('Sam Ortiz', 'freshman', 'Computer Science'),
  ('Priya Shah', 'junior', 'Mathematics'),
  ('Riley Brooks', 'junior', 'English');

INSERT INTO courses (name, credits) VALUES
  ('Databases', 4),
  ('Data Structures', 4),
  ('Calculus', 4),
  ('Writing', 3);

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
      WHEN slot.day >= slot.today_ny - 7
           AND slot.student IN ('Maya Chen', 'Alex Nguyen', 'Jordan Blake', 'Sam Ortiz')
        THEN 'Databases'
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
    CASE
      WHEN slot.day >= slot.today_ny - 7
           AND slot.student IN ('Maya Chen', 'Alex Nguyen', 'Jordan Blake', 'Sam Ortiz')
        THEN 50
      ELSE 30
    END AS minutes,
    slot.base_focus,
    CASE
      WHEN slot.hour >= 21 THEN 160
      WHEN slot.hour >= 17 THEN 80
      ELSE 0
    END AS caffeine_mg
  FROM (
    SELECT
      day_series.day::date AS day,
      (timezone('America/New_York', now()))::date AS today_ny,
      hours.hour,
      hours.base_focus,
      students.name AS student
    FROM generate_series(
      (timezone('America/New_York', now()))::date - 30,
      (timezone('America/New_York', now()))::date - 1,
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

SELECT
  chunk_name,
  range_start,
  range_end
FROM timescaledb_information.chunks
WHERE hypertable_name = 'study_sessions'
ORDER BY range_start;
