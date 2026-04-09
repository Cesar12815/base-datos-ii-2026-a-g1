/*payment_status
payment_method
payment
payment_transaction
refund*/
-- Se desea conocer el valor total de estado de pago FAILDED
select * from payment_status;
select * from payment;
select 
	SUM(p.amount) tatal_value
from 
	payment p 
	inner join payment_status ps on p.payment_status_id = ps.payment_status_id 
where ps.status_code ILIKE '%FAILED%';


select 
	ps.status_code,
	SUM(p.amount) tatal_value
from 
	payment p 
	inner join payment_status ps on p.payment_status_id = ps.payment_status_id 
group by ps.status_code ;

select 
	ps.status_code,
	SUM(p.amount) tatal_value
from 
	payment p 
	right join payment_status ps on p.payment_status_id = ps.payment_status_id 
group by ps.status_code ;


select 
	ps.status_code,
	SUM(p.amount) tatal_value
from 
	payment_status ps 
	left join payment p on p.payment_status_id = ps.payment_status_id 
group by ps.status_code ;


----
CREATE OR REPLACE FUNCTION public.prueba()
	RETURNS TABLE (
		status_code varchar,
		total_value numeric
	)
	LANGUAGE plpgsql
AS $function$
	BEGIN
		return query
		select 
			ps.status_code,
			SUM(p.amount) as total_value
		from 
			payment_status ps 
			left join payment p on p.payment_status_id = ps.payment_status_id 
		group by ps.status_code;
	END;
$function$;