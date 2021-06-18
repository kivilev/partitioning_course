------ Секционирование Внешних таблиц

/*
----- Выполняется один раз
mkdir /opt/oracle/oradata/data4load
chmod 777 /opt/oracle/oradata/data4load

-- 1. Создаем директорию
create or replace directory data4load_dir as '/opt/oracle/oradata/data4load';

-- 2. Даем гранты на чтение
grant read, write on directory data4load_dir to hr;
*/

drop table sale_external;

create table sale_hybrid (
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null  
)
external partition attributes (type oracle_loader
  default directory data4load_dir
  access parameters
  ( records delimited by newline    
    nobadfile
    logfile data4load_dir:'sale_error.log'
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
 partition sales_2014 values less than (date'01-01-2015') external location ('sales2014.csv'),
 partition sales_2015 values less than (date'01-01-2016') external location ('sales2015.csv'),
 partition sales_2016 values less than (date'01-01-2017') external location ('sales2016.csv'),
 partition sales_2017 values less than (date'01-01-2018') external location ('sales2017.txt'),
 partition sales_2018 values less than (date'01-01-2018'),
 partition sales_2018 values less than (date'01-01-2019'),
 partition sales_2019 values less than (date'01-01-2020'),
 partition sales_2020 values less than (date'01-01-2021'),
 partition sales_2021 values less than (date'01-01-2022')
);

select * from sale_hybrid t;

begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_hybrid'); 
end;
/

select * from user_part_tables pt where pt.table_name = 'SALE_HYBRID';
select * from user_tab_partitions t where t.table_name = 'SALE_HYBRID';

-- задействован 1 файл
select * from sale_hybrid t where t.region_id = 'sales_2014'


