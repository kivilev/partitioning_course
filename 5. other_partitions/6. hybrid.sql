/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Другие типы секционирования. Гибридное секционирование
	
  Описание скрипта: пример создания таблицы с гибридным секционированием
*/

drop table sale_hybrid;

create table sale_hybrid (
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null,
  source       varchar2(20 char)
)
external partition attributes (type oracle_loader
  default directory data4load_dir
  access parameters
  ( records delimited by newline    
    nobadfile
    logfile data4load_dir:'sale_error_h.log'
    fields csv with embedded
    terminated by ";" optionally enclosed by '"'
    missing field values are null
    reject rows with all null fields
    date_format date mask "YYYY-MM-DD HH24:MI:SS"
  )
)
reject limit unlimited
partition by range (sale_date)
(
 partition sales_min values less than (date'2019-01-01'),
 partition sales_2019 values less than (date'2020-01-01') external location ('sales_2019.csv'),
 partition sales_2020 values less than (date'2021-01-01') external location ('sales_2020.csv'),
 partition sales_2021 values less than (date'2022-01-01') external location ('sales_2021.csv'),
 partition sales_2022 values less than (date'2023-01-01')
);

begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_hybrid'); 
end;
/

select * from user_part_tables pt where pt.table_name = 'SALE_HYBRID';
select t.read_only, t.tablespace_name, t.num_rows, t.* 
  from user_tab_partitions t where t.table_name = 'SALE_HYBRID';

-- вставка данных
insert into sale_hybrid(sale_id, sale_date, region_id, customer_id, source) values(7777777, date'2022-02-19', 'CA', 101, 'db'); -- 1
insert into sale_hybrid(sale_id, sale_date, region_id, customer_id, source) values(99999, date'2019-02-19', 'CA', 101, 'db'); -- 2
insert into sale_hybrid(sale_id, sale_date, region_id, customer_id, source) values(100002, date'2023-02-19', 'NY', 101, 'db'); -- 3
insert into sale_hybrid(sale_id, sale_date, region_id, customer_id, source) values(1, date'2018-02-19', 'NY', 101, 'db'); -- 4

-- получение данных
select * from sale_hybrid t order by t.sale_date; -- 1 (все секции)
select * from sale_hybrid t where t.region_id = 'CA'; -- 2 (все секции, т.к. не задан ключ секционирования)
select * from sale_hybrid t where t.sale_date >= date'2020-01-01' and t.sale_date < date'2021-01-01'; -- 3 (1 секция, задан ключ секционирования)
select * from sale_hybrid t where t.sale_date = to_date('04.04.2019 4:04:04', 'dd.mm.YYYY hh24:mi:ss'); -- 4 (1 секция, задан ключ секционирования)
select * from sale_hybrid partition (sales_2021) t; -- 5 (1 секция, задали жетско имя, так делать не надо!)


