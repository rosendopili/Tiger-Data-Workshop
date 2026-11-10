# Presenter guide — 45 minutes

You do not need to be a Timescale expert. Paste the file this guide names. Above each statement, the SQL file has three labels: **What the SQL does**, **Expected result**, and **What that result means**. Read those before you interpret the grid.

Share the SQL editor or the slides. Keep this file on a screen you do not share.

| Clock | What is on screen | File |
| --- | --- | --- |
| 0:00–4:00 | Slides 1–4 | `slides/index.html` |
| 4:00–9:00 | Slides 5–6 | `slides/index.html` |
| 9:00–14:00 | SQL editor | `SELECT current_date;` |
| 14:00–20:00 | Create, seed, chunks | `sql/01_hypertable.sql`, then `sql/02_seed.sql` |
| 20:00–25:00 | Look at `focus-log` in Explorer | No new SQL |
| 25:00–36:00 | The questions, one at a time | `sql/03_queries.sql` |
| 36:00–40:00 | First summary, one month | `sql/04_continuous_aggregate.sql`, one block at a time |
| 40:00–44:00 | Older month, summary grows | `sql/05_second_month.sql`, one block at a time |
| 44:00–45:00 | Three project ideas and the repo URL | No new slide |

## Names

- **Tiger Data** is the company. It used to be called Timescale. **Tiger Cloud** is the managed service on screen.
- **TimescaleDB** is the PostgreSQL extension. It is not a second database.
- The sentence to repeat: "Same PostgreSQL, with time-series parts switched on."

## Analogies you can reuse

- **Time series.** Each row stores what happened and when. That timestamp is what lets you group the rows by hour or day.
- **Why it matters.** A few weeks of sessions show the hour and the place where studying actually works.
- **Hypertable.** The sessions table, split by time for you. You still query it with normal SQL.
- **Chunk.** One time slice inside that table. You do not create it. You can list it.
- **Time bucket.** Group the sessions into an hour or a day, then average or sum them.
- **Continuous aggregate.** A summary page that updates itself, so the app does not reread the whole month on every load.

## 0:00–4:00 — Hook and time series

Slides 1 through 4. Right arrow moves forward. Keys 1–6 jump. About 20 seconds on the title, then the rest of this block on slides 2, 3, and 4.

**Slide 1.** "Today we're building a Focus Log with Tiger Data. It's a student habit app, and it takes about 45 minutes."

**Slide 2.** "This is why the app is useful. You want to find when you actually focus. Log three things: the hour, the place, and how the session went. After a few weeks, that pattern is in the rows."

**Slide 3.** "That history is a time series. Each row stores what happened and the time it happened: a study session, an API request, a match, a sensor reading. You mostly add new rows. The useful questions cover a stretch of time, like which hour or which day."

**Slide 4.** "Once you have a month of rows, you can see the best hour and the best place. You can also see what changed the week before a deadline."

Why this block exists: the room needs to hear that a time series is events with timestamps, before any product name. How: the title, then three slides, no SQL yet.

## 4:00–9:00 — Why Tiger Data

Slides 5 and 6. Then leave the slides. Do not come back to them during the SQL.

**Slide 5, four points. Read them. Do not add a fifth.**

1. "The log lives with the rest of the app. A session, a student, and a course join with normal SQL."
2. "The month is split by time for you. You still query it like a normal table. You do not make a new table for each week."
3. "Daily totals stay up to date. A screen of hours and places can read the summary instead of every session."
4. "It is still PostgreSQL. Same SQL, same drivers, same tools."

**Slide 6.** "There are three things in the demo. A hypertable is the sessions table, split by time for you. A time bucket groups those sessions into an hour or a day. A continuous aggregate is the daily totals the database keeps up to date. The queries are normal SQL."

Why: the room should know the destination before the console. How: two slides, then screen-share the SQL editor.

## 9:00–14:00 — Land in the product

Share the Tiger Cloud SQL editor. Zoom is already 150%.

Paste only this:

```sql
SELECT current_date;
```

Say: "We are connected. The question for the next half hour is when you should study, where, and for which class. The data is a student app called Focus Log. Six people logged a month of hourly sessions. I am going to paste the SQL, and I am not going to type it."

Optional, about 20 seconds, around the moment you create the table: flash `SCHEMA.md` if it is already open, then come straight back. The schema file is for the repo. It is not its own section.

Why: a live connection is more convincing than a diagram of a connection. How: one tiny query whose result you can predict, because it is today's date.

## 14:00–20:00 — Hypertable and the month of data

Paste `sql/01_hypertable.sql` as one run. Read the three labels above the statement, then say the line there. The grid should name `study_sessions`.

Why: attendees need to see that the special table still looks like PostgreSQL. How: one `CREATE TABLE`, then a catalog query so the word "hypertable" is on screen.

Paste `sql/02_seed.sql` as one run. Read the three labels above the statement, then say the line there.

Point at the chunk grid and say: "These rows are the time slices. I did not create them. Thirty days of data landed in a handful of weekly chunks." The count above that grid is the number in **Expected result**.

Say: "At a few thousand rows, a plain table is still fast. We are not going to race them. The SQL is the same either way. This is the version that still works when the log is every student for a year, or every request to an API."

Who is who, if you need it:

- Maya Chen and Alex Nguyen, Computer Science, home course Databases
- Jordan Blake and Sam Ortiz, Computer Science, home course Data Structures
- Priya Shah, Mathematics, Calculus
- Riley Brooks, English, Writing

## 20:00–25:00 — Look at the database

Stay on the `focus-log` service. This is the console, not more SQL. Do not click **Convert to columnstore** or turn on **Automated chunk tuning**. Leave **Show catalog objects** off. Catalog tables will flood the list.

1. If the top of the page says **Data view**, switch the toggle to **Ops view**.
2. Click **Explorer**. The object list is the **Schemas** pane. There is no home tab.
3. Filter that pane to **Tables**. You should see `students` and `courses`. Say: "These are two ordinary tables. The students and the courses live right next to the log."
4. Click `students`. That tab shows the columns, not the rows. Click `+`, paste this, and click **Run**.

```sql
SELECT name, school_year, major
FROM students
ORDER BY name;
```

Say: "Here are the six students. This is a normal PostgreSQL table, and these are the actual rows."

5. Click `courses`. Click `+`, paste this, and click **Run**.

```sql
SELECT name, credits
FROM courses
ORDER BY name;
```

Say: "Here are the four courses. This is a normal table too."

6. Filter to **Hypertables** and click `study_sessions`. Point at the approximate row count, about 2,880, and at the chunk timeline. Then click `+`, paste this, and click **Run**, so the room sees real sessions and not only the chart.

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

Say: "These chunks are the time slices. Each one covers about a week. I did not create them one by one. The database did that when the rows arrived."

7. Filter to **Caggs**. The list is empty. Say: "The daily summary is not here yet. We will build it after the questions."
8. Open the SQL editor again. The floating editor, or **SQL Editor** at the bottom, both work. A query you already ran in Explorer also shows up in the scratchpad tab.

## 25:00–36:00 — The questions

Ask chat: "What would you ask this table?" Count to five. If the room is quiet, say: "I'll start with when people focus, and then I'll look at where."

Run the statements in `sql/03_queries.sql` one at a time, in the order they appear. Highlight a single statement. Running the whole file hides the earlier results. For each statement, read **What the SQL does**, **Expected result**, and **What that result means**, then say the line above it.

The order is the story. First, the best hour and the worst hour. Then the most focused place and the least focused place. Then where they actually spend the month. Then the late, high-caffeine hours. Then the join back to students and courses. Last is the week before the deadline, which is the question the summary repeats. Do not recite a second set of numbers from this guide.

Why this block exists: raw rows are individual sessions, and a grouped query is the hour, the place, or the day a person actually wants. How: six prepared questions, run one at a time.

## 36:00–40:00 — Continuous aggregate

Run `sql/04_continuous_aggregate.sql` one block at a time. Wait for each block to finish before you paste the next one. The refresh has to run after the view exists.

For each block, read the three labels, then say the line there. The last statement is the one-month summary. Use it only before `sql/05`. After the second month, the label "earlier 23 days" mixes both months. That statement is:

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

After block 2, show the summary as an object, then come back for blocks 3 and 4. Stay in **Ops view** and open **Explorer**. In the **Schemas** pane, filter to **Caggs** and click `study_daily`. That tab shows its size, whether real-time aggregation is on, and the refresh period. Say: "This is the summary. It is its own object now, instead of a query we have to rerun by hand." Do not click **Convert to columnstore**. The last statement in the file already shows the summary rows.

Why: the point of the feature is to not rescan history on every page load. How: create empty, fill once on camera, show the schedule, read the summary.

## 40:00–44:00 — Another month

Run `sql/05_second_month.sql` one block at a time. This does not rebuild `students` or `courses`. It adds the 30 days before the month already loaded.

For each block, read the three labels above that statement, then say the line there. Block 2 is one statement, and it should still be one month: about 113 rows, oldest day about 30 days ago. Block 4 has two statements. Run the span first, then the single older day.

Do not run the one-month summary from `sql/04` again. That is the query shown in the previous section, the one that splits "earlier 23 days" from "final 7 days."

Why: a continuous aggregate keeps the days it has already stored. Reading it does not reach back into older raw rows, and a refresh with no dates does not go back for them either. How: insert, show that the summary is unchanged, refresh the last 70 days, read the summary again.

## 44:00–45:00 — Send them home

Put the repository URL on screen in the editor as a comment, or just say it and leave it in the chat:

```sql
-- Repo: paste your URL here before the stream
```

Say: "Any of these has the same shape. You need a timestamp, something you measure, and a question over time. That might be an API's latency, a game season, or a personal Wrapped for music, gym, or coffee. The SQL files in this repo are the replay, and the picture of the tables is SCHEMA.md."

Stop talking while the URL is readable.

## If you are behind

- Minute 33: if you have not compared the earlier 23 days with the final 7 days, run this and then open `sql/04`. Leave the remaining statements in `sql/03_queries.sql`.

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

- Minute 38: skip the schedule. Run the refresh, then the summary:

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

- Minute 42: if you have not started the second month, skip `sql/05_second_month.sql` and close.
- The close can be three project ideas and the URL.
