-- 00_reset.sql
-- Run this first when you rehearse, and again if you need a clean database.
-- On the livestream, skip it if the service is already empty.
--
-- SAY THIS
-- "I'm clearing yesterday's rehearsal, so we start from an empty database."
--
-- WHAT THE SQL DOES
-- It drops whatever the last run left behind: the daily summary, the
-- session log, and the student and course tables.
--
-- EXPECTED RESULT
-- You should see DROP MATERIALIZED VIEW and DROP TABLE. If those objects
-- were already gone, that is fine too.
--
-- WHAT THAT RESULT MEANS
-- The focus-log service has no workshop tables. The next files build them again.

DROP MATERIALIZED VIEW IF EXISTS study_daily CASCADE;
DROP TABLE IF EXISTS study_sessions;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;
