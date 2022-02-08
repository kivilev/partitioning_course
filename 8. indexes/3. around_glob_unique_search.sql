/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Индексы
	
  Описание скрипта: примеры обхода глобальных уникальных индексов - БЫСТРЫЙ ПОИСК
  
  Для демонстрации примеров требуется установить API для генерации time-based GUID (не для пром использования)
  Требуемая обвязка находится в папке: /timebased_guid
  
  Проверка работоспособности:
    select guid_pack.get_new_guid(to_date('14.07.1983 14:42:40','dd.mm.YYYY hh24:mi:ss')) from dual;
    select guid_pack.get_date_from_guid('F1022C5D49A411C1BBBA435F05629822') from dual; 
*/

drop table credit_application;
drop sequence credit_application_seq;

-- Таблица с "Заявка на кредит"
create table credit_application
(
  ca_id             number(30) not null,
  ca_creation_date  date not null,
  ida_external_id   VARCHAR2(100 CHAR) not null
  -- другие поля
)
partition by range (ca_creation_date)
interval (interval '1' month)
(
partition pmin values less than (date '2005-01-01')
);

create sequence credit_application_seq;

-- вставка
insert into credit_application 
select credit_application_seq.nextval, sysdate + level, guid_pack.get_new_guid(sysdate + level)
  from dual connect by level <= 1000;  
commit; 

-- посмотрим данные
select t.*, guid_pack.get_date_from_guid(t.ida_external_id) extract_date 
  from credit_application t;

-- локальный уникальный индекс
create unique index credit_application_external_id_unq on credit_application(ida_external_id, ca_creation_date) local;

call dbms_stats.gather_table_stats(ownname => user, tabname => 'credit_application');-- стата

-- см план -> unique scan
select *
  from credit_application ca
 where ca.ca_creation_date = guid_pack.get_date_from_guid('A09181DCDCD411EBB94677F4DF75C5D5')
   and ca.ida_external_id = 'A09181DCDCD411EBB94677F4DF75C5D5';

