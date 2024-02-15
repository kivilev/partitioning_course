/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Дополнительные возможности. Секционирование по нескольким колонкам
	
  Описание скрипта: пример range-секционирования таблицы по нескольким колонкам
*/


drop table sale_part_2cols;

create table sale_part_2cols(
  sale_id         number(30) not null,
  sale_date       date not null,
  sale_date_year  number, -- as (extract(year from sale_date)),
  sale_date_month number, -- as (extract(month from sale_date)),
  region_id       char(2 char) not null,
  customer_id     number(30) not null
)
partition by range(sale_date_year, sale_date_month)
(
  partition p_less_2021 values less than (2021, 1),
  partition p_feb_2021 values less than (2021, 2),
  partition p_mar_2021 values less than (2021, 3),
  partition p_max values less than (maxvalue, 0)
);

insert into sale_part_2cols(sale_id, sale_date, sale_date_year, sale_date_month, region_id, customer_id) values (1, date'2020-01-01', 2020, 1, 'CA', 1);
insert into sale_part_2cols(sale_id, sale_date, sale_date_year, sale_date_month, region_id, customer_id) values (2, date'2021-02-01', 2021, 2, 'CA', 1);
insert into sale_part_2cols(sale_id, sale_date, sale_date_year, sale_date_month, region_id, customer_id) values (3, date'2021-03-01', 2021, 3, 'CA', 1);
insert into sale_part_2cols(sale_id, sale_date, sale_date_year, sale_date_month, region_id, customer_id) values (4, date'2021-05-01', 2021, 5, 'NY', 1);
insert into sale_part_2cols(sale_id, sale_date, sale_date_year, sale_date_month, region_id, customer_id) values (5, date'2021-06-01', 2021, 6, 'NY', 1);
commit;


-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_part_2cols'); 
end;
/

select * from user_part_tables pt where pt.table_name = 'SALE_PART_2COLS';
select * from user_tab_partitions t where t.table_name = 'SALE_PART_2COLS';

select * from sale_part_2cols partition (p_less_2021);

select * from sale_part_2cols t where t.sale_date_year = 2020 and t.sale_date_month = 1;

