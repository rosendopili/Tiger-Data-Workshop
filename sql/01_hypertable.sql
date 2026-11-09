-- 01_hypertable.sql
-- Clock: about minute 14. Paste this whole file as one run.
--
-- SAY THIS
-- "This is an ordinary CREATE TABLE, plus one option: tsdb.hypertable.
-- That option makes study_sessions a hypertable. TimescaleDB splits the
-- rows into chunks by time. A chunk is a weekly chapter. We still insert
-- and query with normal SQL. segmentby stores each student's rows
-- together inside a chunk. orderby keeps newest time first, which matches
-- the questions we ask."
--
-- EXPECT THIS
-- CREATE TABLE. Then one row from the SELECT, with study_sessions in it.
--
-- IF THIS FAILS
-- If CREATE EXTENSION says permission denied, it is already installed.
-- Skip that line and run the CREATE TABLE.
-- If the error mentions tsdb.segmentby, tsdb.orderby, or the WITH clause,
-- paste the rescue statement at the bottom of this file instead.
-- If the error says the relation already exists, run sql/00_reset.sql,
-- then this file again.

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

-- RESCUE, only if the CREATE TABLE above errors.
-- Drop the broken attempt first, then paste this block:
--
-- DROP TABLE IF EXISTS study_sessions;
-- CREATE TABLE study_sessions (
--   time TIMESTAMPTZ NOT NULL,
--   student TEXT NOT NULL,
--   course TEXT NOT NULL,
--   spot TEXT NOT NULL,
--   minutes INTEGER NOT NULL,
--   focus_score INTEGER NOT NULL,
--   caffeine_mg INTEGER NOT NULL
-- );
-- SELECT create_hypertable('study_sessions', by_range('time'));
-- If by_range is not defined on that server, use the older call:
-- SELECT create_hypertable('study_sessions', 'time');
