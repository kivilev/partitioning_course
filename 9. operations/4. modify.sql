/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Лекция. Операции с секциями
	
  Описание скрипта: изменение свойств секций
*/

alter table sales_by_region  modify partition region_south add values ('OK', 'KS');
alter table sales_by_region_quart modify subpartition q1_1999_southeast add values ('KS');
alter table sales_by_region modify partition region_south drop values ('OK', 'KS');
alter table sales_interval set interval (numtoyminterval(1,'MONTH'));

