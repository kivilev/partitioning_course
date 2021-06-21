create or replace package log_message_pack is

  -- Author  : D.KIVILEV
  -- Created : 21.06.2021 16:49:22
  -- Purpose : API по логированию сообщений
  -- это не промышленное решение(!)

  -- Типы сообщений
  c_info_type    constant log_message.message_type%type := 'I';
  c_warning_type constant log_message.message_type%type := 'W';
  c_error_type   constant log_message.message_type%type := 'E';

  -- логирование информационного сообщения
  procedure info(p_message        log_message.message%type
                ,p_message_source log_message.message_source%type
                ,p_message_dtime  log_message.dtime%type := systimestamp);

  -- логирование сообщения с предупреждением
  procedure warning(p_message        log_message.message%type
                   ,p_message_source log_message.message_source%type
                   ,p_message_dtime  log_message.dtime%type := systimestamp);

  -- логирование сообщения об ошибке
  procedure error(p_message        log_message.message%type
                 ,p_message_source log_message.message_source%type
                 ,p_message_dtime  log_message.dtime%type := systimestamp);


  -- процедура очисти таблица
  -- в реальной жизни, это был бы отдельный пакет с тех функционалом по чистке
  procedure clear_messages;

end;
/
