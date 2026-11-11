# Presenter Guide: Focus Log (45 minutes)

You don't need to be a Timescale expert to run this. Everything you need is on this page: what to say, what to paste, and what the result should look like.

## How to read this guide

- **Say** is what you say out loud, written the way people actually talk. Put it in your own words. The facts and numbers matter more than the exact phrasing.
- **Do** is what to click, paste, or point at.
- **Expect** is what the result grid should show. If it doesn't match, check the rescue notes in that section.
- Every SQL block here is copied from the `sql/` folder, so you can paste straight from this page. If you change a SQL file, change it here too.
- Two long `INSERT` statements stay in their files: `sql/02_seed.sql` and Block 1 of `sql/05_second_month.sql`. Paste those from the file.

Share the SQL editor or the slides. Keep this file on a screen you do not share. Host setup lives in `prep/CHECKLIST.md`.

## The 45 minutes at a glance

| Clock | On screen | What you run |
| --- | --- | --- |
| 0:00–4:00 | Slides 1–4 | Nothing (`slides/index.html`) |
| 4:00–9:00 | Slides 5–6 | Nothing (`slides/index.html`) |
| 9:00–14:00 | SQL editor | `SELECT current_date;` |
| 14:00–20:00 | SQL editor | `sql/01_hypertable.sql`, then `sql/02_seed.sql` |
| 20:00–25:00 | `focus-log` in Explorer | A few small queries, all on this page |
| 25:00–36:00 | SQL editor | `sql/03_queries.sql`, one query at a time |
| 36:00–40:00 | SQL editor, then Explorer | `sql/04_continuous_aggregate.sql`, one block at a time |
| 40:00–44:00 | SQL editor | `sql/05_second_month.sql`, one block at a time |
| 44:00–45:00 | SQL editor | Nothing new, just the repo URL |

## Say it the same way every time

- **Tiger Data** is the company. It used to be called Timescale. **Tiger Cloud** is the managed service on screen.
- **TimescaleDB** is the PostgreSQL extension. It is not a second database.
- The sentence to keep repeating: *"Same PostgreSQL, with time-series parts switched on."*

## Plain-English definitions you can reuse

- **Time series.** Each row stores what happened and when. That timestamp is what lets you group rows by hour or by day.
- **Why it matters.** A few weeks of sessions show you the hour and the place where studying actually works.
- **Hypertable.** The sessions table, split up by time for you. You still query it with normal SQL.
- **Chunk.** One time slice inside that table. You don't create it. You can list it.
- **Time bucket.** Group the sessions into an hour or a day, then average or sum them.
- **Continuous aggregate.** A summary page that updates itself, so the app doesn't reread the whole month every time it loads.

---

## 0:00–4:00 — Hook and time series

**On screen:** Slides 1–4. Right arrow moves forward. Keys 1–6 jump to a slide.

**Goal:** Before anyone hears a product name, the room should understand that a time series is just events with timestamps. No SQL yet.

**Slide 1** (about 20 seconds)

> "Hi everyone, welcome. Today we're going to build a Focus Log with Tiger Data. It's a little student habit app, and we'll get through it in about 45 minutes."

**Slide 2**

> "So why would anyone want this app? Because most of us have no real idea when we focus. Say you logged three things every time you studied: the hour, the place, and how the session went. After a few weeks, the answer is already sitting in those rows."

**Slide 3**

> "That history is what we call a time series. Every row says what happened and when it happened. A study session, an API request, a match in a game, a sensor reading. They all look the same. And notice how you use them. Mostly you keep adding new rows, and the interesting questions are about a stretch of time. Which hour? Which day? Which week?"

**Slide 4**

> "Once you've got a month of rows, you can see the best hour and the best place. You can even see what changed the week before a deadline. That's what we're going to go find."

---

## 4:00–9:00 — Why Tiger Data

**On screen:** Slides 5 and 6. After this, leave the slides for good. Don't come back to them during the SQL.

**Goal:** The room should know where we're headed before they see the console.

**Slide 5: four points.** Say these four, in this order, and stop. Don't add a fifth.

> 1. "First, the log lives right next to the rest of your app. A session, a student, and a course all join with normal SQL."
> 2. "Second, the month gets split up by time for you. You still query it like a normal table. You never create a new table for each week."
> 3. "Third, daily totals stay up to date on their own. A screen showing hours and places can read the summary instead of every single session."
> 4. "And fourth, it's still PostgreSQL. Same SQL, same drivers, same tools."

**Slide 6**

> "There are three ideas in today's demo, and we'll see all three live. A hypertable is the sessions table, split up by time for you. A time bucket groups those sessions into an hour or a day. And a continuous aggregate is the set of daily totals that the database keeps up to date. The queries themselves? Normal SQL."

**Transition**

> "Okay, enough slides. Let's go look at the real thing."

---

## 9:00–14:00 — Land in the product

**On screen:** The Tiger Cloud SQL editor. Zoom is already at 150%.

**Goal:** A live connection is more convincing than a diagram of one. This tiny query is easy to trust because you can predict the answer: today's date.

**Do:** Share the SQL editor. Paste only this, then click **Run**.

```sql
SELECT current_date;
```

**Say:**

> "Okay, we're connected. That's today's date, so we know the database is live. Here's the question for the next half hour: when should you study, where, and for which class? The data comes from a student app called Focus Log. Six people logged a month of hourly sessions. One thing before we start. I'm going to paste the SQL, not type it. Everything I paste is in the repo, so you can replay all of it afterwards."

**Optional (about 20 seconds):** Right when you create the table in the next section, flash `SCHEMA.md` if it's already open, then come straight back. It's there for the repo. It isn't its own section.

### Starting over (rehearsal, or if the service isn't empty)

Run this first when you rehearse, or if you need a clean database. On the livestream, skip it if the service is already empty.

```sql
DROP MATERIALIZED VIEW IF EXISTS study_daily CASCADE;
DROP TABLE IF EXISTS study_sessions;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;
```

**Say:** "I'm clearing yesterday's rehearsal, so we start from an empty database."

**Expect:** `DROP MATERIALIZED VIEW` and `DROP TABLE`. If those objects were already gone, that's fine too.

---

## 14:00–20:00 — Hypertable and the month of data

### Step 1: create the hypertable (`sql/01_hypertable.sql`)

**Goal:** Attendees should see that the special table still looks like PostgreSQL. One `CREATE TABLE`, then a catalog query so the word "hypertable" is on screen.

**Do:** Paste the whole file as one run.

```sql
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
```

**Say:**

> "This is a normal create-table statement, plus one option that splits the log by time. Timescale calls that a hypertable. We still insert rows and query them with ordinary SQL."

**Expect:** `CREATE TABLE`, then one row: `hypertable_name = study_sessions`.

**Say (after it runs):**

> "There's the word hypertable in the grid. It's still a PostgreSQL table, and the database will split it by time as rows arrive. Right now it's empty, so let's fill it."

*If someone asks about the last two options:* `segmentby` keeps one student's rows together inside a slice, and `orderby` stores the newest time first. You don't need either one to follow the demo.

### Step 2: load a month of data (`sql/02_seed.sql`)

**Do:** Paste the whole file as one run. The insert is deterministic, so rehearsal and the livestream give the same focus scores, courses, and spots. Hours are America/New_York.

**Say:**

> "I'm loading six students, every hour from 8am to 11pm Eastern, for the 30 days that end yesterday. That comes out to 2,880 study sessions. And I planted the patterns, so we already know what the questions should find. Focus peaks at 10am and falls off by 11pm. The library is the best place, and the dorm is the worst. And Databases jumps in the last week."

**Expect:** `INSERT 0 6`, `INSERT 0 4`, `INSERT 0 2880`. Then two grids at the bottom. These are the last two statements in the file:

```sql
SELECT count(*) AS sessions FROM study_sessions;

SELECT
  chunk_name,
  range_start,
  range_end
FROM timescaledb_information.chunks
WHERE hypertable_name = 'study_sessions'
ORDER BY range_start;
```

- The count grid shows `sessions = 2880`.
- The chunk grid shows a handful of chunks, each covering about a week.

**Say (point at the count):**

> "2,880 is six students, 16 hours a day, for 30 days."

**Say (point at the chunk grid):**

> "And these rows are the time slices. I didn't create them. Thirty days of data landed in a handful of weekly chunks. The insert made them."

**Say (the honest caveat):**

> "At a few thousand rows, a plain table is still fast, so we're not going to race them. The SQL is the same either way. This is the version that keeps working when the log is every student for a year, or every request to an API."

**Who is who, if you need it:**

- Maya Chen and Alex Nguyen: Computer Science, home course Databases
- Jordan Blake and Sam Ortiz: Computer Science, home course Data Structures
- Priya Shah: Mathematics, Calculus
- Riley Brooks: English, Writing

---

## 20:00–25:00 — Look at the database

**On screen:** The `focus-log` service in Tiger Console. This is a console tour, with a few small queries.

**Don't click:** **Convert to columnstore** or **Automated chunk tuning**. Leave **Show catalog objects** off, because catalog tables flood the list.

**Do, step by step:**

1. If the top of the page says **Data view**, switch the toggle to **Ops view**.
2. Click **Explorer**. The object list is the **Schemas** pane. There is no home tab.
3. Filter the pane to **Tables**. You should see `students` and `courses`.

   **Say:** "These are two ordinary tables. The students and the courses live right next to the log."

4. Click `students`. That tab shows the columns, not the rows. Click `+`, paste this, and click **Run**.

   ```sql
   SELECT name, school_year, major
   FROM students
   ORDER BY name;
   ```

   **Say:** "Here are the six students. It's a normal PostgreSQL table, and these are the actual rows."

5. Click `courses`. Click `+`, paste this, and click **Run**.

   ```sql
   SELECT name, credits
   FROM courses
   ORDER BY name;
   ```

   **Say:** "And here are the four courses. Also a normal table."

6. Filter to **Hypertables** and click `study_sessions`. Point at the approximate row count (about 2,880) and at the chunk timeline. Then click `+`, paste this, and click **Run**, so the room sees real sessions and not only a chart.

   ```sql
   SELECT
     time AT TIME ZONE 'America/New_York' AS time_eastern,
     student,
     course,
     spot,
     focus_score
   FROM study_sessions
   ORDER BY time DESC
   LIMIT 8;
   ```

   **Say:** "These chunks are the time slices. Each one covers about a week. I didn't create them one by one. The database did that as the rows arrived. And down here are the eight most recent sessions, so you can see what a row really looks like."

7. Filter to **Caggs**. The list is empty.

   **Say:** "The daily summary isn't here yet. We'll build it right after the questions."

8. Open the SQL editor again. The floating editor and **SQL Editor** at the bottom both work. A query you already ran in Explorer also shows up in the scratchpad tab.

---

## 25:00–36:00 — The questions

**On screen:** The SQL editor.

**Goal:** Raw rows are individual sessions. A grouped query gives you the hour, the place, or the day a person actually cares about. Six prepared questions, run one at a time.

**How to run them:** Highlight a single statement and run only that one. Running the whole file hides the earlier results, and the editor may show only the last one. Hours and days are America/New_York, so hour 10 means 10am Eastern even when the cloud clock is UTC.

**Open with the room:**

> "Before I paste anything, what would you ask this table? Drop it in the chat."

Count to five. If the room is quiet:

> "No worries, I'll start with when people focus, and then I'll look at where."

The order is the story: best and worst hour, then the best and worst place, then where they actually spend time, then the late high-caffeine hours, then the join back to students and courses, and last the week before the deadline.

### Query 1: best hour and worst hour

**Say:**

> "I'm grouping every session into a clock hour and averaging the focus score. The first row is the best hour to study. The last row is the worst."

```sql
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
```

**Expect:** First row is 10 AM, `avg_focus` 92.7, 180 sessions. Last row is 11 PM, `avg_focus` 37.5, 180 sessions. Every hour has 180 sessions.

**Say (after it runs):**

> "10am is when these students focus best, at 92.7. 11pm is the worst, at 37.5. Notice every hour has exactly 180 sessions, because six people logged that hour on all 30 days. So the count never changes, and only the score does. And these are Eastern hours, even though the cloud clock runs on UTC."

### Query 2: where focus is highest, and where it's lowest

**Say:**

> "Now I'm grouping by place instead of by hour, and taking the same average. The first row is where people focus best. The last row is where they focus worst."

```sql
SELECT
  spot,
  round(avg(focus_score), 1) AS avg_focus,
  count(*) AS sessions
FROM study_sessions
GROUP BY spot
ORDER BY avg_focus DESC;
```

**Expect:** Library first at 79.1. Cafe in the middle, around 74. Dorm last, around 48.

**Careful with numbers:** The Cafe and Dorm tenths drift a little with the weekday mix. Quote the Library at 79.1 and call the Dorm "about 48." Don't quote the counts.

**Say (after it runs):**

> "The Library is the most focused place and the Dorm is the least. Part of that is when people are there. Daytime is mostly the Library, and the Library adds a few points. Late night is the Dorm, and the Dorm takes points off. The Cafe sits in between."

### Query 3: where they actually spend the month

**Say:**

> "This one ignores the score and just counts how many sessions happened in each place. It answers a different question: where do they actually spend their time?"

```sql
SELECT
  spot,
  count(*) AS sessions
FROM study_sessions
GROUP BY spot
ORDER BY sessions DESC;
```

**Expect:** Library first, about 1,320 to 1,350 sessions. Cafe and Dorm are each under about 810, and they can trade second place.

**Say (after it runs):**

> "The Library is first again, because most of the daytime hours happen there. I won't lock in a second place. Cafe and Dorm can swap depending on how the weekdays fall."

### Query 4: the late hours, when the caffeine is highest

**Say:**

> "Eleven at night was the worst hour, and it's also one of the high-caffeine hours. This keeps only the sessions at 160 milligrams, which are 9, 10, and 11 at night, and sorts them so the lowest focus comes first."

```sql
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
```

**Expect:** First row is Jordan Blake, 11 PM, `caffeine_mg` 160, `avg_focus` 35.0. The next rows are the other late hours.

**Say (point at the first row):**

> "There's Jordan at 11pm, at 35.0. That's the low end of the high-caffeine hours. The rows underneath are the same late-night pattern for everyone else."

### Query 5: the log, the students, and the courses in one database

**Say:**

> "Remember the students and courses tables from the console? They're ordinary tables sitting right next to the log. So this join puts each person's major beside the courses they actually studied."

```sql
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
```

**Expect:** One row per student and course they logged, with a major beside it. Jordan and Sam each appear twice, once for Data Structures and once for Databases. Maya, Alex, Priya, and Riley appear once.

**Say (after it runs):**

> "The history and the rest of the app are in one database, so this is just a normal join. Jordan and Sam show up twice because in the last week they moved from Data Structures onto Databases. Maya and Alex were already on Databases, so they stay on one row. Priya stays on Calculus and Riley stays on Writing."

### Query 6: the week before the deadline

**Say:**

> "For the first 23 days, everyone studies their home course, 30 minutes a session. In the last 7 days, Maya, Alex, Jordan, and Sam switch every session to Databases, and those sessions get longer, 50 minutes. This query compares the two stretches."

```sql
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
```

**Expect:**

- Databases: earlier 23 days = 960, final 7 days = 3200
- Data Structures: earlier 23 days = 960, and no final-week row
- Calculus: 480, then 480
- Writing: 480, then 480

**Say (after it runs):**

> "Databases goes from 960 minutes a day to 3,200. That's more than triple, because four students switched to it and every session got longer. Now look at Data Structures. There's no final-week row at all. That isn't a bug. Jordan and Sam left that course. And Calculus and Writing stay flat, because Priya and Riley didn't switch."

**Transition:**

> "Hold onto that result, because we're about to ask this exact question again, but this time from a stored summary."

---

## 36:00–40:00 — Continuous aggregate

**On screen:** The SQL editor, with one trip to Explorer in the middle.

**Goal:** The point of this feature is that the database doesn't rescan history on every page load. The flow is: create the summary empty, fill it once on camera, show the schedule, then read the summary.

**How to run it:** Run `sql/04_continuous_aggregate.sql` one block at a time. Wait for each block to finish before you paste the next one. The refresh has to run after the view exists.

### Block 1: create the summary, empty on purpose

**Say:**

> "This creates a daily summary that the database can keep up to date. I'm leaving it empty on purpose. The next statement fills it in."

```sql
CREATE MATERIALIZED VIEW study_daily
WITH (timescaledb.continuous) AS
SELECT
  time_bucket('1 day', time, timezone => 'America/New_York') AS day,
  course,
  sum(minutes) AS total_minutes,
  round(avg(focus_score), 1) AS avg_focus,
  count(*) AS sessions
FROM study_sessions
GROUP BY time_bucket('1 day', time, timezone => 'America/New_York'), course
WITH NO DATA;
```

**Expect:** `CREATE MATERIALIZED VIEW`.

**What it means:** `study_daily` stores one row per Eastern day and course, with total minutes, average focus, and a session count. `WITH NO DATA` means nothing is in it yet.

### Block 2: fill the summary now

**Say:**

> "This reads the month of sessions once and writes the daily totals. After this, a dashboard can read the summary instead of reading every session."

```sql
CALL refresh_continuous_aggregate('study_daily', NULL, NULL);
```

**Expect:** `CALL`, with no error, in a few seconds.

**What it means:** `NULL, NULL` means the whole time range, which right now is the one month in the table. The next question can read about 113 summary rows instead of all 2,880 sessions.

### Pause here: show the summary as an object

**Do:** Stay in **Ops view** and open **Explorer**. In the **Schemas** pane, filter to **Caggs** and click `study_daily`. That tab shows its size, whether real-time aggregation is on, and the refresh period. Don't click **Convert to columnstore**.

**Say:**

> "And here it is. This is the summary. It's its own object now, instead of a query we have to rerun by hand."

Then go back to the SQL editor for Blocks 3 and 4.

### Block 3: the schedule

**Say:**

> "This next part we are not going to sit here and wait for. Once an hour, the database refreshes the recent days in the background."

```sql
SELECT add_continuous_aggregate_policy(
  'study_daily',
  start_offset => INTERVAL '30 days',
  end_offset => INTERVAL '1 day',
  schedule_interval => INTERVAL '1 hour'
);
```

**Expect:** One row with a job id. Any integer means it worked.

**What it means:** The hourly job refreshes `study_daily` from 30 days ago up through yesterday. It does not run during this paste, and you don't wait for it. The page is already filled from the refresh you just ran.

### Block 4: read the summary

**Say:**

> "Here's the same deadline question we just asked. This time the database reads the summary, instead of all 2,880 sessions."

```sql
SELECT
  CASE
    WHEN (day AT TIME ZONE 'America/New_York')::date
         >= (timezone('America/New_York', now()))::date - 7
      THEN 'final 7 days'
    ELSE 'earlier 23 days'
  END AS period,
  course,
  (sum(total_minutes) / count(*))::integer AS avg_minutes_per_day
FROM study_daily
GROUP BY period, course
ORDER BY course, period;
```

**Expect:** Same as Query 6.

- Databases: earlier 23 days = 960, final 7 days = 3200
- Data Structures: earlier 23 days = 960, no final-week row
- Calculus: 480, then 480
- Writing: 480, then 480

**Say (after it runs):**

> "Same answer as before, but this time it came from the summary. Databases more than triples in the last week, and Data Structures disappears because Jordan and Sam left it."

**Heads up:** Use this query only while the table holds one month. After the next file, the "earlier 23 days" label would mix both months.

---

## 40:00–44:00 — Another month

**On screen:** The SQL editor.

**Goal:** A continuous aggregate keeps the days it has already stored. Reading it doesn't reach back into older raw rows, and a refresh with no dates doesn't go back for them either. The flow is: insert, show that the summary is unchanged, refresh the last 70 days, then read the summary again.

**How to run it:** Run `sql/05_second_month.sql` one block at a time. It does not rebuild `students` or `courses`. It adds the 30 days before the month you already loaded (60 days ago through 31 days ago). Run it only after you've queried the summary from `sql/04`.

**Don't:** Run the one-month summary query from `sql/04` again. It splits "earlier 23 days" from "final 7 days," and after this file it mixes both months and keeps printing 960, which hides the new month.

### Block 1: insert the older month

**Do:** Paste Block 1 from the file. It's a long `INSERT` followed by the count query below.

**Say:**

> "This adds the 30 days before the month we already have. Everyone stays on their home course. The log gets bigger, and the summary hasn't been rewritten yet."

The count query that closes the block:

```sql
SELECT
  count(*) AS sessions,
  min((time AT TIME ZONE 'America/New_York')::date) AS oldest_day,
  max((time AT TIME ZONE 'America/New_York')::date) AS newest_day
FROM study_sessions;
```

**Expect:** `INSERT 0 2880`. Then `sessions = 5760`, `oldest_day` is 60 days ago, `newest_day` is yesterday.

**Say (after it runs):**

> "So the raw log now holds two months. Those older days are all home courses at 30 minutes, so no cramming in there. And this insert didn't touch the daily summary."

**Rescue:** If `sessions` already reads 5760, the insert already ran. Skip it and go on to Block 3.

### Block 2: the summary is still the first month

**Say:**

> "The raw log has two months, but the summary still has one. Reading it doesn't reach back into those older sessions."

```sql
SELECT
  min((day AT TIME ZONE 'America/New_York')::date) AS oldest_day,
  max((day AT TIME ZONE 'America/New_York')::date) AS newest_day,
  count(*) AS summary_rows
FROM study_daily;
```

**Expect:** `oldest_day` is about 30 days ago, `newest_day` is yesterday, `summary_rows = 113`. This is one statement, and it should still be one month.

**Say (after it runs):**

> "113 rows, one month. And here's the catch: the hourly job only looks back 30 days, so it won't store this older month on its own either."

### Block 3: write the older month into the summary

**Say:**

> "The first refresh only stored the month that existed at that time. Refreshing again with no dates doesn't go back for this older month either. So this call names the last 70 days and forces those days to be rewritten."

```sql
CALL refresh_continuous_aggregate(
  'study_daily',
  now() - INTERVAL '70 days',
  now() + INTERVAL '1 day',
  force => true
);
```

**Expect:** `CALL`, with no error.

**What it means:** Every daily bucket in the last 70 days is recomputed, including the month older than the 30-day schedule. Left alone, the hourly job would keep refreshing the recent month and leave this older month unstored.

**Rescue:** If `force` is rejected, run this version instead, then go to Block 4.

```sql
CALL refresh_continuous_aggregate(
  'study_daily',
  now() - INTERVAL '70 days',
  now() + INTERVAL '1 day'
);
```

### Block 4: the summary now covers both months

This block has two statements. Run the span first, then the single older day.

**Say:**

> "Now the oldest day jumps back a month, and the summary grows from 113 rows to 233. And look at one day in that older month. It's a normal day, before anyone started cramming."

```sql
SELECT
  min((day AT TIME ZONE 'America/New_York')::date) AS oldest_day,
  max((day AT TIME ZONE 'America/New_York')::date) AS newest_day,
  count(*) AS summary_rows
FROM study_daily;
```

**Expect:** `oldest_day` is 60 days ago, `newest_day` is yesterday, `summary_rows = 233`.

```sql
SELECT
  course,
  total_minutes
FROM study_daily
WHERE (day AT TIME ZONE 'America/New_York')::date
      = (timezone('America/New_York', now()))::date - 45
ORDER BY course;
```

**Expect:** Four rows: Calculus 480, Data Structures 960, Databases 960, Writing 480.

**Say (after it runs):**

> "That's one Eastern day, 45 days ago. Databases is only 960 here, because it's just Maya and Alex at 30 minutes a session. The 3,200-minute week is still only the most recent 7 days. So two months of daily totals are stored now."

---

## 44:00–45:00 — Send them home

**On screen:** The SQL editor. Put the repo URL on screen as a comment, or just say it and drop it in the chat:

```sql
-- Repo: github.com/rosendopili/Tiger-Data-Workshop
```

**Say:**

> "Pretty much any project has this same shape: a timestamp, something you measure, and a question over time. That could be an API's latency, a game season, or a personal Wrapped for your music, gym, or coffee. Every SQL file we pasted today is in the repo, so you can replay all of it, and the picture of the tables is in SCHEMA.md."

Then stop talking while the URL is readable.

**If someone asks where to go next:** two pages go further on the same ideas, [Your first hypertable](https://www.tigerdata.com/docs/build/how-to/your-first-hypertable) and [Create a continuous aggregate](https://www.tigerdata.com/docs/build/continuous-aggregates/create-a-continuous-aggregate).

**If someone asks how an AI assistant can query this database:** point them at the last section of this file. Don't install anything on stream.

---

## If you're behind

### At minute 33

If you haven't compared the earlier 23 days with the final 7 days yet, run this and then jump to `sql/04`. Leave the remaining statements in `sql/03_queries.sql`.

```sql
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
```

### At minute 38

Skip the schedule (Block 3). Run the refresh, then the summary:

```sql
CALL refresh_continuous_aggregate('study_daily', NULL, NULL);
```

```sql
SELECT
  CASE
    WHEN (day AT TIME ZONE 'America/New_York')::date
         >= (timezone('America/New_York', now()))::date - 7
      THEN 'final 7 days'
    ELSE 'earlier 23 days'
  END AS period,
  course,
  (sum(total_minutes) / count(*))::integer AS avg_minutes_per_day
FROM study_daily
GROUP BY period, course
ORDER BY course, period;
```

---

## Bonus: query focus-log from an AI assistant

Tiger Cloud already includes this. The server is called Tiger MCP, and it ships inside the Tiger CLI. You don't write a server for Focus Log. An assistant on your machine can run SQL against the `focus-log` service using your Tiger Cloud login.

```bash
tiger auth login
tiger service list
tiger config set read_only all
tiger mcp install
```

The server shows up as `tiger`. In `tiger service list`, use the service named `focus-log`. The service id in that list may differ from the name.

**Say:**

> "Tiger Cloud ships a server for this, so there's nothing to build. Once it's installed, you can ask an assistant a question about your own data."

Then ask the assistant:

> "Using Tiger MCP, query the focus-log service. What is the oldest day and row count in study_daily, and what is the average focus by hour?"
