CREATE SCHEMA IF NOT EXISTS credit;

DROP TABLE IF EXISTS credit.applications;

CREATE TABLE credit.applications (
    application_id   BIGSERIAL PRIMARY KEY,
    age              INT CHECK (age > 0),
    job              INT,
    housing          TEXT,
    saving_accounts  TEXT,
    checking_account TEXT,
    credit_amount    INT CHECK (credit_amount >= 0),
    duration_months  INT CHECK (duration_months > 0),
    purpose          TEXT,
    default_flag     INT CHECK (default_flag IN (0,1))
);