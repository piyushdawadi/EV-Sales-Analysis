use ev_db;
With TotalSales as(
	select
		state,
		sum(electric_vehicles_sold) as total_ev_sales,
        sum(total_vehicles_sold) as total_sales
	from 
		sales_state
	where 
        (CASE WHEN MONTH(date) >= 4 THEN YEAR(date) + 1 ELSE YEAR(date) END) = 2024
        and state in ('Delhi', 'Karnataka')
	group by
		state
)
select 
		state,
        total_ev_sales,
        total_sales,
        (total_ev_sales/total_sales) *100 as penetration_rate
	from
		TotalSales
	order by
		state;