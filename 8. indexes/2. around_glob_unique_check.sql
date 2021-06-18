----- Примеры обхода глобальных уникальных индексов - УНИКАЛЬНОСТЬ

drop table sales_interval;
drop sequence sales_interval_seq;

create sequence sales_interval_seq;

create table sales_interval(
  sale_id         number(30) not null,
  sale_date       date not null,
  sale_date_month as (trunc(sale_date,'mm')) not null,
  region_id       char(2 char) not null,
  customer_id     number(30) not null
)
partition by range(sale_date_month)
interval(interval '1' month)
(
partition pmin values less than (date '2005-01-01')
);

insert into sales_interval(sale_id, sale_date, region_id, customer_id) 
  select  sales_interval_seq.nextval, sysdate + level, decode(mod(level, 2),0,'CA','NY'), mod(level,10)+1 from dual connect by level <= 1000;
commit; 

select * from sales_interval;

create unique index sales_interval_unq_idx on sales_interval(sale_id, sale_date_month);

select * from sales_interval;

--- Попытка вставить в секцию с разным временем, но с одинаковым ID
insert into sales_interval(sale_id, sale_date, region_id, customer_id) 
values (100000, sysdate, 'NY', 1001);

insert into sales_interval(sale_id, sale_date, region_id, customer_id) 
values (100000, sysdate, 'NY', 1001);


-- вероятность сбоя, когда именно на границе секций крайне низка


