# Focus Log: a 45-minute Tiger Data workshop

A watch-along livestream for people new to time-series data. The presenter builds **Focus Log**, a student habit app, in Tiger Cloud. You can replay every paste from this repo.

Tiger Data is the company behind **TimescaleDB**, a PostgreSQL extension. Tiger Cloud is the managed service. You are not learning a second database. You are using PostgreSQL with time-series parts switched on.

## What happens

| Minutes | You see |
| --- | --- |
| 0–4 | What a time series is: each row records what happened and when |
| 4–9 | Why Tiger Data: one database for the app and the history, automatic time chunks, summaries that stay current, ordinary SQL |
| 9–20 | A hypertable, then 2,880 planted study sessions |
| 20–25 | The `focus-log` service in Tiger Console: two tables, one hypertable, and its chunks |
| 25–36 | The questions: best and worst hour, most and least focused place, where they sit, late caffeine, the join, and the week before a deadline |
| 36–40 | A continuous aggregate for the first month |
| 40–44 | Another month of sessions, and the daily summary grows to cover it |
| 44–45 | Project ideas and where to go next |

The picture of the tables is [SCHEMA.md](SCHEMA.md). The timed script is [PRESENTER.md](PRESENTER.md). Setup for the host is [prep/CHECKLIST.md](prep/CHECKLIST.md).

## The data you are looking at

You do not need to bring a dataset. `sql/02_seed.sql` generates it.

Six students, every hour from 8:00am through 11:00pm Eastern, for the 30 days ending yesterday. That is 2,880 rows in `study_sessions`. `sql/05_second_month.sql` adds the 30 days before that, another 2,880 rows, after the daily summary exists. The summary stays on the first month until that file refreshes the older window. `students` and `courses` are small ordinary tables beside the log.

The seed is deterministic. These results are the ones the demo expects:

- Best focus is **10 AM** (92.7). Worst is **11 PM** (37.5).
- Across the whole month, the **Library** averages 79.1 and the **Dorm** averages about 48. The Cafe sits around 74.
- The Library is also where they spend the most sessions. Cafe and Dorm can trade second place.
- At 160mg, the first row is **Jordan Blake at 11 PM**, focus 35.0.
- **Databases** goes from 960 minutes a day to 3,200 in the last week. Calculus and Writing stay at 480.

Hours are America/New_York, so "10" means 10am Eastern even when the database clock is UTC.

## Replay it in Tiger Cloud

1. Open [Tiger Console](https://console.cloud.tigerdata.com/) and sign in.
2. Click **New service**.
3. Choose the free **Shared** size. Under provider and region, open **AWS** and choose **US East (N. Virginia)**. Click **Continue**. Do not choose plain PostgreSQL.
4. Choose **Development**. Leave high availability, the connection pooler, VPC peering, and private endpoints off. Click **Continue**.
5. Name the service `focus-log`, then click **Create service**.
6. When the service is **Ready**, open **Download your database config** and click **Download the config**. Store that file somewhere safe. It is the only time the password is shown. The SQL editor below does not ask for it.
7. Select the service and click **SQL Editor** at the bottom of the console.
8. Paste this and click **Run**. You should see today's date.

```sql
SELECT current_date;
```

9. Paste and run the workshop files, in order. Run one statement or one labeled block at a time, so the result grid shows the query you just ran.
   - `sql/00_reset.sql` when you are starting over. A brand-new service can skip this.
   - `sql/01_hypertable.sql`
   - `sql/02_seed.sql`
   - Each statement in `sql/03_queries.sql`, in order
   - Each block in `sql/04_continuous_aggregate.sql`
   - Each block in `sql/05_second_month.sql`

For the next run, stay in the same SQL editor. Run `sql/00_reset.sql` to drop the workshop tables, then build them again from `sql/01_hypertable.sql`. Keep the Tiger Cloud service.

## Why this database, in the words of the workshop

- Study sessions, students, and courses live in one database and join with SQL.
- A hypertable splits the log into time chunks. You do not create those partitions yourself.
- A continuous aggregate keeps the daily summary current.
- The queries are PostgreSQL.

## Project ideas

Each one is a timestamp, a measurement, and a question over time.

- **Focus Log.** When do you actually study, and where does it work?
- **API heartbeat.** When does your portfolio site get slow or start returning errors?
- **Season diary.** How did rank and score move across a game season?
- **Personal Wrapped.** What happened to music, gym, or coffee week by week?
- **Study-room sensor.** Which room is free, and is it freezing?
- **Stream pulse.** How many chat messages arrive each minute of a livestream?

## Next

After the workshop files, these two pages go further on the same ideas:

- [Your first hypertable](https://www.tigerdata.com/docs/build/how-to/your-first-hypertable)
- [Create a continuous aggregate](https://www.tigerdata.com/docs/build/continuous-aggregates/create-a-continuous-aggregate)
