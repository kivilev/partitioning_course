/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Индексы
	
  Описание скрипта: демонстрация планов запросов с глобальными и локальными индексами
*/

drop table  sales;

create table sales
(
s_customer_id    number(6),
s_amt      number(9,2),
s_date      date)
partition by range (s_date)
subpartition by hash(s_customer_id) 
subpartitions 8 store in (users)
(
partition q01 values less than (date '2002-01-01'),
partition q02 values less than (date '2002-03-01'),
partition q03 values less than (date '2002-05-01'),
partition q04 values less than (maxvalue)
);

create index sales_ndx on sales (s_customer_id) global
partition by hash (s_customer_id)
(partition p1,
partition p2,
partition p3,
partition p4);

insert into sales select level, level, date '2012-01-01' - level from dual connect by level <= 100000;
commit;

select * from user_tab_partitions t where t.table_name = 'SALES';
select * from user_tab_subpartitions t where t.table_name = 'SALES';
select * from user_ind_partitions t where t.index_name = 'SALES_NDX';


begin
  dbms_stats.gather_table_stats(user, 'SALES');
end;
/


select * from sales s where s.s_date = :s and s.s_customer_id := s1;

select * from sales s where s.s_date = date '2002-06-01' and s.s_customer_id = 3501

