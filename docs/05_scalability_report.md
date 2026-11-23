# Phase 5: Scalability Report

## 1. Status and scope

This report records the large-dataset facts that can be established from the supplied `large_data.zip`, describes the scale-out design, and provides the comparison table for the large-data benchmark.

**Benchmark status:** the optimized workload was run three times per query on PostgreSQL 18.6 against the loaded `netflix_large` database. The summary and all 30 raw three-run plan files are in `benchmarks/results/large/`. Large-data timings below are measured execution times; write queries were rolled back after each run. The benchmark used the CP3 indexes on the original `viewing_activity` table. The separate partitioned copy was validated independently.

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

Some workload statements contain fixed seed-data identifiers. In the large CSV, `title_id = 2909` and `title_id = 2523` are movies, not series, and have no episodes. Therefore the large benchmark used `title_id = 40002` for R02, R07, R13, R25, W01, and W02 while retaining their query IDs and intent. This is a series with 25 episodes, including season 1 episode 5; one episode has no viewing row. W01 used `view_id = 990000001`, verified absent before the benchmark. Profile IDs 7043 and 7393 exist in the large data. The exact fixture-substituted optimized workload is saved as `benchmarks/results/large/workload.sql` beside its three-run plans. Other query SQL was taken from `sql/06_optimized_queries.sql` without changes. The seed-specific IDs in `queries/workload_30.sql` and `sql/06_optimized_queries.sql` were not changed.

## 3. CP3 optimized timings used as the seed comparison

The values below compare committed CP3 optimized averages with the measured large-data averages in `benchmarks/results/large/summary.csv`.

| Query | Type | Optimized seed (ms) | Large (ms) | Growth | Target |
|---|---|---:|---:|---:|---|
| R01 | READ | 0.157 | 0.377 | 2.401× | < 5 ms met |
| R02 | READ | 0.098 | 0.102 | 1.041× | < 5 ms met |
| R03 | READ | 1.460 | 22.289 | 15.266× | < 250 ms met |
| R04 | READ | 0.969 | 9.896 | 10.213× | < 250 ms met |
| R05 | READ | 0.490 | 5.210 | 10.633× | < 250 ms met |
| R06 | READ | 0.229 | 0.218 | 0.952× | < 5 ms met |
| R07 | READ | 0.094 | 0.043 | 0.457× | < 5 ms met |
| R08 | READ | 5.703 | 92.061 | 16.143× | < 5,000 ms met |
| R09 | READ | 32.044 | 414.878 | 12.947× | < 5,000 ms met |
| R10 | READ | 0.081 | 0.224 | 2.765× | < 5 ms met |
| R11 | READ | 6.664 | 64.459 | 9.673× | < 250 ms met |
| R12 | READ | 1.766 | 28.107 | 15.916× | < 5,000 ms met |
| R13 | READ | 0.151 | 0.340 | 2.252× | < 250 ms met |
| R14 | READ | 50.713 | 367.910 | 7.255× | < 5,000 ms met |
| R15 | READ | 9.783 | 59.946 | 6.128× | < 5,000 ms met |
| R16 | READ | 321.487 | 3062.078 | 9.525× | < 5,000 ms met |
| R17 | READ | 12.412 | 90.042 | 7.254× | < 5,000 ms met |
| R18 | READ | 40.838 | 965.358 | 23.639× | < 5,000 ms met |
| R19 | READ | 10.408 | 237.936 | 22.861× | < 5,000 ms met |
| R20 | READ | 2.778 | 56.017 | 20.165× | < 5,000 ms met |
| R21 | READ | 0.720 | 20.605 | 28.618× | < 250 ms met |
| R22 | READ | 0.259 | 1.548 | 5.977× | < 250 ms met |
| R23 | READ | 31.886 | 36.767 | 1.153× | < 250 ms met |
| R24 | READ | 0.087 | 0.129 | 1.483× | < 5 ms met |
| R25 | READ | 1.039 | 4.112 | 3.958× | < 250 ms met |
| W01 | WRITE | 1.506 | 1.891 | 1.256× | < 5 ms met |
| W02 | WRITE | 1.475 | 2.497 | 1.693× | < 5 ms met |
| W03 | WRITE | 0.846 | 1.497 | 1.770× | < 5 ms met |
| W04 | WRITE | 197.795 | 5655.539 | 28.593× | < 2,000 ms missed |
| W05 | WRITE | 26.353 | 1105.907 | 41.965× | < 2,000 ms met |
| **Total** | | **760.291** | **12307.983** | **16.189×** | — |

The target groups follow the CP4 brief:
- Real-time/member-facing: R01, R02, R06, R07, R10, R24, W01, W02, W03 — under 5 ms.
- Interactive rows/search/operations: R03, R04, R05, R11, R13, R21, R22, R23, R25 — under 250 ms.
- Reports/analytics: R08, R09, R12, R14, R15, R16, R17, R18, R19, R20 — under 5,000 ms.
- Batch jobs: W04 and W05 — under 2,000 ms.

**Growth** is large average divided by the committed CP3 optimized average. Target results use the CP4 thresholds shown above. W04 misses its target; its raw plan is available in `benchmarks/results/large/W04.txt`.

## 4. Growth analysis

The table above compares measured average execution time on the seed and large datasets. Absolute times remain within target for all listed groups except W04.

| Query pattern | Observed scale behavior | Plan evidence |
|---|---|---|
| Point lookups and profile-scoped rows (R01, R02, R06, R07, R10, R24) | Remained below 0.4 ms despite 20× table growth | Plans use selective B-tree lookups, with an email bitmap lookup for R10. |
| Date-filtered and operational queries (R03, R11, R21, R22) | Increased 6×–29× but remained below 65 ms | R03 uses the time index; R11 scans accounts and filters invoices; R21 uses the status/date index; R22 uses the leaving-date index. |
| Whole-history aggregates (R09, R14, R16, R18) | Increased about 7×–24×; all remained below 1,000 ms except R16 at 3,062 ms | R16 scans all views and spills sort data to temporary files; R18 uses the time index; R09 and R14 process broad view sets. |
| Originals and anti-join reports (R13, R19) | R13 remained sub-ms; R19 increased about 23× to 238 ms | R13 uses episode and viewing indexes; R19 scans titles and probes the title/time index. |
| Deep pagination (R23) | Increased about 1.15× to 36.8 ms | The ordering index avoids a full sort while walking past the offset. |
| Bulk writes (W04, W05) | W04 increased about 28.6× and missed target; W05 increased about 42× but met target | W04 inserted 424,960 rows and dirtied over 16,000 buffers; W05 scans accounts and probes invoices. |

The measured large averages show approximately flat sub-millisecond point lookups for R01, R02, R06, R07, and R24, while scans and aggregations rose with the larger tables. R16 increased about 9.5× and is the slowest read at 3,062 ms, within its 5,000 ms analytics target. W04 takes 5,656 ms to generate invoices for active accounts and is the only query that misses its target. W05 takes 1,106 ms, within its 2,000 ms batch target. R16’s plan scans viewing activity, profiles, accounts, and plans; W04 scans accounts and plans; W05 scans accounts and probes invoices. See the raw plan files for actual row counts, buffers, and timing details.

## 5. What is likely to become the bottleneck

The large-data plans confirm several scan-heavy workloads:

- **R16** groups viewing rows by account and hour and counts distinct profiles. Its 3,062 ms plan sorts 4,012,819 views and spills sort data to disk, though it remains below the 5,000 ms target.
- **R14** checks viewing activity against kids-profile maturity limits. It must read the qualifying viewing rows and join profiles/titles.
- **R18 and R09** aggregate viewing history by month/device or genre. Their cost depends on the volume of qualifying history.
- **R23** uses deep OFFSET pagination. The current CP3 index supports ordering, but OFFSET still has to skip the earlier rows.
- **W04** inserts one invoice per active account. It inserts 424,960 rows, takes 5,656 ms, and misses the 2,000 ms target; its cost includes invoice index maintenance and a foreign-key check for every row.
- **R19** is much better after CP3's title/time index, but the large dataset has 20× as many viewing rows and 20× as many titles. Confirm that the large plan continues to use the index rather than assuming the seed plan remains optimal.

The measured target misses are documented above. Their current plans indicate broad table work; future tuning should evaluate set-based execution costs and available indexes against actual row counts and buffers before adding indexes.

## 6. Storage measurements

The uncompressed CSV files occupy approximately **655.2 MB** in total. This is input-file size, **not** PostgreSQL database size. PostgreSQL size was measured after loading and applying `sql/05_indexes.sql` and running the partitioning script.

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

The large database was measured after loading the data, applying CP3 indexes, and creating the partitioned copy. Database size includes PostgreSQL catalog and other database overhead. Table and index bytes sum physical relations (`relkind = 'r'`) in the `netflix` schema, including partition children but excluding the partitioned parent to avoid double-counting.

| Dataset | Database size | Table bytes | Index bytes |
|---|---:|---:|---:|
| Seed | Not measured in this run | — | — |
| Large | 3,055,253,183 bytes (2,914 MB) | 1,111,965,696 | 1,933,623,296 |

The 655.2 MB CSV size is input-file size, not PostgreSQL database size.

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

**Partition validation:** `sql/08_partitioning.sql` ran successfully on `netflix_large`. The original and partitioned copies each had 4,012,819 rows; both full-row `EXCEPT ALL` checks returned zero. The June 2026 EXPLAIN scanned only `viewing_activity_p202606` (Execution Time 20.790 ms), confirming month partition pruning. Partition sizes and row counts were also emitted by the script.

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

The large dataset loaded with all expected rows and zero loader integrity violations. CP3 indexes were applied, all 30 optimized queries were measured three times, and the monthly partitioned copy passed row-equality and partition-pruning checks. The report records fixture substitutions and the W04 target miss. This validates the current CP4 workload at the supplied 20× data scale; it does not establish performance at 100×, and the production design still needs a global `view_id` allocation strategy before replacing the original table.
