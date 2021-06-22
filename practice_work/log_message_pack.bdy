create or replace package body log_message_pack is

  g_osuser      v$session.osuser%type;
  g_oracle_user v$process.username%type;
  g_sid         v$session.sid%type;
  g_pid         v$process.pid%type;
  g_serial#     v$process.serial#%type;
  c_delete_size constant pls_integer := 10000;

  procedure log_message_(p_message        log_message.message%type
                        ,p_message_source log_message.message_source%type
                        ,p_message_type   log_message.message_type%type
                        ,p_message_dtime  log_message.dtime%type := systimestamp) is
    pragma autonomous_transaction;
  begin
    insert into log_message
      (id
      ,dtime
      ,message_type
      ,message
      ,message_source
      ,sid
      ,serial
      ,pid
      ,osuser
      ,oracle_user
      ,call_stack)
    values
      (log_message_pk_seq.nextval
      ,p_message_dtime --systimestamp
      ,p_message_type
      ,substr(p_message, 1, 2000)
      ,substr(p_message_source, 1, 2000)
      ,g_sid
      ,g_serial#
      ,g_pid
      ,g_osuser
      ,g_oracle_user
      ,substr(dbms_utility.format_call_stack, 1, 4000));
   commit;
  exception
    when others then
      -- вечный вопрос, что делать если произошла ошибка в процедура логирования =)
      -- один из подходов умолчать и сделать запись в alert.log через dbms_system.ksdwrt
      raise;-- я оставил raise, чтобы вы, если что заметили ошибку
  end;


  procedure info(p_message        log_message.message%type
                ,p_message_source log_message.message_source%type
                ,p_message_dtime  log_message.dtime%type := systimestamp) is
  begin
    log_message_(p_message, p_message_source, c_info_type, p_message_dtime);
  end;

  procedure warning(p_message        log_message.message%type
                   ,p_message_source log_message.message_source%type
                   ,p_message_dtime  log_message.dtime%type := systimestamp) is
  begin
    log_message_(p_message,
                 p_message_source,
                 c_warning_type,
                 p_message_dtime);
  end;

  procedure error(p_message        log_message.message%type
                 ,p_message_source log_message.message_source%type
                 ,p_message_dtime  log_message.dtime%type := systimestamp) is
  begin
    log_message_(p_message,
                 p_message_source,
                 c_error_type,
                 p_message_dtime);
  end;

  -- удаление пачками по типу сообщений с указанием дней за сколько оставить
  procedure clean_message_by_type_(p_message_type     log_message.message_type%type
                                  ,p_records_ttl_days pls_integer) is
    v_delete_next boolean := true;
  begin
    while v_delete_next loop
      delete log_message t
       where t.dtime < trunc(sysdate) - p_records_ttl_days
         and t.message_type = p_message_type
         and rownum <= c_delete_size;
    
      v_delete_next := sql%rowcount >= c_delete_size;
    
      commit;
    end loop;
  end;

  procedure clear_messages is
  begin
    clean_message_by_type_(c_info_type, 10); -- 10 дней на удаление info
    clean_message_by_type_(c_warning_type, 20); -- 20 дней на удаление warning
    clean_message_by_type_(c_error_type, 30); -- 30 дней на удаление error
  end;

begin
  -- 1 раз получаем инфу
  g_sid         := sys_context('userenv', 'sid');
  g_osuser      := sys_context('userenv', 'os_user');
  g_oracle_user := sys_context('userenv', 'session_user');

  select p.pid, p.serial#
    into g_pid, g_serial#
    from v$session s
    join v$process p
      on s.paddr = p.addr
   where s.sid = g_sid;
end;
/
