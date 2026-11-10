# Livestream checklist

Read [PRESENTER.md](../PRESENTER.md) for the words. This file is only the setup.

Every run happens in the Tiger Cloud SQL editor. There is no local database. `sql/00_reset.sql` destroys the workshop objects. The other SQL files build them again.

## The one service

Create one Tiger Cloud service. Do not create a second service, a replica, or a plain PostgreSQL database. The SQL files create `students`, `courses`, `study_sessions`, and `study_daily` inside this service. Do not create those by hand.

| Setting | Use this |
| --- | --- |
| Service name | `focus-log` |
| Compute | Shared, the free size |
| Provider and region | AWS, US East (N. Virginia), `us-east-1` |
| Environment | Development |
| TimescaleDB | On. Do not choose plain PostgreSQL |
| High availability | Off |
| Connection pooler | Off |
| VPC peering and private endpoints | Off |
| Passwordless SQL editor | On, which is the default |

## Day before

1. Open [Tiger Console](https://console.cloud.tigerdata.com/) and sign in.
2. Click **New service**.
3. Choose **Shared**. Under provider and region, open the **AWS** tab and choose **US East (N. Virginia)**. Click **Continue**. Do not click **Create with plain PostgreSQL**.
4. Choose **Development**. Leave high availability, the connection pooler, VPC peering, and private endpoints off. Click **Continue**.
5. Name the service `focus-log`. Click **Create service**.
6. Wait until the service is marked **Ready**.
7. Open **Download your database config** and click **Download the config**. Store that file somewhere safe. This is the only time the password is shown. The SQL editor does not ask for it.
8. Select `focus-log` and click **SQL Editor** at the bottom of the console. Leave this tab in the window you will share.
9. Paste `SELECT current_date;` and click **Run**. You should see today's date. The editor should have no workshop tables yet.
10. Hide the bookmarks bar. Set the browser zoom to 150%. Use the dark theme if the editor has one.
11. Open `slides/index.html` in its own tab. Press the right arrow through all six slides once.
12. Open `sql/` in an editor with the font large enough to read from the back of the room. You will paste from here. You will not type SQL.
13. Rehearse the SQL in order on `focus-log`:
  1. `sql/00_reset.sql`
  2. `sql/01_hypertable.sql`
  3. `sql/02_seed.sql` — last grid is the chunk list, and the count is 2,880
  4. Click **Explorer** on `focus-log`. Confirm `students`, `courses`, and `study_sessions`. Open `study_sessions` and confirm the chunk timeline. The **Caggs** filter should be empty.
  5. Each statement in `sql/03_queries.sql`, one at a time
  6. Each block in `sql/05_continuous_aggregate.sql`, one at a time
  7. Each block in `sql/06_second_month.sql`, one at a time. Sessions become 5,760 and the raw oldest day is about 60 days back. The summary query before the refresh is still one month, about 113 rows. After the refresh, `summary_rows` is 233 and the summary's oldest day is about 60 days back.
14. Confirm the shape, not just that it ran: 10 AM focus is 92.7, 11 PM is 37.5, weeknight Library is 77.3 and Dorm is 60.6, Databases goes from 960 minutes a day to 3,200. After `sql/06`, an older day shows Databases and Data Structures at 960, and Calculus and Writing at 480.
15. Run `sql/00_reset.sql` again when rehearsal is over so the livestream starts empty.
16. For every later run, start with `sql/00_reset.sql` in the same SQL editor, then build from `sql/01_hypertable.sql` onward. Keep the `focus-log` service. Destroy the tables, not the service.

## 30 minutes before

- Tiger Cloud tab is logged in. Run `SELECT current_date;` once. You want today's date and nothing else.
- `slides/index.html` is on slide 1.
- `PRESENTER.md` is on a screen you will not share.
- A timer is visible to you for the blocks 0:00, 4:00, 9:00, 14:00, 20:00, 25:00, 33:00, 38:00, and 43:00.
- Chat is open. The one question you will ask, around minute 25, is: "What would you ask this table?"
- Confirm the editor is empty: `sql/00_reset.sql` has been run, and `SELECT current_date;` returns today.
- Water, zoom at 150%, notifications silenced on the shared screen.

## If the console stalls

Reload the SQL editor tab and paste `SELECT current_date;` again. Stay in Tiger Cloud.

If a later paste fails because an object is half-created, run `sql/00_reset.sql`, then repeat the file you were on. The seed is a few seconds. If the data is already loaded and only the next query failed, do not reset. Continue at the next statement.

## If you are behind the clock

- At minute 30, skip `sql/04_alternates.sql`.
- At minute 36, skip the policy block in `sql/05`. Run the refresh and the final `SELECT`.
- At minute 40, if the second month has not started, skip `sql/06_second_month.sql` and close.
- The closing can be three sentences and the repo URL. Do not add a sixth slide.
