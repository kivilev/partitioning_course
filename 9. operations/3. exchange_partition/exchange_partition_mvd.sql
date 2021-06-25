------ Обмен секциями. Пример. Загрузка паспортов МВД

drop table expired_passport;
drop table expired_passport_stage;


-- Основная таблица
create table expired_passport
(
  ep_serial_num  varchar2(50 char) not null
)
partition by system (partition mp);

insert into expired_passport partition(mp) values ('это 1-й паспорт из секции mp');
insert into expired_passport partition(mp) values ('это 2-й паспорт из секции mp');
insert into expired_passport partition(mp) values ('это 3-й паспорт из секции mp');
commit;

select * from expired_passport;

-- Промежуточная
create table expired_passport_stage
(
  ep_serial_num  varchar2(50 char) not null
);

insert into expired_passport_stage values ('это 1-й паспорт из stage-таблицы');
insert into expired_passport_stage values ('это 2-й паспорт из stage-таблицы');
commit;

alter table expired_passport exchange partition mp
with table expired_passport_stage 
including indexes
without validation;

-- после замены
select * from expired_passport;
select * from expired_passport_stage;
