/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Одноуровневое секционирование. Hash-секционирование
	
  Описание скрипта: пример создания hash-секционированной таблицы
*/

drop table sale_hash;

create table sale_hash(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
) 
partition by hash(sale_id)
( partition p1 
, partition p2 
, partition p3 
, partition p4 
);

-- Вставка 10К записей
insert into sale_hash 
select level, sysdate+level, 'NY', level 
 from dual connect by level <= 10000;
commit; 

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_hash'); 
end;
/
 
-- смотрим какие секции были созданы
select t.* from user_tab_partitions t where t.table_name = 'SALE_HASH';


select * from sale_hash partition (p4);
