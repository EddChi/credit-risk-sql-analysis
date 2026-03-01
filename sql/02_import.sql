-- clearing the staging table (safe to rerun)
TRUNCATE credit.applications_raw;

-- import raw CSV data into the staging table
COPY credit.applications_raw(
    status,
    duration,
    credit_history,
    purpose,
    amount,
    savings,
    employment_duration,
    installment_rate,
    personal_status_sex,
    other_debtors,
    present_residence,
    property,
    age,
    other_installment_plans,
    housing,
    number_credits,
    job,
    people_liable,
    telephone,
    foreign_worker,
    credit_risk
)
-- note: replace the path below with your local path to the GermanCredit.csv file
FROM 'D:/data-analysis/credit-risk-sql-analysis/data/GermanCredit.csv'
WITH (FORMAT csv, HEADER true);

-- clear clean table (safe to rerun)
TRUNCATE credit.applications;

INSERT INTO credit.applications (
    status,
    duration_months,
    credit_history,
    purpose,
    credit_amount,
    savings,
    employment_duration,
    installment_rate,
    personal_status_sex,
    other_debtors,
    present_residence,
    property,
    age,
    other_installment_plans,
    housing,
    number_credits,
    job,
    people_liable,
    telephone,
    foreign_worker,
    credit_risk,
    default_flag
)
SELECT
    status,
    duration,
    credit_history,
    purpose,
    amount,
    savings,
    employment_duration,
    installment_rate,
    personal_status_sex,
    other_debtors,
    present_residence,
    property,
    age,
    other_installment_plans,
    housing,
    number_credits,
    job,
    people_liable,
    telephone,
    foreign_worker,
    credit_risk,
    CASE 
        WHEN LOWER(credit_risk) IN ('bad','1','default') THEN 1 
        ELSE 0
    END AS default_flag
FROM credit.applications_raw;