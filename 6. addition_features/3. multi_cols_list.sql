----- Секционирование по нескольким колонкам

drop table sale_part_3cols;

create table sale_part_3cols(
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
  /*partition p_default values (default)*/
);

insert into sale_part_3cols(sale_id, sale_date, region_id, customer_id, sale_channel_id) values (1, sysdate, 'CA', 101, 'FACEBOOK'); 
insert into sale_part_3cols(sale_id, sale_date, region_id, customer_id, sale_channel_id) values (2, sysdate, 'CA', 102, 'VK');
insert into sale_part_3cols(sale_id, sale_date, region_id, customer_id, sale_channel_id) values (3, sysdate, 'CA', 103, 'TG');-- создастся секция
insert into sale_part_3cols(sale_id, sale_date, region_id, customer_id, sale_channel_id) values (4, sysdate, 'NY', 104, null);
insert into sale_part_3cols(sale_id, sale_date, region_id, customer_id, sale_channel_id) values (5, sysdate, 'NY', 105, 'TG');-- создастся секция
commit;


-- Сбор статистики
begin
  dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_part_3cols'); 
end;
/

select * from user_part_tables pt where pt.table_name = 'SALE_PART_3COLS';
select * from user_tab_partitions t where t.table_name = 'SALE_PART_3COLS';

select * from sale_part_3cols partition (SYS_P2949);

-- посмотреть план
select * from sale_part_3cols t where t.region_id = 'CA' and t.sale_channel_id = 'VK';


