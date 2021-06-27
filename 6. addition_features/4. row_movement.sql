---- Перемещение (миграция) строк (Row movement)

drop table sales_rm;

create table sales_rm(
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
--enable row movement;-- можно разрешить перемешение строк сразу

insert into sales_rm(sale_id, sale_date, region_id, customer_id) values (1, date'2021-01-01', 'CA', 1);
commit;

-- по умолчанию перемешение выключено
update sales_rm s
   set s.sale_date = sale_date + 10
 where s.sale_id = 1;

-- включаем, пробуем заново
alter table sales_rm enable row movement;

-- выключаем
alter table sales_rm disable row movement;

-- можно посмотреть разрешено ли перемещение
select pt.row_movement, pt.* from user_tables pt where pt.table_name = 'SALES_RM';

select * from user_tab_partitions pt where pt.table_name = 'SALES_RM';

select * from sales_rm partition (SYS_P2989);
