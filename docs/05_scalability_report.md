# Phase 4: Scalability Report

**Large CSV inspection:** completed from the supplied `large_data.zip`.  
**Large PostgreSQL benchmark:** pending; no large-data execution times are claimed.

## 1. Method and current limitation

All 11 CSV files were extracted and parsed. Their headers match the corresponding tables in `sql/01_schema.sql`. The large dataset loader is provided in `sql/07_load_large_data.sql`.

Run from the repository root on the PostgreSQL machine:

```bash
createdb netflix_large
psql -d netflix_large -f sql/01_schema.sql
psql -d netflix_large -f sql/07_load_large_data.sql
psql -d netflix_large -f sql/05_indexes.sql
./benchmarks/run_benchmark.sh netflix_large large 3 sql/06_optimized_queries.sql
```

The benchmark script generates `benchmarks/results/large/summary.csv` and 30 raw plan files. Keep the CSV archive local; do not commit it.

**Limitation:** this execution environment has no PostgreSQL server/client, so I could not run the large workload, collect PostgreSQL plans, or measure database/index sizes. Those values are intentionally left pending rather than estimated. CP4 performance validation is not complete until the commands above have been run.

## 2. Actual dataset size

These are parsed row counts from the uploaded archive. Growth is relative to the seed counts documented in the CP3 reports.

| Table | Seed rows | Large rows | Growth |
|---|---:|---:|---:|
| viewing_activity | 200,401 | 4,012,819 | 20.02× |
| invoices | 133,057 | 2,657,600 | 19.97× |
| profiles | 75,000 | 1,500,000 | 20.00× |
| accounts | 25,000 | 500,000 | 20.00× |
| episodes | 20,000 | 400,000 | 20.00× |
| my_list | 59,992 | 1,199,989 | 20.00× |
| ratings | 33,900 | 674,605 | 19.90× |
| title_genres | 5,963 | 119,166 | 19.98× |
| titles | 3,000 | 60,000 | 20.00× |
| genres | 15 | 15 | 1.00× |
| plans | 4 | 4 | 1.00× |
| **Total** | **552,?** | **11,124,198** | — |

The largest table is `viewing_activity` at 4,012,819 rows. The other large operational tables are invoices (2,657,600), profiles (1,500,000), and accounts (500,000).

## 3. CSV-level validation

The following checks were performed against the supplied CSVs and the constraints/relationships in `sql/01_schema.sql`. They are CSV-level checks, not a substitute for a successful PostgreSQL import.

| Check | Result |
|---|---:|
| CSV files parsed | 11 / 11 |
| Total parsed data rows | 11,124,198 |
| Duplicate primary/composite keys | 0 |
| Missing foreign-key parent values | 0 |
| Viewing rows whose episode belongs to a different title | 0 |
| Accounts with more than 5 profiles | 0 |
| Maximum profiles for one account | 5 |
| Viewing rows before title `added_on` (India calendar date) | 0 |
| Cancelled before signup | 0 |
| Account cancellation/billing-date rule violations | 0 |
| Kids profiles outside U / UA7 maturity limits | 0 |
| Invoice billing periods not on day 1 | 0 |
| Failed-invoice / `paid_at` rule violations | 0 |
| Non-positive invoice amounts or viewing durations | 0 |
| Checked VARCHAR lengths and numeric ranges violated | 0 |

The CSV headers and field widths/types checked are compatible with the project schema. The loader runs SQL row-count and integrity checks after import; retain those results after the local PostgreSQL load.

## 4. Timestamp range and monthly distribution

The actual `viewing_activity.started_at` range in Asia/Kolkata is:

- Minimum: **2025-01-01 00:00:00 +05:30**
- Maximum: **2026-07-01 02:19:02 +05:30**

| Month | Viewing rows |
|---|---:|
| 2025-01 | 228,692 |
| 2025-02 | 205,963 |
| 2025-03 | 227,473 |
| 2025-04 | 220,462 |
| 2025-05 | 228,139 |
| 2025-06 | 220,625 |
| 2025-07 | 228,032 |
| 2025-08 | 228,480 |
| 2025-09 | 221,134 |
| 2025-10 | 227,851 |
| 2025-11 | 221,024 |
| 2025-12 | 228,145 |
| 2026-01 | 227,343 |
| 2026-02 | 205,395 |
| 2026-03 | 227,551 |
| 2026-04 | 219,479 |
| 2026-05 | 227,067 |
| 2026-06 | 219,843 |
| 2026-07 | 121 |

**Partition boundary implication:** the dataset contains 121 rows in July 2026. A partition layout ending at July 1 midnight would reject valid rows. `sql/08_partitioning.sql` therefore includes the July 2026 partition and provisions monthly partitions through December 2027.

## 5. CP3 seed timings vs large-data timings

The seed values below are copied from `docs/04_optimization_report.md`. Large values and growth ratios must be filled from the generated large benchmark summary.

| Query | CP3 optimized seed (ms) | Large optimized (ms) | Large / seed |
|---|---:|---:|---:|
| R01 | 0.157 | — | — |
| R02 | 0.098 | — | — |
| R03 | 1.460 | — | — |
| R04 | 0.969 | — | — |
| R05 | 0.490 | — | — |
| R06 | 0.229 | — | — |
| R07 | 0.094 | — | — |
| R08 | 5.703 | — | — |
| R09 | 32.044 | — | — |
| R10 | 0.081 | — | — |
| R11 | 6.664 | — | — |
| R12 | 1.766 | — | — |
| R13 | 0.151 | — | — |
| R14 | 50.713 | — | — |
| R15 | 9.783 | — | — |
| R16 | 321.487 | — | — |
| R17 | 12.412 | — | — |
| R18 | 40.838 | — | — |
| R19 | 10.408 | — | — |
| R20 | 2.778 | — | — |
| R21 | 0.720 | — | — |
| R22 | 0.259 | — | — |
| R23 | 31.886 | — | — |
| R24 | 0.087 | — | — |
| R25 | 1.039 | — | — |
| W01 | 1.506 | — | — |
| W02 | 1.475 | — | — |
| W03 | 0.846 | — | — |
| W04 | 197.795 | — | — |
| W05 | 26.353 | — | — |

Do not assume every query grows by 20×. Inspect point lookups (R01/R06/R10/R24), time-range scans and aggregates (R03/R08/R09/R14/R16/R18), correlated title lookups (R19), deep OFFSET pagination (R23), and batch writes (W04/W05) separately. R23 still has to walk past 150,000 rows even when an index avoids a full sort; keyset pagination is preferable for a production API.

## 6. Storage measurements

Run after `ANALYZE` on seed and large databases:

```sql
SELECT pg_size_pretty(pg_database_size(current_database())) AS database_size;

SELECT relname,
       pg_size_pretty(pg_total_relation_size(oid)) AS total_size,
       pg_size_pretty(pg_relation_size(oid)) AS table_size,
       pg_size_pretty(pg_indexes_size(oid)) AS indexes_size
FROM pg_class
WHERE relkind = 'r'
  AND relnamespace = 'netflix'::regnamespace
ORDER BY pg_total_relation_size(oid) DESC;
```

| Dataset | Database size | viewing_activity table | Its indexes |
|---|---:|---:|---:|
| Seed | Pending | Pending | Pending |
| Large | Pending | Pending | Pending |

## 7. Partitioning design

### 7.1 Monthly RANGE partitioning

`viewing_activity` is the largest relation, and R03, R08, R09 and R18 filter by `started_at`. Monthly `PARTITION BY RANGE (started_at)` allows PostgreSQL to prune unrelated months for date-bounded queries and simplifies retention/archival operations.

`sql/08_partitioning.sql` creates a side-by-side `viewing_activity_partitioned` table, creates 36 monthly partitions from January 2025 through December 2027 with explicit +05:30 boundaries, copies the 4,012,819 source rows, recreates the useful CP3 indexes, runs `ANALYZE`, and executes a June 2026 pruning check.

Run after loading the large dataset and applying CP3 indexes:

```bash
psql -d netflix_large -f sql/08_partitioning.sql
```

The June 2026 EXPLAIN should touch only `viewing_activity_2026_06`. Confirm this in the actual PostgreSQL plan; the script has not been executed in this environment. No DEFAULT partition is used, so provision future partitions before inserting rows for those months.

### 7.2 Primary-key trade-off

PostgreSQL requires a partitioned table's primary/unique constraint to include the partition key. The example uses `PRIMARY KEY (view_id, started_at)`, not the source table's sole `PRIMARY KEY (view_id)`. The CSV has no duplicate `view_id`, but the composite key does not enforce global uniqueness of `view_id` across different partitions. The current workload has no FK referencing `viewing_activity(view_id)`; nevertheless, check application code and external consumers before production migration. If global uniqueness is required, retain a separate global ID registry/allocator or choose another partitioning design.

### 7.3 Sharding, replicas and caching

- Hash-sharding by `profile_id` keeps a profile's Continue Watching (R01) and binge history (R08) together, but makes account-wide sharing detection (R16) and title-wide analytics (R03/R17/R19/R20) cross-shard.
- Sharding by `account_id` helps account transactions but still distributes title-wide reports. Sharding by `title_id` helps title analytics but scatters a profile's history. Choose based on the dominant transactional access pattern.
- Read replicas suit reporting queries where replication lag is acceptable; keep writes and read-after-write operations on the primary.
- Cache stable catalog/UI results with account/profile and authorization context in the cache key. Do not cache compliance or authorization decisions beyond their freshness requirement.
- Use scheduled or incrementally maintained aggregates for broad analytics. Keep autovacuum enabled, run `ANALYZE` after bulk loads, and monitor bloat, partition sizes, vacuum duration and replication lag.

## 8. Conclusion

The supplied CSVs are structurally consistent with the checked CP1 schema constraints and are approximately 20× seed scale for the major operational tables. The actual timestamp range requires a July 2026 partition. Monthly time partitioning is a reasonable design for the timestamp-filtered workload.

However, large-data query performance and storage have not yet been measured. The CP3 11.2× seed-data speed-up is not proof of the same performance at 20× volume. Complete CP4 performance validation only after the PostgreSQL import, all 30 large benchmark queries, storage measurements and partition-pruning plan have been captured.
