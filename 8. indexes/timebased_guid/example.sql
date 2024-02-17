-- получаем UUID v1 по текущей дате
select guid_pack.get_new_guid() from dual;

-- получаем дату из UUID v1
select guid_pack.get_date_from_guid('DAE9AF63CD8B11EE98573DF342219D6B') from dual;

-- пример таблички
create table requests(
  request_id   number(30) not null,
  request_date date not null,
  region_id    char(2 char) not null,
  customer_id  number(30) not null,
  external_id  varchar2(200) not null
)
partition by range(request_date)
interval(numtodsinterval(1,'DAY')) -- интервал 1 день
(
partition pmin values less than (date '2024-01-01') -- одна секция за любой период
);

-- вариант 1. локальный уникальный индекс
create unique index requests_external_id_loc_uq on sales_interval(external_id, request_date) local;
select * 
  from requests t 
 where t.external_id = :v 
   and request_date = guid_pack.get_date_from_guid(:v);

-- вариант 2. глобальный уникальный индекс
create unique index requests_external_id_glob_uq on sales_interval(external_id);
