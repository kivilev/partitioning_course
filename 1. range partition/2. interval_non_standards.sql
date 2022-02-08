/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)
  
  Лекция. Одноуровневое секционирование. Интервальное секционирование
	
  Описание скрипта: примеры задания таблиц с различными интервалами
*/

---- 2 месяца
drop table sale_interval_2m;

create table sale_interval_2m(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date)
interval(numtoyminterval(2,'MONTH'))
(
partition pmin values less than (date '2005-01-01')
);

insert into sale_interval_2m values (1, date'2021-01-05', 'CA', 1);
insert into sale_interval_2m values (2, date'2021-01-08', 'CA', 1);
insert into sale_interval_2m values (3, date'2021-02-08', 'NY', 1);
insert into sale_interval_2m values (4, date'2021-03-08', 'NY', 1);

select * from user_tab_partitions t where t.table_name = 'SALE_INTERVAL_2M';


---- 3 дня
drop table sale_interval_3d;

create table sale_interval_3d(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date) -- секционируем по дате
interval(numtodsinterval(3,'DAY')) -- интервал 1 день
(
partition pmin values less than (date '2005-01-01') -- одна секция за любой период
);

insert into sale_interval_3d
select level, date '2020-12-27' + level, 'CA', level from dual connect by level <= 10;

select * from user_tab_partitions t where t.table_name = 'SALE_INTERVAL_3D';


---- 7 чаcов
drop table sale_interval_7h;

create table sale_interval_7h(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date)
interval(interval '7' hour)
(partition pmin values less than (date '2021-06-26'));
 
insert into sale_interval_7h 
select level, date '2021-06-25' + level/24, 'NY', level from dual connect by level <= 100;

select * from user_tab_partitions t where t.table_name = 'SALE_INTERVAL_7H';

begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'SALE_INTERVAL_7H');
end;
/

select * from sale_interval_7h partition(SYS_P2089);


---- 10 минут
drop table sale_interval_10m;

create table sale_interval_10m(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date)
interval(interval '10' minute)
(
partition pmin values less than (date '2005-01-01')
);
 
insert into sale_interval_10m 
select level, date '2021-01-01' + level/24/60, 'CA', level from dual connect by level <= 100;

select * from user_tab_partitions t where t.table_name = 'SALE_INTERVAL_10M';

begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'SALE_INTERVAL_10M');
end;
/
