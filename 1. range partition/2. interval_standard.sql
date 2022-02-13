/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Одноуровневое секционирование. Интервальное секционирование
	
  Описание скрипта: классические примеры интервального секционирования
*/

---- 1 день
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

insert into sales_interval_1d values (1, date'2021-01-05', 'CA', 1);--1
insert into sales_interval_1d values (2, date'2021-01-05', 'CA', 1);--2
insert into sales_interval_1d values (3, timestamp'2021-01-08 12:25:00', 'CA', 1); --3
insert into sales_interval_1d values (4, date'2021-02-08', 'NY', 1);--4
commit;

-- информация по секционированной таблицы
select * from user_tab_partitions t where t.table_name = 'SALES_INTERVAL_1D';
select * from user_part_tables t where t.table_name = 'SALES_INTERVAL_1D';

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sales_interval_1d'); 
end;
/

select * from sales_interval_1d t where t.sale_date = date'2021-01-05';
select * from sales_interval_1d t where t.sale_date = date'2004-12-05';
select * from sales_interval_1d t where t.sale_date = date'2005-01-01';


---- 1 месяц
drop table sales_interval_1m;

create table sales_interval_1m(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date) -- секционируем по дате
interval(numtoyminterval(1,'MONTH')) -- интервал 1 месяц
(
  partition pmin values less than (date '2005-01-15') -- точка перехода начинается не с первого дня, а с 15го
);

insert into sales_interval_1m values (1, date'1900-01-05', 'CA', 1);--1
insert into sales_interval_1m values (2, date'2000-01-05', 'NY', 1);--2
insert into sales_interval_1m values (3, date'2021-01-05', 'WA', 1);--3
insert into sales_interval_1m values (5, date'2021-02-05', 'CA', 1);--4
insert into sales_interval_1m values (6, date'2021-03-08', 'CC', 1);--5
commit;

-- смотрим какие секции были созданы. границы по 15е число
select * from user_tab_partitions t where t.table_name = 'SALES_INTERVAL_1M' order by t.partition_position;

