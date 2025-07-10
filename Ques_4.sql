use ev_db;
With SalesWithFiscalPeriods as(
	select
		maker,
        electric_vehicles_sold,
        case
			when month(date) >= 4 then year(date) + 1
            else year(date)
		end as fiscal_year,
        case
			when month(date) between 4 and 6 then "Q1"
            WHEN MONTH(date) BETWEEN 7 AND 9 THEN 'Q2'
            WHEN MONTH(date) BETWEEN 10 AND 12 THEN 'Q3'
            WHEN MONTH(date) BETWEEN 1 AND 3 THEN 'Q4'
        END AS fiscal_quarter
	from
		sales_makers
	where
		vehicle_category = '4-Wheelers'
		AND (CASE WHEN MONTH(date) >= 4 THEN YEAR(date) + 1 ELSE YEAR(date) END) IN (2022, 2023, 2024)
),
Top5EVMakers as(
	select 
		maker
	from(
		select
			maker,
            sum(electric_vehicles_sold) as total_ev_sales_overall,
            Dense_Rank() Over (Order by sum(electric_vehicles_sold) desc) as maker_rank
		from 
			SalesWithFiscalPeriods
		Group By
			maker
    )
    as RankedOverallMakers
    where maker_rank <= 5
),
QuarterlyTrends AS (
    SELECT
        sfp.maker,
        sfp.fiscal_year,
        sfp.fiscal_quarter,
        SUM(sfp.electric_vehicles_sold) AS quarterly_ev_sales_volume
    FROM
        SalesWithFiscalPeriods sfp
    JOIN
        Top5EVMakers tm ON sfp.maker = tm.maker 
    GROUP BY
        sfp.maker,
        sfp.fiscal_year,
        sfp.fiscal_quarter
)
SELECT
    maker,
    fiscal_year,
    fiscal_quarter,
    quarterly_ev_sales_volume
FROM
    QuarterlyTrends
ORDER BY
    maker,
    fiscal_year,
    CASE fiscal_quarter
        WHEN 'Q1' THEN 1
        WHEN 'Q2' THEN 2
        WHEN 'Q3' THEN 3
        WHEN 'Q4' THEN 4
    END;
