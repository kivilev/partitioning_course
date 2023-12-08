/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Запросы к секционированным таблицами
	
  Описание скрипта: пример нескольких планов запросов с range-секционированной таблицей
*/

drop table sale_range;

create table sale_range(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date) -- секционируем по дате
interval(interval '1' day) -- интервал 1 день
(
partition pmin values less than (date'2021-01-01') -- одна секция за любой период
);

-- 100 строк
insert into sale_range(sale_id, sale_date, region_id, customer_id)
select level, date'2021-01-01' + level -1, 'CA', level*100 
  from dual connect by level <= 100;
commit;

-- стата
call dbms_stats.gather_table_stats(ownname => user, tabname => 'SALE_RANGE');

select count(*) from user_tab_partitions t where t.table_name = 'SALE_RANGE';


-- план запроса
select * from sale_range s where s.sale_date = date'2020-01-26';-- нет данных

select * from sale_range s where s.sale_date = date'2021-01-28';-- 1 секция

select * from sale_range s where s.sale_date in(date'2021-01-28', date'2021-01-29');-- 2 секции

select * from sale_range s where s.sale_date >= date'2021-01-28';-- диапазон от до 1М
