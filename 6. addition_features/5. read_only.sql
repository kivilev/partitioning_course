---- Секции только для чтения

drop table sales_ro;

create table sales_ro(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null
)
partition by range(sale_date) -- секционируем по дате
(
partition p_sale_2018 values less than (date '2019-01-01'),-- read only,
partition p_sale_2019 values less than (date '2020-01-01'),
partition p_sale_2020 values less than (date '2021-01-01'),
partition p_sale_2021 values less than (date '2022-01-01')
);

insert into sales_ro(sale_id, sale_date, region_id, customer_id) values (1, date'2018-07-14', 'CA', 1);
insert into sales_ro(sale_id, sale_date, region_id, customer_id) values (2, date'2019-07-14', 'CA', 1);
insert into sales_ro(sale_id, sale_date, region_id, customer_id) values (3, date'2020-07-14', 'CA', 1);
insert into sales_ro(sale_id, sale_date, region_id, customer_id) values (4, date'2021-07-14', 'CA', 1);

commit;

select * from sales_ro;

alter table sales_ro modify partition p_sale_2018 read only;
alter table sales_ro modify partition p_sale_2018 read write;


select * from user_tab_partitions pt where pt.table_name = 'sales_ro';

-- по умолчанию перемешение выключено
update sales_ro s
   set s.region_id = region_id || 'A'
 where s.sale_id = 1;

-- включаем, пробуем заново
alter table sales_ro enable row movement;

-- выключаем
alter table sales_ro disable row movement;

-- можно посмотреть разрешено ли перемещение
select pt.row_movement, pt.* from user_tables pt where pt.table_name = 'SALES_RO';
select pt.read_only, pt.* from user_tab_partitions pt  where pt.table_name = 'SALES_RO';

-- Read Only
update sales_ro s
   set s.customer_id = s.customer_id + 1
 where s.sale_id = 1;

update sales_ro s
   set s.sale_date = sale_date + 10000
 where s.sale_id = 1;
