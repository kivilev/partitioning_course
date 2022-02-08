/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Операции с секциями
	
  Описание скрипта: обслуживание индексов
*/


drop table sale;

create table sale(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date) -- секционируем по дате
interval(numtodsinterval(1,'DAY')) -- интервал 1 день
(
partition pmin values less than (date '2005-01-01') -- одна секция за любой период
);

-- Глобальный уникальный
create unique index sale_sale_id_glob_idx on sale(sale_id);
-- Локальный 
create unique index sale_customer_id_loc_idx on sale(customer_id, sale_date) local;

insert into sale values (1, date'2021-01-05', 'CA', 101);
insert into sale values (2, date'2021-01-06', 'CA', 102);
insert into sale values (3, date'2021-01-07', 'CA', 103);
insert into sale values (4, date'2021-02-08', 'NY', 104);
commit;

call dbms_stats.gather_table_stats(ownname => user, tabname => 'sale');

-- По глобальному
select * from sale t where t.sale_id = 2;
-- По локальному
select * from sale t where t.sale_date = date'2021-01-06' and t.customer_id = 102;

-- Статусы индексов - VALID, USABLE
select t.status, t.* from user_indexes t where t.index_name = 'SALE_SALE_ID_GLOB_IDX';
select t.status, t.* from user_ind_partitions t where t.index_name = 'SALE_CUSTOMER_ID_LOC_IDX'; 
select * from user_tab_partitions t where t.table_name = 'SALE' order by t.partition_position;

-- Выполим усечение одной из секций
alter table sale truncate partition SYS_P2013;-- приведен к UNUSABLE индекса
alter table sale truncate partition SYS_P2018 update global indexes; -- не приведет к UNUSABLE индекса

-- Посмотрим статусы еще раз. Глобальный - UNUSABLE, Локальный - USABLE
select t.status, t.* from user_indexes t where t.index_name = 'SALE_SALE_ID_GLOB_IDX';
select t.status, t.* from user_ind_partitions t where t.index_name = 'SALE_CUSTOMER_ID_LOC_IDX'; 
select * from user_tab_partitions t where t.table_name = 'SALE' order by t.partition_position;

insert into sale values (11, date'2021-01-05', 'CA', 100);-- Попробуйем сделать вставку
select * from sale t where t.sale_id = 2;-- select выполняется, но индекс не используется

alter index sale_sale_id_glob_idx rebuild; -- надо перестроить тогда будет ок.

-- Выполим усечение одной из секций с ONLINE-перестроением индекса
alter table sale truncate partition sys_p691 update global indexes ;

-- проверим статусы -> все ок
alter table sales drop partition dec98 update indexes;


