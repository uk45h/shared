use role sysadmin;
use testy.testy;
use warehouse TRANSFORMING;

create or replace table streaming (id int, text varchar);

CREATE OR REPLACE STREAM stream1 on table streaming; 
CREATE OR REPLACE STREAM stream2 on table streaming; 
CREATE OR REPLACE STREAM stream3 on table streaming; 

show streams;
drop stream stream3;

insert into streaming values (1,'a');
insert into streaming values (2,'b');
insert into streaming values (3,'c');

select * from streaming;

--Step 1
select * from stream3;

create or replace table streaming_step1 as
    select * from stream1 where id=2;
--delete from streaming_step1

--Step 2
select * from stream1;
select * from stream2;

insert into streaming values (4,'d');
insert into streaming values (5,'d');
delete from streaming where id=4;
update streaming set text='X' where id=3;

--Step 3
select * from stream1;
select * from stream2;