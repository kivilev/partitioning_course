---- Составное секционирование. Range(Interval) - List.
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

insert into sale_interval_list values (1, sysdate, 'CA', 100);
insert into sale_interval_list values (2, sysdate+1, 'WA', 101);
insert into sale_interval_list values (3, sysdate+2, 'TX', 102);
insert into sale_interval_list values (4, sysdate+3, 'NY', 103);
insert into sale_interval_list values (6, sysdate+4, null, 105);
commit;

-- Сбор статистики
call dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_interval_list'); 


select * from user_tab_partitions t where t.table_name = 'SALE_INTERVAL_LIST';
select * from user_tab_subpartitions t where t.table_name = 'SALE_INTERVAL_LIST' order by t.partition_position, t.subpartition_position;

select * from sale_interval_list partition (p_west);
--select * from sale_list_hash partition for(to_char(sysdate));
select * from sale t partition for(date'1900-06-01');

select * from sale_interval_list subpartition (SYS_SUBP2388);
select * from sale t subpartition for(date'1900-06-01', 'CA');

select * from  all_subpartition_templates;



