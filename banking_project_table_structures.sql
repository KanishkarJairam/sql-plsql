create table ttsbank_banks(
bank_id number  ,
bank_code varchar2(50) ,
bank_location varchar2(50),
is_headoffice varchar2(1) ,
constraint bank_id_pk primary key(bank_id) ,
constraint is_headoffice_ck check(is_headoffice in('y','n'))
 );


create table ttsbank_products(
product_id number ,
product_name varchar2(50) ,
product_code varchar2(2),
constraint product_id_pk primary key(product_id)
);


create table ttsbank_sub_products(
sub_product_id number ,
product_id number ,
features varchar2(50),
balance_limit number ,
constraint sub_product_id_pk primary key(sub_product_id) ,
constraint product_id_fk foreign key(product_id) references ttsbank_products(product_id)
);



create table ttsbank_employees(
employee_id number ,
employee_name varchar2(50) ,
bank_id number,
constraint employee_id_pk primary key(employee_id) ,
constraint bank_id_fk foreign key(bank_id) references ttsbank_banks(bank_id)
);


create table ttsbank_customers(
customer_id number ,
customer_name varchar2(50) ,
customer_phno number ,
customer_mail varchar2(50) ,
aadhar_no number ,
pan_no varchar2(15) ,
password varchar2(25) ,
constraint customer_id_pk primary key(customer_id) ,
constraint customer_phno_ck check(length(customer_phno)=10) ,
constraint aadhar_no_ck check(length(aadhar_no)=12)
);



create table ttsbank_cus_products(
cus_product_id number ,
sub_product_id number ,
customer_id number ,
account_no number ,
account_open_on date default sysdate ,
status varchar2(15) default 'Active',
available_balanace number ,
bank_id number ,
constraint cus_product_id_pk  primary key(cus_product_id) ,
constraint sub_product_id_fk foreign key(sub_product_id) references ttsbank_sub_products(sub_product_id) ,
constraint customer_id_fk foreign key(customer_id) references ttsbank_customers(customer_id) ,
constraint cus_products_bank_id_fk foreign key(bank_id) references ttsbank_banks(bank_id) ,
constraint account_no_uk unique(account_no)
);


create table ttsbank_cus_transactions(
cus_trans_id number ,
cus_product_id number ,
trans_amount number ,
trans_type varchar2(1),
trans_on date default sysdate ,
benef_account varchar2(25) ,
trans_mode varchar2(25) ,
account_balanace number ,
constraint cus_trans_id_pk primary key(cus_trans_id) ,
constraint cus_product_id_fk foreign key(cus_product_id) references ttsbank_cus_products(cus_product_id) ,
constraint trans_type_ck check(trans_type in ('c','d'))
);

alter table ttsbank_transactions rename to ttsbank_cus_transactions ;

create table ttsbank_password_track(
track_id number ,
customer_id number ,
customer_password varchar2(25),
password_changed_on date default sysdate ,
constraint track_id_pk primary key(track_id) ,
constraint password_track_customer_id_fk foreign key(customer_id) references ttsbank_customers(customer_id)
);


----creating sequence
---customer_id
create sequence cus_id_seq start with 5000 increment by 1 ;
---cus_product_id
create sequence  cus_product_id_seq start with 6000 increment by 1 ;
---creating sequence for account number generation
create sequence acc_no_gen_sq start with 100054321001 increment by 1 ;
---creating sequence for generating transaction_id \
create sequence trans_id_seq start with 7000 increment by 1 ;
---craeting sequence for account number generation
create sequence track_id_seq start with 8000 increment by 1 ;


select * from ttsbank_banks ;

select * from ttsbank_products ;

select * from ttsbank_sub_products ;

select * from ttsbank_employees ;

select * from ttsbank_customers ;

select * from ttsbank_cus_products ;

select * from ttsbank_cus_transactions ;


delete from  ttsbank_customers where  CUSTOMER_ID = 5027 ;

select * from ttsbank_password_track ;

commit ;
/*
create or replace trigger pass_track before update of PASSWORD on ttsbank_customers for each row
begin
    insert into   ttsbank_password_track (TRACK_ID, CUSTOMER_ID, OLD_PASSWORD, PASSWORD_CHANGED_ON)
    values(track_id_seq.nextval ,:old.customer_id ,:old.PASSWORD, sysdate) ;
end;
/
*/

----sp_password_remover
/*
create or replace procedure sp_password_remover as
begin
delete from ttsbank_password_track where track_id  not in(
select track_id from(
 select track_id , customer_id ,  dense_rank() over(partition by customer_id order by PASSWORD_CHANGED_ON desc) as rn
from ttsbank_password_track ) where rn <=2 
);

end ;
/

*/
---SCHEDULER
/*
begin
dbms_scheduler.create_job(

job_name =>  'password_deleter',
job_type => 'stored_procedure',
job_action  => 'sp_password_remover',
start_date  =>  TO_DATE('19/FEB/2015 11:15:00 AM', 'DD/MON/YYYY HH:MI:SS AM') ,
repeat_interval => 'freq = minutely;interval = 5',
end_date =>  TO_DATE('19/FEB/2015 8:00:00 PM', 'DD/MON/YYYY HH:MI:SS AM'),
auto_drop => false ,
comments  => 'This job will delete all the old password from password_track_table'
);
end ;
/
---TO ENABLE SCHEDULER
execute dbms_scheduler.enable('password_deleter') ;
---TO DISBABLE SCHEDULER 
execute dbms_scheduler.disable('password_deleter') ;

*/


DELETE  ttsbank_cus_transactions ;





flashback table ttsbank_password_track to before drop ;


