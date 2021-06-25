create table t (
  c1 int, c2 int
) partition by range ( c1 )
  interval ( 10 ) (
    partition p0 values less than ( 11 )
  );

create index i on t ( c2 );


insert into t 
select t2.object_id, t2.object_id 
 from all_objects, all_objects, all_objects t2;

   

select * from user_tab_partitions t where t.table_name = 'T';

alter table t truncate partition sys_p21917;

select index_name
      ,status
  from user_indexes t
 where t.index_name = 'I'

alter index i rebuild;

alter table t truncate partition p0 update global indexes;



