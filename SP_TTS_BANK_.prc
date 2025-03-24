CREATE OR REPLACE procedure HR.sp_tts_bank_newaccount(
p_customer_id in varchar2 ,
p_customer_name in varchar2 , 
p_customer_phno in  number , 
p_customer_mail in varchar2,
p_aadhar_no in number, 
p_cus_pan_no in varchar2,
p_password in varchar2 ,
p_sub_product_id in  number ,
p_trans_amount in number ,
p_trans_type in varchar2 ,
p_trans_for in varchar2 ,
p_trans_mode in varchar2 ,
p_benef_account in varchar2 ,
p_flag in number ,
p_message_ out varchar2
)
as
l_cusid number ;
l_cus_prod_id number ;
l_acc_no number ;
l_avl_balanace number ;
l_cpi number ;
l_wdl number ;
l_sum_trans number ;
l_duplicate_found number ;
l_current_pass varchar2(50) ;

begin
if p_flag = 1 then
    
    if p_trans_type = 'c' then
        insert into ttsbank_customers(customer_id, customer_name, customer_phno, customer_mail, aadhar_no, pan_no, password)
        values(cus_id_seq.nextval, p_customer_name, p_customer_phno , p_customer_mail ,p_aadhar_no , p_cus_pan_no , p_password)
        returning customer_id into l_cusid ;

        insert into ttsbank_cus_products(cus_product_id, sub_product_id, customer_id, account_no, account_open_on, status ,available_balanace)
        values(cus_product_id_seq.nextval , p_sub_product_id , l_cusid , acc_no_gen_sq.nextval , sysdate , 'Active',p_trans_amount) 
        returning cus_product_id , account_no into l_cus_prod_id , l_acc_no ;
       
        insert into ttsbank_cus_transactions(cus_trans_id, cus_product_id, trans_amount, trans_type, trans_on, trans_for, trans_mode, account_balanace)
        values(trans_id_seq.nextval , l_cus_prod_id ,p_trans_amount , 'c' , sysdate , p_trans_for , p_trans_mode , p_trans_amount) ;

        p_message_ := 'Account Created And  A/C No is'||l_acc_no ;
    else 
        raise_application_error(-20005,'first trasn_type must be credit while opening account') ;
        end if ;



elsif p_flag = 2 then
    if p_trans_type = 'c' then
        select available_balanace into l_avl_balanace from  ttsbank_cus_products
        where customer_id = p_customer_id and  sub_product_id = p_sub_product_id ;
        select cus_product_id into l_cpi from ttsbank_cus_products 
        where customer_id = p_customer_id and sub_product_id = p_sub_product_id;
        
        insert into ttsbank_cus_transactions(  cus_trans_id, cus_product_id, trans_amount, trans_type, trans_on, trans_for, trans_mode, account_balanace)
        values(trans_id_seq.nextval,l_cpi,p_trans_amount,p_trans_type,sysdate,p_benef_account,p_trans_mode, p_trans_amount+l_avl_balanace) ;
        
        update ttsbank_cus_products set available_balanace = p_trans_amount + l_avl_balanace 
        where customer_id = p_customer_id and sub_product_id = p_sub_product_id ;
        p_message_ := 'Amount credited '||P_trans_amount||'to '||l_acc_no ;
        
    elsif p_trans_type = 'd' then
        select PASSWORD into l_current_pass from  ttsbank_customers where customer_id = p_customer_id ;
        if l_current_pass != p_customer_id then
          raise_application_error(-20007,'invalid password') ;
        end if ;
        select available_balanace into l_avl_balanace from  ttsbank_cus_products 
        
        where customer_id = p_customer_id and  sub_product_id = p_sub_product_id ;
        select cus_product_id into l_cpi from ttsbank_cus_products 
        where customer_id = p_customer_id and sub_product_id = p_sub_product_id;
        if p_trans_amount < l_avl_balanace then
            select withdrawl_limit into l_wdl from ttsbank_sub_products
            where sub_product_id = 3001 ;
            
            select nvl(sum(trans_amount),0) into l_sum_trans from ttsbank_cus_transactions A , ttsbank_cus_products B
            where a.cus_product_id = b.cus_product_id and B.sub_product_id = p_sub_product_id and customer_id = p_customer_id and trans_type = 'd' ;
            dbms_output.put_line('available Bal- '||l_avl_balanace||'withdrwal limit -'||l_wdl||'total transaction -'||l_sum_trans) ;
            if   l_sum_trans + p_trans_amount < l_wdl then 
            
            
                insert into ttsbank_cus_transactions(  cus_trans_id, cus_product_id, trans_amount, trans_type, trans_on, trans_for, trans_mode, account_balanace)
                values(trans_id_seq.nextval,l_cpi,p_trans_amount,p_trans_type,sysdate,p_benef_account,p_trans_mode, l_avl_balanace - p_trans_amount  ) ;
        
                update ttsbank_cus_products set available_balanace = l_avl_balanace - p_trans_amount  
                where customer_id = p_customer_id and sub_product_id = p_sub_product_id ;
                p_message_ := 'Amount debited '||P_trans_amount ;
              
            else  

             raise_application_error(-20001,'withdrawl limit reached') ;
         
            end if ;
         else
         raise_application_error(-20002,'insufficient fund') ;
       
         end if ;
        end if ;
        
elsif p_flag = 3 then
     if p_trans_type = 'c' then
     insert into ttsbank_cus_products(cus_product_id, sub_product_id, customer_id, account_no, account_open_on, status ,available_balanace)
     values(cus_product_id_seq.nextval , p_sub_product_id , p_customer_id , acc_no_gen_sq.nextval , sysdate , 'Active',p_trans_amount) 
     returning cus_product_id , account_no into l_cus_prod_id , l_acc_no ;
    
     insert into ttsbank_cus_transactions(cus_trans_id, cus_product_id, trans_amount, trans_type, trans_on, trans_for, trans_mode, account_balanace)
     values(trans_id_seq.nextval , l_cus_prod_id ,p_trans_amount , p_trans_type , sysdate , p_trans_for , p_trans_mode , p_trans_amount) ;

     p_message_ := 'Account created And A/C No is'||l_acc_no ;
     
     else
        raise_application_error(-20005,'first trasn_type must be credit while opening account') ;

     end if ;

     elsif p_flag = 4 then 
        select count(*) into l_duplicate_found from(
        select password from ttsbank_customers where customer_id =  p_customer_id
        union 
        select old_password from(select OLD_PASSWORD from  ttsbank_password_track
        where customer_id = p_customer_id
        order by PASSWORD_CHANGED_ON desc )
        where rownum <= 2) where password = p_password ;
        if  l_duplicate_found >0 then
            dbms_output.put_line('try a new password... Dont repeat the same') ;
            raise_application_error(-20003,'try new Different password...dont use the same password') ;
            end if ;
        update ttsbank_customers set PASSWORD = p_password where customer_id = p_customer_id ;
        p_message_ := 'password Changed' ;
      
end if ;
end ;
/