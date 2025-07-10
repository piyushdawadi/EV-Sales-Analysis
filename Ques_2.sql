USE ev_db;
WITH StateCategorySales AS (
    SELECT
        state,
        vehicle_category,
        CASE
            WHEN MONTH(date) >= 4 THEN YEAR(date) + 1
            ELSE YEAR(date)
        END AS fiscal_year,
        SUM(electric_vehicles_sold) AS total_ev_sold,
        SUM(total_vehicles_sold) AS total_vehicles
    FROM
        sales_state
    WHERE
        (CASE WHEN MONTH(date) >= 4 THEN YEAR(date) + 1 ELSE YEAR(date) END) = 2024
        AND vehicle_category IN ('2-wheelers', '4-wheelers')
    GROUP BY
        state,
        vehicle_category,
        fiscal_year
),
RankedPenetration AS (
    SELECT
        state,
        vehicle_category,
        CAST(total_ev_sold AS DECIMAL(10, 4)) / NULLIF(total_vehicles, 0) AS penetration_rate,
        DENSE_RANK() OVER (PARTITION BY vehicle_category ORDER BY CAST(total_ev_sold AS DECIMAL(10, 4)) / NULLIF(total_vehicles, 0) DESC) AS category_rank
    FROM
        StateCategorySales
    WHERE
        total_vehicles > 0
)
SELECT
    state,
    vehicle_category,
    (penetration_rate * 100) AS penetration_rate_percentage,
    category_rank
FROM
    RankedPenetration
WHERE
    category_rank <= 5
ORDER BY
    vehicle_category,
    penetration_rate DESC;


