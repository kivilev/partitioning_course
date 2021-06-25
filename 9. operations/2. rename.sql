------ Переименование секций

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

-- создадим 10 секций
insert into sales_interval_1d 
select level, sysdate+level, 'CA', level*10 from dual connect by level <= 10;
commit;

-- Какие секции сейчас?
select * from user_tab_partitions t where t.table_name = 'SALES_INTERVAL_1D';

-- функция получения текстового представления
create or replace function get_partition_high_value(p_table_name     user_tab_partitions.table_name%type
                                 ,p_partition_name user_tab_partitions.partition_name%type)
  return varchar2 is
  v_high_value user_tab_partitions.high_value%type;
begin
  select t.high_value
    into v_high_value
    from user_tab_partitions t
   where t.table_name = p_table_name
     and t.partition_name = p_partition_name;
  return substr(v_high_value, 1, 1000);
end;
/


-- ЭТО НЕ ПРОМЫШЛЕННОЕ РЕШЕНИЕ(!)
declare
  v_date     date;
  v_new_name user_tab_partitions.partition_name%type;
  v_sql      varchar2(1000 char);
begin
  -- проходим по всем секциям
  for p in (select t.table_name
                  ,t.partition_name old_name
                  ,get_partition_high_value(t.table_name, t.partition_name) dtime_expression
              from user_tab_partitions t
             where t.table_name = 'SALES_INTERVAL_1D') loop
    -- получаем дату верхней границы
    execute immediate 'select '||p.dtime_expression||' from dual' into v_date;
    -- новое имя
    v_new_name := to_char(v_date - 1, '"P_"YYYYMMDD');
    -- SQL для переименования
    v_sql := 'alter table '|| p.table_name ||' rename partition '|| p.old_name ||' to '||v_new_name;
    -- выводим
    dbms_output.put_line(p.old_name || ' ->  '|| v_new_name ||' -> ' ||v_sql );
    -- переименовыываем
    -- execute immediate v_sql;

  end loop;

end;
/

-- Какие секции после?
select * from user_tab_partitions t where t.table_name = 'SALES_INTERVAL_1D';

select * from sales_interval_1d partition(p_20210623);
