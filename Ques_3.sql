use ev_db;
with StateSales as(
	select
		state,
        vehicle_category,
        case
			when month(date) >= 4 then year(date) +1
            else year(date)
		end as fiscal_year,
        sum(electric_vehicles_sold) as total_ev_sold,
        sum(total_vehicles_sold) as total_vehicles
        from 
			sales_state
		where 
			(case when month(date) >= 4 then year(date) +1 else year(date) end) in (2022, 2024)
			and vehicle_category in ('2-Wheelers', '4-Wheelers')
		group by 
			state,
            vehicle_category,
            fiscal_year
),
StatePenetrationRate as(
	select
		state,
        vehicle_category,
        fiscal_year,
        total_ev_sold,
        total_vehicles,
        total_ev_sold/total_vehicles as penetration_rate
        from 
			StateSales
		where 
			total_vehicles>0
)
SELECT
    fy2024.state,
    fy2024.vehicle_category,
    (fy2022.penetration_rate * 100) AS penetration_rate_fy_2022_percentage,
    (fy2024.penetration_rate * 100) AS penetration_rate_fy_2024_percentage,
    'Decline' AS trend
FROM
    StatePenetrationRate fy2024
JOIN
    StatePenetrationRate fy2022 ON fy2024.state = fy2022.state
                                AND fy2024.vehicle_category = fy2022.vehicle_category
WHERE
    fy2024.fiscal_year = 2024
    AND fy2022.fiscal_year = 2022
    AND fy2024.penetration_rate < fy2022.penetration_rate
ORDER BY
    fy2024.state,
    fy2024.vehicle_category;