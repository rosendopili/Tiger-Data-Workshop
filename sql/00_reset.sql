-- 00_reset.sql
-- Run this first when you rehearse, and again if you need a clean database.
-- On the livestream, skip it if the service is already empty.
--
-- SAY THIS
-- "I'm clearing yesterday's rehearsal so we start from an empty database."
--
-- EXPECT THIS
-- DROP MATERIALIZED VIEW and DROP TABLE lines. No error if the objects
-- were already gone.
--
-- IF THIS FAILS
-- Read the error once. If it names a different view or table you created
-- while practicing, drop that object, then run this file again.
-- Do not debug on stream past one retry.

DROP MATERIALIZED VIEW IF EXISTS study_daily CASCADE;
DROP TABLE IF EXISTS study_sessions;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;
