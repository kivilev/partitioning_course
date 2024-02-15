/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Описание скрипта: базовая таблица "Payment" для выполнения домашних заданий
*/

-- drop table payment;

create table payment
(
  payment_id      number(30) not null,
  from_client_id  number(30) not null,
  to_client_id       number(30) not null,
  status_id       varchar2(10 char) not null,
  payment_date  date not null,
  summa         number(20,2)
);

-- alter table payment add constraint payment_pk primary key (payment_id);

alter table payment add constraint payment_status_chk
check (status_id in ('PAYED', 'CANCELED', 'NOT_PAYED', 'ERROR'));

comment on table PAYMENT  is 'Платежи';

comment on column PAYMENT.payment_id is 'Unique ID';
comment on column PAYMENT.from_client_id is 'Клиент - отправитель';
comment on column PAYMENT.to_client_id is 'Клиент - получатель';
comment on column PAYMENT.status_id is 'Статус платежа';
comment on column PAYMENT.payment_date is 'Дата платежа';
comment on column PAYMENT.summa is 'Сумма платежа';
