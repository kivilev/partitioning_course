/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Операции с секциями
	
  Описание скрипта: примеры создания, удаления, усечения секций
*/

---- List
drop table sale_list;

create table sale_list(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
) 
partition by list(region_id)
( partition p_ca    values ('CA'),
  partition p_nd values ('ND'),
  partition p_me   values ('ME')
  --,partition p_default values (default)  -- с Default не получится, надо делать SPLIT
);
insert into sale_list values (2, sysdate, 'CA', 102);
commit;

-- add
insert into sale_list values (1, sysdate, 'NY', 101);-- ORA-14400: inserted partition key does not map to any partition

alter table sale_list add partition p_ny values ('NY');-- Создадим секцию

insert into sale_list values (1, sysdate, 'NY', 101); -- Повторим
commit;
select * from sale_list;

select * from user_tab_partitions t where t.table_name = 'SALE_LIST';-- см. секции


-- truncate
alter table sale_list truncate partition p_ny;-- отсекаем данные
alter table sale_list truncate partition for('NY'); -- 2-й способ. удаление по ссылке

select * from sale_list;

-- drop
alter table sale_list drop partition p_ny; -- 1-й способ. Удаление по имени
alter table sale_list drop partition for('NY'); -- 2-й способ. удаление по ссылке


---- Interval
drop table sales_interval_1d;

create table sales_interval_1d(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date) -- секционируем по дате
interval(numtodsinterval(1,'DAY')) -- интервал 1 день
(
partition pmin values less than (date '2005-01-01') -- одна секция за любой период
);

-- add
lock table sales_interval_1d partition for(date'2020-01-01') in share mode;-- 1й способ
lock table sales_interval_1d partition for(date'2020-01-02') in share mode;
commit;

insert into sales_interval_1d values (1, date'2020-01-03', 'CA', 101); -- 2й способ
insert into sales_interval_1d values (2, date'2020-01-04', 'CA', 101);
rollback;-- отмена вставки

select * from user_tab_partitions t where t.table_name = 'SALES_INTERVAL_1D';-- см. секции
select * from sales_interval_1d;-- данных нет

-- drop
alter table sales_interval_1d drop partition SYS_P3573; -- удаление по имени
alter table sales_interval_1d drop partition for(date'2020-01-01');-- удаление по ссылке на значение
alter table sales_interval_1d drop partition for(date'2020-01-03'), for(date'2020-01-04');-- удаление сразу двух



---- Пример удаления секций

create table payment
(
  payment_id           number(38) not null,
  create_dtime         timestamp(6) not null,
  summa                number(30,2) not null,
  currency_id          number(3) not null,
  from_client_id       number(30) not null,
  to_client_id         number(30) not null,
  status               number(10) default 0 not null,
  status_change_reason varchar2(200 char),
  create_dtime_tech    timestamp(6) default systimestamp not null,
  update_dtime_tech    timestamp(6) default systimestamp not null
)
partition by range (create_dtime) interval (numtodsinterval(1,'DAY'))
(
  partition pmin values less than (timestamp' 2023-01-01 00:00:00')
);


create or replace procedure clear_payments is
  c_days_left constant number(3) := 90;
  v_current_payment_count number(38);
begin
  
  select count(*)
    into v_current_payment_count
    from payment t
   where t.create_dtime < trunc(sysdate - c_days_left)
     and rownum < 2;

  if v_current_payment_count >= 1 then
    for p in (select to_char(trunc(create_dtime), 'yyyymmdd') pdate
                from payment t
               where t.create_dtime < trunc(sysdate - c_days_left)
               group by trunc(create_dtime)) loop
      
      execute immediate 'alter table payment drop partition for(to_date(' ||      p.pdate || ',''yyyymmdd'')) update global indexes';

    end loop;
  end if;
end;
/




