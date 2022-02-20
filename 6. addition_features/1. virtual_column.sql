/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Дополнительные возможности. Секционирование по виртуальной колонки
	
  Описание скрипта: пример list-секционирования таблицы по виртуальной колонки
*/

drop table sale_virt_list;

create table sale_virt_list(
  sale_id         number(30) not null,
  sale_date       date not null,  
  region_id       char(2 char) not null,
  customer_id     number(30) not null,
  sale_date_month varchar2(20 char) as (upper(trim(to_char(sale_date, 'month', 'nls_date_language = american'))))
)
partition by list(sale_date_month)
automatic
(
  partition p_january values ('JANUARY'),
  partition p_february values ('FEBRUARY'),
  partition p_march values ('MARCH')
);

insert into sale_virt_list(sale_id, sale_date, region_id, customer_id) values (1, date'2021-01-01', 'CA', 1); --1
insert into sale_virt_list(sale_id, sale_date, region_id, customer_id) values (2, date'2021-02-01', 'CA', 1); --2
insert into sale_virt_list(sale_id, sale_date, region_id, customer_id) values (3, date'2021-03-01', 'CA', 1); --3
insert into sale_virt_list(sale_id, sale_date, region_id, customer_id) values (4, date'2021-05-01', 'NY', 1); --4
insert into sale_virt_list(sale_id, sale_date, region_id, customer_id) values (4, date'2021-06-01', 'NY', 1); --5
commit;

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_virt_list'); 
end;
/

select * from user_part_tables pt where pt.table_name = 'SALE_VIRT_LIST';
select t.num_rows, t.* from user_tab_partitions t where t.table_name = 'SALE_VIRT_LIST';


select * from sale_virt_list;

select * from sale_virt_list t where t.sale_date_month = 'MAY'; -- 1 (будет выбрана 1 секция)
select * from sale_virt_list t where t.sale_date = date'2021-05-01'; -- 2 (будут выбраны все секции)

select * from sale_virt_list t where t.sale_date_month = 'MAY' and t.sale_date = date'2021-05-01'; -- 3 (будет выбрана 1 секция)
select * from sale_virt_list t 
 where t.sale_date_month = (upper(trim(to_char(date'2021-05-01', 'month', 'nls_date_language = american'))))
   and t.sale_date = date'2021-05-01'; -- 4 аналогичный вариант

 

