--SHIPPING

insert into dw.shipping_dim (shipping_mode)
select distinct o.ship_mode 
  from stg.orders o 
  ;
commit;


--PRODUCT

insert into dw.product_dim(product_id, product_name, category, sub_category, segment)
select distinct o.product_id 
	  ,o.product_name 
	  ,o.category 
	  ,o.subcategory 
	  ,o.segment 
  from stg.orders o 
  ;
commit;

--GEO

insert into dw.geo_dim(country, city, state, postal_code)
select distinct o.country 
	  ,o.city 
	  ,o.state 
	  ,o.postal_code 
  from stg.orders o 
  ;
 
update dw.geo_dim
set postal_code = '05401'
where city = 'Burlington'  and postal_code is null;


update stg.orders
set postal_code = '05401'
where city = 'Burlington'  and postal_code is null;

commit;

--CUSTOMER


insert into dw.customer_dim(customer_id, customer_name)
select distinct o.customer_id, o.customer_name 
  from stg.orders o 
;

commit;


--CALENDAR
insert into dw.calendar_dim(year, quarter, month, week, "date", week_day, leap)
select extract(year from t.date) as year
	  ,extract(quarter from t.date) as quarter
	  ,extract(month from t.date) as month
	  ,extract(week from t.date) as week
	  ,t.date::date as "date"
	  ,to_char(t.date, 'dy') as week_day
	  ,case when 
	  			extract('day' from (t.date + interval '2 month - 1 day')) = 29 then 'yes'
	  		else 'no'
	   end as leap
  from pg_catalog.generate_series(date'2016-01-03', date'2020-01-05', interval '1 day') as t(date)
  ;
  
commit;


--SALES

insert into dw.sales_fact(cust_id, order_date_id, ship_date_id, prod_id, ship_id, geo_id, order_id, sales, profit, quantity, discount)
select cd.cust_id as cust_id
	  ,cd2.dateid as order_date_id
	  ,cd3.dateid as ship_date_id
	  ,pd.prod_id as prod_id
	  ,sd.ship_id as ship_id
	  ,gd.geo_id as geo_id
	  ,o.order_id as order_id
	  ,o.sales as sales
	  ,o.profit as profit
	  ,o.quantity as quantity 
	  ,o.discount as discount 
  from stg.orders o 
  join dw.customer_dim cd 
    on cd.customer_id = o.customer_id
  join dw.calendar_dim cd2 
    on cd2."date"  = o.order_date 
  join dw.calendar_dim cd3 
    on cd3."date"  = o.ship_date  
  join dw.shipping_dim sd 
    on sd.shipping_mode = o.ship_mode 
  join dw.product_dim pd 
    on pd.product_id = o.product_id 
   and pd.product_name = o.product_name 
   and pd.category = o.category 
   and pd.sub_category = o.subcategory 
   and pd.segment = o.segment 
  join dw.geo_dim gd 
    on gd.postal_code = o.postal_code 
   and gd.city = o.city 
    ;
    
commit;