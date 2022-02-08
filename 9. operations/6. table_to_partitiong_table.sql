/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Операции с секциями
	
  Описание скрипта: преобразование обычной таблицы в секционированную
    Это не единственный вариант, см. так же dbms_redefinition.
*/

drop table sale_heap;

-- обычная таблица
create table sale_heap(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
);

-- вставка данных
insert into sale_heap
select level, sysdate+level, 'CA', level+100 
  from dual connect by level <= 10;
commit;

-- индексы
create unique index sale_heap_sale_id_unq on sale_heap(sale_id);
create index sale_heap_customer_id_idx on sale_heap(customer_id);
-- create unique index sale_heap_customer_id_idx on sale_heap(customer_id); => не получится без ключа секционирования в локальный уникальный

alter table sale_heap add constraint sale_heap_region_id_chk check (region_id in ('CA', 'NY'));

-- данные по таблице
select * from user_tables t where t.table_name = 'SALE_HEAP';
select * from user_part_tables t where t.table_name = 'SALE_HEAP';
select * from user_tab_partitions t where t.table_name = 'SALE_HEAP';

-- преобразовываем таблицу в секционированную
alter table sale_heap modify
partition by range (sale_date) interval (interval '1' day) -- Interval 1 день
(
 partition pmin values less than (date'2021-06-01') -- стартовая секция
)
online update indexes
(
  sale_heap_customer_id_idx local, -- будет локальный
  sale_heap_sale_id_unq global -- будет глобальным уникальным
);

-- проверяем
select * from user_part_tables t where t.table_name = 'SALE_HEAP';
select * from user_tab_partitions t where t.table_name = 'SALE_HEAP';
select * from user_indexes t where t.table_name = 'SALE_HEAP';
select * from user_ind_partitions t where t.index_name = 'SALE_HEAP_CUSTOMER_ID_IDX';



-- вставка данных в другой сессии блокирует изменение несмотря на online
insert into sale_heap
select level+100, sysdate+level, 'CA', level+100 
  from dual connect by level <= 10;
