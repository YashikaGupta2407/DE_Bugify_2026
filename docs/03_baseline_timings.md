# Phase 3: Baseline Timings Report

## 1. Benchmark Setup

This report documents the baseline performance benchmark for the 30 standardized workload queries (`R01`–`R25` and `W01`–`W05`) on the Netflix database before any indexing or query optimization.

- **Database Engine:** PostgreSQL 18 (v18.7)
- **Database Name:** `netflix_bench`
- **Schema:** `netflix` (`SET search_path TO netflix;`)
- **Measurement Methodology:** Every query was executed three consecutive times using `EXPLAIN (ANALYZE, BUFFERS)` to collect execution times, buffer statistics, memory usage, and exact plan operator trees.
- **Run Count:** Exactly 3 runs per query; reporting Run 1, Run 2, Run 3, and the mathematical average.
- **Write Transaction Safety:** All five write queries (`W01`–`W05`) were executed inside atomic `BEGIN; ... ROLLBACK;` blocks. The underlying seed data was never modified, preserving full reproducibility.
- **Schema State:** Untuned baseline schema containing only primary key and unique constraint indexes generated automatically by PostgreSQL (no secondary or workload-tuning indexes).
- **Dataset Size:** 11 seed tables loaded and analyzed (200,401 viewing records, 133,057 invoices, 75,000 profiles, 25,000 accounts, 20,000 episodes, 59,992 My List entries, 33,900 ratings, 5,963 title genres, 3,000 titles, 15 genres, 4 plans).
- **Raw Benchmark Artifacts:**
  - Summary CSV: `benchmarks/results/baseline/summary.csv`
  - Raw Plan Logs: `benchmarks/results/baseline/R01.txt` through `benchmarks/results/baseline/W05.txt`

---

## 2. Baseline Timing Table (All 30 Queries)

The following table presents the exact execution timings (in milliseconds) for all 30 queries across all three runs, extracted directly from the raw execution plans and validated against `benchmarks/results/baseline/summary.csv`.

| SQL Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|:---:|---:|---:|---:|---:|
| **R01**: "Continue Watching" row: latest unfinished viewing per title for profile 7043 | READ | 6.632 | 5.600 | 5.516 | 5.916 |
| **R02**: Title page: seasons of series 2909 with the number of episodes in each | READ | 0.405 | 0.035 | 0.031 | 0.157 |
| **R03**: "Top 10 in India today" row: most-watched titles on 30 June 2026 | READ | 5.738 | 5.236 | 5.568 | 5.514 |
| **R04**: Genre row for a kids profile: Comedy titles rated U or UA7, newest additions first | READ | 0.606 | 0.614 | 0.610 | 0.610 |
| **R05**: Search: titles whose name contains "love" | READ | 0.655 | 0.682 | 0.680 | 0.672 |
| **R06**: "My List" row for profile 7393 | READ | 0.417 | 0.054 | 0.053 | 0.175 |
| **R07**: Autoplay: the next episode of series 2909 after season 1 episode 4 | READ | 0.021 | 0.020 | 0.022 | 0.021 |
| **R08**: Insights: binge sessions in June 2026 (3+ episodes of one series by one profile on one day) | READ | 8.053 | 8.089 | 7.819 | 7.987 |
| **R09**: Content analytics: completion rate per genre (2026) | READ | 26.203 | 26.489 | 26.227 | 26.306 |
| **R10**: Sign-in: find the account by email, ignoring case | READ | 3.062 | 2.970 | 2.944 | 2.992 |
| **R11**: Payments: active accounts whose June 2026 invoice failed (retry list) | READ | 7.657 | 7.598 | 7.394 | 7.550 |
| **R12**: Retention: cancellations per month in 2026 and average tenure (days) of those accounts | READ | 1.450 | 1.457 | 1.389 | 1.432 |
| **R13**: Content team: episodes of series 2523 that nobody has watched | READ | 19.178 | 19.338 | 18.405 | 18.974 |
| **R14**: Compliance: kids profiles that watched titles above their maturity limit | READ | 21.496 | 21.970 | 22.455 | 21.974 |
| **R15**: Finance: active accounts and monthly recurring revenue per plan | READ | 4.517 | 4.513 | 4.492 | 4.507 |
| **R16**: Account sharing check: accounts with more profiles watching in same hour than plan streams | READ | 140.184 | 144.112 | 154.865 | 146.387 |
| **R17**: Content strategy: share of "LOVE" ratings for Netflix Originals vs licensed titles | READ | 5.104 | 5.040 | 5.067 | 5.070 |
| **R18**: Device analytics: viewing hours per device per month in 2026 | READ | 27.127 | 27.201 | 27.038 | 27.122 |
| **R19**: Originals report: total views and the most recent view of every Netflix Original | READ | 6330.138 | 6401.136 | 6372.885 | 6368.053 |
| **R20**: Marketing: 10 titles added to the most My Lists in June 2026 | READ | 2.719 | 2.635 | 2.630 | 2.661 |
| **R21**: Payments: accounts on hold whose billing date has already passed | READ | 1.114 | 1.217 | 1.681 | 1.337 |
| **R22**: "Last chance to watch" row: licensed titles leaving in July 2026 | READ | 0.157 | 0.158 | 0.152 | 0.156 |
| **R23**: Support console: all viewing activity, newest first, page 6,001 (25 per page) | READ | 40.725 | 40.509 | 41.823 | 41.019 |
| **R24**: "Who's watching?" screen: profiles of account 1409 | READ | 1.748 | 1.803 | 1.795 | 1.782 |
| **R25**: "More like this": titles sharing at least 2 genres with series 2909 | READ | 0.890 | 0.617 | 0.621 | 0.709 |
| **W01**: Player: profile 7043 starts episode S1E5 of series 2909 | WRITE | 1.855 | 0.418 | 0.386 | 0.886 |
| **W02**: "+ My List": profile 7043 adds series 2523 | WRITE | 1.283 | 0.417 | 0.399 | 0.700 |
| **W03**: Account settings: account 1409 downgrades to the STANDARD plan | WRITE | 1.826 | 0.202 | 0.209 | 0.746 |
| **W04**: Monthly billing run: create July 2026 invoices for every active account | WRITE | 157.091 | 95.123 | 104.433 | 118.882 |
| **W05**: Dunning: put active accounts whose latest invoice failed on hold | WRITE | 31.124 | 11.397 | 11.480 | 18.000 |
| **Total (sum of all 30)** | | **6849.175** | **6836.650** | **6829.069** | **6838.297** |

---

## 3. Execution Plan Analysis for Every Query

Below is the detailed analysis of each query's execution plan extracted directly from the raw baseline benchmark output logs.

### R01: "Continue Watching" row: latest unfinished viewing per title for profile 7043
- **Type:** READ
- **Timings:** Run 1: 6.632 ms · Run 2: 5.600 ms · Run 3: 5.516 ms · **Average: 5.916 ms**
- **Scan Nodes:**
  - `Seq Scan on viewing_activity` (Parallel Seq Scan)
  - `Index Scan using titles_pkey on titles`
- **Plan Breakdown:** The planner executes a Parallel Seq Scan on `viewing_activity` across 2 worker loops (visiting 1,739 shared buffer pages) filtering for `profile_id = 7043` and `NOT completed`. A Nested Loop performs an Index Scan on `titles` using `titles_pkey`, followed by a Sort by `title_id, started_at DESC` and a `Unique` node for `DISTINCT ON (v.title_id)`.
- **Performance Rationale:** Slow for a real-time UI home row (5.916 ms). The query lacks a composite index on `(profile_id, started_at)` on `viewing_activity`, forcing the engine to scan all 200,401 viewing records simply to find the few rows belonging to profile 7043.

### R02: Title page: seasons of series 2909 with the number of episodes in each
- **Type:** READ
- **Timings:** Run 1: 0.405 ms · Run 2: 0.035 ms · Run 3: 0.031 ms · **Average: 0.157 ms**
- **Scan Nodes:**
  - `Index Scan using episodes_title_id_season_no_episode_no_key on episodes`
- **Plan Breakdown:** Leverages the unique constraint B-tree index on `episodes(title_id, season_no, episode_no)` to seek directly to `title_id = 2909` (reading 13 rows), followed by a `GroupAggregate` on `season_no`.
- **Performance Rationale:** Very fast (0.157 ms). Because `title_id` is the leading attribute of the natural candidate key index, the engine performs a tight range seek touching only 2 buffer pages.

### R03: "Top 10 in India today" row: most-watched titles on 30 June 2026
- **Type:** READ
- **Timings:** Run 1: 5.738 ms · Run 2: 5.236 ms · Run 3: 5.568 ms · **Average: 5.514 ms**
- **Scan Nodes:**
  - `Seq Scan on viewing_activity` (Parallel Seq Scan)
  - `Index Scan using titles_pkey on titles`
- **Plan Breakdown:** Parallel Seq Scan over `viewing_activity` (1,736 buffer pages) filtering for `started_at >= '2026-06-30' AND started_at < '2026-07-01'`. The matches are sorted by `title_id, profile_id`, merge-joined with `titles` via `titles_pkey`, aggregated with `GroupAggregate` to compute `count(DISTINCT profile_id)`, and sorted via top-10 heapsort.
- **Performance Rationale:** Slow for an interactive home screen row (5.514 ms). The absence of a B-tree index on `viewing_activity(started_at)` forces a full table scan over 200,401 rows.

### R04: Genre row for a kids profile: Comedy titles rated U or UA7, newest additions first
- **Type:** READ
- **Timings:** Run 1: 0.606 ms · Run 2: 0.614 ms · Run 3: 0.610 ms · **Average: 0.610 ms**
- **Scan Nodes:**
  - `Seq Scan on titles`
  - `Seq Scan on title_genres`
  - `Seq Scan on genres`
- **Plan Breakdown:** Seq Scan on `genres` (15 rows) to locate 'Comedy', Hash Join with Seq Scan on `title_genres` (5,963 rows), and Hash Join with Seq Scan on `titles` (3,000 rows, filtering for `maturity_rating IN ('U', 'UA7')`), followed by a top-40 heapsort on `added_on DESC`.
- **Performance Rationale:** Moderately fast (0.610 ms) only because all three tables fit entirely into shared cache (67 buffers). However, scanning all three tables sequentially without indexing on `genre_name` or `(genre_id, title_id)` causes unscalable CPU overhead.

### R05: Search: titles whose name contains "love"
- **Type:** READ
- **Timings:** Run 1: 0.655 ms · Run 2: 0.682 ms · Run 3: 0.680 ms · **Average: 0.672 ms**
- **Scan Nodes:**
  - `Seq Scan on titles`
- **Plan Breakdown:** Seq Scan on `titles` evaluating `name ILIKE '%love%'` across all 3,000 rows (36 buffer pages), filtering out 2,812 rows, followed by a top-30 heapsort on `release_year DESC`.
- **Performance Rationale:** Acceptable on small seed data (0.672 ms), but fundamentally unoptimized: without trigram (`pg_trgm`) GIN indexing, pattern matching with leading wildcards forces full table scans that degrade linearly with catalog growth.

### R06: "My List" row for profile 7393
- **Type:** READ
- **Timings:** Run 1: 0.417 ms · Run 2: 0.054 ms · Run 3: 0.053 ms · **Average: 0.175 ms**
- **Scan Nodes:**
  - `Index Scan using my_list_pkey on my_list`
  - `Index Scan using titles_pkey on titles`
- **Plan Breakdown:** The primary key B-tree index on `my_list(profile_id, title_id)` is scanned for `profile_id = 7393` (reading 6 rows). A Nested Loop joins each title via `Index Scan using titles_pkey`, followed by an in-memory quicksort on `added_at DESC`.
- **Performance Rationale:** Fast (0.175 ms). `profile_id` is the leading column of `my_list_pkey`, enabling an efficient index seek. The small quicksort on 6 rows takes negligible time.

### R07: Autoplay: the next episode of series 2909 after season 1 episode 4
- **Type:** READ
- **Timings:** Run 1: 0.021 ms · Run 2: 0.020 ms · Run 3: 0.022 ms · **Average: 0.021 ms**
- **Scan Nodes:**
  - `Index Scan using episodes_title_id_season_no_episode_no_key on episodes`
- **Plan Breakdown:** Direct B-tree index seek on the unique key `(title_id, season_no, episode_no)` evaluating `(title_id = 2909) AND ((season_no, episode_no) > (1, 4))` with `LIMIT 1`.
- **Performance Rationale:** The fastest query in the entire benchmark (0.021 ms). The tuple-comparison condition matches the composite unique B-tree index perfectly, reading only 3 buffer pages.

### R08: Insights: binge sessions in June 2026 (3+ episodes of one series by one profile on one day)
- **Type:** READ
- **Timings:** Run 1: 8.053 ms · Run 2: 8.089 ms · Run 3: 7.819 ms · **Average: 7.987 ms**
- **Scan Nodes:**
  - `Seq Scan on viewing_activity`
- **Plan Breakdown:** Seq Scan on `viewing_activity` filtering for `episode_id IS NOT NULL` and `started_at >= '2026-06-01'` (discards 194,583 rows and retains 5,818 rows). It then performs a `HashAggregate` on `(profile_id, title_id, started_at::date)` with a `HAVING count(*) >= 3` filter, and quicksorts by `episodes DESC, day`.
- **Performance Rationale:** Heavy (7.987 ms). Reading all 200,401 rows (1,736 buffer pages) sequentially to retrieve 5,818 matching rows dominates the execution time.

### R09: Content analytics: completion rate per genre (2026)
- **Type:** READ
- **Timings:** Run 1: 26.203 ms · Run 2: 26.489 ms · Run 3: 26.227 ms · **Average: 26.306 ms**
- **Scan Nodes:**
  - `Seq Scan on viewing_activity` (Parallel Seq Scan)
  - `Seq Scan on title_genres`
  - `Seq Scan on genres`
- **Plan Breakdown:** Parallel Seq Scan on `viewing_activity` evaluates `EXTRACT(YEAR FROM started_at) = 2026`, joined through two Hash Joins to `title_genres` and `genres`. Parallel aggregation is handled by `Partial HashAggregate` and `Finalize GroupAggregate` before sorting.
- **Performance Rationale:** Slow (26.306 ms). The non-sargable expression `EXTRACT(YEAR FROM ...)` forces a full parallel scan across 200,401 rows, followed by joining 131,367 resulting row pairs.

### R10: Sign-in: find the account by email, ignoring case
- **Type:** READ
- **Timings:** Run 1: 3.062 ms · Run 2: 2.970 ms · Run 3: 2.944 ms · **Average: 2.992 ms**
- **Scan Nodes:**
  - `Seq Scan on accounts`
- **Plan Breakdown:** Sequential scan over all 25,000 rows in `accounts` (308 buffer pages) evaluating `lower(email) = 'arjun.chopra1409@yahoo.com'`.
- **Performance Rationale:** Severely unoptimized for user login (2.992 ms). Despite a `UNIQUE` B-tree index on `email`, wrapping the column in `lower()` prevents index usage, causing PostgreSQL to inspect every single account in the database.

### R11: Payments: active accounts whose June 2026 invoice failed (retry list)
- **Type:** READ
- **Timings:** Run 1: 7.657 ms · Run 2: 7.598 ms · Run 3: 7.394 ms · **Average: 7.550 ms**
- **Scan Nodes:**
  - `Seq Scan on accounts`
  - `Seq Scan on invoices`
- **Plan Breakdown:** Seq Scan on `invoices` (133,057 rows) filtering for `status = 'FAILED'` and `billing_period_start = '2026-06-01'` (1,376 rows matched). It builds an in-memory hash table and performs a Hash Join against a Seq Scan on `accounts` (25,000 rows, filtering `status IN ('ACTIVE', 'ON_HOLD')`), then sorts by `account_id`.
- **Performance Rationale:** Slow (7.550 ms). Scanning 133k invoices and 25k accounts sequentially (1,468 buffer hits) creates high I/O overhead due to lack of indexes on `(status, billing_period_start)` in `invoices` and `status` in `accounts`.

### R12: Retention: cancellations per month in 2026 and average tenure (days) of those accounts
- **Type:** READ
- **Timings:** Run 1: 1.450 ms · Run 2: 1.457 ms · Run 3: 1.389 ms · **Average: 1.432 ms**
- **Scan Nodes:**
  - `Seq Scan on accounts`
- **Plan Breakdown:** Seq Scan on `accounts` (25,000 rows, 308 buffer pages) filtering for `status = 'CANCELLED'` and `EXTRACT(YEAR FROM cancelled_on) = 2026` (597 rows retained), followed by quicksort and `GroupAggregate` on `date_trunc('month', cancelled_on)`.
- **Performance Rationale:** Moderate (1.432 ms). The scan evaluates all 25,000 rows sequentially because neither `status` nor `cancelled_on` is indexed.

### R13: Content team: episodes of series 2523 that nobody has watched
- **Type:** READ
- **Timings:** Run 1: 19.178 ms · Run 2: 19.338 ms · Run 3: 18.405 ms · **Average: 18.974 ms**
- **Scan Nodes:**
  - `Index Scan using episodes_title_id_season_no_episode_no_key on episodes`
  - `Seq Scan on viewing_activity`
- **Plan Breakdown:** Uses `Index Scan` on `episodes` for `title_id = 2523` (20 rows), but the subquery `WHERE e.episode_id NOT IN (SELECT v.episode_id FROM viewing_activity v)` triggers a complete `Seq Scan on viewing_activity` over 200,401 rows to build a hashed subplan.
- **Performance Rationale:** Slow (18.974 ms). Scanning all 200k viewing rows is expensive. Furthermore, because `viewing_activity.episode_id` contains `NULL` values for movies, `NOT IN` logic evaluates to `NULL` for every candidate, returning 0 rows (the known subtle SQL NULL bug to be addressed in Phase 4).

### R14: Compliance: kids profiles that watched titles above their maturity limit
- **Type:** READ
- **Timings:** Run 1: 21.496 ms · Run 2: 21.970 ms · Run 3: 22.455 ms · **Average: 21.974 ms**
- **Scan Nodes:**
  - `Seq Scan on viewing_activity` (Parallel Seq Scan)
  - `Seq Scan on profiles`
  - `Seq Scan on titles`
- **Plan Breakdown:** Parallel Seq Scan on `viewing_activity` (200,401 rows), Hash Joined to a Seq Scan on `profiles` (75,000 rows, filtering `is_kids`), and Hash Joined to a Seq Scan on `titles` (3,000 rows), evaluating the custom array position inequality `array_position(...) > array_position(...)`.
- **Performance Rationale:** Very slow (21.974 ms). Scans all three large tables sequentially (over 278,400 total rows inspected) with complex array index lookups evaluated per tuple.

### R15: Finance: active accounts and monthly recurring revenue per plan
- **Type:** READ
- **Timings:** Run 1: 4.517 ms · Run 2: 4.513 ms · Run 3: 4.492 ms · **Average: 4.507 ms**
- **Scan Nodes:**
  - `Seq Scan on accounts`
  - `Seq Scan on plans`
- **Plan Breakdown:** Seq Scan on `accounts` (25,000 rows) filtering `status = 'ACTIVE'`, Hash Joined with Seq Scan on `plans` (4 rows), aggregated with `HashAggregate` on `plan_name`, and sorted.
- **Performance Rationale:** Moderate (4.507 ms). Full sequential scan of all accounts without a partial index on active status.

### R16: Account sharing check: accounts with more profiles watching in same hour than plan streams
- **Type:** READ
- **Timings:** Run 1: 140.184 ms · Run 2: 144.112 ms · Run 3: 154.865 ms · **Average: 146.387 ms**
- **Scan Nodes:**
  - `Seq Scan on viewing_activity` (Parallel Seq Scan)
  - `Seq Scan on profiles`
  - `Seq Scan on accounts`
  - `Seq Scan on plans`
- **Plan Breakdown:** A complex 4-way join across all four primary operational tables: Parallel Seq Scan on `viewing_activity` (200,401 rows), Hash Joined to `profiles` (75,000 rows), `accounts` (25,000 rows), and `plans` (4 rows). Followed by a heavy `HashAggregate` on `(pr.account_id, date_trunc('hour', v.started_at), pl.max_streams)` with a `HAVING count(DISTINCT v.profile_id) > pl.max_streams` filter.
- **Performance Rationale:** The second slowest query in the benchmark (146.387 ms). Scans over 300,000 records across four unindexed relations and builds multiple massive hash tables in memory.

### R17: Content strategy: share of "LOVE" ratings for Netflix Originals vs licensed titles
- **Type:** READ
- **Timings:** Run 1: 5.104 ms · Run 2: 5.040 ms · Run 3: 5.067 ms · **Average: 5.070 ms**
- **Scan Nodes:**
  - `Seq Scan on ratings`
  - `Seq Scan on titles`
- **Plan Breakdown:** Seq Scan on `ratings` (33,900 rows, 187 buffer pages), Hash Joined with Seq Scan on `titles` (3,000 rows, 36 buffer pages) on `title_id`, aggregated with `HashAggregate` grouping on `is_netflix_original`.
- **Performance Rationale:** Moderate (5.070 ms). Scans the entirety of both `ratings` and `titles` sequentially.

### R18: Device analytics: viewing hours per device per month in 2026
- **Type:** READ
- **Timings:** Run 1: 27.127 ms · Run 2: 27.201 ms · Run 3: 27.038 ms · **Average: 27.122 ms**
- **Scan Nodes:**
  - `Seq Scan on viewing_activity`
- **Plan Breakdown:** Seq Scan on `viewing_activity` filtering for `(started_at)::date >= '2026-01-01'` (retaining 66,546 rows out of 200,401), followed by an expensive memory quicksort (`4000kB` RAM) on `(date_trunc('month', started_at), device_type)` and `GroupAggregate`.
- **Performance Rationale:** Slow (27.122 ms). Full scan of 200,401 records combined with a large in-memory sort of 66k rows on non-indexed date truncation expressions.

### R19: Originals report: total views and the most recent view of every Netflix Original
- **Type:** READ
- **Timings:** Run 1: 6330.138 ms · Run 2: 6401.136 ms · Run 3: 6372.885 ms · **Average: 6368.053 ms**
- **Scan Nodes:**
  - `Seq Scan on titles`
  - `Seq Scan on viewing_activity`
- **Plan Breakdown:** Seq Scan on `titles` filtering for `is_netflix_original = true` (610 rows). For **each** of the 610 Netflix Originals, PostgreSQL must execute **two** correlated scalar subqueries (`SubPlan 1` for `count(*)` and `SubPlan 2` for `max(started_at)`). Each subquery executes a separate full `Seq Scan on viewing_activity` (200,401 rows). In total, PostgreSQL executes $610 \times 2 = 1,220$ full table scans on `viewing_activity`, inspecting over 244 million rows and logging 2,117,959 shared buffer hits!
- **Performance Rationale:** By far the slowest query in the entire workload (6,368.053 ms / ~6.37 seconds). Catastrophic $O(N \times M)$ nested loop behavior resulting from correlated scalar subqueries executed against an unindexed table.

### R20: Marketing: 10 titles added to the most My Lists in June 2026
- **Type:** READ
- **Timings:** Run 1: 2.719 ms · Run 2: 2.635 ms · Run 3: 2.630 ms · **Average: 2.661 ms**
- **Scan Nodes:**
  - `Seq Scan on my_list`
  - `Seq Scan on titles`
- **Plan Breakdown:** Seq Scan on `my_list` (59,992 rows, 325 buffer pages) filtering `added_at >= '2026-06-01' AND added_at < '2026-07-01'` (3,328 rows matched), Hash Joined to a Seq Scan on `titles` (3,000 rows), aggregated with `HashAggregate` on `(title_id, name)`, and top-10 heapsorted.
- **Performance Rationale:** Moderate (2.661 ms). Full table scan on `my_list` because `added_at` is unindexed (the primary key is on `(profile_id, title_id)`).

### R21: Payments: accounts on hold whose billing date has already passed
- **Type:** READ
- **Timings:** Run 1: 1.114 ms · Run 2: 1.217 ms · Run 3: 1.681 ms · **Average: 1.337 ms**
- **Scan Nodes:**
  - `Seq Scan on accounts`
- **Plan Breakdown:** Seq Scan on `accounts` (25,000 rows, 308 buffer pages) filtering for `status = 'ON_HOLD'` and `next_billing_date < '2026-07-01'` (739 rows matched), followed by quicksort on `next_billing_date`.
- **Performance Rationale:** Moderate (1.337 ms). Must inspect all 25,000 accounts sequentially because no partial index exists for accounts on hold.

### R22: "Last chance to watch" row: licensed titles leaving in July 2026
- **Type:** READ
- **Timings:** Run 1: 0.157 ms · Run 2: 0.158 ms · Run 3: 0.152 ms · **Average: 0.156 ms**
- **Scan Nodes:**
  - `Seq Scan on titles`
- **Plan Breakdown:** Seq Scan on `titles` (3,000 rows, 36 buffer pages) filtering for `leaving_on BETWEEN '2026-07-01' AND '2026-07-31'` (54 rows matched), followed by quicksort on `leaving_on`.
- **Performance Rationale:** Fast (0.156 ms). The table is very small (36 pages), allowing a rapid sequential scan entirely in CPU L1/L2 cache.

### R23: Support console: all viewing activity, newest first, page 6,001 (25 per page)
- **Type:** READ
- **Timings:** Run 1: 40.725 ms · Run 2: 40.509 ms · Run 3: 41.823 ms · **Average: 41.019 ms**
- **Scan Nodes:**
  - `Seq Scan on viewing_activity`
- **Plan Breakdown:** Seq Scan on all 200,401 rows of `viewing_activity` (1,736 buffer pages), followed by an external merge disk sort (`Disk: 7536kB`, temporary I/O: 835 pages read, 946 written) to sort the full table on `started_at DESC`, before discarding 150,000 rows via `OFFSET 150000 LIMIT 25`.
- **Performance Rationale:** Very slow (41.019 ms). High-offset pagination without a supporting B-tree index forces PostgreSQL to read the entire table and spill a 7.5 MB sort operation to temporary disk files.

### R24: "Who's watching?" screen: profiles of account 1409
- **Type:** READ
- **Timings:** Run 1: 1.748 ms · Run 2: 1.803 ms · Run 3: 1.795 ms · **Average: 1.782 ms**
- **Scan Nodes:**
  - `Seq Scan on profiles`
- **Plan Breakdown:** Seq Scan on `profiles` (75,000 rows, 608 buffer pages) filtering for `account_id = 1409` (4 rows matched), followed by quicksort on `created_at`.
- **Performance Rationale:** Slow for a simple profile selection screen (1.782 ms). The foreign key `account_id` in `profiles` lacks a secondary index in the baseline schema, requiring a scan of 75,000 rows to find 4 records.

### R25: "More like this": titles sharing at least 2 genres with series 2909
- **Type:** READ
- **Timings:** Run 1: 0.890 ms · Run 2: 0.617 ms · Run 3: 0.621 ms · **Average: 0.709 ms**
- **Scan Nodes:**
  - `Seq Scan on title_genres`
  - `Index Only Scan using title_genres_pkey on title_genres`
- **Plan Breakdown:** Uses `Index Only Scan using title_genres_pkey` on `tg1` for `title_id = 2909` (reading 3 genres), Hash Joined with a full `Seq Scan on title_genres tg2` (5,963 rows) on `genre_id`, aggregated via `HashAggregate` on `tg2.title_id` (`HAVING count(*) >= 2`), and top-20 heapsorted.
- **Performance Rationale:** Moderately fast (0.709 ms). The primary key on `title_genres(title_id, genre_id)` allows an Index Only Scan on `tg1`, but joining back to `tg2` on `genre_id` forces a sequential scan because `genre_id` is the second column of the primary key.

### W01: Player: profile 7043 starts episode S1E5 of series 2909
- **Type:** WRITE
- **Timings:** Run 1: 1.855 ms · Run 2: 0.418 ms · Run 3: 0.386 ms · **Average: 0.886 ms**
- **Scan Nodes:**
  - `Index Scan using episodes_title_id_season_no_episode_no_key on episodes`
- **Plan Breakdown:** Performs an Index Scan on `episodes` using the unique candidate key to locate `episode_id` for S1E5 of title 2909, inserts the tuple into `viewing_activity`, and fires three foreign key verification triggers (`viewing_activity_profile_id_fkey`: 0.560 ms, `viewing_activity_title_id_fkey`: 0.094 ms, `viewing_activity_episode_id_fkey`: 0.411 ms). Executed inside `BEGIN ... ROLLBACK`.
- **Performance Rationale:** Fast (0.886 ms). The single-tuple lookup is index-backed; the majority of execution time is spent on foreign key constraint triggers.

### W02: "+ My List": profile 7043 adds series 2523
- **Type:** WRITE
- **Timings:** Run 1: 1.283 ms · Run 2: 0.417 ms · Run 3: 0.399 ms · **Average: 0.700 ms**
- **Scan Nodes:**
  - `(no scan)`
- **Plan Breakdown:** Direct tuple insertion into `my_list` with `ON CONFLICT (profile_id, title_id) DO NOTHING` via `my_list_pkey`. Triggers fire to validate `my_list_profile_id_fkey` (0.282 ms) and `my_list_title_id_fkey` (0.098 ms). Executed inside `BEGIN ... ROLLBACK`.
- **Performance Rationale:** Fast (0.700 ms). No table scans required; execution is dominated by foreign key verification.

### W03: Account settings: account 1409 downgrades to the STANDARD plan
- **Type:** WRITE
- **Timings:** Run 1: 1.826 ms · Run 2: 0.202 ms · Run 3: 0.209 ms · **Average: 0.746 ms**
- **Scan Nodes:**
  - `Seq Scan on plans`
  - `Index Scan using accounts_pkey on accounts`
- **Plan Breakdown:** `InitPlan 1` performs a Seq Scan on `plans` (4 rows) to resolve the plan_id for 'STANDARD', followed by an `Index Scan using accounts_pkey` on `accounts` to locate account 1409 and update its `plan_id`. Fires `accounts_plan_id_fkey` trigger. Executed inside `BEGIN ... ROLLBACK`.
- **Performance Rationale:** Fast (0.746 ms). Primary key index on `accounts` enables an instant single-row update.

### W04: Monthly billing run: create July 2026 invoices for every active account
- **Type:** WRITE
- **Timings:** Run 1: 157.091 ms · Run 2: 95.123 ms · Run 3: 104.433 ms · **Average: 118.882 ms**
- **Scan Nodes:**
  - `Seq Scan on accounts`
  - `Seq Scan on plans`
- **Plan Breakdown:** Hash Join between `Seq Scan on accounts` (21,282 active accounts) and `Seq Scan on plans` (4 rows). Inserts 21,282 rows into `invoices`. For every inserted invoice, PostgreSQL executes the foreign key check trigger `invoices_account_id_fkey` (21,282 calls, taking 72.202 ms alone), modifying 747 shared buffer pages and writing 218 blocks. Executed inside `BEGIN ... ROLLBACK`.
- **Performance Rationale:** The slowest write operation (118.882 ms). Batch inserting 21,282 tuples with individual row-level foreign key constraint validation imposes heavy CPU and lock overhead.

### W05: Dunning: put active accounts whose latest invoice failed on hold
- **Type:** WRITE
- **Timings:** Run 1: 31.124 ms · Run 2: 11.397 ms · Run 3: 11.480 ms · **Average: 18.000 ms**
- **Scan Nodes:**
  - `Seq Scan on accounts`
  - `Seq Scan on invoices`
- **Plan Breakdown:** Hash Join between Seq Scan on `accounts` (21,282 active accounts) and Seq Scan on `invoices` (1,376 failed June 2026 invoices) on `account_id`. Updates 634 accounts to `ON_HOLD`, modifying 404 shared buffer pages. Executed inside `BEGIN ... ROLLBACK`.
- **Performance Rationale:** Heavy write operation (18.000 ms). Both large tables (`accounts` and `invoices`) must be scanned sequentially to compute the join before applying the updates.

---

## 4. Key Observations

### 4.1 Slowest Queries
1. **R19 (6,368.053 ms / ~6.37 s):** By far the slowest query. Correlated scalar subqueries cause an $O(N \times M)$ nested loop resulting in 1,220 complete sequential scans of `viewing_activity` (244 million rows inspected).
2. **R16 (146.387 ms):** Multi-table join across four large tables without foreign key indexes, coupled with distinct multi-column aggregation.
3. **W04 (118.882 ms):** Bulk insertion of 21,282 invoices requiring 21,282 individual foreign key constraint trigger executions.
4. **R23 (41.019 ms):** Deep offset pagination (`OFFSET 150000 LIMIT 25`) forces a full table scan and an external spill-to-disk merge sort of 7.5 MB.
5. **R18 (27.122 ms) & R09 (26.306 ms):** Aggregations over all 200k viewing records with date parsing and multi-table hash joins.
6. **R14 (21.974 ms):** Three-table join evaluating custom array position comparisons on over 278,000 rows.
7. **R13 (18.974 ms):** Full table scan on 200,401 viewing records to build a hashed subplan for `NOT IN`.
8. **W05 (18.000 ms):** Dual full table scans on `invoices` (133k) and `accounts` (25k) to update 634 delinquent accounts.

### 4.2 Fastest Queries
1. **R07 (0.021 ms):** Direct point seek on the composite unique key `(title_id, season_no, episode_no)` in `episodes`.
2. **R22 (0.156 ms):** Small table scan over 3,000 titles fitting completely in L1/L2 cache.
3. **R02 (0.157 ms):** Index prefix scan on `episodes(title_id, ...)`.
4. **R06 (0.175 ms):** Primary key index lookup on `my_list(profile_id, ...)`.
5. **R04 (0.610 ms), R05 (0.672 ms), W02 (0.700 ms), R25 (0.709 ms), W03 (0.746 ms), W01 (0.886 ms):** All executing under 1.0 ms due to small table sizes or targeted primary key updates.

### 4.3 General Performance Observations
- **Missing Foreign Key Indexes:** PostgreSQL does not automatically index foreign key columns. Key foreign keys (`viewing_activity.profile_id`, `viewing_activity.title_id`, `profiles.account_id`, `invoices.account_id`) lack indexes, forcing the optimizer into sequential scans for parent-child navigations.
- **Correlated Subqueries vs Joins:** Queries written with correlated subqueries in the SELECT clause (`R19`) exhibit quadratic algorithmic complexity. Rewriting to joins or aggregations is mandatory for Phase 4.
- **Suppression of Indexes by Expressions:** Query `R10` uses `lower(email)`, which completely disables the unique B-tree index on `email`. An expression index or case-insensitive collation is needed.
- **Pagination Pitfalls:** Deep pagination via `OFFSET` (`R23`) is inherently inefficient without index-supported ordering or keyset pagination, as it reads and sorts all preceding rows before discarding them.
- **SQL NULL Semantics:** `R13` (`NOT IN`) produces incorrect empty results due to NULLs in `viewing_activity.episode_id`. Fixing this in Phase 4 via `NOT EXISTS` or `IS NOT NULL` will fix both correctness and execution time.
- **Write Constraint Overhead:** Batch inserts (`W04`) spend over 60% of their execution time validating foreign key constraints.

---

## 5. Conclusion

- **Benchmark Completeness:** All 30 queries (`R01`–`R25` reads and `W01`–`W05` writes) were successfully benchmarked against `netflix_bench` on PostgreSQL 18 with exactly three runs each.
- **Baseline Establishment:** The cumulative average workload runtime across all 30 queries is **6,838.297 ms**, with a single query (`R19`) accounting for 93.1% of the total time.
- **Next Phase (CP3 / Phase 4):** These genuine measurements establish the rigorous baseline against which optimization speedups (B-tree indexing, partial indexes, expression indexes, query rewrites, and VACUUM/ANALYZE tuning) will be measured in Phase 4.

---

## 6. Raw Benchmark Files Location

All raw timing data, execution plans, and summary metrics are preserved in the repository:
- **Summary Metrics:** [`benchmarks/results/baseline/summary.csv`](file:///Users/aishsagwal/DE_Bugify_2026/benchmarks/results/baseline/summary.csv)
- **Raw Execution Plans:** [`benchmarks/results/baseline/`](file:///Users/aishsagwal/DE_Bugify_2026/benchmarks/results/baseline/)
  - `R01.txt` through `R25.txt`
  - `W01.txt` through `W05.txt`
