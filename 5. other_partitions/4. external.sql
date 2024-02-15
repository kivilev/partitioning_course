/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Другие типы секционирования. Секционирование внешних таблиц
	
  Описание скрипта: пример создания внешней таблицы с секционированием
  
  Подготовительные действия:
	-- 0. На сервере СУБД
	mkdir /opt/oracle/oradata/data4load
  chown oracle:oinstall /opt/oracle/oradata/data4load
	chmod 700 /opt/oracle/oradata/data4load
	копируем файлы в эту директорию из каталога data4load репозитория

	-- 1. Создаем директорию в СУБД по привелегированным пользователем
	create or replace directory data4load_dir as '/opt/oracle/oradata/data4load';
  create or replace directory data4load_dir as '/opt/oracle/oradata/XE/XEPDB1/data4load';

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

call dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_external');

select * from user_tab_partitions t where t.table_name = 'SALE_EXTERNAL';

-- получим данные
select * from sale_external t; -- 1 (просмотр всех файлов)
select * from sale_external t where t.region_id = 'CA'; -- 2 (просмотр 1-го файла)
select * from sale_external partition (p_CA) t; -- 3 (просмотр 1-го файла), так не надо делать, используйте (2)


