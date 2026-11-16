# Schema design

The design uses the eleven supplied CSV files as the source of truth. All relations are created in the `netflix` PostgreSQL schema. The DDL uses only primary keys, foreign keys, unique constraints, not-null requirements and checks; no workload-tuning indexes are added. PostgreSQL creates indexes for primary keys and unique constraints.

## Data dictionary

| Table | Columns and types | Keys, constraints and rationale |
|---|---|---|
| `plans` | `plan_id SMALLINT`, `plan_name VARCHAR(20)`, `monthly_price_inr NUMERIC(7,2)`, `max_streams SMALLINT`, `max_resolution VARCHAR(5)`, `has_ads BOOLEAN` | `plan_id` primary key; unique non-null plan name; positive price; streams from 1 to 4; supported resolution values; ad flag required. |
| `accounts` | `account_id INTEGER`, `email VARCHAR(254)`, `phone VARCHAR(20)`, `country_code CHAR(2)`, `plan_id SMALLINT`, `signup_date DATE`, `status VARCHAR(10)`, `cancelled_on DATE`, `next_billing_date DATE` | `account_id` primary key; unique non-null email; nullable unique phone; plan foreign key with delete restricted; status and country checks; cancellation date required only for cancelled accounts; next billing date absent only for cancelled accounts; cancellation cannot precede signup. Phone can be empty because some accounts have no number. |
| `profiles` | `profile_id INTEGER`, `account_id INTEGER`, `profile_name VARCHAR(50)`, `is_kids BOOLEAN`, `maturity_limit VARCHAR(5)`, `language VARCHAR(30)`, `created_at TIMESTAMPTZ` | `profile_id` primary key; account foreign key with cascade; required values; allowed maturity ratings; kids profiles limited to U or UA7. Profile name is not unique because names such as Guest are reused. The five-profile maximum is checked as a data integrity query, since a row-level check cannot enforce a limit across rows. |
| `genres` | `genre_id SMALLINT`, `genre_name VARCHAR(40)` | `genre_id` primary key; genre name unique and required. |
| `titles` | `title_id INTEGER`, `title_type VARCHAR(10)`, `name VARCHAR(200)`, `release_year SMALLINT`, `maturity_rating VARCHAR(5)`, `original_language VARCHAR(30)`, `runtime_min SMALLINT`, `is_netflix_original BOOLEAN`, `added_on DATE`, `leaving_on DATE` | `title_id` primary key; type and maturity checks; release year range; movies require runtime and series must omit it; runtime positive; leave date cannot precede add date; Originals cannot have a leave date. |
| `title_genres` | `title_id INTEGER`, `genre_id SMALLINT` | Composite primary key `(title_id, genre_id)`; title and genre foreign keys. Title deletion cascades; genre deletion is restricted while referenced. This resolves the many-to-many title/genre relationship. |
| `episodes` | `episode_id INTEGER`, `title_id INTEGER`, `season_no SMALLINT`, `episode_no SMALLINT`, `episode_title VARCHAR(200)`, `runtime_min SMALLINT`, `release_date DATE` | `episode_id` primary key; title foreign key with cascade; positive bounded season, episode and runtime; `(title_id, season_no, episode_no)` unique. |
| `viewing_activity` | `view_id BIGINT`, `profile_id INTEGER`, `title_id INTEGER`, `episode_id INTEGER`, `started_at TIMESTAMPTZ`, `duration_watched_sec INTEGER`, `device_type VARCHAR(10)`, `completed BOOLEAN` | `view_id` primary key; profile and title foreign keys restricted from deletion; optional episode foreign key set null if the episode is deleted; positive duration; supported device values. Episode ID is empty for movie views and can also be absent where the record is not tied to a specific episode. |
| `ratings` | `profile_id INTEGER`, `title_id INTEGER`, `rating VARCHAR(12)`, `rated_at TIMESTAMPTZ` | Composite primary key `(profile_id, title_id)`; profile/title foreign keys cascade; rating restricted to the three supplied values. |
| `my_list` | `profile_id INTEGER`, `title_id INTEGER`, `added_at TIMESTAMPTZ` | Composite primary key `(profile_id, title_id)`; profile/title foreign keys cascade. A profile can list a title once. |
| `invoices` | `invoice_id BIGINT`, `account_id INTEGER`, `billing_period_start DATE`, `amount_inr NUMERIC(7,2)`, `status VARCHAR(10)`, `paid_at TIMESTAMPTZ` | `invoice_id` primary key; account foreign key restricted from deletion; unique account/billing period; billing starts on day one; positive amount; supported statuses; failed invoices have no payment time, while paid and refunded invoices have one. |

Empty CSV fields become SQL `NULL`. This occurs for account phone (4,888 rows), `cancelled_on` (22,021), `next_billing_date` (2,979), movie/series `runtime_min` (1,000 series), licensed-title `leaving_on` (2,738), viewing `episode_id` (93,056), and failed-invoice `paid_at` (4,764). These nulls describe optional or inapplicable facts; required identifying and relationship fields remain non-null.

## Constraints and index policy

Checks constrain plan prices and streams, supported resolutions, country codes, account statuses and date relationships, maturity ratings and kids limits, title types and runtime rules, year/runtime ranges, original-title exit dates, episode numbering/runtime, viewing duration/devices, rating values, invoice status/payment consistency and month-start billing dates. These checks are declared in `sql/01_schema.sql`. Primary keys and unique constraints create the only indexes at this stage; no additional indexes are present so baseline timing reflects an untuned schema.

## Relationships and cardinalities

- One plan has many accounts; every account has one plan.
- One account has one to five profiles; every profile belongs to one account.
- Titles and genres have a many-to-many relationship through `title_genres`.
- A series title has many episodes; each episode belongs to one title.
- Profiles have many viewing records, ratings and My List entries; titles also have many of each.
- An account has many invoices; each invoice belongs to one account.

The ER image is `diagrams/er_diagram.svg`; editable Mermaid source is `diagrams/er_diagram.mmd`.

## Functional dependencies and normal form

Each relation is in 3NF and BCNF under the listed dependencies. Each determinant below is a candidate key, and each non-key attribute depends on that key, the whole key, and nothing but the key.

| Relation | Functional dependency |
|---|---|
| `plans` | `plan_id → plan_name, monthly_price_inr, max_streams, max_resolution, has_ads`; `plan_name → plan_id, monthly_price_inr, max_streams, max_resolution, has_ads` |
| `accounts` | `account_id → email, phone, country_code, plan_id, signup_date, status, cancelled_on, next_billing_date`; `email → account_id, ...`; non-null `phone → account_id, ...` |
| `profiles` | `profile_id → account_id, profile_name, is_kids, maturity_limit, language, created_at` |
| `genres` | `genre_id → genre_name`; `genre_name → genre_id` |
| `titles` | `title_id → title_type, name, release_year, maturity_rating, original_language, runtime_min, is_netflix_original, added_on, leaving_on` |
| `title_genres` | `(title_id, genre_id) →` no non-key attributes |
| `episodes` | `episode_id → title_id, season_no, episode_no, episode_title, runtime_min, release_date`; `(title_id, season_no, episode_no) → episode_id, episode_title, runtime_min, release_date` |
| `viewing_activity` | `view_id → profile_id, title_id, episode_id, started_at, duration_watched_sec, device_type, completed` |
| `ratings` | `(profile_id, title_id) → rating, rated_at` |
| `my_list` | `(profile_id, title_id) → added_at` |
| `invoices` | `invoice_id → account_id, billing_period_start, amount_inr, status, paid_at`; `(account_id, billing_period_start) → invoice_id, amount_inr, status, paid_at` |

`viewing_activity.completed` can be recomputed from watched duration and the title or episode runtime, but it is kept as a supplied event outcome and to support query semantics. `invoices.amount_inr` may match the current plan price, but it records the billed amount at that historical billing period, so later plan changes do not rewrite invoice history. `viewing_activity.title_id` is redundant when `episode_id` is present because the episode also references a title; it is retained because the supplied workload queries directly filter/join on `title_id`. A cross-row check or composite foreign key would be needed to guarantee that the episode and title IDs agree; the supplied schema includes the validation query below rather than adding a new composite key to the given data model.

## Load results and integrity checks

Seed CSV row counts are: plans 4, accounts 25,000, profiles 75,000, genres 15, titles 3,000, title_genres 5,963, episodes 20,000, viewing_activity 200,401, ratings 33,900, my_list 59,992 and invoices 133,057. The CSV files were inspected locally. PostgreSQL is unavailable in this environment, so these counts and checks are source-data inspection results; execute `sql/02_load_data.sql` in PostgreSQL to confirm the actual load.

| Integrity check | Violations found in seed data |
|---|---:|
| Viewing record episode belongs to the same title | 0 |
| Accounts with more than five profiles | 0 |
| Viewing starts before the title was added | 0 |
| Accounts referencing a missing plan | 0 |
| Profiles referencing a missing account | 0 |
| Episodes referencing a missing title | 0 |
| Kids profiles with maturity limit outside U/UA7 | 0 |
| Cancelled account/date mismatches | 0 |
| Invoice status/payment-time mismatches | 0 |

No source-data violations were found for these checks. Additional null patterns and representative allowed values were inspected from the CSV files before choosing the constraints.
