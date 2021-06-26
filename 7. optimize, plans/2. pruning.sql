------ Отсечение секций (partition pruning)

---- 1) Таблички для экспериментов
drop table sale_range;
drop table sale_list;

create table sale_range(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date) -- секционируем по дате
interval(numtodsinterval(1,'DAY')) -- интервал 1 день
(
partition pmin values less than (date '2020-01-01') -- одна секция за любой период
);

insert into sale_range select level, trunc(sysdate)-level, 'CA', level*100 from dual connect by level <= 1000;
commit;

create table sale_list(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
) 
partition by list(region_id)
( partition p_west    values ('CA','WA','OR'),
  partition p_midwest values ('ND', 'MN'),
  partition p_north   values ('ME', 'PA'),
  partition p_south   values ('TX'),
  partition p_default values (default)
);

insert into sale_list values (1, sysdate,    'CA', 1);
insert into sale_list values (2, sysdate,    'ND', 1);
insert into sale_list values (3, sysdate+10, 'TX', 1);
insert into sale_list values (4, sysdate-1,  'XX', 1);
insert into sale_list values (5, sysdate+1,  null, 1);
commit;

-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'SALE_RANGE'); 
  dbms_stats.gather_table_stats(ownname => user, tabname => 'SALE_LIST'); 
end;
/

create or replace function get_date return date
is
begin
  return sysdate + 1;
end;
/

---- 2) Правильное использование -> отсечение секций

select * from sale_range t where t.sale_date = get_date();-- PARTITION RANGE SINGLE

select * from sale_list l where l.region_id in ('CA', 'WA');
select * from sale_list l where l.region_id in ('TX');

select * from sale_range t where t.sale_date >= date'2021-06-02'; -- PARTITION RANGE ITERATOR

select * from sale_range t where t.sale_date in(date'2019-01-01', date'2021-01-02'); -- PARTITION RANGE INLIST


---- 3) Неправильное использование -> отсечения НЕ будет

-- не указан ключ секционирования
select * from sale_range t where t.sale_id = 1;
select * from sale_list t where t.sale_id = 1;

-- преобразование ключа
select * from sale t where trunc(t.sale_date) = date'1900-06-01';

select * from sale t where t.sale_date + 1 = date'1900-06-01';

select * from sale_list t where upper(t.region_id) = 'CA';

-- неявное преобразование типа ключа
select * from sale t where t.sale_date = timestamp'2021-06-01 00:00:00.0000';


