CREATE SCHEMA netflix;
SET search_path TO netflix;

CREATE TABLE plans (
    plan_id SMALLINT PRIMARY KEY,
    plan_name VARCHAR(20) NOT NULL UNIQUE,
    monthly_price_inr NUMERIC(7,2) NOT NULL CHECK (monthly_price_inr > 0),
    max_streams SMALLINT NOT NULL CHECK (max_streams BETWEEN 1 AND 4),
    max_resolution VARCHAR(5) NOT NULL CHECK (max_resolution IN ('480p','720p','1080p','4K')),
    has_ads BOOLEAN NOT NULL
);

CREATE TABLE accounts (
    account_id INTEGER PRIMARY KEY,
    email VARCHAR(254) NOT NULL UNIQUE,
    phone VARCHAR(20) UNIQUE,
    country_code CHAR(2) NOT NULL CHECK (country_code IN ('IN','AE','SG')),
    plan_id SMALLINT NOT NULL REFERENCES plans(plan_id) ON DELETE RESTRICT,
    signup_date DATE NOT NULL,
    status VARCHAR(10) NOT NULL CHECK (status IN ('ACTIVE','CANCELLED','ON_HOLD')),
    cancelled_on DATE,
    next_billing_date DATE,
    CHECK ((status = 'CANCELLED') = (cancelled_on IS NOT NULL)),
    CHECK ((status = 'CANCELLED') = (next_billing_date IS NULL)),
    CHECK (cancelled_on IS NULL OR cancelled_on >= signup_date)
);

CREATE TABLE profiles (
    profile_id INTEGER PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
    profile_name VARCHAR(50) NOT NULL,
    is_kids BOOLEAN NOT NULL,
    maturity_limit VARCHAR(5) NOT NULL CHECK (maturity_limit IN ('U','UA7','UA13','UA16','A')),
    language VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CHECK (NOT is_kids OR maturity_limit IN ('U','UA7'))
);

CREATE TABLE genres (
    genre_id SMALLINT PRIMARY KEY,
    genre_name VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE titles (
    title_id INTEGER PRIMARY KEY,
    title_type VARCHAR(10) NOT NULL CHECK (title_type IN ('MOVIE','SERIES')),
    name VARCHAR(200) NOT NULL,
    release_year SMALLINT NOT NULL CHECK (release_year BETWEEN 1888 AND 2100),
    maturity_rating VARCHAR(5) NOT NULL CHECK (maturity_rating IN ('U','UA7','UA13','UA16','A')),
    original_language VARCHAR(30) NOT NULL,
    runtime_min SMALLINT,
    is_netflix_original BOOLEAN NOT NULL,
    added_on DATE NOT NULL,
    leaving_on DATE,
    CHECK ((title_type = 'MOVIE') = (runtime_min IS NOT NULL)),
    CHECK (runtime_min IS NULL OR runtime_min BETWEEN 1 AND 1000),
    CHECK (leaving_on IS NULL OR leaving_on >= added_on),
    CHECK (NOT is_netflix_original OR leaving_on IS NULL)
);

CREATE TABLE title_genres (
    title_id INTEGER NOT NULL REFERENCES titles(title_id) ON DELETE CASCADE,
    genre_id SMALLINT NOT NULL REFERENCES genres(genre_id) ON DELETE RESTRICT,
    PRIMARY KEY (title_id, genre_id)
);

CREATE TABLE episodes (
    episode_id INTEGER PRIMARY KEY,
    title_id INTEGER NOT NULL REFERENCES titles(title_id) ON DELETE CASCADE,
    season_no SMALLINT NOT NULL CHECK (season_no BETWEEN 1 AND 100),
    episode_no SMALLINT NOT NULL CHECK (episode_no BETWEEN 1 AND 1000),
    episode_title VARCHAR(200) NOT NULL,
    runtime_min SMALLINT NOT NULL CHECK (runtime_min BETWEEN 1 AND 1000),
    release_date DATE NOT NULL,
    UNIQUE (title_id, season_no, episode_no)
);

CREATE TABLE viewing_activity (
    view_id BIGINT PRIMARY KEY,
    profile_id INTEGER NOT NULL REFERENCES profiles(profile_id) ON DELETE RESTRICT,
    title_id INTEGER NOT NULL REFERENCES titles(title_id) ON DELETE RESTRICT,
    episode_id INTEGER REFERENCES episodes(episode_id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ NOT NULL,
    duration_watched_sec INTEGER NOT NULL CHECK (duration_watched_sec > 0),
    device_type VARCHAR(10) NOT NULL CHECK (device_type IN ('TV','MOBILE','TABLET','LAPTOP')),
    completed BOOLEAN NOT NULL
);

CREATE TABLE ratings (
    profile_id INTEGER NOT NULL REFERENCES profiles(profile_id) ON DELETE CASCADE,
    title_id INTEGER NOT NULL REFERENCES titles(title_id) ON DELETE CASCADE,
    rating VARCHAR(12) NOT NULL CHECK (rating IN ('THUMBS_DOWN','THUMBS_UP','LOVE')),
    rated_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (profile_id, title_id)
);

CREATE TABLE my_list (
    profile_id INTEGER NOT NULL REFERENCES profiles(profile_id) ON DELETE CASCADE,
    title_id INTEGER NOT NULL REFERENCES titles(title_id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (profile_id, title_id)
);

CREATE TABLE invoices (
    invoice_id BIGINT PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(account_id) ON DELETE RESTRICT,
    billing_period_start DATE NOT NULL CHECK (EXTRACT(DAY FROM billing_period_start) = 1),
    amount_inr NUMERIC(7,2) NOT NULL CHECK (amount_inr > 0),
    status VARCHAR(10) NOT NULL CHECK (status IN ('PAID','FAILED','REFUNDED')),
    paid_at TIMESTAMPTZ,
    UNIQUE (account_id, billing_period_start),
    CHECK ((status = 'FAILED') = (paid_at IS NULL))
);
