USE ev_db;

WITH SalesWithFiscalYear AS (
    SELECT
        maker,
        CASE
            WHEN MONTH(date) >= 4 THEN YEAR(date) + 1
            ELSE YEAR(date)
        END AS fiscal_year,
        electric_vehicles_sold
    FROM
        sales_makers
    WHERE
        vehicle_category = '4-wheelers'
        AND (CASE WHEN MONTH(date) >= 4 THEN YEAR(date) + 1 ELSE YEAR(date) END) IN (2022, 2024)
),
MakerAnnualEVSales AS (
    SELECT
        maker,
        fiscal_year,
        SUM(electric_vehicles_sold) AS annual_ev_units
    FROM
        SalesWithFiscalYear
    GROUP BY
        maker,
        fiscal_year
),
Top5EVMakersOverall AS (
    SELECT
        maker
    FROM (
        SELECT
            maker,
            SUM(annual_ev_units) AS overall_ev_units,
            DENSE_RANK() OVER (ORDER BY SUM(annual_ev_units) DESC) AS maker_rank
        FROM
            MakerAnnualEVSales
        GROUP BY
            maker
    ) AS RankedOverallEVMakers
    WHERE maker_rank <= 5
),
CAGRCalculation AS (
    SELECT
        maes.maker,
        MAX(CASE WHEN maes.fiscal_year = 2024 THEN maes.annual_ev_units ELSE NULL END) AS units_2024,
        MAX(CASE WHEN maes.fiscal_year = 2022 THEN maes.annual_ev_units ELSE NULL END) AS units_2022
    FROM
        MakerAnnualEVSales maes
    JOIN
        Top5EVMakersOverall tm ON maes.maker = tm.maker
    GROUP BY
        maes.maker
)
SELECT
    maker,
    units_2022,
    units_2024,
    -- CAGR Formula: ((Ending Value / Beginning Value)^(1/Number of Periods)) - 1
    -- Number of periods from FY2022 to FY2024 is 2 (FY2023 and FY2024)
    (POWER(CAST(units_2024 AS DECIMAL(18, 4)) / CAST(NULLIF(units_2022, 0) AS DECIMAL(18, 4)), 1.0/2) - 1) * 100 AS cagr_percentage
FROM
    CAGRCalculation
WHERE
    units_2022 IS NOT NULL AND units_2024 IS NOT NULL
    AND units_2022 > 0
ORDER BY
    cagr_percentage DESC;