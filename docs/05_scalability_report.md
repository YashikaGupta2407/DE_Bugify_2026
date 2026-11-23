# Phase 5: Scalability Report

## 1. Status and scope

This report records the large-dataset facts that can be established from the supplied `large_data.zip`, describes the scale-out design, and provides the comparison table for the large-data benchmark.

**Benchmark status:** `benchmarks/results/large/summary.csv` is being produced by a teammate. Large-data execution times, growth factors, target verdicts, execution plans, and PostgreSQL storage measurements are intentionally left as pending until that measured output is available. No large-data timings or database sizes are invented in this report.

The CP4 instructions require the optimized workload (not the original baseline workload), three runs per query, writes inside a transaction that is rolled back, and the same query IDs so results can be compared with CP3.

## 2. Dataset and environment

### 2.1 Exact large-data row counts

The supplied large dataset contains 11 CSV files and **12,124,194 rows** in total. The following counts were read from the CSV data, not estimated from the faculty brief.

| CSV / table | Seed rows | Large rows | Growth |
|---|---:|---:|---:|
| `plans` | 4 | 4 | 1.000× |
| `accounts` | 25,000 | 500,000 | 20.000× |
| `profiles` | 75,000 | 1,500,000 | 20.000× |
| `genres` | 15 | 15 | 1.000× |
| `titles` | 3,000 | 60,000 | 20.000× |
| `title_genres` | 5,963 | 119,166 | 19.984× |
| `episodes` | 20,000 | 400,000 | 20.000× |
| `viewing_activity` | 200,401 | 4,012,819 | 20.024× |
| `ratings` | 33,900 | 674,605 | 19.900× |
| `my_list` | 59,992 | 1,199,989 | 20.002× |
| `invoices` | 133,057 | 2,657,600 | 19.973× |
| **Total** | **556,332** | **12,124,194** | **21.794×** |

The total growth is greater than 20× because the small lookup tables remain fixed while the larger tables grow by approximately 20×.

### 2.2 Viewing-data time distribution

- Earliest `viewing_activity.started_at`: **2025-01-01**.
- Latest timestamp: **2026-07-01 02:19:02 (+05:30)**.
- The CSV contains **19 calendar months** (January 2025 through July 2026).
- July 2026 contains **121** viewing rows; the other months have roughly 205,000–228,700 rows each.

This time distribution supports monthly RANGE partitioning on `started_at`. The July 2026 tail is small but must not be discarded.

### 2.3 Data validation observations

The CSV validation performed for this dataset found no duplicate primary/composite keys, null primary-key values, or invalid foreign-key references among the checked relationships. It also found no non-positive viewing durations, unsupported device values, invalid episode/title pairings, or checked account/profile/invoice business-rule violations.

A substantial number of viewing rows have `episode_id IS NULL`. This is valid: movie views do not require an episode. Any anti-join against `episode_id` must therefore account for SQL NULL semantics. CP3 already corrected the `NOT IN` issue in R13 by using `NOT EXISTS`.

### 2.4 Large-data workload compatibility

Some workload statements contain fixed seed-data identifiers. In the large CSV, `title_id = 2909` and `title_id = 2523` are movies, not series, and have no episodes. Therefore the unchanged seed-specific R02, R07, R13, and W01 statements do not exercise the intended series/episode path on this dataset.

For a meaningful large-data benchmark, retain the same query IDs and query intent, but use a documented large-data fixture identifier. The inspected large dataset contains series `title_id = 40002` with 25 episodes, including season 1 episode 5; one episode has no viewing row. W01 must also use a view ID that does not already exist. The teammate preparing the large summary should record any fixture-only ID substitutions alongside the raw plans. Do not silently compare an empty/no-op query with a seed query that exercised real rows.

## 3. CP3 optimized timings used as the seed comparison

The values below are the committed CP3 optimized averages in milliseconds. The large-data column must be filled from the teammate's measured `benchmarks/results/large/summary.csv`.

| Query | Type | Optimized seed (ms) | Large (ms) | Growth | Target |
|---|---|---:|---:|---:|---|
| R01 | READ | 0.157 | Pending | Pending | <5 ms |
| R02 | READ | 0.098 | Pending | Pending | <5 ms |
| R03 | READ | 1.460 | Pending | Pending | <250 ms |
| R04 | READ | 0.969 | Pending | Pending | <250 ms |
| R05 | READ | 0.490 | Pending | Pending | <250 ms |
| R06 | READ | 0.229 | Pending | Pending | <5 ms |
| R07 | READ | 0.094 | Pending | Pending | <5 ms |
| R08 | READ | 5.703 | Pending | Pending | <5,000 ms |
| R09 | READ | 32.044 | Pending | Pending | <5,000 ms |
| R10 | READ | 0.081 | Pending | Pending | <5 ms |
| R11 | READ | 6.664 | Pending | Pending | <250 ms |
| R12 | READ | 1.766 | Pending | Pending | <5,000 ms |
| R13 | READ | 0.151 | Pending | Pending | <250 ms |
| R14 | READ | 50.713 | Pending | Pending | <5,000 ms |
| R15 | READ | 9.783 | Pending | Pending | <5,000 ms |
| R16 | READ | 321.487 | Pending | Pending | <5,000 ms |
| R17 | READ | 12.412 | Pending | Pending | <5,000 ms |
| R18 | READ | 40.838 | Pending | Pending | <5,000 ms |
| R19 | READ | 10.408 | Pending | Pending | <5,000 ms |
| R20 | READ | 2.778 | Pending | Pending | <5,000 ms |
| R21 | READ | 0.720 | Pending | Pending | <250 ms |
| R22 | READ | 0.259 | Pending | Pending | <250 ms |
| R23 | READ | 31.886 | Pending | Pending | <250 ms |
| R24 | READ | 0.087 | Pending | Pending | <5 ms |
| R25 | READ | 1.039 | Pending | Pending | <250 ms |
| W01 | WRITE | 1.506 | Pending | Pending | <5 ms |
| W02 | WRITE | 1.475 | Pending | Pending | <5 ms |
| W03 | WRITE | 0.846 | Pending | Pending | <5 ms |
| W04 | WRITE | 197.795 | Pending | Pending | <2,000 ms |
| W05 | WRITE | 26.353 | Pending | Pending | <2,000 ms |
| **Total** | | **760.291** | **Pending** | **Pending** | — |

The target groups follow the CP4 brief:
- Real-time/member-facing: R01, R02, R06, R07, R10, R24, W01, W02, W03 — under 5 ms.
- Interactive rows/search/operations: R03, R04, R05, R11, R13, R21, R22, R23, R25 — under 250 ms.
- Reports/analytics: R08, R09, R12, R14, R15, R16, R17, R18, R19, R20 — under 5,000 ms.
- Batch jobs: W04 and W05 — under 2,000 ms.

**How to complete this table:** copy the `avg_ms` value for each query ID from the teammate's large summary. Calculate `Growth = large avg_ms / optimized seed avg_ms`. Mark the target as met only after checking the relevant threshold. If a query uses a fixture-only ID substitution, retain the query ID and record the substitution in §2.4 and with the benchmark artifacts.

## 4. Growth analysis

The table above establishes the input growth, but query-time growth cannot be classified until the large benchmark is measured. The following are hypotheses to test against the actual plans, not claims about measured large-data performance.

| Query pattern | Likely scale behavior | Reason to verify |
|---|---|---|
| Point lookups and profile-scoped rows (R01, R02, R06, R07, R10, R24) | Near-flat or logarithmic growth | Selective B-tree lookups should visit a small number of index and heap pages. |
| Date-filtered top rows and operational lookups (R03, R11, R21, R22) | Depends on selectivity and partition/index pruning | A date window can remain selective, but a broad range may touch many pages. |
| Whole-history aggregates (R09, R14, R16, R18) | May grow with the rows scanned | These queries aggregate a substantial share of viewing activity; an index cannot eliminate the need to read qualifying rows. |
| Originals and anti-join reports (R13, R19) | Depends on join/index selectivity | The episode anti-join and per-title counts must use the relevant indexes; inspect actual loops and buffers. |
| Deep pagination (R23) | May grow more than linearly in user-visible cost | OFFSET must walk past earlier rows. A stable index helps, but keyset pagination is the long-term design. |
| Bulk writes (W04, W05) | Grows with inserted/updated rows and index/FK maintenance | More accounts and invoices increase row work, index maintenance, and foreign-key checks. |

After the benchmark arrives, replace these hypotheses with measured classifications: approximately unchanged, approximately proportional to scanned data, or worse than proportional. Include the plan evidence for any query that misses its target.

## 5. What is likely to become the bottleneck

CP3 already identified several scan-heavy queries on the seed dataset:

- **R16** groups viewing rows by account and hour and counts distinct profiles. It is a broad aggregation, so its large-data plan and memory/sort behavior need attention.
- **R14** checks viewing activity against kids-profile maturity limits. It must read the qualifying viewing rows and join profiles/titles.
- **R18 and R09** aggregate viewing history by month/device or genre. Their cost depends on the volume of qualifying history.
- **R23** uses deep OFFSET pagination. The current CP3 index supports ordering, but OFFSET still has to skip the earlier rows.
- **W04** inserts one invoice per active account. Its cost includes invoice index maintenance and a foreign-key check for each inserted row.
- **R19** is much better after CP3's title/time index, but the large dataset has 20× as many viewing rows and 20× as many titles. Confirm that the large plan continues to use the index rather than assuming the seed plan remains optimal.

No large-data fix is claimed here until the teammate's plan and timing evidence show a target miss. The first response to a miss should be to inspect the actual plan, row estimates, buffer reads, sort method, and loops—not to add indexes speculatively.

## 6. Storage measurements

The uncompressed CSV files occupy approximately **655.2 MB** in total. This is input-file size, **not** PostgreSQL database size. PostgreSQL table, index, WAL, and free-space sizes must be measured after loading and applying `sql/05_indexes.sql`.

Run the following on both the seed and large databases after `ANALYZE`:

```sql
-- Total database size
SELECT current_database() AS database_name,
       pg_size_pretty(pg_database_size(current_database())) AS database_size_bytes;

-- Table, index, and total relation sizes for the Netflix schema
SELECT
    c.relname AS table_name,
    pg_size_pretty(pg_table_size(c.oid)) AS table_size,
    pg_size_pretty(pg_indexes_size(c.oid)) AS indexes_size,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'netflix'
  AND c.relkind IN ('r', 'p')
ORDER BY pg_total_relation_size(c.oid) DESC;
```

Record the outputs for the seed and large databases here after they are measured:

| Dataset | Database size | Table bytes | Index bytes |
|---|---:|---:|---:|
| Seed | Pending PostgreSQL measurement | Pending | Pending |
| Large | Pending PostgreSQL measurement | Pending | Pending |

Do not substitute CSV file size for PostgreSQL storage size.

## 7. Architecture for 100× volume

### 7.1 Partitioning

Partition `viewing_activity` by **RANGE(`started_at`)**, one partition per calendar month.

Reasons:
1. The large dataset has 4,012,819 viewing rows and spans January 2025 through July 2026.
2. R03, R08, R09, R18, R20 and time-bounded compliance/analytics workloads filter by time.
3. Monthly retention and archival become operationally manageable: detach/archive old monthly partitions instead of deleting millions of rows.
4. PostgreSQL can prune partitions outside a query's time range before scanning data.

The runnable design is in `sql/08_partitioning.sql`. It creates a separate `viewing_activity_partitioned` table so the CP1/CP3 table remains untouched for comparison. It creates monthly partitions from January 2025 through December 2027 plus a DEFAULT partition, copies existing rows, builds the CP3 access indexes, runs `ANALYZE`, and includes row-count/equality checks and a partition-pruning EXPLAIN example.

**Primary-key rule:** a UNIQUE or PRIMARY KEY constraint on a PostgreSQL partitioned table must include every partition-key column. Since the partition key is `started_at`, the partitioned copy uses `PRIMARY KEY (view_id, started_at)`. This guarantees uniqueness of the pair, not global uniqueness of `view_id` alone. The original unpartitioned table's `PRIMARY KEY (view_id)` is unchanged. A production cutover that requires globally unique `view_id` must add a non-partitioned ID registry/sequence-backed allocation strategy and make every insert use it; do not treat the partitioned copy as a drop-in replacement until that is implemented.

**Partition pruning validation:** run the EXPLAIN example at the end of `sql/08_partitioning.sql`. The plan should show only the monthly partition(s) intersecting the requested time range. Save the actual plan in the submission evidence; this report does not claim that PostgreSQL execution was performed in this environment.

### 7.2 Sharding

For a future distributed deployment, the first candidate is **account-based sharding** because an account owns up to five profiles and billing/settings operations are account-scoped. Keeping an account and its profiles on the same shard helps profile switching, account settings, billing, and household-level operations.

The current `viewing_activity` table stores `profile_id`, not `account_id`. A production sharding layer therefore needs a reliable profile-to-account routing directory, or a carefully constrained `account_id` routing key carried with each viewing row. If `account_id` is denormalized into viewing rows, enforce that the profile belongs to that account.

Queries that become cross-shard under account sharding include:
- R03 Top 10 titles across all viewers.
- R09 genre completion rates.
- R17 Originals versus licensed ratings.
- R19 total views and last view per Original.
- R20 most-added titles.
- R16 account/hour sharing checks can be local if all profiles of an account are colocated, but its time aggregation still spans the account's history.

For global analytics, each shard should compute partial aggregates (counts, sums, maxima, and grouped values); a coordinator merges those aggregates. For example, global Top 10 merges per-shard title view counts and sorts the combined counts. Avoid moving raw viewing rows between shards for every report.

Profile-based sharding would make R01 straightforward but can split profiles from the same household, complicating account sharing and billing. Title-based sharding would help title-centric analytics but scatter a household's activity across shards. Account-based placement is the better initial trade-off for this product's transactional access pattern.

### 7.3 Read replicas and caching

| Workload | Suggested route | Reason |
|---|---|---|
| R01 Continue Watching, R06 My List, R24 profile list | Primary for strict freshness; replica if bounded replication lag is acceptable | Member-facing state can change immediately after a play or list update. |
| R10 sign-in and account settings | Primary | Identity and account state should be current. |
| W01–W05 | Primary only | Writes and transactional billing/dunning operations must commit on the primary. |
| R03, R08, R09, R12, R14–R20 | Read replica or analytics replica | Reporting can tolerate small replication lag and should not compete with transactional writes. |
| R04, R05, R11, R13, R21, R22, R23, R25 | Replica where freshness requirements allow; cache selected stable results | These are read-heavy rows/search/operations, but compliance and payment retry views may require primary freshness. |

Cache only data with an explicit freshness policy. Examples include title catalogue search results and genre rows with short TTLs. Do not cache account status, billing state, or compliance results without a correctness-approved invalidation and freshness design.

### 7.4 Maintenance and retention

- Keep autovacuum enabled. Monitor dead tuples, vacuum/analyze frequency, and per-partition statistics; tune per-table settings only after observing write rate and vacuum lag.
- Run `ANALYZE` after bulk loads and after creating or attaching partitions. Analyze individual hot partitions when data distribution changes materially.
- Keep each new monthly partition ready before the month begins. Monitor the DEFAULT partition; rows accumulating there indicate a missing future partition or out-of-range timestamp.
- Define a retention policy with the product/compliance owner before archiving or dropping old viewing partitions. Detach and archive partitions only after retention and legal requirements are approved.
- Refresh any future summary/materialized views on a defined schedule and expose their freshness timestamp to report consumers.
- Monitor index/table bloat and write overhead. Partitioning does not remove the need for appropriate indexes or vacuuming.

## 8. Conclusion

The large CSV has been inspected and its exact row counts and time range are documented. The design is prepared for monthly time partitioning, and the SQL keeps the original CP1/CP3 table intact for safe comparison.

**The database cannot yet be declared benchmark-verified for next year's load.** The teammate's large benchmark output, the PostgreSQL storage measurements, and actual partition-pruning execution plan still need to be added. Once those are available, fill the pending cells in §3 and §6, classify measured growth in §4, and document any target misses with before/after plans. A 100× production claim should be made only after those measurements and the global-ID uniqueness decision are resolved.
