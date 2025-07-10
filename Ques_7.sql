USE ev_db;

WITH StateSalesWithFiscalYear AS (
    SELECT
        state,
        CASE
            WHEN MONTH(date) >= 4 THEN YEAR(date) + 1
            ELSE YEAR(date)
        END AS fiscal_year,
        total_vehicles_sold
    FROM
        sales_state
    WHERE
        (CASE WHEN MONTH(date) >= 4 THEN YEAR(date) + 1 ELSE YEAR(date) END) IN (2022, 2024)
),
StateAnnualTotalSales AS (
    SELECT
        state,
        fiscal_year,
        SUM(total_vehicles_sold) AS annual_total_units
    FROM
        StateSalesWithFiscalYear
    GROUP BY
        state,
        fiscal_year
),
CAGRCalculation AS (
    SELECT
        sats.state,
        MAX(CASE WHEN sats.fiscal_year = 2024 THEN sats.annual_total_units ELSE NULL END) AS units_2024,
        MAX(CASE WHEN sats.fiscal_year = 2022 THEN sats.annual_total_units ELSE NULL END) AS units_2022
    FROM
        StateAnnualTotalSales sats
    GROUP BY
        sats.state
    HAVING
        MAX(CASE WHEN sats.fiscal_year = 2022 THEN sats.annual_total_units ELSE NULL END) IS NOT NULL AND
        MAX(CASE WHEN sats.fiscal_year = 2024 THEN sats.annual_total_units ELSE NULL END) IS NOT NULL AND
        MAX(CASE WHEN sats.fiscal_year = 2022 THEN sats.annual_total_units ELSE NULL END) > 0
),
StateCAGR AS (
    SELECT
        state,
        units_2022,
        units_2024,
        (POWER(CAST(units_2024 AS DECIMAL(18, 4)) / CAST(units_2022 AS DECIMAL(18, 4)), 1.0/2) - 1) * 100 AS cagr_percentage
    FROM
        CAGRCalculation
)
SELECT
    state,
    cagr_percentage
FROM
    StateCAGR
ORDER BY
    cagr_percentage DESC
LIMIT 10;