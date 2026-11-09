# Presenter guide — 45 minutes

You do not need to be a Timescale expert. Read the line, paste the file it names, and check the result against the number in this guide. If a paste fails, say the rescue line once and move forward.

Share the SQL editor or the slides. Keep this file on a screen you do not share.

| Clock | What is on screen | File |
| --- | --- | --- |
| 0:00–4:00 | Slides 1–4 | `slides/index.html` |
| 4:00–9:00 | Slides 5–6 | `slides/index.html` |
| 9:00–14:00 | SQL editor | `SELECT current_date;` |
| 14:00–20:00 | Create, seed, chunks | `sql/01_hypertable.sql`, then `sql/02_seed.sql` |
| 20:00–25:00 | Look at `focus-log` in Explorer | No new SQL |
| 25:00–33:00 | Three questions | `sql/03_queries.sql`, one query at a time |
| 33:00–40:00 | Summary page | `sql/05_continuous_aggregate.sql`, one block at a time |
| 40:00–45:00 | Repo URL, spoken | No new slide |

`sql/04_alternates.sql` is optional. Use it only if chat asks and you are ahead.

## Names

- **Tiger Data** is the company. It used to be called Timescale. **Tiger Cloud** is the managed service on screen.
- **TimescaleDB** is the PostgreSQL extension. It is not a second database.
- The sentence to repeat: "Same PostgreSQL, with time-series parts switched on."

## Do not say

- Do not say Tiger Data wins every benchmark, or quote a speedup you have not just shown.
- If someone asks "is it faster than X?", say: "The reason in this workshop is one database, automatic time partitioning, summaries that stay current, and ordinary SQL. Speed depends on the workload. Tiger publishes numbers on their site. We are not reproducing those today."
- Do not compare products as a buying guide. Stay on what this database is good at.
- Do not invent an answer. A true line is: "I don't want to make that up on stream. The docs link is in the repo, and I'll follow up in chat."
- Hypercore and tiered storage get one sentence each, at the end, and then you stop.

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

**Slide 6.** "Three things in the demo. A hypertable is the sessions table, split by time for you. A time bucket groups those sessions into an hour or a day. A continuous aggregate is daily totals the database keeps up to date. The queries are normal SQL."

Why: the room should know the destination before the console. How: two slides, then screen-share the SQL editor.

## 9:00–14:00 — Land in the product

Share the Tiger Cloud SQL editor. Zoom is already 150%.

Paste only this:

```sql
SELECT current_date;
```

Say: "We are connected. The question for the next half hour is: when should I study, where, and for which class? The data is a student app called Focus Log. Six people, a month of hourly sessions. I am going to paste the SQL. I am not going to type it."

Optional, about 20 seconds, around the moment you create the table: flash `SCHEMA.md` if it is already rendered, then come straight back. If the preview is fiddly, skip it. The schema file is for the repo. It is not its own section.

Why: a live connection is more convincing than a diagram of a connection. How: one tiny query whose result you can predict, because it is today's date.

**If `current_date` fails:** reload the Tiger Cloud SQL editor and paste it again. Stay in the console. Do not switch to a local database.

## 14:00–23:00 — Hypertable and the month of data

Paste `sql/01_hypertable.sql` as one run.

Say: "This is a normal `CREATE TABLE`. The extra is `tsdb.hypertable`. TimescaleDB will partition `study_sessions` by time into chunks. A chunk is a weekly chapter. `segmentby` keeps one student's rows together inside a chapter. `orderby` stores newest time first. We still `INSERT` and `SELECT` with normal SQL. The grid should list `study_sessions`."

Why: attendees need to see that the special table still looks like PostgreSQL. How: one `CREATE TABLE`, then a catalog query so the word "hypertable" is on screen.

**If the `WITH` clause errors:** paste the rescue block at the bottom of `sql/01_hypertable.sql`. Say "Older syntax, same idea: create the table, then turn it into a hypertable."

Paste `sql/02_seed.sql` as one run.

Say: "Six students. Every hour from 8am to 11pm Eastern, for the 30 days ending yesterday. 2,880 sessions. The patterns are planted, so we can predict the answers. Focus peaks at 10am. The library beats the dorm on weeknights. In the last week, four students cram Databases."

Point at the chunk grid. "These rows are the chapters. I did not create them. Thirty days of data landed in a handful of weekly chunks. The count just above is 2,880."

Say this so you do not get dragged into a benchmark: "At a few thousand rows, a plain table is still fast. We are not going to race them. The SQL is identical on purpose. This is the version that still works when the log is every student for a year, or every request to an API."

Who is who, if you need it:

- Maya Chen and Alex Nguyen, Computer Science, home course Databases
- Jordan Blake and Sam Ortiz, Computer Science, home course Data Structures
- Priya Shah, Mathematics, Calculus
- Riley Brooks, English, Writing

**If the seed errors with "already exists":** you rehearsed and did not reset. Say "That copy is from rehearsal." Run `sql/00_reset.sql`, then `01`, then `02`.

**If the chunk columns error:** the insert already worked. Paste the `show_chunks` rescue at the bottom of `sql/02_seed.sql`.

## 20:00–25:00 — Look at the database

Stay on the `focus-log` service. This is the console, not more SQL. Do not click **Convert to columnstore** or turn on **Automated chunk tuning**. Leave **Show catalog objects** off. Catalog tables will flood the list.

1. If the top of the page says **Data view**, switch the toggle to **Ops view**.
2. Click **Explorer**.
3. On the home tab, point at **General information**. You should see `students`, `courses`, and `study_sessions`. Say: "Two ordinary tables, and one hypertable. The students and the courses live next to the log."
4. In the **Schemas** pane, filter to **Tables**. Click `students`. Point at the columns `name`, `school_year`, and `major`. Say: "Six students. This is a normal PostgreSQL table."
5. Click `courses`. Say: "Four courses. Also a normal table."
6. Filter to **Hypertables** and click `study_sessions`. Point at the approximate row count, about 2,880, and at the chunk timeline. Say: "These chunks are the time slices. Each one covers about a week. I did not create them one by one. The database did that when the rows arrived."
7. Filter to **Caggs**. The list is empty. Say: "The daily summary is not here yet. We build it after the questions."
8. Open the SQL editor again. The floating editor, or **SQL Editor** at the bottom, both work.

**If Explorer is not where you expect:** search the Schemas pane for `study_sessions` and open that. If you still cannot find it after about 20 seconds, say "The object list is being shy. The SQL already showed the chunks," and go to the questions.

## 25:00–33:00 — Three questions

Ask chat: "What would you ask this table?" Count to five. If the room is quiet, say "The three I prepared are when, where, and which class."

Run the statements in `sql/03_queries.sql` one at a time. The whole file at once hides the earlier results.

**Query A, when.** " `time_bucket` staples every session into a clock hour. Then we average focus. Hour 10 means 10am Eastern, even if the cloud clock is UTC."

Expect the first row to be **10 AM, 92.7 focus, 180 sessions**. The bottom of the list is **11 PM, 37.5**. Every hour has 180 sessions because six students logged that hour on all 30 days.

**Query B, where.** "Weeknights, 5pm to 8pm. Library versus dorm."

Expect **Library 77.3** and **Dorm 60.6**. Session counts depend on how many weekdays fall in this particular month. Talk about the averages.

**Query C, which class.** "For 23 days each student stays on a home course, 30 minutes. In the last 7 days Maya, Alex, Jordan, and Sam switch every session to Databases and those sessions become 50 minutes."

Expect:

- Databases, earlier 23 days, **960** minutes a day, then final 7 days **3200**
- Data Structures, **960**, and no final-week row. Say: "Jordan and Sam left Data Structures. A missing row is the switch, not a bug."
- Calculus **480** then **480**. Writing **480** then **480**.

Why this block exists: raw rows are a diary, and buckets are the summary a person wants. How: three prepared questions, each using `time_bucket`.

**If a query errors:** read the rescue under that query in the SQL file, say it, and go to the next query. Do not edit SQL on camera.

## 33:00–40:00 — Continuous aggregate

Run `sql/05_continuous_aggregate.sql` one block at a time. Wait for each success. Pasting the whole file can fail because the refresh needs the view to exist outside the statement that created it.

**Block 1.** "A continuous aggregate is a materialized view TimescaleDB knows how to refresh. `WITH NO DATA` creates the page immediately, empty, so we are not stuck waiting inside the create."

**Block 2.** "This fills `study_daily` now: one row per course per day. A dashboard reads that page instead of rereading 2,880 sessions every time it loads." If you are still inside this block's time, click **Explorer**, filter **Caggs**, and open `study_daily`. Say: "This is the empty spot from earlier. It is the daily summary now." Then come back to the SQL editor. Skip this click if you are behind.

**Block 3.** "This schedules the refresh we are not waiting for. Once an hour, recent daily buckets get updated. The integer on screen is a job id. Any integer means the schedule exists."

**Block 4.** "Same deadline question. The numbers should match the earlier query, because the summary was built from the same sessions. Databases 960 then 3,200. Calculus and Writing stay at 480."

Why: the point of the feature is to not rescan history on every page load. How: create empty, fill once on camera, show the schedule, read the summary.

**If block 1 rejects `timezone`:** use the rescue view in the SQL file and say the summary days are UTC for this run. The jump should still be visible. Do not promise 960 and 3200 after switching to UTC buckets.

**If block 3 fails:** the page is already filled. Skip the schedule and run block 4.

## 40:00–45:00 — Send them home

Put the repository URL on screen in the editor as a comment, or just say it and leave it in the chat:

```sql
-- Repo: paste your URL here before the stream
```

Say: "Same shape for any of these projects. A timestamp, a thing you measure, a question over time."

- Focus Log, the demo: sessions over a semester.
- API heartbeat: latency and error rate for a portfolio site. This is the one that shows up in jobs.
- A season diary: rank and score across a game season.
- A personal Wrapped: music, gym, or coffee, grouped by week.
- A study-room sensor: temperature and occupancy, so you stop walking to a full library.
- Stream pulse: chat messages per minute. You are watching one of those right now.

"Two things we did not demo. Hypercore is Tiger's storage engine: recent rows stay easy to update, older data is stored in a column layout, and Tiger documents large storage savings from that. Tiered storage can move cold data to cheaper object storage and still query it. Both are real. A retention policy, dropping raw rows you no longer need, is the other lever. None of the three fit this 45 minutes."

"Replay is the SQL files in order. The picture of the tables is `SCHEMA.md`. The shortest official next step is the Tiger 5-minute quickstart, then the first-hypertable page."

- https://www.tigerdata.com/docs/get-started/quickstart/quickstart-5-minutes
- https://www.tigerdata.com/docs/build/how-to/your-first-hypertable

Stop talking while the URL is readable.

## If you are behind

- If Explorer takes more than 20 seconds to find, skip the rest of the tour and start the questions.
- Minute 30: skip `sql/04_alternates.sql`.
- Minute 36: skip the policy. Refresh and run the last `SELECT`.
- The close can be three project ideas and the URL.

## Optional answers

Only if asked, and only the matching query in `sql/04_alternates.sql`.

- "Who had the most caffeine and the least focus?" First row: **Jordan Blake, 11 PM, 160mg, focus 35.0**. Point at that row. Later rows are other late nights.
- "Which spot is busiest?" **Library**, about 1,300 to 1,350 sessions. Cafe and Dorm are each under about 810. Say Library is first.
- "Where are the students?" Run the join. Maya, Alex, Jordan, and Sam each have two courses because of the cram week. Priya and Riley have one.
