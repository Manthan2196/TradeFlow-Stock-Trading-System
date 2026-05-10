-- ============================================================================
-- TRADEFLOW v4 — COMPLETE SQL FILE
-- Order: Tables → Indexes → Views → Functions → Triggers
-- ============================================================================


-- ============================================================================
-- SECTION 1: TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
    user_id     SERIAL PRIMARY KEY,
    name        TEXT          NOT NULL,
    email       TEXT          NOT NULL UNIQUE,
    password    TEXT          NOT NULL,
    role        TEXT          NOT NULL DEFAULT 'USER'    CHECK (role IN ('USER','ADMIN','COMPANY')),
    kyc_status  TEXT          NOT NULL DEFAULT 'PENDING' CHECK (kyc_status IN ('PENDING','VERIFIED','REJECTED')),
    is_active   BOOLEAN       NOT NULL DEFAULT TRUE,
    last_login  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wallet (
    wallet_id    SERIAL PRIMARY KEY,
    user_id      INTEGER       NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    balance      NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    last_updated TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wallet_transactions (
    transaction_id   SERIAL PRIMARY KEY,
    wallet_id        INTEGER       NOT NULL REFERENCES wallet(wallet_id) ON DELETE CASCADE,
    amount           NUMERIC(18,2) NOT NULL,
    transaction_type TEXT          NOT NULL CHECK (transaction_type IN ('CREDIT','DEBIT')),
    description      TEXT,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stocks (
    stock_id     SERIAL PRIMARY KEY,
    symbol       TEXT        NOT NULL UNIQUE,
    company_name TEXT        NOT NULL,
    sector       TEXT        NOT NULL DEFAULT 'General',
    is_active    BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stock_price_history (
    price_id        SERIAL PRIMARY KEY,
    stock_id        INTEGER       NOT NULL REFERENCES stocks(stock_id) ON DELETE CASCADE,
    price           NUMERIC(18,2) NOT NULL CHECK (price > 0),
    price_timestamp TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
    order_id     SERIAL PRIMARY KEY,
    user_id      INTEGER       NOT NULL REFERENCES users(user_id)   ON DELETE CASCADE,
    stock_id     INTEGER       NOT NULL REFERENCES stocks(stock_id) ON DELETE CASCADE,
    order_type   TEXT          NOT NULL CHECK (order_type IN ('BUY','SELL')),
    order_price  NUMERIC(18,2) NOT NULL CHECK (order_price > 0),
    quantity     INTEGER       NOT NULL CHECK (quantity > 0),
    order_status TEXT          NOT NULL DEFAULT 'PENDING' CHECK (order_status IN ('PENDING','EXECUTED','CANCELLED')),
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS trades (
    trade_id          SERIAL PRIMARY KEY,
    order_id          INTEGER       NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    executed_price    NUMERIC(18,2) NOT NULL,
    executed_quantity INTEGER       NOT NULL,
    trade_time        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS portfolio (
    portfolio_id  SERIAL PRIMARY KEY,
    user_id       INTEGER       NOT NULL REFERENCES users(user_id)   ON DELETE CASCADE,
    stock_id      INTEGER       NOT NULL REFERENCES stocks(stock_id) ON DELETE CASCADE,
    total_quantity INTEGER      NOT NULL DEFAULT 0 CHECK (total_quantity >= 0),
    avg_buy_price NUMERIC(18,4) NOT NULL DEFAULT 0,
    UNIQUE (user_id, stock_id)
);

CREATE TABLE IF NOT EXISTS portfolio_transactions (
    pt_id           SERIAL PRIMARY KEY,
    portfolio_id    INTEGER     NOT NULL REFERENCES portfolio(portfolio_id) ON DELETE CASCADE,
    order_id        INTEGER     REFERENCES orders(order_id),
    trade_id        INTEGER     REFERENCES trades(trade_id),
    quantity_change INTEGER     NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS company_profiles (
    company_id         SERIAL PRIMARY KEY,
    user_id            INTEGER NOT NULL UNIQUE REFERENCES users(user_id)   ON DELETE CASCADE,
    stock_id           INTEGER NOT NULL UNIQUE REFERENCES stocks(stock_id) ON DELETE CASCADE,
    company_name       TEXT    NOT NULL,
    cin_number         TEXT,
    registered_address TEXT,
    contact_email      TEXT,
    website            TEXT,
    verified           BOOLEAN NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS company_announcements (
    announcement_id   SERIAL PRIMARY KEY,
    company_id        INTEGER     NOT NULL REFERENCES company_profiles(company_id) ON DELETE CASCADE,
    title             TEXT        NOT NULL,
    content           TEXT        NOT NULL,
    announcement_type TEXT        NOT NULL DEFAULT 'OTHER'
                      CHECK (announcement_type IN ('DIVIDEND','SPLIT','BONUS','RESULTS','AGM','OTHER')),
    effective_date    DATE,
    is_published      BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS company_financials (
    financial_id SERIAL PRIMARY KEY,
    company_id   INTEGER       NOT NULL REFERENCES company_profiles(company_id) ON DELETE CASCADE,
    quarter      TEXT          NOT NULL CHECK (quarter IN ('Q1','Q2','Q3','Q4')),
    fiscal_year  INTEGER       NOT NULL,
    revenue      NUMERIC(18,2) NOT NULL,
    net_profit   NUMERIC(18,2) NOT NULL,
    eps          NUMERIC(10,4) NOT NULL,
    published_at TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE (company_id, quarter, fiscal_year)
);

CREATE TABLE IF NOT EXISTS audit_logs (
    audit_id    SERIAL PRIMARY KEY,
    user_id     INTEGER     REFERENCES users(user_id) ON DELETE SET NULL,
    action      TEXT        NOT NULL,
    resource    TEXT        NOT NULL,
    resource_id INTEGER,
    details     TEXT,
    ip_address  TEXT,
    status      TEXT        NOT NULL DEFAULT 'SUCCESS' CHECK (status IN ('SUCCESS','FAILED','WARNING')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS database_transactions (
    txn_id     SERIAL PRIMARY KEY,
    user_id    INTEGER     REFERENCES users(user_id) ON DELETE SET NULL,
    txn_state  TEXT        NOT NULL DEFAULT 'ACTIVE' CHECK (txn_state IN ('ACTIVE','COMMITTED','ROLLED_BACK')),
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS system_logs (
    log_id    SERIAL PRIMARY KEY,
    txn_id    INTEGER     REFERENCES database_transactions(txn_id) ON DELETE SET NULL,
    operation TEXT        NOT NULL,
    status    TEXT        NOT NULL DEFAULT 'SUCCESS',
    details   TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS locks (
    lock_id       SERIAL PRIMARY KEY,
    txn_id        INTEGER REFERENCES database_transactions(txn_id) ON DELETE CASCADE,
    resource_type TEXT    NOT NULL,
    resource_id   INTEGER,
    lock_mode     TEXT    NOT NULL DEFAULT 'EXCLUSIVE' CHECK (lock_mode IN ('SHARED','EXCLUSIVE')),
    acquired_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS system_config (
    config_id    SERIAL PRIMARY KEY,
    config_key   TEXT NOT NULL UNIQUE,
    config_value TEXT NOT NULL,
    description  TEXT,
    updated_by   INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================================
-- SECTION 2: INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_users_email        ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role         ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active    ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_kyc_status   ON users(kyc_status);
CREATE INDEX IF NOT EXISTS idx_users_created_at   ON users(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_wallet_user_id     ON wallet(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_txn_wallet  ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_txn_date    ON wallet_transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_stocks_symbol      ON stocks(symbol);
CREATE INDEX IF NOT EXISTS idx_stocks_sector      ON stocks(sector);
CREATE INDEX IF NOT EXISTS idx_stocks_active      ON stocks(is_active);
CREATE INDEX IF NOT EXISTS idx_price_stock_ts     ON stock_price_history(stock_id, price_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_price_ts           ON stock_price_history(price_timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_orders_user_id     ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_stock_id    ON orders(stock_id);
CREATE INDEX IF NOT EXISTS idx_orders_status      ON orders(order_status);
CREATE INDEX IF NOT EXISTS idx_orders_type        ON orders(order_type);
CREATE INDEX IF NOT EXISTS idx_orders_created_at  ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_user_stock  ON orders(user_id, stock_id);

CREATE INDEX IF NOT EXISTS idx_trades_order_id    ON trades(order_id);
CREATE INDEX IF NOT EXISTS idx_trades_trade_time  ON trades(trade_time DESC);

CREATE INDEX IF NOT EXISTS idx_portfolio_user     ON portfolio(user_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_stock    ON portfolio(stock_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_qty      ON portfolio(total_quantity) WHERE total_quantity > 0;

CREATE INDEX IF NOT EXISTS idx_company_user       ON company_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_company_stock      ON company_profiles(stock_id);
CREATE INDEX IF NOT EXISTS idx_ann_company        ON company_announcements(company_id);
CREATE INDEX IF NOT EXISTS idx_ann_published      ON company_announcements(is_published, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fin_company        ON company_financials(company_id, fiscal_year DESC, quarter);

CREATE INDEX IF NOT EXISTS idx_audit_user         ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_action       ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_resource     ON audit_logs(resource);
CREATE INDEX IF NOT EXISTS idx_audit_created      ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_syslog_txn         ON system_logs(txn_id);
CREATE INDEX IF NOT EXISTS idx_syslog_ts          ON system_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_dbtxn_user         ON database_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_dbtxn_state        ON database_transactions(txn_state);


-- ============================================================================
-- SECTION 3: VIEWS
-- ============================================================================

-- Shared: latest price per stock (used by all roles)
CREATE OR REPLACE VIEW v_stock_latest_price AS
SELECT DISTINCT ON (sph.stock_id)
    s.stock_id,
    s.symbol,
    s.company_name,
    s.sector,
    sph.price           AS latest_price,
    sph.price_timestamp AS last_updated
FROM   stock_price_history sph
JOIN   stocks s ON s.stock_id = sph.stock_id
ORDER  BY sph.stock_id, sph.price_timestamp DESC;

-- User: full portfolio with P&L per holding
CREATE OR REPLACE VIEW v_portfolio_detail AS
SELECT
    p.portfolio_id,
    p.user_id,
    p.stock_id,
    s.symbol,
    s.company_name,
    s.sector,
    p.total_quantity,
    p.avg_buy_price,
    COALESCE(lp.latest_price, p.avg_buy_price)                              AS current_price,
    ROUND(p.avg_buy_price * p.total_quantity, 2)                            AS invested_value,
    ROUND(COALESCE(lp.latest_price, p.avg_buy_price) * p.total_quantity, 2) AS current_value,
    ROUND((COALESCE(lp.latest_price, p.avg_buy_price) - p.avg_buy_price)
           * p.total_quantity, 2)                                            AS unrealized_pnl,
    ROUND(((COALESCE(lp.latest_price, p.avg_buy_price) - p.avg_buy_price)
           / NULLIF(p.avg_buy_price, 0)) * 100, 2)                          AS pnl_pct
FROM   portfolio p
JOIN   stocks s ON s.stock_id = p.stock_id
LEFT   JOIN v_stock_latest_price lp ON lp.stock_id = p.stock_id
WHERE  p.total_quantity > 0;

-- User: order history with stock names and totals
CREATE OR REPLACE VIEW v_orders AS
SELECT
    o.order_id,
    o.user_id,
    u.name                                 AS user_name,
    u.email                                AS user_email,
    o.stock_id,
    s.symbol,
    s.company_name,
    o.order_type,
    o.order_price,
    o.quantity,
    ROUND(o.order_price * o.quantity, 2)   AS total_value,
    o.order_status,
    o.created_at
FROM   orders o
JOIN   users  u ON u.user_id  = o.user_id
JOIN   stocks s ON s.stock_id = o.stock_id;

-- User: trade execution history
CREATE OR REPLACE VIEW v_trades AS
SELECT
    t.trade_id,
    t.order_id,
    o.user_id,
    u.name                                              AS user_name,
    o.stock_id,
    s.symbol,
    s.company_name,
    o.order_type                                        AS trade_type,
    t.executed_quantity                                 AS quantity,
    t.executed_price                                    AS price,
    ROUND(t.executed_price * t.executed_quantity, 2)    AS total_value,
    t.trade_time                                        AS executed_at
FROM   trades t
JOIN   orders  o ON o.order_id  = t.order_id
JOIN   users   u ON u.user_id   = o.user_id
JOIN   stocks  s ON s.stock_id  = o.stock_id;

-- User: dashboard summary (wallet + portfolio + orders in one row)
CREATE OR REPLACE VIEW v_dashboard AS
SELECT
    u.user_id,
    u.name,
    u.email,
    u.role,
    COALESCE(w.balance, 0)                AS wallet_balance,
    COALESCE(ptf.total_invested, 0)       AS total_invested,
    COALESCE(ptf.current_value, 0)        AS portfolio_value,
    COALESCE(ord.total_orders, 0)         AS total_orders,
    COALESCE(ord.executed_orders, 0)      AS executed_orders
FROM   users u
LEFT   JOIN wallet w ON w.user_id = u.user_id
LEFT   JOIN (
    SELECT user_id,
           SUM(ROUND(avg_buy_price * total_quantity, 2))                             AS total_invested,
           SUM(ROUND(COALESCE(lp.latest_price, p.avg_buy_price) * p.total_quantity, 2)) AS current_value
    FROM   portfolio p
    LEFT   JOIN v_stock_latest_price lp ON lp.stock_id = p.stock_id
    GROUP  BY user_id
) ptf ON ptf.user_id = u.user_id
LEFT   JOIN (
    SELECT user_id,
           COUNT(*)                                                                   AS total_orders,
           SUM(CASE WHEN upper(order_status) = 'EXECUTED' THEN 1 ELSE 0 END)        AS executed_orders
    FROM   orders
    GROUP  BY user_id
) ord ON ord.user_id = u.user_id;

-- Company: buy/sell sentiment for a stock
CREATE OR REPLACE VIEW v_company_stock_sentiment AS
SELECT
    o.stock_id,
    s.symbol,
    s.company_name,
    COUNT(*)                                                                             AS total_orders,
    SUM(CASE WHEN o.order_type = 'BUY'  THEN 1 ELSE 0 END)                            AS buy_count,
    SUM(CASE WHEN o.order_type = 'SELL' THEN 1 ELSE 0 END)                            AS sell_count,
    SUM(CASE WHEN o.order_type = 'BUY'  THEN o.quantity ELSE 0 END)                   AS buy_volume,
    SUM(CASE WHEN o.order_type = 'SELL' THEN o.quantity ELSE 0 END)                   AS sell_volume,
    ROUND(100.0 * SUM(CASE WHEN o.order_type = 'BUY'  THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 1)                                                    AS buy_pct,
    ROUND(100.0 * SUM(CASE WHEN o.order_type = 'SELL' THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 1)                                                    AS sell_pct,
    (SELECT COUNT(DISTINCT user_id) FROM portfolio
     WHERE  stock_id = o.stock_id AND total_quantity > 0)                              AS total_holders
FROM   orders o
JOIN   stocks s ON s.stock_id = o.stock_id
WHERE  upper(o.order_status) = 'EXECUTED'
GROUP  BY o.stock_id, s.symbol, s.company_name;

-- Company: investor breakdown per stock
CREATE OR REPLACE VIEW v_company_investor_summary AS
SELECT
    p.stock_id,
    s.symbol,
    COUNT(DISTINCT p.user_id)                        AS total_investors,
    SUM(p.total_quantity)                            AS total_shares_held,
    ROUND(AVG(p.avg_buy_price), 2)                   AS avg_investor_price,
    MIN(p.avg_buy_price)                             AS min_buy_price,
    MAX(p.avg_buy_price)                             AS max_buy_price,
    SUM(ROUND(p.avg_buy_price * p.total_quantity, 2)) AS total_invested_value
FROM   portfolio p
JOIN   stocks s ON s.stock_id = p.stock_id
WHERE  p.total_quantity > 0
GROUP  BY p.stock_id, s.symbol;

-- Company: daily trading activity per stock
CREATE OR REPLACE VIEW v_company_daily_activity AS
SELECT
    o.stock_id,
    s.symbol,
    DATE(t.trade_time)                                    AS trade_date,
    COUNT(t.trade_id)                                     AS trade_count,
    SUM(t.executed_quantity)                              AS volume,
    ROUND(SUM(t.executed_price * t.executed_quantity), 2) AS turnover,
    MIN(t.executed_price)                                 AS day_low,
    MAX(t.executed_price)                                 AS day_high
FROM   trades t
JOIN   orders  o ON o.order_id  = t.order_id
JOIN   stocks  s ON s.stock_id  = o.stock_id
GROUP  BY o.stock_id, s.symbol, DATE(t.trade_time);

-- Admin: every user with wallet + order + portfolio summary
CREATE OR REPLACE VIEW view_admin_user_overview AS
SELECT
    u.user_id,
    u.name,
    u.email,
    u.role,
    u.is_active,
    u.created_at,
    COALESCE(w.balance, 0)                                                        AS wallet_balance,
    COALESCE(o.total_orders, 0)                                                   AS total_orders,
    COALESCE(o.executed_orders, 0)                                                AS executed_orders,
    COALESCE(o.pending_orders, 0)                                                 AS pending_orders,
    COALESCE(p.holdings_count, 0)                                                 AS holdings_count
FROM   users u
LEFT   JOIN wallet w ON w.user_id = u.user_id
LEFT   JOIN (
    SELECT user_id,
           COUNT(*)                                                                AS total_orders,
           SUM(CASE WHEN upper(order_status) = 'EXECUTED' THEN 1 ELSE 0 END)     AS executed_orders,
           SUM(CASE WHEN upper(order_status) = 'PENDING'  THEN 1 ELSE 0 END)     AS pending_orders
    FROM   orders
    GROUP  BY user_id
) o ON o.user_id = u.user_id
LEFT   JOIN (
    SELECT user_id,
           COUNT(DISTINCT stock_id) AS holdings_count
    FROM   portfolio
    WHERE  total_quantity > 0
    GROUP  BY user_id
) p ON p.user_id = u.user_id;

-- Admin: single-row platform-wide stats
CREATE OR REPLACE VIEW view_admin_platform_stats AS
SELECT
    (SELECT COUNT(*)  FROM users)                                                 AS total_users,
    (SELECT COUNT(*)  FROM users   WHERE is_active = TRUE)                        AS active_users,
    (SELECT COUNT(*)  FROM orders)                                                AS total_orders,
    (SELECT COUNT(*)  FROM orders  WHERE upper(order_status) = 'EXECUTED')        AS executed_orders,
    (SELECT COUNT(*)  FROM orders  WHERE upper(order_status) = 'PENDING')         AS pending_orders,
    (SELECT COUNT(*)  FROM trades)                                                AS total_trades,
    (SELECT COALESCE(SUM(executed_price * executed_quantity), 0) FROM trades)     AS total_volume,
    (SELECT COALESCE(SUM(balance), 0) FROM wallet)                                AS total_wallet_balance,
    (SELECT COUNT(*)  FROM stocks  WHERE is_active = TRUE)                        AS active_stocks,
    (SELECT COUNT(*)  FROM portfolio WHERE total_quantity > 0)                    AS active_holdings;

-- Admin: every stock with latest price and trading activity
CREATE OR REPLACE VIEW view_admin_stock_overview AS
SELECT
    s.stock_id,
    s.symbol,
    s.company_name,
    s.sector,
    s.is_active,
    COALESCE(lp.latest_price, 0)                                                  AS latest_price,
    COALESCE(t.total_trades, 0)                                                   AS total_trades,
    COALESCE(t.total_volume, 0)                                                   AS total_volume,
    COALESCE(t.total_value, 0)                                                    AS total_value,
    COALESCE(h.total_holders, 0)                                                  AS total_holders
FROM   stocks s
LEFT   JOIN (
    SELECT DISTINCT ON (stock_id)
        stock_id,
        price AS latest_price
    FROM   stock_price_history
    ORDER  BY stock_id, price_timestamp DESC
) lp ON lp.stock_id = s.stock_id
LEFT   JOIN (
    SELECT o.stock_id,
           COUNT(t.trade_id)                                                      AS total_trades,
           COALESCE(SUM(t.executed_quantity), 0)                                  AS total_volume,
           COALESCE(ROUND(SUM(t.executed_price * t.executed_quantity), 2), 0)     AS total_value
    FROM   trades t
    JOIN   orders o ON o.order_id = t.order_id
    GROUP  BY o.stock_id
) t ON t.stock_id = s.stock_id
LEFT   JOIN (
    SELECT stock_id,
           COUNT(DISTINCT user_id) AS total_holders
    FROM   portfolio
    WHERE  total_quantity > 0
    GROUP  BY stock_id
) h ON h.stock_id = s.stock_id;


-- ============================================================================
-- SECTION 4: FUNCTIONS
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- USER FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────────────

-- Returns full portfolio with P&L for a specific user
CREATE OR REPLACE FUNCTION fn_get_user_portfolio(p_user_id INTEGER)
RETURNS TABLE (
    stock_id       INTEGER,
    symbol         TEXT,
    company_name   TEXT,
    sector         TEXT,
    total_quantity INTEGER,
    avg_buy_price  NUMERIC,
    current_price  NUMERIC,
    invested_value NUMERIC,
    current_value  NUMERIC,
    unrealized_pnl NUMERIC,
    pnl_pct        NUMERIC
) LANGUAGE SQL STABLE AS $$
    SELECT
        p.stock_id, s.symbol, s.company_name, s.sector,
        p.total_quantity, p.avg_buy_price,
        COALESCE(lp.latest_price, p.avg_buy_price),
        ROUND(p.avg_buy_price * p.total_quantity, 2),
        ROUND(COALESCE(lp.latest_price, p.avg_buy_price) * p.total_quantity, 2),
        ROUND((COALESCE(lp.latest_price, p.avg_buy_price) - p.avg_buy_price) * p.total_quantity, 2),
        ROUND(((COALESCE(lp.latest_price, p.avg_buy_price) - p.avg_buy_price)
               / NULLIF(p.avg_buy_price, 0)) * 100, 2)
    FROM   portfolio p
    JOIN   stocks s ON s.stock_id = p.stock_id
    LEFT   JOIN v_stock_latest_price lp ON lp.stock_id = p.stock_id
    WHERE  p.user_id = p_user_id AND p.total_quantity > 0
    ORDER  BY s.symbol;
$$;

-- Returns % price change for a stock over N days
CREATE OR REPLACE FUNCTION fn_stock_price_change(p_stock_id INTEGER, p_days INTEGER DEFAULT 1)
RETURNS NUMERIC LANGUAGE SQL STABLE AS $$
    WITH
    current_p AS (
        SELECT price FROM stock_price_history
        WHERE  stock_id = p_stock_id
        ORDER  BY price_timestamp DESC LIMIT 1
    ),
    old_p AS (
        SELECT price FROM stock_price_history
        WHERE  stock_id = p_stock_id
          AND  price_timestamp <= NOW() - (p_days || ' days')::INTERVAL
        ORDER  BY price_timestamp DESC LIMIT 1
    )
    SELECT ROUND(((c.price - o.price) / NULLIF(o.price, 0)) * 100, 2)
    FROM   current_p c, old_p o;
$$;

-- Returns total unrealized P&L for a specific user
CREATE OR REPLACE FUNCTION fn_user_total_pnl(p_user_id INTEGER)
RETURNS NUMERIC LANGUAGE SQL STABLE AS $$
    SELECT COALESCE(
        SUM(ROUND((COALESCE(lp.latest_price, p.avg_buy_price) - p.avg_buy_price)
                   * p.total_quantity, 2)),
        0
    )
    FROM   portfolio p
    LEFT   JOIN v_stock_latest_price lp ON lp.stock_id = p.stock_id
    WHERE  p.user_id = p_user_id AND p.total_quantity > 0;
$$;

-- Returns top N stocks by % price gain
CREATE OR REPLACE FUNCTION fn_top_gainers(p_limit INTEGER DEFAULT 5)
RETURNS TABLE (
    stock_id      INTEGER,
    symbol        TEXT,
    company_name  TEXT,
    current_price NUMERIC,
    prev_price    NUMERIC,
    change_pct    NUMERIC
) LANGUAGE SQL STABLE AS $$
    SELECT
        s.stock_id, s.symbol, s.company_name,
        lp.latest_price::NUMERIC,
        ph.prev_price::NUMERIC,
        ROUND(((lp.latest_price - ph.prev_price) / NULLIF(ph.prev_price, 0)) * 100, 2)
    FROM   stocks s
    JOIN   v_stock_latest_price lp ON lp.stock_id = s.stock_id
    JOIN   LATERAL (
        SELECT price AS prev_price FROM stock_price_history
        WHERE  stock_id = s.stock_id
          AND  price_timestamp < NOW() - INTERVAL '1 day'
        ORDER  BY price_timestamp DESC LIMIT 1
    ) ph ON TRUE
    WHERE  s.is_active = TRUE
    ORDER  BY change_pct DESC NULLS LAST
    LIMIT  p_limit;
$$;

-- Records the last login time for a user (called on every login)
CREATE OR REPLACE FUNCTION RecordUserLogin(p_user_id INTEGER)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE users
       SET last_login = NOW()
     WHERE user_id = p_user_id;
END;
$$;

-- Deposits money into a user's wallet and logs the transaction
CREATE OR REPLACE FUNCTION fn_deposit_wallet(p_user_id INTEGER, p_amount NUMERIC)
RETURNS NUMERIC LANGUAGE plpgsql AS $$
DECLARE
    v_wallet_id  INTEGER;
    v_new_balance NUMERIC;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Deposit amount must be positive.';
    END IF;

    SELECT wallet_id INTO v_wallet_id
    FROM   wallet WHERE user_id = p_user_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found for user_id = %', p_user_id;
    END IF;

    UPDATE wallet
       SET balance = balance + p_amount
     WHERE wallet_id = v_wallet_id
    RETURNING balance INTO v_new_balance;

    INSERT INTO wallet_transactions (wallet_id, amount, transaction_type, description, created_at)
    VALUES (v_wallet_id, p_amount, 'CREDIT', 'Deposit via fn_deposit_wallet', NOW());

    RETURN v_new_balance;
END;
$$;

-- Withdraws money from a user's wallet (checks for sufficient balance)
CREATE OR REPLACE FUNCTION fn_withdraw_wallet(p_user_id INTEGER, p_amount NUMERIC)
RETURNS NUMERIC LANGUAGE plpgsql AS $$
DECLARE
    v_wallet_id   INTEGER;
    v_balance     NUMERIC;
    v_new_balance NUMERIC;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Withdrawal amount must be positive.';
    END IF;

    SELECT wallet_id, balance INTO v_wallet_id, v_balance
    FROM   wallet WHERE user_id = p_user_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found for user_id = %', p_user_id;
    END IF;

    IF v_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance. Available: %, Requested: %', v_balance, p_amount;
    END IF;

    UPDATE wallet
       SET balance = balance - p_amount
     WHERE wallet_id = v_wallet_id
    RETURNING balance INTO v_new_balance;

    INSERT INTO wallet_transactions (wallet_id, amount, transaction_type, description, created_at)
    VALUES (v_wallet_id, p_amount, 'DEBIT', 'Withdrawal via fn_withdraw_wallet', NOW());

    RETURN v_new_balance;
END;
$$;

-- Cancels a PENDING order — only if it belongs to the user
CREATE OR REPLACE FUNCTION fn_cancel_order(p_order_id INTEGER, p_user_id INTEGER)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    v_status TEXT;
BEGIN
    SELECT order_status INTO v_status
    FROM   orders
    WHERE  order_id = p_order_id AND user_id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not found or does not belong to this user.';
    END IF;

    IF upper(v_status) != 'PENDING' THEN
        RAISE EXCEPTION 'Only PENDING orders can be cancelled. Current status: %', v_status;
    END IF;

    UPDATE orders
       SET order_status = 'CANCELLED'
     WHERE order_id = p_order_id;

    RETURN 'Order ' || p_order_id::TEXT || ' cancelled successfully.';
END;
$$;

-- Returns wallet balance and recent transactions for a user
CREATE OR REPLACE FUNCTION fn_get_wallet_summary(p_user_id INTEGER)
RETURNS TABLE (
    wallet_id        INTEGER,
    balance          NUMERIC,
    last_updated     TIMESTAMPTZ,
    total_credits    NUMERIC,
    total_debits     NUMERIC,
    transaction_count BIGINT
) LANGUAGE SQL STABLE AS $$
    SELECT
        w.wallet_id,
        w.balance,
        w.last_updated,
        COALESCE(SUM(CASE WHEN wt.transaction_type = 'CREDIT' THEN wt.amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN wt.transaction_type = 'DEBIT'  THEN wt.amount ELSE 0 END), 0),
        COUNT(wt.transaction_id)
    FROM   wallet w
    LEFT   JOIN wallet_transactions wt ON wt.wallet_id = w.wallet_id
    WHERE  w.user_id = p_user_id
    GROUP  BY w.wallet_id, w.balance, w.last_updated;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- COMPANY FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────────────

-- Returns trading stats for a company's stock
CREATE OR REPLACE FUNCTION fn_company_stats(p_stock_id INTEGER)
RETURNS TABLE (
    total_orders   BIGINT,
    total_volume   BIGINT,
    total_value    NUMERIC,
    unique_holders BIGINT,
    buy_pressure   NUMERIC,
    sell_pressure  NUMERIC
) LANGUAGE SQL STABLE AS $$
    SELECT
        COUNT(DISTINCT o.order_id),
        COALESCE(SUM(t.executed_quantity), 0)::BIGINT,
        COALESCE(ROUND(SUM(t.executed_price * t.executed_quantity), 2), 0),
        COUNT(DISTINCT p.user_id),
        ROUND(100.0 * SUM(CASE WHEN o.order_type = 'BUY'  THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*), 0), 1),
        ROUND(100.0 * SUM(CASE WHEN o.order_type = 'SELL' THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*), 0), 1)
    FROM   orders o
    LEFT   JOIN trades t    ON t.order_id  = o.order_id
    LEFT   JOIN portfolio p ON p.stock_id  = o.stock_id AND p.total_quantity > 0
    WHERE  o.stock_id = p_stock_id AND upper(o.order_status) = 'EXECUTED';
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- ADMIN FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────────────

-- Returns top N stocks by % price gain (admin market insights)
-- fn_top_gainers is already defined above under shared functions

-- Returns platform-wide stats as a single record
CREATE OR REPLACE FUNCTION fn_admin_platform_stats()
RETURNS TABLE (
    total_users         BIGINT,
    active_users        BIGINT,
    total_orders        BIGINT,
    executed_orders     BIGINT,
    pending_orders      BIGINT,
    total_trades        BIGINT,
    total_volume        NUMERIC,
    total_wallet_balance NUMERIC,
    active_stocks       BIGINT,
    active_holdings     BIGINT
) LANGUAGE SQL STABLE AS $$
    SELECT
        (SELECT COUNT(*) FROM users),
        (SELECT COUNT(*) FROM users   WHERE is_active = TRUE),
        (SELECT COUNT(*) FROM orders),
        (SELECT COUNT(*) FROM orders  WHERE upper(order_status) = 'EXECUTED'),
        (SELECT COUNT(*) FROM orders  WHERE upper(order_status) = 'PENDING'),
        (SELECT COUNT(*) FROM trades),
        (SELECT COALESCE(SUM(executed_price * executed_quantity), 0) FROM trades),
        (SELECT COALESCE(SUM(balance), 0) FROM wallet),
        (SELECT COUNT(*) FROM stocks  WHERE is_active = TRUE),
        (SELECT COUNT(*) FROM portfolio WHERE total_quantity > 0);
$$;

-- Adjusts a user's wallet balance by a given amount (admin only)
-- Positive amount = add money, negative amount = deduct money
CREATE OR REPLACE FUNCTION fn_admin_adjust_wallet(p_user_id INTEGER, p_amount NUMERIC, p_reason TEXT DEFAULT 'Admin adjustment')
RETURNS NUMERIC LANGUAGE plpgsql AS $$
DECLARE
    v_wallet_id   INTEGER;
    v_new_balance NUMERIC;
    v_type        TEXT;
BEGIN
    SELECT wallet_id INTO v_wallet_id
    FROM   wallet WHERE user_id = p_user_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found for user_id = %', p_user_id;
    END IF;

    IF (SELECT balance + p_amount FROM wallet WHERE wallet_id = v_wallet_id) < 0 THEN
        RAISE EXCEPTION 'Adjustment would result in negative balance.';
    END IF;

    v_type := CASE WHEN p_amount >= 0 THEN 'CREDIT' ELSE 'DEBIT' END;

    UPDATE wallet
       SET balance = balance + p_amount
     WHERE wallet_id = v_wallet_id
    RETURNING balance INTO v_new_balance;

    INSERT INTO wallet_transactions (wallet_id, amount, transaction_type, description, created_at)
    VALUES (v_wallet_id, ABS(p_amount), v_type, p_reason, NOW());

    RETURN v_new_balance;
END;
$$;

-- Deactivates a user account (admin soft-delete)
CREATE OR REPLACE FUNCTION fn_admin_deactivate_user(p_user_id INTEGER)
RETURNS TEXT LANGUAGE plpgsql AS $$
BEGIN
    UPDATE users SET is_active = FALSE WHERE user_id = p_user_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', p_user_id;
    END IF;
    RETURN 'User ' || p_user_id::TEXT || ' deactivated.';
END;
$$;

-- Activates a user account (admin re-enable)
CREATE OR REPLACE FUNCTION fn_admin_activate_user(p_user_id INTEGER)
RETURNS TEXT LANGUAGE plpgsql AS $$
BEGIN
    UPDATE users SET is_active = TRUE WHERE user_id = p_user_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', p_user_id;
    END IF;
    RETURN 'User ' || p_user_id::TEXT || ' activated.';
END;
$$;

-- Returns audit log entries filtered by action type and date range
CREATE OR REPLACE FUNCTION fn_admin_get_audit_log(
    p_action    TEXT    DEFAULT NULL,
    p_days      INTEGER DEFAULT 7
)
RETURNS TABLE (
    audit_id    INTEGER,
    user_id     INTEGER,
    action      TEXT,
    resource    TEXT,
    resource_id INTEGER,
    details     TEXT,
    status      TEXT,
    created_at  TIMESTAMPTZ
) LANGUAGE SQL STABLE AS $$
    SELECT audit_id, user_id, action, resource, resource_id,
           details, status, created_at
    FROM   audit_logs
    WHERE  (p_action IS NULL OR action = p_action)
      AND  created_at >= NOW() - (p_days || ' days')::INTERVAL
    ORDER  BY created_at DESC;
$$;

-- ============================================================================
-- SECTION 5: TRIGGERS
-- ============================================================================

-- Trigger 1: Log every order placed or cancelled into audit_logs
CREATE OR REPLACE FUNCTION trg_fn_audit_orders()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (user_id, action, resource, resource_id, details, status)
        VALUES (NEW.user_id, 'ORDER_PLACED', 'orders', NEW.order_id,
                'Type: ' || NEW.order_type || ', Stock: ' || NEW.stock_id::TEXT ||
                ', Qty: ' || NEW.quantity::TEXT || ', Price: ' || NEW.order_price::TEXT,
                'SUCCESS');
    ELSIF TG_OP = 'UPDATE' AND NEW.order_status = 'CANCELLED' THEN
        INSERT INTO audit_logs (user_id, action, resource, resource_id, details, status)
        VALUES (NEW.user_id, 'ORDER_CANCELLED', 'orders', NEW.order_id,
                'Cancelled order for stock ' || NEW.stock_id::TEXT, 'SUCCESS');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_orders ON orders;
CREATE TRIGGER trg_audit_orders
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION trg_fn_audit_orders();

-- Trigger 2: Log every wallet credit and debit into audit_logs
CREATE OR REPLACE FUNCTION trg_fn_audit_wallet()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.balance IS DISTINCT FROM NEW.balance THEN
        INSERT INTO audit_logs (user_id, action, resource, resource_id, details, status)
        VALUES (NEW.user_id,
                CASE WHEN NEW.balance > OLD.balance THEN 'WALLET_CREDIT' ELSE 'WALLET_DEBIT' END,
                'wallet', NEW.wallet_id,
                'Balance changed from ' || OLD.balance::TEXT || ' to ' || NEW.balance::TEXT,
                'SUCCESS');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_wallet ON wallet;
CREATE TRIGGER trg_audit_wallet
AFTER UPDATE ON wallet
FOR EACH ROW EXECUTE FUNCTION trg_fn_audit_wallet();

-- Trigger 3: Auto-update wallet.last_updated on every balance change
CREATE OR REPLACE FUNCTION trg_fn_wallet_updated()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.last_updated = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_wallet_last_updated ON wallet;
CREATE TRIGGER trg_wallet_last_updated
BEFORE UPDATE ON wallet
FOR EACH ROW EXECUTE FUNCTION trg_fn_wallet_updated();

-- Trigger 4: Prevent portfolio quantity from ever going negative
CREATE OR REPLACE FUNCTION trg_fn_portfolio_positive()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.total_quantity < 0 THEN
        RAISE EXCEPTION 'Portfolio quantity cannot be negative (stock_id=%, user_id=%)',
                        NEW.stock_id, NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_portfolio_positive ON portfolio;
CREATE TRIGGER trg_portfolio_positive
BEFORE INSERT OR UPDATE ON portfolio
FOR EACH ROW EXECUTE FUNCTION trg_fn_portfolio_positive();

-- Trigger 5: Auto-update announcement updated_at on every edit
CREATE OR REPLACE FUNCTION trg_fn_ann_updated()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ann_updated_at ON company_announcements;
CREATE TRIGGER trg_ann_updated_at
BEFORE UPDATE ON company_announcements
FOR EACH ROW EXECUTE FUNCTION trg_fn_ann_updated();

-- Trigger 6: Log system event when a DB transaction commits or rolls back
CREATE OR REPLACE FUNCTION trg_fn_dbtxn_log()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.txn_state = 'ACTIVE' THEN
        INSERT INTO system_logs (txn_id, operation, status, details)
        VALUES (NEW.txn_id,
                'TRANSACTION_' || NEW.txn_state,
                CASE NEW.txn_state WHEN 'COMMITTED' THEN 'SUCCESS' ELSE 'FAILED' END,
                'Transaction ' || NEW.txn_id::TEXT || ' ' || NEW.txn_state ||
                ' (duration: ' ||
                ROUND(EXTRACT(EPOCH FROM (COALESCE(NEW.end_time, NOW()) - NEW.start_time)) * 1000)
                || 'ms)');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_dbtxn_log ON database_transactions;
CREATE TRIGGER trg_dbtxn_log
AFTER UPDATE ON database_transactions
FOR EACH ROW EXECUTE FUNCTION trg_fn_dbtxn_log();

-- ============================================================================
-- SECTION 6: ADVANCED INDICES (non-default)
-- ============================================================================

-- ============================================
-- COMPOSITE (multi-column)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_portfolio_user_stock  ON portfolio(user_id, stock_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_status    ON orders(user_id, order_status);
CREATE INDEX IF NOT EXISTS idx_sph_stock_timestamp   ON stock_price_history(stock_id, price_timestamp DESC);

-- ============================================
-- HASH (exact equality only)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_users_email_hash      ON users USING HASH(email);

-- ============================================
-- GIN (JSONB search inside details column)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_audit_details_gin     ON audit_logs USING GIN(to_tsvector('english', COALESCE(details, '')));

-- ============================================
-- PARTIAL (only rows that matter)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_orders_pending        ON orders(user_id, created_at DESC) WHERE order_status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_portfolio_active      ON portfolio(user_id, stock_id)     WHERE total_quantity > 0;
CREATE INDEX IF NOT EXISTS idx_stocks_active_symbol  ON stocks(symbol)                   WHERE is_active = TRUE;


-- ============================================================================
-- SECTION 7: SAMPLE QUERIES (using functions + views + indices)
-- ============================================================================

-- ── Q1: USER role — Get full portfolio with P&L for user_id = 1
-- Uses: fn_get_user_portfolio, idx_portfolio_user, idx_portfolio_active
SELECT symbol, total_quantity, avg_buy_price,
       current_price, current_value, unrealized_pnl, pnl_pct
FROM   fn_get_user_portfolio(1)
ORDER  BY unrealized_pnl DESC;

-- ── Q2: USER role — Get total P&L for user_id = 1
-- Uses: fn_user_total_pnl, idx_portfolio_user, idx_portfolio_active
SELECT fn_user_total_pnl(1) AS total_pnl;

-- ── Q3: USER role — Get all PENDING orders for user_id = 1
-- Uses: v_orders, idx_orders_pending (partial index)
SELECT order_id, symbol, order_type, quantity, order_price, total_value, created_at
FROM   v_orders
WHERE  user_id = 1
  AND  order_status = 'PENDING'
ORDER  BY created_at DESC;

-- ── Q4: USER role — Get trade history for user_id = 1
-- Uses: v_trades, idx_trades_order_id, idx_orders_user_id
SELECT symbol, trade_type, quantity, price, total_value, executed_at
FROM   v_trades
WHERE  user_id = 1
ORDER  BY executed_at DESC;

-- ── Q5: USER role — Get dashboard summary for user_id = 1
-- Uses: v_dashboard, idx_wallet_user_id, idx_portfolio_user
SELECT wallet_balance, total_invested, portfolio_value, total_orders, executed_orders
FROM   v_dashboard
WHERE  user_id = 1;

-- ── Q6: COMPANY role — Get sentiment for stock_id = 1
-- Uses: fn_company_stats, idx_orders_stock_id, idx_portfolio_stock
SELECT total_orders, total_volume, total_value,
       unique_holders, buy_pressure, sell_pressure
FROM   fn_company_stats(1);

-- ── Q7: COMPANY role — Get buy/sell sentiment view for stock_id = 1
-- Uses: v_company_stock_sentiment, idx_orders_stock_id
SELECT total_orders, buy_count, sell_count,
       buy_pct, sell_pct, total_holders
FROM   v_company_stock_sentiment
WHERE  stock_id = 1;

-- ── Q8: ADMIN role — Get top 5 gaining stocks today
-- Uses: fn_top_gainers, idx_sph_stock_timestamp (composite DESC)
SELECT symbol, company_name, current_price, prev_price, change_pct
FROM   fn_top_gainers(5);

-- ── Q9: ADMIN role — Get 7-day price change for all active stocks
-- Uses: fn_stock_price_change, idx_sph_stock_timestamp, idx_stocks_active_symbol
SELECT s.stock_id, s.symbol, s.company_name,
       fn_stock_price_change(s.stock_id, 7) AS change_7d_pct
FROM   stocks s
WHERE  s.is_active = TRUE
ORDER  BY change_7d_pct DESC NULLS LAST;

-- ── Q10: ADMIN role — Get all users with full activity summary
-- Uses: view_admin_user_overview, idx_wallet_user_id, idx_portfolio_user
SELECT name, role, wallet_balance, total_orders,
       executed_orders, pending_orders, holdings_count
FROM   view_admin_user_overview
ORDER  BY total_orders DESC;

-- ── Q11: ADMIN role — Platform-wide stats in one row
-- Uses: view_admin_platform_stats
SELECT total_users, active_users, total_orders, executed_orders,
       total_trades, total_volume, total_wallet_balance, active_stocks
FROM   view_admin_platform_stats;

-- ── Q12: ADMIN role — Search audit logs for wallet events (GIN index)
-- Uses: idx_audit_details_gin, idx_audit_action
SELECT user_id, action, resource, details, created_at
FROM   audit_logs
WHERE  action IN ('WALLET_CREDIT', 'WALLET_DEBIT')
ORDER  BY created_at DESC
LIMIT  50;

-- ── Q13: USER role — Get all orders for a specific stock by a user
-- Uses: idx_orders_user_stock (composite), idx_orders_user_status
SELECT order_id, order_type, quantity, order_price, order_status, created_at
FROM   orders
WHERE  user_id  = 1
  AND  stock_id = 5
ORDER  BY created_at DESC;

-- ── Q14: ADMIN role — Get price history chart for stock_id = 1 (last 30 days)
-- Uses: idx_sph_stock_timestamp (composite DESC)
SELECT price, price_timestamp
FROM   stock_price_history
WHERE  stock_id = 1
  AND  price_timestamp >= NOW() - INTERVAL '30 days'
ORDER  BY price_timestamp ASC;

-- ── Q15: USER role — Find user by email (HASH index — exact match)
-- Uses: idx_users_email_hash
SELECT user_id, name, email, role
FROM   users
WHERE  email = 'allison@example.com';

-- ============================================================================
-- END OF FILE
-- ============================================================================
