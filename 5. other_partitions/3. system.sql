/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Другие типы секционирования. Системное секционирование
	
  Описание скрипта: пример создания таблицы с системным секционированием  
*/

drop table sale_system;

create table sale_system (
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
)
partition by system (
  partition p1,
  partition p2,
  partition p3
);

insert into sale_system partition (p1) values (1, sysdate, 'CA', 101);
insert into sale_system partition (p2) values (2, sysdate + 1, 'NY', 102);
insert into sale_system partition (p3) values (3, sysdate + 2, 'NY', 102);
commit;

-- Сбор статистики
call dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_system'); 


select * from user_part_tables pt where pt.table_name = 'SALE_SYSTEM';
select * from user_tab_partitions t where t.table_name = 'SALE_SYSTEM';
  
select * from sale_system;
select * from sale_system partition (p1);
select * from sale_system partition (p2);
select * from sale_system partition (p3);
