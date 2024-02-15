/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Составное секционирование
	
  Описание скрипта: пример создания Range(Interval) - List секционированной таблицы
*/

drop table sale_interval_list;

create table sale_interval_list(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
)
partition by range(sale_date) -- первый уровень. interval по "дате продажи"
interval(numtodsinterval(1, 'DAY')) -- c автонарезанием по 1 дню
subpartition by list (region_id) -- второй уровень. list по "регионам"
subpartition template( -- подсекции
  subpartition p_west    values ('CA','WA','OR'),
  subpartition p_south   values ('TX'),
  subpartition p_null    values(null),
  subpartition p_default values (default)
)
(
   partition pmin values less than (date '2005-01-01') -- одна секция за любой период
);

select * from user_tab_partitions t where t.table_name = 'SALE_INTERVAL_LIST';
select * from user_tab_subpartitions t where t.table_name = 'SALE_INTERVAL_LIST' order by t.partition_position, t.subpartition_position;
select * from user_subpartition_templates t where t.table_name = 'SALE_INTERVAL_LIST' order by t.subpartition_position;
select * from user_part_tables t where t.table_name = 'SALE_INTERVAL_LIST';


-- вставка данных
insert into sale_interval_list values (1, sysdate, 'CA', 100); -- 1
insert into sale_interval_list values (2, date '2004-01-01', 'WA', 101); -- 2
insert into sale_interval_list values (3, sysdate+1, 'TX', 102); -- 3
insert into sale_interval_list values (4, sysdate+1, 'NY', 103); -- 4
commit;

-- сбор статистики
call dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_interval_list'); 
select t.num_rows, t.* from user_tab_subpartitions t where t.num_rows <> 0 and t.table_name = 'SALE_INTERVAL_LIST';

-- строка 2
select * from sale_interval_list subpartition (pmin_p_west); 
select * from sale_interval_list subpartition for(date'2004-01-01', 'CA');

-- строки 3 и 4
select * from sale_interval_list partition (SYS_P3297);
select * from sale_interval_list subpartition (SYS_SUBP3274);
select * from sale_interval_list subpartition (SYS_SUBP3274);

-- правильное обращение 
select * 
  from sale_interval_list t
 where t.sale_date = date '2004-01-01' 
   and t.region_id = 'WA';
