USE ev_db;

SET @price_2_wheeler = 85000;
SET @price_4_wheeler = 1500000;

WITH AnnualEVSalesRevenue AS (
    SELECT
        vehicle_category,
        CASE
            WHEN MONTH(date) >= 4 THEN YEAR(date) + 1
            ELSE YEAR(date)
        END AS fiscal_year,
        SUM(electric_vehicles_sold) AS annual_ev_units,
        SUM(electric_vehicles_sold) *
            CASE vehicle_category
                WHEN '2-wheelers' THEN @price_2_wheeler
                WHEN '4-wheelers' THEN @price_4_wheeler
                ELSE 0
            END AS estimated_revenue
    FROM
        sales_makers
    WHERE
        vehicle_category IN ('2-wheelers', '4-wheelers')
        AND (CASE WHEN MONTH(date) >= 4 THEN YEAR(date) + 1 ELSE YEAR(date) END) IN (2022, 2023, 2024)
    GROUP BY
        vehicle_category,
        fiscal_year
),

PivotedRevenue AS (
    SELECT
        vehicle_category,
        MAX(CASE WHEN fiscal_year = 2022 THEN estimated_revenue ELSE NULL END) AS revenue_2022,
        MAX(CASE WHEN fiscal_year = 2023 THEN estimated_revenue ELSE NULL END) AS revenue_2023,
        MAX(CASE WHEN fiscal_year = 2024 THEN estimated_revenue ELSE NULL END) AS revenue_2024
    FROM
        AnnualEVSalesRevenue
    GROUP BY
        vehicle_category
)
SELECT
    vehicle_category,
    revenue_2022,
    revenue_2023,
    revenue_2024,
    -- Growth Rate (2022 vs 2024) = ((Revenue 2024 - Revenue 2022) / Revenue 2022) * 100
    (
        (CAST(revenue_2024 AS DECIMAL(18, 4)) - CAST(revenue_2022 AS DECIMAL(18, 4))) /
        NULLIF(CAST(revenue_2022 AS DECIMAL(18, 4)), 0)
    ) * 100 AS growth_rate_2022_vs_2024_percentage,
    -- Growth Rate (2023 vs 2024) = ((Revenue 2024 - Revenue 2023) / Revenue 2023) * 100
    (
        (CAST(revenue_2024 AS DECIMAL(18, 4)) - CAST(revenue_2023 AS DECIMAL(18, 4))) /
        NULLIF(CAST(revenue_2023 AS DECIMAL(18, 4)), 0)
    ) * 100 AS growth_rate_2023_vs_2024_percentage
FROM
    PivotedRevenue
WHERE
    revenue_2022 IS NOT NULL AND revenue_2023 IS NOT NULL AND revenue_2024 IS NOT NULL
ORDER BY
    vehicle_category;