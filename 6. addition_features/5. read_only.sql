/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Дополнительные возможности. Секции только для чтения
	
  Описание скрипта: пример перевода определенных секций в режим "только чтение"
*/

drop table sales_ro;

create table sales_ro(
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    varchar2(10 char) not null,
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

alter table sales_ro modify partition p_sale_2018 read only;
select pt.read_only, pt.* from user_tab_partitions pt  where pt.table_name = 'SALES_RO';

-- ORA-14466: Data in a read-only partition or subpartition cannot be modified.
update sales_ro s
   set s.region_id = region_id || 'J'
 where s.sale_id = 1;

alter table sales_ro modify partition p_sale_2018 read write;

