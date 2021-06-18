---- Пример Range-секционировани

-- 1 день
drop table sale_range;

create table sale_range(
  sale_id      number(30) not null,
  sale_date    date, -- not null (!)
  region_id    char(2 char) not null,
  customer_id  number(30) not null
) 
partition by range(sale_date)
( partition pmin  values less than (date '2009-01-01'),
  partition p01    values less than (date '2010-01-01'),
  partition p02    values less than (date '2012-03-01'),
  partition pmax values less than (maxvalue)
);

insert into sale_range values (1, date'2009-01-01', 'CA', 1);
insert into sale_range values (2, date'2008-12-01', 'CA', 1);
insert into sale_range values (3, date'2021-01-08', 'CA', 1);
insert into sale_range values (4, date'2021-02-08', 'NY', 1);
insert into sale_range values (4, null, 'NY', 1);
commit;

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'SALE_RANGE'); 
end;
/

-- инфа по секционированию
select * from user_part_tables pt where pt.table_name = 'SALE_RANGE';
 
-- смотрим какие секции были созданы
select * from user_tab_partitions t where t.table_name = 'SALE_RANGE';



