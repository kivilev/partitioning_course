---- Пример List-секционировани с автоматическим нарезанием

drop table sale_list_auto;

create table sale_list_auto(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
) 
partition by list(region_id)
automatic
( partition p_ca    values ('CA'),
  partition p_null    values(null)
);


insert into sale_list_auto values (1, sysdate,    'CA', 1);
insert into sale_list_auto values (2, sysdate,    'ND', 1);
insert into sale_list_auto values (3, sysdate+10, 'TX', 1);
insert into sale_list_auto values (4, sysdate-1,  'XX', 1);
insert into sale_list_auto values (5, sysdate+1,  null, 1);
commit;

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_list_auto'); 
end;
/
 
-- смотрим какие секции были созданы
select t.* from user_tab_partitions t where t.table_name = 'SALE_LIST_AUTO';


select * from sale_list_auto partition (SYS_P7708);
