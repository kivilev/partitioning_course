/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Операции с секциями
	
  Описание скрипта: пример обмена секциями
*/

---- 1. Создадим секционированную табличку
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

create unique index sale_sale_id_glob_idx on sale(sale_id);
create index sale_customer_id_loc_idx on sale(customer_id) local;
alter table sale add constraint sale_region_chk check (region_id in ('NY', 'CA', 'LA'));

insert into sale values (1, date'2021-01-05', 'CA', 101);
insert into sale values (2, date'2021-01-06', 'CA', 102);
insert into sale values (3, date'2021-01-07', 'CA', 103);-- будем меняться с этой секцией
insert into sale values (4, date'2021-02-08', 'NY', 104);
commit;

call dbms_stats.gather_table_stats(ownname => user, tabname => 'sale');

-- смотрим какие секции были созданы
select * from user_tab_partitions t where t.table_name = 'SALE';
select * from user_part_tables t where t.table_name = 'SALE';
select * from user_indexes t where t.table_name = 'SALE';
select t.status, t.* from user_ind_partitions t where t.index_name = 'SALE_CUSTOMER_ID_LOC_IDX';

---- 2. Создадим обычную таблицу по образу секционированной
drop table sale_stage;
create table sale_stage for exchange with table sale;

-- смотрим определение таблички sale_stage => check, index не создались

-- добавляем
alter table sale_stage add constraint sale_stage_region_chk check (region_id in ('NY', 'CA', 'LA'));
create index sale_stage_customer_id on sale_stage(customer_id);--без local, т.к. это обычная таблица

insert into sale_stage values (300, date'2021-01-07', 'CA', 100003);
commit;


---- 3. Обмен секциями
-- alter table sale exchange partition SYS_P503 with table sale_stage;
alter table sale exchange partition for (date'2021-01-07')
 with table sale_stage including indexes with validation;

select * from sale_stage;
select * from sale;
select * from sale partition for (date'2021-01-07');

-- можно выполнить еще раз и данные окажутся на старом месте =)



---- 4. Обмен секциями без валидации и с некорректными данными
insert into sale_stage values (6666, date'2021-01-12', 'CA', 666666); -- строка с "неверной" датой
commit;

select * from sale_stage;

-- С валидацией => ORA-14099: all rows in table do not qualify for specified partition 
alter table sale exchange partition for (date'2021-01-07')
 with table sale_stage including indexes with validation;

-- Без валидации => OK, но теперь битые данные в секционированной таблице
alter table sale exchange partition for (date'2021-01-07')
 with table sale_stage including indexes without validation;

-- проверяем относится ли строка к секции
select s.*
      ,ora_partition_validation(s.rowid) is_valid_row
  from sale partition
   for(date '2021-01-07') s;



---- 5. Без включения индекса
alter table sale exchange partition for (date'2021-01-07')
 with table sale_stage excluding indexes with validation;

-- Локальный индекс секции, которой поменяли в UNUSABLE
select t.status, t.* from user_ind_partitions t where t.index_name = 'SALE_CUSTOMER_ID_LOC_IDX'; 

-- Глобальный индекс UNUSABLE 
select t.status, t.* from user_indexes t where t.table_name = 'SALE';


