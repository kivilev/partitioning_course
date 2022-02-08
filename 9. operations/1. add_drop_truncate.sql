/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Операции с секциями
	
  Описание скрипта: примеры создания, удаления, усечения секций
*/

---- List
drop table sale_list;

create table sale_list(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
) 
partition by list(region_id)
( partition p_ca    values ('CA'),
  partition p_nd values ('ND'),
  partition p_me   values ('ME')
  --,partition p_default values (default)  -- с Default не получится, надо делать SPLIT
);
insert into sale_list values (2, sysdate, 'CA', 102);
commit;

-- add
insert into sale_list values (1, sysdate, 'NY', 101);-- ORA-14400: inserted partition key does not map to any partition

alter table sale_list add partition p_ny values ('NY');-- Создадим секцию

insert into sale_list values (1, sysdate, 'NY', 101); -- Повторим
commit;
select * from sale_list;

select * from user_tab_partitions t where t.table_name = 'SALE_LIST';-- см. секции


-- truncate
alter table sale_list truncate partition p_ny;-- отсекаем данные
alter table sale_list truncate partition for('NY'); -- 2-й способ. удаление по ссылке

select * from sale_list;

-- drop
alter table sale_list drop partition p_ny; -- 1-й способ. Удаление по имени
alter table sale_list drop partition for('NY'); -- 2-й способ. удаление по ссылке




---- Interval
drop table sales_interval_1d;

create table sales_interval_1d(
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

-- add
lock table sales_interval_1d partition for(date'2020-01-01') in share mode;-- 1й способ
lock table sales_interval_1d partition for(date'2020-01-02') in share mode;
commit;

insert into sales_interval_1d values (1, date'2020-01-03', 'CA', 101); -- 2й способ
insert into sales_interval_1d values (2, date'2020-01-04', 'CA', 101);
rollback;-- отмена вставки

select * from user_tab_partitions t where t.table_name = 'SALES_INTERVAL_1D';-- см. секции
select * from sales_interval_1d;-- данных нет

-- drop
alter table sales_interval_1d drop partition SYS_P441; -- удаление по имени
alter table sales_interval_1d drop partition for(date'2020-01-02');-- удаление по ссылке на значение
alter table sales_interval_1d drop partition for(date'2020-01-03'), for(date'2020-01-04');-- удаление сразу двух


