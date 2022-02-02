---- Составное секционирование. Hash - Hash

drop table sale_hash_hash;

create table sale_hash_hash(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
)
partition by hash(sale_id) -- первый уровень. hash по "ID продажи"
subpartition by hash (customer_id) -- второй уровень. hash по "ID клиента"
subpartitions 2
partitions 4;

select * from user_tab_partitions t where t.table_name = 'SALE_HASH_HASH';
select * from user_tab_subpartitions t where t.table_name = 'SALE_HASH_HASH' order by t.partition_position, t.subpartition_position;
select * from user_part_tables t where t.table_name = 'SALE_HASH_HASH';

-- Данные 
insert into sale_hash_hash values (1, sysdate, 'CA', 100);-- 1
insert into sale_hash_hash values (2, sysdate, 'TX', 200);-- 2
insert into sale_hash_hash values (3, sysdate, 'NY', 300);-- 3
insert into sale_hash_hash values (4, sysdate, null, 600);-- 4
commit;


-- правильное обращение
select * from sale_hash_hash t where t.sale_id = 1 and t.customer_id = 100;
