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

drop table sale_external_composite;

create table sale_external_composite (
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null  
)
organization external
(type oracle_loader
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
PARTITION BY LIST (region_id)
SUBPARTITION BY RANGE (sale_date)
(
  partition p_ca values ('CA') 
  ( subpartition p_ca_2011 values less than (date'2012-01-01') location ('sale_CA.csv'),
    subpartition p_ca_2012 values less than (date'2013-01-01') location ('sale_CA_2012.csv')
  ),
  partition p_ny values ('NY') 
  ( subpartition p_ny_2011 values less than (date'2012-01-01') location ('sale_NY.csv'),
    subpartition p_ny_2012 values less than (date'2013-01-01') location ('sale_NY_2012.csv')
  )
);

select * from sale_external_composite t;

begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_external_composite'); 
end;
/

select * from user_part_tables pt where pt.table_name = 'SALE_EXTERNAL_COMPOSITE';
select * from user_tab_partitions t where t.table_name = 'SALE_EXTERNAL_COMPOSITE';
select * from user_tab_subpartitions t where t.table_name = 'SALE_EXTERNAL_COMPOSITE' order by t.partition_position, t.subpartition_position;

-- задействовано 2 файла
select * from sale_external_composite t where t.region_id = 'CA';

-- задействован 1 файл
select *
  from sale_external_composite t
 where t.region_id = 'NY'
   and t.sale_date between date '2012-01-01' and date '2012-12-31';

