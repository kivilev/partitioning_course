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

create table sale_external (
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
partition by list (region_id)
(
  partition p_CA values ('CA') location ('sale_CA.csv'),
  partition p_NY values ('NY') default directory data4load_dir location ('sale_NY.csv')
);

select * from sale_external t;

begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_external'); 
end;
/

select * from user_part_tables pt where pt.table_name = 'SALE_EXTERNAL';
select * from user_tab_partitions t where t.table_name = 'SALE_EXTERNAL';

select * from sale_external t;
-- задействован 1 файл
select * from sale_external t where t.region_id = 'CA';


