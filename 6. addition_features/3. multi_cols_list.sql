/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Дополнительные возможности. Секционирование по нескольким колонкам
	
  Описание скрипта: пример list(automatic)-секционирования таблицы по нескольким колонкам
*/


drop table sale_part_2cols;

create table sale_part_2cols(
  sale_id          number(30) not null,
  sale_date        date not null,
  region_id        char(2 char) not null,
  customer_id      number(30) not null,
  sale_channel_id  varchar2(20 char)
)
partition by list(region_id, sale_channel_id)
automatic
(
  partition p_ca_facebook values ('CA', 'FACEBOOK'),
  partition p_ca_vk values ('CA', 'VK'),
  partition p_ca_not_defined values ('CA', null),
  partition p_ny_facebook values ('NY', 'FACEBOOK'),
  partition p_ny_not_defined values ('NY', null)
);

insert into sale_part_2cols(sale_id, sale_date, region_id, customer_id, sale_channel_id) values (1, sysdate, 'CA', 101, 'FACEBOOK');--1
insert into sale_part_2cols(sale_id, sale_date, region_id, customer_id, sale_channel_id) values (2, sysdate, 'CA', 102, 'VK');--2
insert into sale_part_2cols(sale_id, sale_date, region_id, customer_id, sale_channel_id) values (3, sysdate, 'CA', 103, 'TELEGRAM');--3
insert into sale_part_2cols(sale_id, sale_date, region_id, customer_id, sale_channel_id) values (4, sysdate, 'NY', 104, null);--4
insert into sale_part_2cols(sale_id, sale_date, region_id, customer_id, sale_channel_id) values (5, sysdate, 'NY', 105, 'TELEGRAM');--5
commit;


-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_part_2cols'); 
end;
/

select * from user_part_tables pt where pt.table_name = 'SALE_PART_2COLS';
select num_rows, t.* from user_tab_partitions t where t.table_name = 'SALE_PART_2COLS';


select * from sale_part_2cols t where t.region_id = 'CA' and t.sale_channel_id = 'VK'; -- 1 (прсомотр 1 секции)
select * from sale_part_2cols t where t.region_id = 'CA'; -- 2 (будут просмотрены все секции с region_id = 'CA'
select * from sale_part_2cols t where t.sale_channel_id = 'VK'; -- 3 (будут просмотрены все секции с sale_channel_id = 'VK')


