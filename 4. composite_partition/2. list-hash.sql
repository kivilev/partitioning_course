/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Составное секционирование
	
  Описание скрипта: пример создания List - Hash секционированной таблицы
*/

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

select * from user_tab_partitions t where t.table_name = 'SALE_LIST_HASH';
select * from user_tab_subpartitions t where t.table_name = 'SALE_LIST_HASH' order by t.partition_position, t.subpartition_position;
select * from user_part_tables t where t.table_name = 'SALE_LIST_HASH';


-- вставка данных
insert into sale_list_hash values (1, sysdate, 'CA', 100);-- 1
insert into sale_list_hash values (2, sysdate, 'TX', 200);-- 2
insert into sale_list_hash values (3, sysdate, 'NY', 300);-- 3
insert into sale_list_hash values (4, sysdate, null, 500);-- 4
commit;


-- 1
select * from sale_list_hash partition (p_west);
select * from sale_list_hash partition for('OR');

-- 2
select * from sale_list_hash subpartition for('TX', 200);

-- правильное обращение 
select * from sale_list_hash t where t.region_id = 'TX' and t.customer_id = 200;

