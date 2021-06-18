---- Пример List-секционировани 

-- 
drop table sale_list;

create table sale_list(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
) 
partition by list(region_id)
( partition p_west    values ('CA','WA','OR'),
  partition p_midwest values ('ND', 'MN'),
  partition p_north   values ('ME', 'PA'),
  partition p_south   values ('TX'),
  partition p_null    values(null),
  partition p_default values (default)
);


insert into sale_list values (1, sysdate,    'CA', 1);
insert into sale_list values (2, sysdate,    'ND', 1);
insert into sale_list values (3, sysdate+10, 'TX', 1);
insert into sale_list values (4, sysdate-1,  'XX', 1);
insert into sale_list values (5, sysdate+1,  null, 1);
commit;

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'SALE_LIST'); 
end;
/
 
-- смотрим какие секции были созданы
select t.* from user_tab_partitions t where t.table_name = 'SALE_LIST';


select * from sale_list partition (p_default);
