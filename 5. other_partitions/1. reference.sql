------ Ссылочное секционирование

drop table sale_detail;
drop table sale;

create table sale (
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null,
  constraint sale_pk primary key(sale_id) -- создается глобальный индекс
)
partition by range(sale_date)
interval (interval '1' day)
(
  partition p1 values less than (date'1900-01-01')
);

create table sale_detail (
  sale_id            number(30) not null,
  product_id         number(6)  not null,
  unit_price         number(30,2),
  quantity           number(10),
  constraint sale_detail_fk
  foreign key(sale_id) references sale(sale_id)
)
partition by reference(sale_detail_fk);

-- Вставка в Master. Cоздает секции только там. В detail они появляются при вставки в Detail.
insert into sale values (1, sysdate, 'CA', 101);
insert into sale values (2, sysdate + 1, 'NY', 102);

-- Вставка в Detail. Создает секции в Detail. Названия совпадают с Master.
insert into sale_detail 
select 1, level, level+1, level*10 from dual connect by level <= 5;

insert into sale_detail 
select 2, level, level+2, level*10 from dual connect by level <= 5;
commit;


-- Сбор статистики
call dbms_stats.gather_table_stats(ownname => user, tabname => 'sale');
call dbms_stats.gather_table_stats(ownname => user, tabname => 'sale_detail');

select * from user_tab_partitions t where t.table_name = 'SALE';
select * from user_tab_partitions t where t.table_name = 'SALE_DETAIL';


select * from sale_detail t where t.sale_id = 1;

select /*+ use_nl(t1 t2) leading(t1 t2) */* 
  from sale t1
  join sale_detail t2 on t1.sale_id = t2.sale_id
 where t1.sale_id = 1
   and t1.sale_date between trunc(sysdate) and  trunc(sysdate)+1;


   
