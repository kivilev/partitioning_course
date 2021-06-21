----- Глобальные и локальные индексы

drop table sales_interval;

create table sales_interval(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date)
interval(interval '1' month)
(
partition pmin values less than (date '2005-01-01')
);

insert into sales_interval 
  select level, sysdate + level, decode(mod(level, 2),0,'CA','NY'), mod(level,10)+1 from dual connect by level <= 1000;
commit; 

call dbms_stats.gather_table_stats(ownname => user, tabname => 'sales_interval');-- стата

select t.* from user_tab_partitions t where t.table_name ='SALES_INTERVAL';-- секции

----- Обычные индексы
-- глобальный индекс
create index sales_interval_sale_id_glob_idx on sales_interval(sale_id);

-- локальный индекс
create index sales_interval_cust_id_loc_idx on sales_interval(customer_id) local;

select *
  from sales_interval t
 where t.sale_id = 555;

select *
  from sales_interval t
 where t.customer_id = 10
   and t.sale_date between sysdate+8 and sysdate + 12;

-- очень плохо
select *
  from sales_interval t
 where t.customer_id = 10;
   --and t.sale_date between sysdate+8 and sysdate + 12;

----- Уникальные индексы
drop index sales_interval_sale_id_glob_idx;
drop index sales_interval_cust_id_loc_idx;

-- глобальный индекс
create unique index sales_interval_sale_id_glob_unq_idx on sales_interval(sale_id);

-- локальный индекс
create unique index sales_interval_cust_id_loc_unq_idx on sales_interval(customer_id, sale_date) local;

-- unique index scan
select * 
  from sales_interval t
 where t.sale_id = 555;

-- range index scan
select * 
  from sales_interval t
 where t.customer_id = 10
   and t.sale_date between sysdate+8 and sysdate + 12;

-- unique index scan
select * 
  from sales_interval t
 where t.customer_id = 10
   and t.sale_date = to_date('23.06.2021 16:12:02','dd.mm.YYYY hh24:mi:ss');
