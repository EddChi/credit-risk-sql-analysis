-- Credit Risk Analysis (PostgreSQL)

-- Q1: overall default rate
SELECT
    COUNT(*) AS applications,
    ROUND(AVG(default_flag::numeric), 3) AS default_rate
FROM credit.applications;


-- Q2: default rate by purpose (only segments with enough samples)
SELECT
    purpose,
    COUNT(*) AS applications,
    ROUND(AVG(default_flag::numeric), 3) AS default_rate
FROM credit.applications
GROUP BY purpose
HAVING COUNT(*) >= 30
ORDER BY default_rate DESC, applications DESC;


-- Q3: exposure-weighted default rate by housing (amount matters)
SELECT
    housing,
    COUNT(*) AS applications,
    SUM(credit_amount) AS total_exposure,
    ROUND(
        SUM(credit_amount * default_flag)::numeric / NULLIF(SUM(credit_amount), 0),
        3
    ) AS exposure_weighted_default_rate
FROM credit.applications
GROUP BY housing
ORDER BY exposure_weighted_default_rate DESC, total_exposure DESC;


-- Q4: top risky segments using a window function (purpose x housing)
WITH seg AS (
    SELECT
        purpose,
        housing,
        COUNT(*) AS n,
        ROUND(AVG(default_flag::numeric), 3) AS default_rate
    FROM credit.applications
    GROUP BY purpose, housing
    HAVING COUNT(*) >= 20
)
SELECT *
FROM (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY default_rate DESC) AS risk_rank
    FROM seg
) ranked
WHERE risk_rank <= 10
ORDER BY default_rate DESC, n DESC;


--Q5: default rate by age group (using binning/case statement)
WITH binned AS (
    SELECT
        CASE
            WHEN age < 25 THEN '<25'
            WHEN age BETWEEN 25 AND 34 THEN '25-34'
            WHEN age BETWEEN 35 AND 44 THEN '35-44'
            WHEN age BETWEEN 45 AND 54 THEN '45-54'
            ELSE '55+'
        END AS age_band,
        default_flag
    FROM credit.applications
)
SELECT
    age_band,
    COUNT(*) AS applications,
    ROUND(AVG(default_flag::numeric), 3) AS default_rate
FROM binned
GROUP BY age_band
HAVING COUNT(*) >= 30
ORDER BY
    CASE age_band
        WHEN '<25' THEN 1
        WHEN '25-34' THEN 2
        WHEN '35-44' THEN 3
        WHEN '45-54' THEN 4
        ELSE 5
    END;


-- Q6: default rate by exposure decile (NTILE window function)
-- bins customers into 10 groups based on their exposure score (credit_amount x duration_months)
WITH scored AS (
    SELECT
        application_id,
        (credit_amount * duration_months) AS exposure_score,
        default_flag
    FROM credit.applications
),
bucketed AS (
    SELECT
        *,
        NTILE(10) OVER (ORDER BY exposure_score DESC) AS exposure_decile
    FROM scored
)
SELECT
    exposure_decile,
    COUNT(*) AS applications,
    ROUND(AVG(default_flag::numeric), 3) AS default_rate,
    SUM(exposure_score) AS total_exposure_score
FROM bucketed
GROUP BY exposure_decile
ORDER BY exposure_decile;


-- Q7: top 3 highest risk purposes within each housing segment
WITH seg AS (
    SELECT
        housing,
        purpose,
        COUNT(*) AS applications,
        ROUND(AVG(default_flag::numeric), 3) AS default_rate
    FROM credit.applications
    GROUP BY housing, purpose
    HAVING COUNT(*) >= 20
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY housing
            ORDER BY default_rate DESC
        ) AS risk_rank_in_housing
    FROM seg
)
SELECT
    housing,
    purpose,
    applications,
    default_rate,
    risk_rank_in_housing
FROM ranked
WHERE risk_rank_in_housing <= 3
ORDER BY housing, risk_rank_in_housing, applications DESC;