/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Запросы к секционированным таблицами. Умное секционирование (Partition Wise)
	
  Описание скрипта: примеры "умного секционирования"
*/

--------- Single

drop table pwdemo;

create table pwdemo (
  id number,
  d1 date,
  n1 number,
  n2 number,
  n3 number,
  pad varchar2(4000) 
)
partition by range (d1)
(
  partition t_q1_2018 values less than (to_date('2018-04-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
  partition t_q2_2018 values less than (to_date('2018-07-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
  partition t_q3_2018 values less than (to_date('2018-10-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
  partition t_q4_2018 values less than (to_date('2019-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
);

insert into pwdemo
select rownum as id,
       trunc(to_date('2018-01-01','YYYY-MM-DD')+rownum/27.4) as d1,
       1+mod(rownum,4) as n1,
       rownum as n2,
       rownum as n3,
       rpad('*',100,'*') as pad
from dual
connect by level <= 10000;
commit;

call dbms_stats.gather_table_stats( ownname => user, tabname => 'pwdemo');

select t.num_rows, t.* from user_tab_subpartitions t where t.table_name = 'PWDEMO'


---- Group by 
select /*+ no_use_partition_wise_gby */ d1, sum(n2) from pwdemo group by d1;

select d1, sum(n2) from pwdemo group by d1;

---- Distinct
select /*+ no_use_partition_wise_distinct */ distinct d1 from pwdemo;

select distinct d1 from pwdemo;


---- Analytic Functions (18.1 добавили, но не в параллеле не работает)
select /*+ no_use_partition_wise_wif */ 
       avg(n2) over (partition by d1) as average 
 from pwdemo;

select avg(n2) over (partition by d1) as average 
 from pwdemo;


--------- Composite

drop table pwdemo;

create table pwdemo (
  id number,
  d1 date,
  n1 number,
  n2 number,
  n3 number,
  pad varchar2(4000) 
)
partition by range (d1)
subpartition by list (n1)
subpartition template (
  subpartition sp_1 values (1),
  subpartition sp_2 values (2),
  subpartition sp_3 values (3),
  subpartition sp_4 values (4)
)(
  partition t_q1_2018 values less than (to_date('2018-04-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
  partition t_q2_2018 values less than (to_date('2018-07-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
  partition t_q3_2018 values less than (to_date('2018-10-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
  partition t_q4_2018 values less than (to_date('2019-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
);

insert into pwdemo
select rownum as id,
       trunc(to_date('2018-01-01','YYYY-MM-DD')+rownum/27.4) as d1,
       1+mod(rownum,4) as n1,
       rownum as n2,
       rownum as n3,
       rpad('*',100,'*') as pad
from dual
connect by level <= 10000;

call dbms_stats.gather_table_stats( ownname => user, tabname => 'pwdemo');


---- Group by 
select /*+ no_use_partition_wise_gby */ n1, d1, sum(n2) from pwdemo group by n1, d1;

select n1, d1, sum(n2) from pwdemo group by n1, d1;

---- Distinct
select /*+ no_use_partition_wise_gby */ distinct n1, d1 from pwdemo;

select distinct n1, d1 from pwdemo;


---- Analytic Functions (18.1 добавили, но не в параллеле не работает)
select /*+ no_use_partition_wise_wif */ n1, d1,
       avg(n2) over (partition by n1, d1) as average 
 from pwdemo;

select /*+ use_partition_wise_wif */ n1, d1,
       avg(n2) over (partition by n1, d1) as average 
 from pwdemo;
