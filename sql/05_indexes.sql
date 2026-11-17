-- =====================================================================
-- Bugify — CP3: index set for the optimised workload
--
-- Every index below is justified by a measured bottleneck in
-- benchmarks/results/baseline/summary.csv (and by the plan captured in
-- the matching raw plan file). Nothing here is speculative: if a query
-- is not listed as the reason for an index, the index does not exist.
--
-- Apply with:  psql -d netflix_bench -f sql/05_indexes.sql
--
-- Indexes are additive only — no column is renamed, retyped or
-- constrained, so the schema from CP1 and the data from CP1 stay valid.
-- =====================================================================

BEGIN;

SET search_path TO netflix;

-- Trigram matching for the free-text title search (R05: name ILIKE '%love%').
-- A plain B-tree cannot serve a leading-wildcard LIKE.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------
-- viewing_activity (200,401 rows) — the hot table; 13 of 25 read
-- queries touch it and every one of them currently does a Seq Scan.
-- ---------------------------------------------------------------------

-- R01 "Continue watching": one profile, unfinished rows, newest first.
-- Partial, because only unfinished rows are ever looked up by this row.
CREATE INDEX viewing_activity_profile_unfinished_idx
    ON viewing_activity (profile_id, started_at DESC)
    INCLUDE (title_id, episode_id, duration_watched_sec)
    WHERE NOT completed;

-- R08 binge sessions, R14 compliance, R16 sharing check: per-profile
-- history over a time window.
CREATE INDEX viewing_activity_profile_started_idx
    ON viewing_activity (profile_id, started_at DESC)
    INCLUDE (title_id, episode_id, duration_watched_sec, completed);

-- R19 originals report: two correlated subqueries per title
-- (count(*) and max(started_at)) over the same column pair.
CREATE INDEX viewing_activity_title_started_idx
    ON viewing_activity (title_id, started_at DESC);

-- R13 "episodes nobody watched": the anti-join probe on episode_id.
-- Partial, because 93,056 of 200,401 rows have episode_id IS NULL.
CREATE INDEX viewing_activity_episode_idx
    ON viewing_activity (episode_id)
    WHERE episode_id IS NOT NULL;

-- R23 support console: newest-first ordering with OFFSET 150000, and
-- the date-window filters of R03 / R08 / R18 / R20.
CREATE INDEX viewing_activity_started_idx
    ON viewing_activity (started_at DESC);

-- ---------------------------------------------------------------------
-- titles (3,000 rows)
-- ---------------------------------------------------------------------

-- R04 genre row for a kids profile: rating filter, newest additions first.
CREATE INDEX titles_maturity_added_idx
    ON titles (maturity_rating, added_on DESC);

-- R22 "last chance to watch": licensed titles leaving in July 2026.
CREATE INDEX titles_leaving_idx
    ON titles (leaving_on)
    WHERE leaving_on IS NOT NULL;

-- R05 search: names containing "love".
CREATE INDEX titles_name_trgm_idx
    ON titles USING gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------
-- title_genres (5,963 rows) — PK is (title_id, genre_id), so a lookup
-- by genre_id has no supporting index.
-- ---------------------------------------------------------------------
CREATE INDEX title_genres_genre_idx
    ON title_genres (genre_id, title_id);

-- ---------------------------------------------------------------------
-- accounts (25,000 rows)
-- ---------------------------------------------------------------------

-- R10 sign-in: the query compares lower(email), so the UNIQUE index on
-- the raw column cannot be used — this is a functional index.
CREATE INDEX accounts_lower_email_idx
    ON accounts (lower(email));

-- R21 dunning (ON_HOLD + past billing date), R11 / R15 status filters,
-- W04 monthly billing run, W05 dunning update.
CREATE INDEX accounts_status_next_billing_idx
    ON accounts (status, next_billing_date);

-- R12 retention: cancellations per month in 2026.
CREATE INDEX accounts_cancelled_idx
    ON accounts (cancelled_on)
    WHERE status = 'CANCELLED';

-- ---------------------------------------------------------------------
-- profiles (75,000 rows)
-- ---------------------------------------------------------------------

-- R24 "who's watching" for one account, ordered by creation time.
CREATE INDEX profiles_account_created_idx
    ON profiles (account_id, created_at);

-- R14 compliance: kids profiles only.
CREATE INDEX profiles_kids_idx
    ON profiles (maturity_limit)
    WHERE is_kids;

-- ---------------------------------------------------------------------
-- invoices (133,057 rows)
-- ---------------------------------------------------------------------

-- R11 failed June invoices, W05 dunning probe on (account, period, status).
CREATE INDEX invoices_status_period_idx
    ON invoices (status, billing_period_start)
    INCLUDE (account_id, amount_inr);

-- ---------------------------------------------------------------------
-- ratings (33,900 rows) — PK is (profile_id, title_id); R17 joins the
-- other way round, by title_id.
-- ---------------------------------------------------------------------
CREATE INDEX ratings_title_idx
    ON ratings (title_id);

-- ---------------------------------------------------------------------
-- my_list (59,992 rows) — R20 counts additions in a June 2026 window.
-- ---------------------------------------------------------------------
CREATE INDEX my_list_added_title_idx
    ON my_list (added_at, title_id);

COMMIT;
