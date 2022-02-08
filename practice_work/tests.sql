/*
  Курс: Секционирование в СУБД Oracle
  Автор: Кивилев Д.С. (https://t.me/oracle_dbd, https://oracle-dbd.ru, https://www.youtube.com/c/OracleDBD)

  Практическая работа. Логирование
	
  Описание скрипта: UNIT-тесты к функционалу (на вставку и очистку)
    тесты не покрывают многие тест-кейсы, только самый основной функционал.
*/


--============== Тест записи
declare
  v_value       varchar2(200 char) := dbms_random.string('p', 200);
  v_count       number(20, 0);
  v_dtime       log_message.dtime%type;
  v_dtime2      log_message.dtime%type;
  v_message_rnd log_message.message%type;
  c_message_source constant log_message.message_source%type := 'test.insert';
  
  -- получить количество строк соответствующих условию
  function get_count_found_recs(p_from_dtime     log_message.dtime%type
                               ,p_to_dtime       log_message.dtime%type
                               ,p_message        log_message.message%type
                               ,p_message_source log_message.message_source%type := c_message_source)
    return pls_integer is
    v_cnt pls_integer;
  begin
    select count(*)
      into v_cnt
      from log_message t
     where t.dtime between p_from_dtime and p_to_dtime
       and t.message_type in
           (log_message_pack.c_info_type,
            log_message_pack.c_warning_type,
            log_message_pack.c_error_type)
       and t.message = p_message
       and t.message_source = p_message_source;
    return v_cnt;
  end;

begin
  -- проверяем вставку под текущей датой
  v_dtime       := systimestamp;
  v_message_rnd := dbms_random.string('p', 200);
  log_message_pack.info(p_message        => v_message_rnd,
                        p_message_source => c_message_source);
  log_message_pack.warning(p_message        => v_message_rnd,
                        p_message_source => c_message_source);
  log_message_pack.error(p_message        => v_message_rnd,
                        p_message_source => c_message_source);
  v_dtime2 := systimestamp;

  if get_count_found_recs(v_dtime, v_dtime2, v_message_rnd) <> 3 then
    raise_application_error(-20100,
                            'Ошибка записи с текущей датой');
  end if;

  -- проверяем вставку с указанием даты
  v_dtime       := systimestamp - interval '1' day;
  v_message_rnd := dbms_random.string('p', 200);
  log_message_pack.info(p_message        => v_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime  => v_dtime);
  log_message_pack.warning(p_message        => v_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime  => v_dtime);
  log_message_pack.error(p_message        => v_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime  => v_dtime);

  if get_count_found_recs(v_dtime, v_dtime, v_message_rnd) <> 3 then
    raise_application_error(-20100,
                            'Ошибка записи с указанной датой');
  end if;
  
  dbms_output.put_line('All insert tests passed'); 
end;
/

--================ Тест очистки
declare
  с_message_rnd   constant log_message.message%type := dbms_random.string('p',
                                                                          200);
  c_message_source constant log_message.message_source%type := 'test.clear';
 v_info_cnt pls_integer;  
         v_warning_cnt  pls_integer;
        v_error_cnt   pls_integer;
begin
  ------- вставляем данные  
  ---- info
  -- не удалится  
  log_message_pack.info(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp + interval '100' day);  
  -- не удалится  
  log_message_pack.info(p_message        => с_message_rnd,
                        p_message_source => c_message_source);
  -- не удалится  
  log_message_pack.info(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp - interval '9' day);
  -- не удалится  
  log_message_pack.info(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp - interval '10' day);
  -- удалится !
  log_message_pack.info(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp - interval '11' day);
  ---- warning
    -- не удалится  
  log_message_pack.warning(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp + interval '100' day);                        
  -- не удалится  
  log_message_pack.warning(p_message        => с_message_rnd,
                        p_message_source => c_message_source);
  -- не удалится  
  log_message_pack.warning(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp - interval '19' day);
  -- не удалится  
  log_message_pack.warning(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp - interval '20' day);
  -- удалится !
  log_message_pack.warning(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp - interval '21' day);

  ---- error
  -- не удалится  
  log_message_pack.error(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp + interval '100' day);                        
  -- не удалится  
  log_message_pack.error(p_message        => с_message_rnd,
                        p_message_source => c_message_source);
  -- не удалится  
  log_message_pack.error(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp - interval '29' day);
  -- не удалится  
  log_message_pack.error(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp - interval '30' day);
  -- удалится !
  log_message_pack.error(p_message        => с_message_rnd,
                        p_message_source => c_message_source,
                        p_message_dtime => systimestamp - interval '31' day);

  -- проведем чистку
  log_message_pack.clear_messages();

  -- сверим полученный результат => должно остаться по четыре события
  select sum(decode(t.message_type, log_message_pack.c_info_type, 1, 0)) info_cnt,
          sum(decode(t.message_type, log_message_pack.c_warning_type, 1, 0)) warning_cnt,
          sum(decode(t.message_type, log_message_pack.c_error_type, 1, 0)) error_cnt
   into  v_info_cnt,  
         v_warning_cnt,
         v_error_cnt
    from log_message t
    where t.message = с_message_rnd
      and t.message_source = c_message_source;      
  
  if v_info_cnt <> 4 then
    raise_application_error(-20100, 'Процедура очистки некорректно удаляет INFO-сообщения');
  end if;
  
  if v_warning_cnt <> 4 then
    raise_application_error(-20100, 'Процедура очистки некорректно удаляет WARNING-сообщения');
  end if;
  
  if v_error_cnt <> 4 then
    raise_application_error(-20100, 'Процедура очистки некорректно удаляет ERROR-сообщения');
  end if;

  dbms_output.put_line('All clear tests passed');   
end;
/

