/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Одноуровневое секционирование.  List-секционирование
	
  Описание скрипта: пример создания таблицы с list-секционированием
*/

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

-- вставка данных
insert into sale_list values (1, sysdate,    'CA', 1);--1
insert into sale_list values (2, sysdate,    'ND', 1);--2
insert into sale_list values (3, sysdate+10, 'TX', 1);--3
insert into sale_list values (4, sysdate-1,  'XX', 1);--4
insert into sale_list values (5, sysdate+1,  null, 1);--5
commit;

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'SALE_LIST'); 
end;
/
 
-- секции таблицы
select t.num_rows, t.* from user_tab_partitions t where t.table_name = 'SALE_LIST';

-- обращение
select * from sale_list t where t.region_id = 'ND';--1
select * from sale_list partition (p_west);--2 (в промышленных решения так не используют)
