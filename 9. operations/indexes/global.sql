------- Глобальные индексы

drop table sale_range;

create table sale_range(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date) -- секционируем по дате
interval(interval '1' month) -- интервал 1 месяц
(
partition pmin values less than (date '2020-01-01') -- одна секция за любой период
);

-- Unique
alter table sale_range add constraint sale_pk primary key (sale_id);

insert into sale_range select level, trunc(sysdate)-level, 'CA', level*100 from dual connect by level <= 1000;
commit;


select * from SALE_RANGE t where t.sale_id = 5;
