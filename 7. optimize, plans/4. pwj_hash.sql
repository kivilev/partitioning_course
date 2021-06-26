drop table customer2;
drop table sale2;

drop table customer;
drop table sale;

------ Секции совпадают
create table sale (
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
)
partition by range(sale_date)
interval (interval '1' day)
subpartition by hash(customer_id)
subpartitions 8
(
  partition p1 values less than (date'1900-01-01')
);

create table customer (
  customer_id        number(30) not null,
  first_name         varchar2(200),
  last_name          varchar2(200),
  score              number(10)
)
partition by hash(customer_id)
partitions 8;


select /*+ use_hash(s d)  parallel(s 8)  parallel(d 8) Full(s) full(d) */ * 
  from sale s
  join customer d on s.customer_id = d.customer_id
 where s.sale_date between :v and v1;



----- Секции не совпадают
create table sale2 (
  sale_id      number(30) not null,
  sale_date    date not null,
  region_id    char(2 char),
  customer_id  number(30) not null
)
partition by range(sale_date)
interval (interval '1' day)
(
  partition p1 values less than (date'1900-01-01')
);

create table customer2 (
  customer_id        number(30) not null,
  first_name         varchar2(200),
  last_name          varchar2(200),
  score              number(10)
)
partition by hash(customer_id)
partitions 8;


select /*+ use_hash(s d)  parallel(s 8)  parallel(d 8) full(s) full(d) */  
        d.last_name, count(*)
  from sale2 s
  join customer2 d on s.customer_id = d.customer_id
 where s.sale_date between :v and :v1
 group by d.last_name
having count(*) > 100;
