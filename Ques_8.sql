USE ev_db;

WITH MonthlyEVSales AS (
    SELECT
        MONTH(date) AS month_number,
        SUM(electric_vehicles_sold) AS total_ev_sold
    FROM
        sales_state
    WHERE
        YEAR(date) BETWEEN 2022 AND 2024
    GROUP BY
        MONTH(date)
),
RankedMonths AS (
    SELECT
        month_number,
        total_ev_sold,
        RANK() OVER (ORDER BY total_ev_sold DESC) AS sales_rank_desc,
        RANK() OVER (ORDER BY total_ev_sold ASC) AS sales_rank_asc
    FROM
        MonthlyEVSales
)
SELECT
    CASE month_number
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END AS month_name,
    total_ev_sold,
    CASE
        WHEN sales_rank_desc = 1 THEN 'Peak Season'
        WHEN sales_rank_asc = 1 THEN 'Low Season'
        ELSE 'Normal Season'
    END AS season_type
FROM
    RankedMonths
WHERE
    sales_rank_desc = 1 OR sales_rank_asc = 1
ORDER BY
    season_type DESC, total_ev_sold DESC;