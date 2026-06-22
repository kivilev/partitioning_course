/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)
  Практическая работа. Логирование — UNIT-тесты

  Test 1  - вставка под текущей датой
  Test 2  - вставка с явной датой
  Test 3  - полный сценарий очистки TTL
  Test 4  - создание субпартиций по типам
  Test 5  - три типа за один день
  Test 6  - две записи одной субпартиции
  Test 7  - разные дни разные партиции
  Test 8  - корректная RANGE-маршрутизация
  Test 9  - очистка без старых данных
  Test 10 - идемпотентность clear_messages
  Test 11 - удаление нескольких дней сразу
  Test 12 - один тип за устаревший день
  Test 13 - граница полуночи TTL
  Test 14 - усечение длинных строк
  Test 15 - дифференцированное удаление типов
  Test 16 - будущие даты не удаляются
  Test 17 - метаданные сессии заполнены
  Test 18 - уникальность id из sequence
  Test 19 - ERROR удаляет целую партицию
  Test 20 - глубоко устаревший WARNING
*/

--set serveroutput on size unlimited

--============== Общие утилиты для тестов
create or replace package log_message_test_util is

  c_err_code constant pls_integer := -20100;

  function to_dtime(p_day date, p_hour number default 12) return timestamp;

  function subpart_count(p_date   date
                        ,p_type   varchar2
                        ,p_source log_message.message_source%type)
    return pls_integer;

  function count_by_source(p_message        log_message.message%type
                          ,p_message_source log_message.message_source%type
                          ,p_message_type   log_message.message_type%type := null)
    return pls_integer;

  function count_by_source_only(p_message_source log_message.message_source%type
                                 ,p_day            date := null)
    return pls_integer;

  procedure assert_eq(p_test_name varchar2
                     ,p_expected  pls_integer
                     ,p_actual    pls_integer);

  procedure prepare_clean_table;

end log_message_test_util;
/

create or replace package body log_message_test_util is

  function to_dtime(p_day date, p_hour number default 12) return timestamp is
  begin
    return cast(p_day as timestamp) + numtodsinterval(p_hour, 'HOUR');
  end;

  function subpart_count(p_date   date
                        ,p_type   varchar2
                        ,p_source log_message.message_source%type)
    return pls_integer is
    v_cnt pls_integer;
  begin
    execute immediate
      'select count(*) from log_message subpartition for ' ||
      '(timestamp''' || to_char(p_date, 'yyyy-mm-dd') ||
      ' 00:00:00'', ''' || p_type || ''') ' ||
      'where message_source = :1'
      into v_cnt
      using p_source;
    return v_cnt;
  exception
    when others then
      return 0;
  end;

  function count_by_source(p_message        log_message.message%type
                          ,p_message_source log_message.message_source%type
                          ,p_message_type   log_message.message_type%type := null)
    return pls_integer is
    v_cnt pls_integer;
  begin
    select count(*)
      into v_cnt
      from log_message t
     where t.message = p_message
       and t.message_source = p_message_source
       and (p_message_type is null or t.message_type = p_message_type);
    return v_cnt;
  end;

  function count_by_source_only(p_message_source log_message.message_source%type
                                 ,p_day            date := null)
    return pls_integer is
    v_cnt pls_integer;
  begin
    select count(*)
      into v_cnt
      from log_message t
     where t.message_source = p_message_source
       and (p_day is null or trunc(t.dtime) = p_day);
    return v_cnt;
  end;

  procedure assert_eq(p_test_name varchar2
                     ,p_expected  pls_integer
                     ,p_actual    pls_integer) is
  begin
    if nvl(p_actual, -1) <> p_expected then
      raise_application_error(c_err_code,
        p_test_name || ' FAILED: expected=' || p_expected ||
        ', actual=' || nvl(to_char(p_actual), 'NULL'));
    end if;
  end;

  procedure prepare_clean_table is
  begin
    execute immediate 'truncate table log_message';
  end;

end log_message_test_util;
/

begin
  log_message_test_util.prepare_clean_table;
  dbms_output.put_line('Test data cleared');
end;
/


--============== Test 1 - вставка под текущей датой
declare
  c_source constant log_message.message_source%type := 'test.01';
  v_msg    log_message.message%type := dbms_random.string('p', 200);
  v_from   log_message.dtime%type   := systimestamp;
  v_to     log_message.dtime%type;
  v_cnt    pls_integer;
begin
  log_message_pack.info(p_message => v_msg, p_message_source => c_source);
  log_message_pack.warning(p_message => v_msg, p_message_source => c_source);
  log_message_pack.error(p_message => v_msg, p_message_source => c_source);
  v_to := systimestamp;

  select count(*)
    into v_cnt
    from log_message t
   where t.dtime between v_from and v_to
     and t.message = v_msg
     and t.message_source = c_source
     and t.message_type in (log_message_pack.c_info_type,
                            log_message_pack.c_warning_type,
                            log_message_pack.c_error_type);

  log_message_test_util.assert_eq('Test 1', 3, v_cnt);
  dbms_output.put_line('Test 1 passed');
end;
/


--============== Test 2 - вставка с явной датой
declare
  c_source constant log_message.message_source%type := 'test.02';
  v_msg    log_message.message%type := dbms_random.string('p', 200);
  v_dtime  log_message.dtime%type   := systimestamp - interval '1' day;
  v_cnt    pls_integer;
begin
  log_message_pack.info(p_message => v_msg, p_message_source => c_source, p_message_dtime => v_dtime);
  log_message_pack.warning(p_message => v_msg, p_message_source => c_source, p_message_dtime => v_dtime);
  log_message_pack.error(p_message => v_msg, p_message_source => c_source, p_message_dtime => v_dtime);

  select count(*)
    into v_cnt
    from log_message t
   where t.dtime = v_dtime
     and t.message = v_msg
     and t.message_source = c_source;

  log_message_test_util.assert_eq('Test 2', 3, v_cnt);

  select count(*)
    into v_cnt
    from log_message t
   where t.message = v_msg
     and t.message_source = c_source
     and trunc(t.dtime) = trunc(sysdate);

  log_message_test_util.assert_eq('Test 2 (not today)', 0, v_cnt);
  dbms_output.put_line('Test 2 passed');
end;
/


--============== Test 3 - полный сценарий очистки TTL
declare
  c_msg    constant log_message.message%type        := dbms_random.string('p', 200);
  c_source constant log_message.message_source%type := 'test.03';
  v_info_cnt    pls_integer;
  v_warning_cnt pls_integer;
  v_error_cnt   pls_integer;
begin
  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => systimestamp + interval '100' day);
  log_message_pack.info(p_message => c_msg, p_message_source => c_source);
  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => systimestamp - interval '9' day);
  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => systimestamp - interval '10' day);

  log_message_pack.warning(p_message => c_msg, p_message_source => c_source,
                           p_message_dtime => systimestamp + interval '100' day);
  log_message_pack.warning(p_message => c_msg, p_message_source => c_source);
  log_message_pack.warning(p_message => c_msg, p_message_source => c_source,
                           p_message_dtime => systimestamp - interval '19' day);
  log_message_pack.warning(p_message => c_msg, p_message_source => c_source,
                           p_message_dtime => systimestamp - interval '20' day);

  log_message_pack.error(p_message => c_msg, p_message_source => c_source,
                         p_message_dtime => systimestamp + interval '100' day);
  log_message_pack.error(p_message => c_msg, p_message_source => c_source);
  log_message_pack.error(p_message => c_msg, p_message_source => c_source,
                         p_message_dtime => systimestamp - interval '29' day);
  log_message_pack.error(p_message => c_msg, p_message_source => c_source,
                         p_message_dtime => systimestamp - interval '30' day);

  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => systimestamp - interval '11' day);
  log_message_pack.warning(p_message => c_msg, p_message_source => c_source,
                           p_message_dtime => systimestamp - interval '21' day);
  log_message_pack.error(p_message => c_msg, p_message_source => c_source,
                         p_message_dtime => systimestamp - interval '31' day);

  log_message_pack.clear_messages();

  select sum(decode(t.message_type, log_message_pack.c_info_type, 1, 0)),
         sum(decode(t.message_type, log_message_pack.c_warning_type, 1, 0)),
         sum(decode(t.message_type, log_message_pack.c_error_type, 1, 0))
    into v_info_cnt, v_warning_cnt, v_error_cnt
    from log_message t
   where t.message = c_msg
     and t.message_source = c_source;

  log_message_test_util.assert_eq('Test 3 INFO kept', 4, v_info_cnt);
  log_message_test_util.assert_eq('Test 3 WARNING kept', 4, v_warning_cnt);
  log_message_test_util.assert_eq('Test 3 ERROR kept', 4, v_error_cnt);
  dbms_output.put_line('Test 3 passed');
end;
/


--============== Test 4 - создание субпартиций по типам
declare
  c_source constant log_message.message_source%type := 'test.04';
  v_date   date := trunc(sysdate - 3);
  v_cnt    pls_integer;
begin
  log_message_pack.info(p_message => 't4-i', p_message_source => c_source,
                        p_message_dtime => log_message_test_util.to_dtime(v_date));
  log_message_pack.warning(p_message => 't4-w', p_message_source => c_source,
                           p_message_dtime => log_message_test_util.to_dtime(v_date));
  log_message_pack.error(p_message => 't4-e', p_message_source => c_source,
                         p_message_dtime => log_message_test_util.to_dtime(v_date));

  log_message_test_util.assert_eq('Test 4 INFO subpart', 1,
    log_message_test_util.subpart_count(v_date, log_message_pack.c_info_type, c_source));
  log_message_test_util.assert_eq('Test 4 WARNING subpart', 1,
    log_message_test_util.subpart_count(v_date, log_message_pack.c_warning_type, c_source));
  log_message_test_util.assert_eq('Test 4 ERROR subpart', 1,
    log_message_test_util.subpart_count(v_date, log_message_pack.c_error_type, c_source));

  v_cnt := log_message_test_util.count_by_source_only(c_source, trunc(sysdate - 33));
  log_message_test_util.assert_eq('Test 4 no data wrong day', 0, v_cnt);
  dbms_output.put_line('Test 4 passed');
end;
/


--============== Test 5 - три типа за один день
declare
  c_source constant log_message.message_source%type := 'test.05';
  v_date   date := trunc(sysdate - 4);
  v_cnt    pls_integer;
begin
  log_message_pack.info(p_message => 't5-i', p_message_source => c_source,
                        p_message_dtime => log_message_test_util.to_dtime(v_date, 2));
  log_message_pack.warning(p_message => 't5-w', p_message_source => c_source,
                           p_message_dtime => log_message_test_util.to_dtime(v_date, 5));
  log_message_pack.error(p_message => 't5-e', p_message_source => c_source,
                         p_message_dtime => log_message_test_util.to_dtime(v_date, 7));

  v_cnt := log_message_test_util.count_by_source_only(c_source, v_date);
  log_message_test_util.assert_eq('Test 5 rows', 3, v_cnt);

  log_message_test_util.assert_eq('Test 5 INFO subpart', 1,
    log_message_test_util.subpart_count(v_date, log_message_pack.c_info_type, c_source));
  log_message_test_util.assert_eq('Test 5 WARNING subpart', 1,
    log_message_test_util.subpart_count(v_date, log_message_pack.c_warning_type, c_source));
  log_message_test_util.assert_eq('Test 5 ERROR subpart', 1,
    log_message_test_util.subpart_count(v_date, log_message_pack.c_error_type, c_source));

  dbms_output.put_line('Test 5 passed');
end;
/


--============== Test 6 - две записи одной субпартиции
declare
  c_source constant log_message.message_source%type := 'test.06';
  v_date   date := trunc(sysdate - 5);
  v_cnt    pls_integer;
begin
  log_message_pack.info(p_message => 't6-a', p_message_source => c_source,
                        p_message_dtime => log_message_test_util.to_dtime(v_date, 6));
  log_message_pack.info(p_message => 't6-b', p_message_source => c_source,
                        p_message_dtime => log_message_test_util.to_dtime(v_date, 18));

  v_cnt := log_message_test_util.subpart_count(v_date, log_message_pack.c_info_type, c_source);
  log_message_test_util.assert_eq('Test 6 rows in one subpart', 2, v_cnt);
  dbms_output.put_line('Test 6 passed');
end;
/


--============== Test 7 - разные дни разные партиции
declare
  c_source constant log_message.message_source%type := 'test.07';
  v_day1   date := trunc(sysdate - 6);
  v_day2   date := trunc(sysdate - 7);
begin
  log_message_pack.info(p_message => 't7-d1', p_message_source => c_source,
                        p_message_dtime => log_message_test_util.to_dtime(v_day1));
  log_message_pack.info(p_message => 't7-d2', p_message_source => c_source,
                        p_message_dtime => log_message_test_util.to_dtime(v_day2));

  log_message_test_util.assert_eq('Test 7 day1', 1,
    log_message_test_util.subpart_count(v_day1, log_message_pack.c_info_type, c_source));
  log_message_test_util.assert_eq('Test 7 day2', 1,
    log_message_test_util.subpart_count(v_day2, log_message_pack.c_info_type, c_source));

  log_message_test_util.assert_eq('Test 7 total', 2,
    log_message_test_util.count_by_source_only(c_source));

  dbms_output.put_line('Test 7 passed');
end;
/


--============== Test 8 - корректная RANGE-маршрутизация
declare
  c_source constant log_message.message_source%type := 'test.08';
  v_date   date := trunc(sysdate - 2);
  v_min_d  date;
  v_max_d  date;
begin
  log_message_pack.info(p_message => 't8', p_message_source => c_source,
                        p_message_dtime => log_message_test_util.to_dtime(v_date));

  execute immediate
    'select trunc(min(dtime)), trunc(max(dtime)) ' ||
    'from log_message subpartition for ' ||
    '(timestamp''' || to_char(v_date, 'yyyy-mm-dd') || ' 00:00:00'', ''' ||
    log_message_pack.c_info_type || ''') where message_source = :1'
    into v_min_d, v_max_d using c_source;

  if v_min_d <> v_date or v_max_d <> v_date then
    raise_application_error(-20100,
      'Test 8 FAILED: min=' || to_char(v_min_d) || ' max=' || to_char(v_max_d));
  end if;

  log_message_pack.info(p_message => 't8-late', p_message_source => c_source,
                        p_message_dtime => log_message_test_util.to_dtime(v_date, 23) +
                                           numtodsinterval(59, 'MINUTE') +
                                           numtodsinterval(59, 'SECOND'));

  execute immediate
    'select trunc(max(dtime)) from log_message subpartition for ' ||
    '(timestamp''' || to_char(v_date, 'yyyy-mm-dd') || ' 00:00:00'', ''' ||
    log_message_pack.c_info_type || ''') where message_source = :1'
    into v_max_d using c_source;

  if v_max_d <> v_date then
    raise_application_error(-20100, 'Test 8 FAILED: late row in wrong day');
  end if;

  dbms_output.put_line('Test 8 passed');
end;
/


--============== Test 9 - очистка без старых данных
declare
  c_source constant log_message.message_source%type := 'test.09';
  v_before pls_integer;
  v_after  pls_integer;
begin
  log_message_pack.info(p_message => 't9', p_message_source => c_source);
  v_before := log_message_test_util.count_by_source_only(c_source);

  log_message_pack.clear_messages();

  v_after := log_message_test_util.count_by_source_only(c_source);
  log_message_test_util.assert_eq('Test 9 rows unchanged', v_before, v_after);
  dbms_output.put_line('Test 9 passed');
end;
/


--============== Test 10 - идемпотентность clear_messages
declare
  c_msg    constant log_message.message%type        := dbms_random.string('p', 50);
  c_source constant log_message.message_source%type := 'test.10';
begin
  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => systimestamp - interval '15' day);

  log_message_pack.clear_messages();
  log_message_pack.clear_messages();

  log_message_test_util.assert_eq('Test 10 deleted', 0,
    log_message_test_util.count_by_source(c_msg, c_source));

  -- corner: повторная вставка в тот же день после очистки
  log_message_pack.info(p_message => c_msg || '-2', p_message_source => c_source,
                        p_message_dtime => systimestamp - interval '15' day);

  log_message_test_util.assert_eq('Test 10 re-insert', 1,
    log_message_test_util.count_by_source(c_msg || '-2', c_source));

  dbms_output.put_line('Test 10 passed');
end;
/


--============== Test 11 - удаление нескольких дней сразу
declare
  c_msg    constant log_message.message%type        := dbms_random.string('p', 50);
  c_source constant log_message.message_source%type := 'test.11';
  v_cnt    pls_integer;
begin
  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => systimestamp - interval '12' day);
  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => systimestamp - interval '15' day);
  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => systimestamp - interval '40' day);
  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => systimestamp - interval '9' day);

  log_message_pack.clear_messages();

  v_cnt := log_message_test_util.count_by_source(c_msg, c_source, log_message_pack.c_info_type);
  log_message_test_util.assert_eq('Test 11 kept one', 1, v_cnt);
  dbms_output.put_line('Test 11 passed');
end;
/


--============== Test 12 - один тип за устаревший день
declare
  c_msg    constant log_message.message%type        := dbms_random.string('p', 50);
  c_source constant log_message.message_source%type := 'test.12';
  v_cnt    pls_integer;
begin
  log_message_pack.warning(p_message => c_msg, p_message_source => c_source,
                           p_message_dtime => systimestamp - interval '25' day);

  log_message_pack.clear_messages();

  v_cnt := log_message_test_util.count_by_source(c_msg, c_source);
  log_message_test_util.assert_eq('Test 12 deleted', 0, v_cnt);
  dbms_output.put_line('Test 12 passed');
end;
/


--============== Test 13 - граница полуночи TTL
declare
  c_msg      constant log_message.message%type        := dbms_random.string('p', 50);
  c_source   constant log_message.message_source%type := 'test.13';
  v_boundary timestamp(6);
  v_cnt      pls_integer;
begin
  v_boundary := cast(trunc(sysdate - 11) as timestamp);
  log_message_pack.info(p_message => c_msg, p_message_source => c_source, p_message_dtime => v_boundary);
  log_message_pack.clear_messages();

  v_cnt := log_message_test_util.count_by_source(c_msg, c_source);
  log_message_test_util.assert_eq('Test 13 -11 midnight deleted', 0, v_cnt);

  v_boundary := cast(trunc(sysdate - 10) as timestamp);
  log_message_pack.info(p_message => c_msg, p_message_source => c_source, p_message_dtime => v_boundary);
  log_message_pack.clear_messages();

  v_cnt := log_message_test_util.count_by_source(c_msg, c_source);
  log_message_test_util.assert_eq('Test 13 -10 midnight kept', 1, v_cnt);
  dbms_output.put_line('Test 13 passed');
end;
/


--============== Test 14 - усечение длинных строк
declare
  c_marker constant varchar2(10) := 'T14MARK___';
  v_cnt    pls_integer;
begin
  log_message_pack.info(p_message        => c_marker || rpad('X', 3000, 'X'),
                        p_message_source => rpad('S', 2500, 'S'),
                        p_message_dtime  => systimestamp);

  select count(*)
    into v_cnt
    from log_message t
   where t.message_type = log_message_pack.c_info_type
     and substr(t.message, 1, 10) = c_marker
     and length(t.message) = 2000
     and length(t.message_source) = 2000;

  log_message_test_util.assert_eq('Test 14 truncated', 1, v_cnt);
  dbms_output.put_line('Test 14 passed');
end;
/


--============== Test 15 - дифференцированное удаление типов
declare
  c_msg    constant log_message.message%type        := dbms_random.string('p', 50);
  c_source constant log_message.message_source%type := 'test.15';
begin
  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => systimestamp - interval '11' day);
  log_message_pack.warning(p_message => c_msg, p_message_source => c_source,
                           p_message_dtime => systimestamp - interval '11' day);
  log_message_pack.error(p_message => c_msg, p_message_source => c_source,
                         p_message_dtime => systimestamp - interval '11' day);

  log_message_pack.clear_messages();

  log_message_test_util.assert_eq('Test 15 INFO gone', 0,
    log_message_test_util.count_by_source(c_msg, c_source, log_message_pack.c_info_type));
  log_message_test_util.assert_eq('Test 15 WARNING kept', 1,
    log_message_test_util.count_by_source(c_msg, c_source, log_message_pack.c_warning_type));
  log_message_test_util.assert_eq('Test 15 ERROR kept', 1,
    log_message_test_util.count_by_source(c_msg, c_source, log_message_pack.c_error_type));
  dbms_output.put_line('Test 15 passed');
end;
/


--============== Test 16 - будущие даты не удаляются
declare
  c_msg    constant log_message.message%type        := dbms_random.string('p', 50);
  c_source constant log_message.message_source%type := 'test.16';
  v_cnt    pls_integer;
begin
  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => systimestamp + interval '365' day);
  log_message_pack.warning(p_message => c_msg, p_message_source => c_source,
                           p_message_dtime => systimestamp + interval '365' day);
  log_message_pack.error(p_message => c_msg, p_message_source => c_source,
                         p_message_dtime => systimestamp + interval '365' day);

  log_message_pack.clear_messages();

  v_cnt := log_message_test_util.count_by_source(c_msg, c_source);
  log_message_test_util.assert_eq('Test 16 future kept', 3, v_cnt);
  dbms_output.put_line('Test 16 passed');
end;
/


--============== Test 17 - метаданные сессии заполнены
declare
  c_source constant log_message.message_source%type := 'test.17';
  v_sid         log_message.sid%type;
  v_serial      log_message.serial%type;
  v_pid         log_message.pid%type;
  v_osuser      log_message.osuser%type;
  v_oracle_user log_message.oracle_user%type;
  v_stack       log_message.call_stack%type;
begin
  log_message_pack.info(p_message => 't17', p_message_source => c_source);

  select t.sid, t.serial, t.pid, t.osuser, t.oracle_user, t.call_stack
    into v_sid, v_serial, v_pid, v_osuser, v_oracle_user, v_stack
    from log_message t
   where t.message_source = c_source
     and t.message = 't17'
     and rownum = 1;

  if v_sid is null or v_serial is null or v_pid is null then
    raise_application_error(-20100, 'Test 17 FAILED: sid/serial/pid is null');
  end if;
  if v_osuser is null or v_oracle_user is null then
    raise_application_error(-20100, 'Test 17 FAILED: user fields is null');
  end if;
  if v_stack is null or length(trim(v_stack)) = 0 then
    raise_application_error(-20100, 'Test 17 FAILED: call_stack is empty');
  end if;
  if v_sid <> sys_context('userenv', 'sid') then
    raise_application_error(-20100, 'Test 17 FAILED: sid mismatch');
  end if;

  dbms_output.put_line('Test 17 passed');
end;
/


--============== Test 18 - уникальность id из sequence
declare
  c_source constant log_message.message_source%type := 'test.18';
  v_cnt    pls_integer;
  v_dup    pls_integer;
begin
  log_message_pack.info(p_message => 't18-1', p_message_source => c_source);
  log_message_pack.info(p_message => 't18-2', p_message_source => c_source);
  log_message_pack.info(p_message => 't18-3', p_message_source => c_source);

  select count(*), count(distinct t.id)
    into v_cnt, v_dup
    from log_message t
   where t.message_source = c_source;

  log_message_test_util.assert_eq('Test 18 rows', 3, v_cnt);
  log_message_test_util.assert_eq('Test 18 unique ids', 3, v_dup);
  dbms_output.put_line('Test 18 passed');
end;
/


--============== Test 19 - ERROR удаляет целую партицию
declare
  c_msg    constant log_message.message%type        := dbms_random.string('p', 50);
  c_source constant log_message.message_source%type := 'test.19';
  v_date   date := trunc(sysdate - 35);
begin
  log_message_pack.info(p_message => c_msg, p_message_source => c_source,
                        p_message_dtime => log_message_test_util.to_dtime(v_date, 2));
  log_message_pack.warning(p_message => c_msg, p_message_source => c_source,
                           p_message_dtime => log_message_test_util.to_dtime(v_date, 5));
  log_message_pack.error(p_message => c_msg, p_message_source => c_source,
                         p_message_dtime => log_message_test_util.to_dtime(v_date, 7));

  log_message_pack.clear_messages();

  log_message_test_util.assert_eq('Test 19 all types deleted', 0,
    log_message_test_util.count_by_source(c_msg, c_source));

  log_message_test_util.assert_eq('Test 19 ERROR subpart gone', 0,
    log_message_test_util.subpart_count(v_date, log_message_pack.c_error_type, c_source));
  dbms_output.put_line('Test 19 passed');
end;
/


--============== Test 20 - глубоко устаревший WARNING
declare
  c_msg    constant log_message.message%type        := dbms_random.string('p', 50);
  c_source constant log_message.message_source%type := 'test.20';
  v_cnt    pls_integer;
begin
  log_message_pack.warning(p_message => c_msg, p_message_source => c_source,
                           p_message_dtime => systimestamp - interval '25' day);

  log_message_pack.clear_messages();

  v_cnt := log_message_test_util.count_by_source(c_msg, c_source, log_message_pack.c_warning_type);
  log_message_test_util.assert_eq('Test 20 WARNING deleted', 0, v_cnt);
  dbms_output.put_line('Test 20 passed');
end;
/


begin
  execute immediate 'drop package log_message_test_util';
exception
  when others then
    if sqlcode != -4043 then
      raise;
    end if;
end;
/

begin
  dbms_output.put_line('---');
end;
/
