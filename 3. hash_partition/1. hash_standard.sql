/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://backend-pro.ru, https://www.youtube.com/@pro_backendD)

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
partition by hash(customer_id)
partitions 4;

-- Вставка 16К записей
insert into sale_hash 
select level, sysdate+level, 'NY', level 
 from dual connect by level <= 16000;
commit; 

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_hash'); 
end;
/

select * from user_part_tables pt where pt.table_name = 'SALE_HASH';
 
-- смотрим какие секции были созданы
select t.num_rows, t.* from user_tab_partitions t where t.table_name = 'SALE_HASH';


select * from sale_hash t where t.customer_id = 1000; -- 1
select * from sale_hash partition (SYS_P13834); -- 2. подставляем секцию из user_tab_partitions

select sale_id, ora_hash(t.sale_id, 3), t.*
  from sale_hash t;

  
select ora_hash(t.sale_id, 3) part_num, count(*)
  from sale_hash t
 group by ora_hash(t.sale_id, 3);
 
