drop table payment$$;
create table payment$$
(
  payment_id           number(38) not null,
  create_dtime         timestamp(6),
  summa                number(30,2) not null,
  currency_id          number(3) not null,
  from_client_id       number(30) not null,
  to_client_id         number(30) not null,
  status               number(10) default 0 not null,
  status_change_reason varchar2(200 char),
  create_dtime_tech    timestamp(6) default systimestamp not null,
  update_dtime_tech    timestamp(6) default systimestamp not null
)
partition by range (create_dtime) interval (numtodsinterval(1,'DAY'))
(
  partition pmin values less than (timestamp' 2023-01-01 00:00:00')
);


insert into payment$$ (payment_id, create_dtime, summa, currency_id, from_client_id, to_client_id, status, status_change_reason, create_dtime_tech, update_dtime_tech)
select level, systimestamp + numtodsinterval(level, 'day'), 1250.45, 840, 110, 210, 1, 'Payment approved', systimestamp, systimestamp from dual
connect by level <= 10;


select * from payment$$ t where t.create_dtime >= systimestamp - interval '1' day;
