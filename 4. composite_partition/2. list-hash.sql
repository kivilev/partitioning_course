---- Составное секционирование. List - Hash

drop table sale_list_hash;

create table sale_list_hash(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
)
partition by list(region_id) -- первый уровень. list по "региону"
subpartition by hash (customer_id)-- второй уровень. hash по "ID покупателя"
subpartitions 4
(
  partition p_west    values ('CA','WA','OR'),
  partition p_south   values ('TX'),
  partition p_null    values(null),
  partition p_default values (default)
);

insert into sale_list_hash values (1, sysdate, 'CA', 100);
insert into sale_list_hash values (2, sysdate, 'TX', 200);
insert into sale_list_hash values (3, sysdate, 'NY', 300);
insert into sale_list_hash values (4, sysdate, 'WA', 400);
insert into sale_list_hash values (5, sysdate, null, 500);
insert into sale_list_hash values (6, sysdate, null, 600);
commit;

-- Сбор статистики
call dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_list_hash');


select * from user_tab_partitions t where t.table_name = 'SALE_LIST_HASH';
select * from user_tab_subpartitions t where t.table_name = 'SALE_LIST_HASH' and t.partition_name = 'P_WEST';


select * from sale_list_hash partition (p_west);
select * from sale_list_hash partition for('CA');

select * from sale_list_hash subpartition (SYS_SUBP7912);
select * from sale_list_hash subpartition for('CA', 400);


