/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Операции с секциями
	
  Описание скрипта: обмен секциями с неверными значениями диапазона
*/

----- 
create table test1 (column1 number) 
        partition by range(column1) 
        (partition p1 values less than (10), 
         partition p2 values less than (20));

create table test2 (column1 number);

insert into test1 values (1);

insert into test2 values (99);

-- при обмене не проверяются значения подходят ли под ключ секционирования
alter table test1 exchange partition p2 with table test2 without validation;

-- проверка
select test1.*, ora_partition_validation(rowid) from test1;

