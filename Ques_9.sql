USE ev_db;

WITH StateFiscalSales AS (
    SELECT
        state,
        CASE
            WHEN MONTH(date) >= 4 THEN YEAR(date) + 1
            ELSE YEAR(date)
        END AS fiscal_year,
        SUM(electric_vehicles_sold) AS annual_ev_sold,
        SUM(total_vehicles_sold) AS annual_total_vehicles
    FROM
        sales_state
    WHERE
        (CASE WHEN MONTH(date) >= 4 THEN YEAR(date) + 1 ELSE YEAR(date) END) IN (2022, 2023, 2024)
    GROUP BY
        state,
        fiscal_year
),
StatePenetrationFY2024 AS (
    SELECT
        state,
        (CAST(annual_ev_sold AS DECIMAL(18, 4)) / NULLIF(annual_total_vehicles, 0)) AS penetration_rate,
        DENSE_RANK() OVER (ORDER BY (CAST(annual_ev_sold AS DECIMAL(18, 4)) / NULLIF(annual_total_vehicles, 0)) DESC) AS penetration_rank
    FROM
        StateFiscalSales
    WHERE
        fiscal_year = 2024
        AND annual_total_vehicles > 0
),
Top10StatesByPenetration AS (
    SELECT
        state
    FROM
        StatePenetrationFY2024
    WHERE
        penetration_rank <= 10
),
AnnualEVSalesForCAGR AS (
    SELECT
        sfs.state,
        MAX(CASE WHEN sfs.fiscal_year = 2024 THEN sfs.annual_ev_sold ELSE NULL END) AS ev_sales_2024,
        MAX(CASE WHEN sfs.fiscal_year = 2022 THEN sfs.annual_ev_sold ELSE NULL END) AS ev_sales_2022
    FROM
        StateFiscalSales sfs
    JOIN
        Top10StatesByPenetration ts ON sfs.state = ts.state
    WHERE
        sfs.fiscal_year IN (2022, 2024)
    GROUP BY
        sfs.state
    HAVING
        -- Ensure we have valid sales data for both start and end years for CAGR
        MAX(CASE WHEN sfs.fiscal_year = 2022 THEN sfs.annual_ev_sold ELSE NULL END) IS NOT NULL AND
        MAX(CASE WHEN sfs.fiscal_year = 2024 THEN sfs.annual_ev_sold ELSE NULL END) IS NOT NULL AND
        MAX(CASE WHEN sfs.fiscal_year = 2022 THEN sfs.annual_ev_sold ELSE NULL END) > 0
),
StateEVCAGR AS (
    SELECT
        state,
        ev_sales_2024,
        ev_sales_2022,
        -- CAGR Formula: ((Ending Value / Beginning Value)^(1/Number of Periods)) - 1
        -- Number of periods from FY2022 to FY2024 is 2 (FY2023 and FY2024)
        (POWER(CAST(ev_sales_2024 AS DECIMAL(18, 4)) / CAST(ev_sales_2022 AS DECIMAL(18, 4)), 1.0/2) - 1) AS cagr_decimal
    FROM
        AnnualEVSalesForCAGR
)
SELECT
    sec.state,
    sec.ev_sales_2024 AS base_ev_sales_fy2024,
    (sec.cagr_decimal * 100) AS cagr_percentage,
    -- Projected Sales = Present Value * (1 + CAGR)^Number of Periods
    -- Number of periods from FY 2024 to FY 2030 is 6 (2025, 2026, 2027, 2028, 2029, 2030)
    ROUND(sec.ev_sales_2024 * POWER(1 + sec.cagr_decimal, 6)) AS projected_ev_sales_fy2030
FROM
    StateEVCAGR sec
ORDER BY
    projected_ev_sales_fy2030 DESC;