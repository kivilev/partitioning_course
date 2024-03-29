﻿/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Другие типы секционирования. Секционирование внешних таблиц
	
  Описание скрипта: пример создания внешней таблицы с двухуровневым секционированием (list-range)
  
  Подготовительные действия:
	-- 0. На сервере СУБД
	mkdir /opt/oracle/oradata/data4load
  chown oracle:oinstall /opt/oracle/oradata/data4load
	chmod 700 /opt/oracle/oradata/data4load
	копируем файлы в эту директорию из каталога data4load репозитория

	-- 1. Создаем директорию в СУБД по привелегированным пользователем
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
partition by list (region_id)
subpartition by range (sale_date)
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

call dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_external_composite');

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

