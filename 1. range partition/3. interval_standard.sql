---- Классический пример интервального секционирования

-- 1 день
drop table sales_interval_1d;

create table sales_interval_1d(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date) -- секционируем по дате
interval(numtodsinterval(1,'DAY')) -- интервал 1 день
(
partition pmin values less than (date '2005-01-01') -- одна секция за любой период
);

insert into sales_interval_1d values (1, date'2021-01-05', 'CA', 1);
insert into sales_interval_1d values (2, date'2021-01-05', 'CA', 1);
insert into sales_interval_1d values (3, date'2021-01-08', 'CA', 1);
insert into sales_interval_1d values (4, date'2021-02-08', 'NY', 1);
commit;

-- смотрим какие секции были созданы
select * from user_tab_partitions t where t.table_name = 'SALES_INTERVAL_1D';
select * from user_part_tables t where t.table_name = 'SALES_INTERVAL_1D';

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sales_interval_1d'); 
end;
/
 
