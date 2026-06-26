/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://backend-pro.ru, https://www.youtube.com/@pro_backendD)

  Лекция. Операции с секциями
  
  Описание скрипта: преобразование обычной таблицы в секционированну. Вариант с dbms_redefinition.
  
  sys: grant create any table     to part;
       grant alter any table      to part;
       grant drop any table       to part;
       grant lock any table       to part;
       grant select any table     to part;

       -- Для выполнения самого пакета
       grant execute on dbms_redefinition to part;

       -- Для индексов
       grant create any index     to part;
       grant alter any index      to part;
       grant drop any index       to part;

       -- Для работы с ограничениями и триггерами (если есть)
       grant create any trigger   to part;
       grant alter any trigger    to part;
*/

-- Обычная таблицы
drop table sale;
create table sale
(
  sale_id     number(30) not null,
  sale_date   date not null,
  region_id   char(2 char) not null,
  customer_id number(30) not null
);

alter table sale add constraint sale_pk primary key (sale_id); --> Global index
create index sale_customer_id_i on sale (customer_id); --> Local index

insert into sale
select level,
       date '2026-01-01' + level,
       chr(65 + mod(level, 26)) || chr(65 + mod(level * 3, 26)),
       trunc(dbms_random.value(1, 1000))
from dual
connect by level <= 100;
commit;


-- 2. Проверка возможности переопределения
begin
  dbms_redefinition.can_redef_table(
    uname        => user,
    tname        => 'SALE',
    options_flag => dbms_redefinition.cons_use_pk
  );
  dbms_output.put_line('Таблица может быть переопределена.');
end;
/

-- 3. Промежуточная (interim) таблица - целевая структура
create table sale_interim
(
  sale_id     number(30) not null,
  sale_date   date not null,
  region_id   char(2 char) not null,
  customer_id number(30) not null
)
partition by range (sale_date)
interval (numtoyminterval(1, 'MONTH'))
(
  partition p_initial values less than (date '2026-01-01')
);

-- Глобальный уникальный индекс (PK)
alter table sale_interim add constraint sale_interim_pk primary key (sale_id);

-- Локальный индекс
create index sale_interim_customer_id_i on sale_interim (customer_id) local;


-- 4. Запуск переопределения (данные уже скопировались)
begin
  dbms_redefinition.start_redef_table(
    uname        => user,
    orig_table   => 'SALE',
    int_table    => 'SALE_INTERIM',
    options_flag => dbms_redefinition.cons_use_pk
  );
  dbms_output.put_line('start_redef_table - OK');
end;
/

-- 100 строк в новой таблице
select count(1) from sale_interim; -- DML выполнять нельзя

-- вставим новую строку в исходную. 
insert into sale values(1000, sysdate, 'XX', trunc(dbms_random.value(1, 1000)));
commit;

select * from sale_interim where sale_id = 1000; -- её нет в новой


-- 5. Синхронизация (опционально, при активном DML на SALE)
begin
  dbms_redefinition.sync_interim_table(
    uname      => user,
    orig_table => 'SALE',
    int_table  => 'SALE_INTERIM'
  );
  dbms_output.put_line('sync_interim_table - OK');
end;
/

-- после синхронизации она появилась
select * from sale_interim where sale_id = 1000;


-- 6. Завершение переопределения
begin
  dbms_redefinition.finish_redef_table(
    uname      => user,
    orig_table => 'SALE',
    int_table  => 'SALE_INTERIM'
  );
  dbms_output.put_line('finish_redef_table - OK');
end;
/

-- 7. Очистка промежуточной таблицы
drop table sale_interim purge;


-- Секции таблицы
select partition_name, high_value, num_rows 
  from user_tab_partitions
 where table_name = 'SALE'
order by partition_position;

-- Индексы: тип и статус
select index_name,
       partitioned,
       uniqueness,
       status
from user_indexes
where table_name = 'SALE'
order by index_name;

-- Локальность секционированных индексов
select index_name, locality
  from user_part_indexes
 where table_name = 'SALE';
