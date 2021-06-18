---- Составное секционирование. Hash - Hash

drop table sale_hash_hash;

create table sale_hash_hash(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
)
partition by hash(sale_id) -- первый уровень. hash по "ID продажи"
subpartition by hash (sale_date) -- второй уровень. hash по "ID клиента"
subpartitions 2
partitions 4;

insert into sale_hash_hash values (1, sysdate, 'CA', 100);
insert into sale_hash_hash values (2, sysdate, 'TX', 200);
insert into sale_hash_hash values (3, sysdate, 'NY', 300);
insert into sale_hash_hash values (4, sysdate, 'WA', 400);
insert into sale_hash_hash values (5, sysdate, null, 500);
insert into sale_hash_hash values (6, sysdate, null, 600);
commit;

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_hash_hash'); 
end;
/

select * from user_tab_partitions t where t.table_name = 'SALE_HASH_HASH';
select * from user_tab_subpartitions t where t.table_name = 'SALE_HASH_HASH' order by t.partition_position, t.subpartition_position;

select * from sale_hash_hash subpartition (SYS_SUBP7912);
