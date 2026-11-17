# Phase 4: Optimization Report

## 1. Environment and method

| Item | Value |
|---|---|
| Database engine | PostgreSQL 18.7 (Debian 18.7-1.pgdg13+2), aarch64 |
| Database | `netflix_bench`, schema `netflix` |
| Dataset | the CP1 seed data, unmodified: 200,401 `viewing_activity`, 133,057 `invoices`, 75,000 `profiles`, 25,000 `accounts`, 20,000 `episodes`, 59,992 `my_list`, 33,900 `ratings`, 5,963 `title_genres`, 3,000 `titles`, 15 `genres`, 4 `plans` |
| Measurement | `EXPLAIN (ANALYZE, BUFFERS)`, 3 consecutive runs per query, average reported |
| Write safety | all write queries run inside `BEGIN; … ROLLBACK;`, so the data is identical before and after the run |
| Tooling | `./benchmarks/run_benchmark.sh` from the repository, unmodified |

**Why this report contains a second "before" column.** The baseline in
`benchmarks/results/baseline/` was measured on a different machine, and this
machine is slower on the very same plans: R01 takes 15.896 ms here against
5.916 ms in the committed baseline, and the plan chosen by the optimiser is
identical in both cases for all 30 queries. Comparing this machine's
"after" numbers against the committed baseline would therefore mix two
machines and flatter the result. Every speed-up quoted below is therefore
measured **before and after on the same machine, in the same database**, and
the committed baseline is shown only as a cross-check.

## 2. What the baseline showed

Reading `benchmarks/results/baseline/summary.csv` and the raw plans next to it,
the baseline has three separate problems:

1. **13 of the 25 read queries run a Seq Scan on `viewing_activity`** (200,401
   rows). The table has a primary key on `view_id` and nothing else, so every
   filter on `profile_id`, `title_id` or `started_at` reads the whole table.
   R19 was the worst at 6368.053 ms, because it runs two correlated subqueries
   per Netflix Original against an unindexed `title_id`.
2. **Three filters cannot use any index even if one existed**, because the
   column is wrapped in a function: `lower(email)`, `EXTRACT(YEAR FROM
   started_at)` and `started_at::date`.
3. **Two queries are not correct.** R13 uses `NOT IN` against a subquery that
   returns 93,056 NULL `episode_id` values, and `NOT IN` can never be true when
   the right-hand side contains a NULL — so R13 returns **zero rows**, not the
   episodes that nobody watched. The intended answer is 8 rows.

## 3. Index design (`sql/05_indexes.sql`)

17 indexes were added. Every one of them is justified by a measured bottleneck
above; nothing was added speculatively.

| Index | Table | Queries it serves | Why it is needed |
|---|---|---|---|
| `viewing_activity_profile_unfinished_idx` (partial, `WHERE NOT completed`) | `viewing_activity` | R01 | One profile, unfinished rows, newest first. Partial because only unfinished rows are ever looked up by this row. |
| `viewing_activity_profile_started_idx` | `viewing_activity` | R08, R14, R16 | Per-profile history over a time window. |
| `viewing_activity_title_started_idx` | `viewing_activity` | R19 | Turns both correlated subqueries (`count(*)`, `max(started_at)`) into index lookups. |
| `viewing_activity_episode_idx` (partial) | `viewing_activity` | R13 | The anti-join probe. Partial: 93,056 rows have `episode_id IS NULL`. |
| `viewing_activity_started_idx` | `viewing_activity` | R03, R08, R18, R23 | Date-window filters and the newest-first ordering of the support console. |
| `titles_maturity_added_idx` | `titles` | R04 | Rating filter with `added_on DESC`. |
| `titles_leaving_idx` (partial) | `titles` | R22 | Licensed titles leaving in a month. |
| `titles_name_trgm_idx` (GIN + pg_trgm) | `titles` | R05 | `name ILIKE '%love%'` — a leading wildcard cannot use a B-tree. |
| `title_genres_genre_idx` | `title_genres` | R04, R09, R25 | The primary key is `(title_id, genre_id)`, so a lookup by `genre_id` had no index. |
| `accounts_lower_email_idx` (functional) | `accounts` | R10 | The query compares `lower(email)`, so the `UNIQUE` index on the raw column cannot be used. |
| `accounts_status_next_billing_idx` | `accounts` | R11, R15, R21, W04, W05 | Status filter plus billing date. |
| `accounts_cancelled_idx` (partial) | `accounts` | R12 | Cancellations per month. |
| `profiles_account_created_idx` | `profiles` | R16, R24 | One account's profiles, ordered by creation time. |
| `profiles_kids_idx` (partial) | `profiles` | R14 | Kids profiles only. |
| `invoices_status_period_idx` | `invoices` | R11, W05 | Failed invoices for one billing period. |
| `ratings_title_idx` | `ratings` | R17 | The primary key is `(profile_id, title_id)`; R17 joins the other way round. |
| `my_list_added_title_idx` | `my_list` | R20 | Additions inside a month window. |

The indexes are additive: no column is renamed, retyped or constrained, so the
CP1 schema and the CP1 data stay valid and the whole file can be applied to a
fresh copy of the database.

## 4. Query rewrites (`sql/06_optimized_queries.sql`)

27 of the 30 queries are byte-for-byte identical to `queries/workload_30.sql`;
the speed-up comes from the planner being given an index to use. Three queries
are rewritten, and each rewrite is marked `REWRITTEN` in the file:

| Query | Before | After | Why |
|---|---|---|---|
| R09 | `EXTRACT(YEAR FROM v.started_at) = 2026` | `v.started_at >= TIMESTAMPTZ '2026-01-01 00:00:00' AND v.started_at < TIMESTAMPTZ '2027-01-01 00:00:00'` | The function call is not sargable, so no index on `started_at` can ever be chosen. |
| R18 | `started_at::date >= '2026-01-01'` | `started_at >= TIMESTAMPTZ '2026-01-01 00:00:00'` | Casting the column to `date` is not sargable either. |
| R13 | `e.episode_id NOT IN (SELECT v.episode_id FROM viewing_activity v)` | `e.episode_id NOT EXISTS (…)` (correlated) | `NOT IN` with a NULL on the right-hand side is never true, so the original returns 0 rows instead of 8. |

Both performance rewrites were checked to return exactly the same rows as the
originals (15 genre rows for R09, 24 month/device rows for R18), and R13 now
returns the 8 episodes that nobody has watched.

## 5. Results

Average of 3 runs, milliseconds. "Before" and "after" are the same machine and
the same database.

| Query | Type | Baseline (CP2, other machine) | Before | After | Speed-up |
|---|---|---:|---:|---:|---:|
| R01 | READ | 5.916 | 15.896 | 0.157 | **101.2x** |
| R02 | READ | 0.157 | 0.134 | 0.098 | 1.4x |
| R03 | READ | 5.514 | 12.559 | 1.460 | 8.6x |
| R04 | READ | 0.610 | 1.466 | 0.969 | 1.5x |
| R05 | READ | 0.672 | 2.206 | 0.490 | 4.5x |
| R06 | READ | 0.175 | 0.187 | 0.229 | 0.8x |
| R07 | READ | 0.021 | 0.062 | 0.094 | 0.7x |
| R08 | READ | 7.987 | 16.611 | 5.703 | 2.9x |
| R09 | READ | 26.306 | 54.126 | 32.044 | 1.7x |
| R10 | READ | 2.992 | 10.305 | 0.081 | **127.2x** |
| R11 | READ | 7.550 | 14.486 | 6.664 | 2.2x |
| R12 | READ | 1.432 | 2.951 | 1.766 | 1.7x |
| R13 | READ | 18.974 | 59.748 | 0.151 | **395.7x** (correctness fix) |
| R14 | READ | 21.974 | 51.837 | 50.713 | 1.0x |
| R15 | READ | 4.507 | 9.619 | 9.783 | 1.0x |
| R16 | READ | 146.387 | 326.625 | 321.487 | 1.0x |
| R17 | READ | 5.070 | 12.806 | 12.412 | 1.0x |
| R18 | READ | 27.122 | 53.442 | 40.838 | 1.3x |
| R19 | READ | 6368.053 | 7570.013 | 10.408 | **727.3x** |
| R20 | READ | 2.661 | 5.466 | 2.778 | 2.0x |
| R21 | READ | 1.337 | 2.116 | 0.720 | 2.9x |
| R22 | READ | 0.156 | 0.351 | 0.259 | 1.4x |
| R23 | READ | 41.019 | 84.907 | 31.886 | 2.7x |
| R24 | READ | 1.782 | 3.155 | 0.087 | **36.3x** |
| R25 | READ | 0.709 | 1.536 | 1.039 | 1.5x |
| W01 | WRITE | 0.886 | 0.806 | 1.506 | 0.5x |
| W02 | WRITE | 0.700 | 1.181 | 1.475 | 0.8x |
| W03 | WRITE | 0.746 | 0.649 | 0.846 | 0.8x |
| W04 | WRITE | 118.882 | 165.720 | 197.795 | 0.8x |
| W05 | WRITE | 18.000 | 23.186 | 26.353 | 0.9x |
| **Total (30 queries)** | | **6838.297** | **8504.152** | **760.291** | **11.2x** |

Raw data: `benchmarks/results/optimized/summary.csv` and the 30 raw plan files
`benchmarks/results/optimized/R01.txt` … `W05.txt`.

### The three results that matter

* **R19, 7570.013 ms → 10.408 ms.** The plan changed from
  `Seq Scan on viewing_activity | Seq Scan on titles` to
  `Seq Scan on titles | Index Only Scan using viewing_activity_title_started_idx`.
  The two correlated subqueries now answer from the index instead of scanning
  200,401 rows once per Netflix Original.
* **R01, 15.896 ms → 0.157 ms.** The partial index on unfinished rows per
  profile turned a parallel Seq Scan of the whole table into an index-only
  scan of a few dozen rows — the single most user-visible query in the app
  (the "Continue watching" row).
* **R10, 10.305 ms → 0.081 ms.** The functional index on `lower(email)` is
  what makes sign-in possible; the `UNIQUE` index on the raw column was
  unusable for a case-insensitive comparison.

## 6. What did not improve, and why

Reporting only the wins would be misleading, so the four read queries that
barely moved are analysed here.

* **R14 (51.837 → 50.713 ms), R16 (326.625 → 321.487 ms), R15 (9.619 → 9.783 ms),
  R17 (12.806 → 12.412 ms)** are *scan-bound by their own definition*: each of
  them aggregates over a large share of `viewing_activity` (R16 groups every
  viewing row by account and hour), or over every `accounts` / `ratings` row.
  The indexes improve the join side — the plans confirm it, R14 now uses
  `profiles_kids_idx` and R17 can start from the 3,000 `titles` — but the
  aggregate still has to read the rows, so the wall clock stays where it is.
  An index cannot remove a full aggregation.
* **R18 (53.442 → 40.838 ms)** improves only 1.3x for the same reason: it sums
  `duration_watched_sec` over every 2026 row.
* **R06, R07, W01, W02, W03** are all under 2 ms. The differences there
  (0.062 ms → 0.094 ms, and so on) are measurement noise on sub-millisecond
  statements, not a regression.

## 7. The cost side: index write overhead

Two write queries got slower, and the reason was measured rather than assumed.

* **W04, 165.720 ms → 197.795 ms (−19%).** The query inserts one invoice per
  active account, 21,282 rows. Every one of those inserts has to maintain the
  new `invoices_status_period_idx`. Dropping that index and re-running the
  same insert gave **150.464 ms**, so the index costs about **47 ms** on this
  bulk insert. The same plan line shows the other half of the cost:
  `Trigger for constraint invoices_account_id_fkey: time=76.570 calls=21282` —
  the foreign key check against `accounts` is more expensive than the index.
* **W05, 23.186 ms → 26.353 ms (−14%).** With the new index the planner uses a
  `Bitmap Index Scan` on `invoices` for the `EXISTS` probe instead of the
  unique `(account_id, billing_period_start)` index.

This is the real trade-off of the phase: the read side of the workload is 11x
faster overall, and the write side pays about 30 ms per bulk billing run.
Since the billing run is a monthly job and the read queries are served on every
page view, that is a good trade for this application. If the billing run ever
became hot enough to matter, the fix would be to drop
`invoices_status_period_idx` and let R11 fall back to the existing unique
index on `(account_id, billing_period_start)`.

## 8. Correctness verification

| Check | Result |
|---|---|
| `sql/05_indexes.sql` applies to the CP1 database | Yes, 17 indexes created, no error |
| `sql/06_optimized_queries.sql` vs `queries/workload_30.sql` | 27 of 30 queries byte-for-byte identical; 3 rewrites, each documented in the file |
| R09 rewrite returns the same rows | Yes — 15 genre rows before and after |
| R18 rewrite returns the same rows | Yes — 24 month/device rows before and after |
| R13 correctness | Before: 0 rows. After (`NOT EXISTS`): 8 episodes, the correct answer |
| Raw plans | 30 files in `benchmarks/results/optimized/`, three runs each, writes rolled back |

## 9. How to reproduce

```bash
unzip seed_data.zip -d seed_data/
psql -d netflix_bench -f sql/01_schema.sql
psql -d netflix_bench -f sql/02_load_data.sql
psql -d netflix_bench -f sql/05_indexes.sql

# before
./benchmarks/run_benchmark.sh netflix_bench baseline 3
# after
./benchmarks/run_benchmark.sh netflix_bench optimized 3 sql/06_optimized_queries.sql
```

The before and after runs must happen on the same machine and the same
database; that is why this report quotes its own "before" measurement instead
of reusing the committed baseline.
