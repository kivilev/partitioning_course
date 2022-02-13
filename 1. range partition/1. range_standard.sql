/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Одноуровневое секционирование. Range-секционирование
	
  Описание скрипта: пример создания таблицы с range-секционированием
*/


-- 1 день
drop table sale_range;

create table sale_range(
  sale_id      number(30) not null,
  sale_date    date, -- not null (!)
  region_id    char(2 char) not null,
  customer_id  number(30) not null
) 
partition by range(sale_date)
( partition pmin  values less than (date '2009-01-01'),
  partition p01    values less than (date '2010-01-01'),
  partition p02    values less than (date '2012-03-01'),
  partition pmax values less than (maxvalue)
);

-- инфа по секционированию
select * from user_part_tables pt where pt.table_name = 'SALE_RANGE';
 
-- смотрим какие секции были созданы
select * from user_tab_partitions t where t.table_name = 'SALE_RANGE' order by t.partition_position;

-- вставка данных
insert into sale_range values (1, date'2009-01-01', 'WA', 1);--1
insert into sale_range values (2, date'2008-12-01', 'CA', 1);--2
insert into sale_range values (3, date'2008-12-01', 'NY', 1);--3
insert into sale_range values (4, date'2021-01-08', 'CA', 1);--4
insert into sale_range values (5, date'2011-02-08', 'NY', 1);--5
insert into sale_range values (6, null, 'NY', 1);--6
commit;

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'SALE_RANGE'); 
end;
/

select t.num_rows, t.* from user_tab_partitions t where t.table_name = 'SALE_RANGE' order by t.partition_position;

select * from sale_range;-- 1
select * from sale_range t where t.sale_date = date'2008-12-01'; -- 2
select * from sale_range partition(pmax);-- 3 (! в промышленном коде так не пишут)

