------ План в целом

drop table sale_range;

create table sale_range(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date) -- секционируем по дате
interval(interval '1' day) -- интервал 1 день
(
partition pmin values less than (date '2021-01-01') -- одна секция за любой период
);

-- 100 строк
insert into sale_range select level, trunc(sysdate)+level, 'CA', level*100 from dual connect by level <= 100;
commit;

-- стата
call dbms_stats.gather_table_stats(ownname => user, tabname => 'SALE_RANGE');

select * from user_tab_partitions t where t.table_name = 'SALE_RANGE';


-- план запроса
select * from sale_range s where s.sale_date = date '2021-06-26';-- нет данных

select * from sale_range s where s.sale_date = date '2021-06-28';-- 1 секция

select * from sale_range s where s.sale_date in(date '2021-06-28', date '2021-06-29');-- 2 секции

select * from sale_range s where s.sale_date >= date '2021-06-28';-- диапазон от до 1М
