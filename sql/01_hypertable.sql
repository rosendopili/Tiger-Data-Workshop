-- 01_hypertable.sql
-- Clock: about minute 14. Paste this whole file as one run.
--
-- SAY THIS
-- "This is a normal create-table statement, plus one option that splits
-- the log by time. Timescale calls that a hypertable. We still insert
-- rows and query them with ordinary SQL."
--
-- WHAT THE SQL DOES
-- It turns TimescaleDB on if the service does not already have it, creates
-- the empty study_sessions table as a hypertable, and checks the catalog
-- for that name.
--
-- EXPECTED RESULT
-- CREATE TABLE, then one row: hypertable_name = study_sessions.
--
-- WHAT THAT RESULT MEANS
-- The log is a PostgreSQL table, and the database will split it by time
-- as rows arrive. It is empty right now. segmentby keeps one student's
-- rows together inside a slice. orderby stores the newest time first.

CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE study_sessions (
  time TIMESTAMPTZ NOT NULL,
  student TEXT NOT NULL,
  course TEXT NOT NULL,
  spot TEXT NOT NULL,
  minutes INTEGER NOT NULL,
  focus_score INTEGER NOT NULL,
  caffeine_mg INTEGER NOT NULL
) WITH (
  tsdb.hypertable,
  tsdb.segmentby = 'student',
  tsdb.orderby = 'time DESC'
);

SELECT hypertable_name
FROM timescaledb_information.hypertables
WHERE hypertable_name = 'study_sessions';
