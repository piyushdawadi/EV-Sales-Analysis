WITH MakerSales AS (
    SELECT
        maker,
        CASE
            WHEN MONTH(date) >= 4 THEN YEAR(date) + 1
            ELSE YEAR(date)
        END AS fiscal_year,
        SUM(electric_vehicles_sold) AS total_vehicles_sold
    FROM
        sales_makers
    WHERE
        vehicle_category = '2-wheelers'
        AND (CASE WHEN MONTH(date) >= 4 THEN YEAR(date) + 1 ELSE YEAR(date) END) IN (2023, 2024)
    GROUP BY
        maker,
        fiscal_year
),
RankedMakers AS (
    SELECT
        maker,
        fiscal_year,
        total_vehicles_sold,
        RANK() OVER (PARTITION BY fiscal_year ORDER BY total_vehicles_sold DESC) AS rank_top,
        RANK() OVER (PARTITION BY fiscal_year ORDER BY total_vehicles_sold ASC) AS rank_bottom
    FROM
        MakerSales
)
SELECT
    maker,
    fiscal_year,
    total_vehicles_sold,
    'Top 3' AS rank_type
FROM
    RankedMakers
WHERE
    rank_top <= 3    
UNION ALL
SELECT
    maker,
    fiscal_year,
    total_vehicles_sold,
    'Bottom 3' AS rank_type
FROM
    RankedMakers
WHERE
    rank_bottom <= 3
ORDER BY
    fiscal_year,
    CASE WHEN rank_type = 'Top 3' THEN 1 ELSE 2 END,
    total_vehicles_sold DESC;