insert into t 
select t2.object_id, t2.object_id 
 from all_objects, all_objects, all_objects t2;
