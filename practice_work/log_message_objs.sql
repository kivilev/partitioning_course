/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Практическая работа. Логирование
	
  Описание скрипта: объекты для системы логирования
*/

drop table log_message;
drop sequence log_message_pk_seq;

-- Таблица для логирования
create table log_message
(
  id             number(30) not null,
  dtime          timestamp(6) default systimestamp not null,
  message_type   char(1 char) not null,
  message        varchar2(2000 char) not null,
  message_source varchar2(2000 char) not null,
  sid            number(10) not null,
  serial         number(10) not null,
  pid            number(10) not null,
  osuser         varchar2(200 char) not null,
  oracle_user    varchar2(200 char) not null,
  call_stack     varchar2(4000 char) not null
);

alter table log_message add constraint log_message_message_type_chk check (message_type in ('I', 'E', 'W'));

create index log_message_message_source_idx on log_message(dtime desc, message_source);
create index log_message_message_type_idx on log_message(dtime desc, message_type);
create index log_message_message_idx on log_message(dtime desc, substr(message, 1, 100));


comment on table log_message is 'Лог событий в БД';
comment on column log_message.id is 'UID';
comment on column log_message.dtime is 'Дата события';
comment on column log_message.message_type is 'Тип сообщения: I - инфо, E - ошибка, W - предупреждение';
comment on column log_message.message is 'Текст сообщения';
comment on column log_message.message_source is 'Место из которого логируется';
comment on column log_message.sid is 'ID сессии';
comment on column log_message.pid is 'ID процесса Oracle';
comment on column log_message.osuser is 'Пользователь ОС';
comment on column log_message.oracle_user is 'Пользователь БД';
comment on column log_message.call_stack is 'Стек вызова';

-- Sequence
create sequence log_message_pk_seq start with 1 increment by 1 cache 1000 cycle maxvalue 99999999999999999999999999999;

