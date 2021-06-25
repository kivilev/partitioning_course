create table t (
  c1 int, c2 int, c3 int
);

create index i1 on t ( c1 );
create index i2 on t ( c2 );
create index i3 on t ( c3 );

alter table t
  modify partition by range ( c1 ) 
  interval ( 100 ) (
    partition p0 values less than ( 101 )
  ) update indexes (
    i1 local,
    i2 global,
    i3 global 
      partition by hash ( c3 ) 
      partitions 4
  );

select index_name, partitioned 
from   user_indexes
where  table_name = 'T';

INDEX_NAME    PARTITIONED   
I1            YES            
I2            NO             
I3            YES 

select index_name, partition_name 
from   user_ind_partitions;
