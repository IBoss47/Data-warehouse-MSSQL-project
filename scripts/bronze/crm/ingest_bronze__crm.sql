/*
 ==============================================
 Create View
 ==============================================
 Script Purposes:
    This scripts create view for each table, and load from source
    just copy 1:1 not include data warehouse timestamp.
*/

use DataWareHouse;
go

create or alter view bronze.vw_crm_cust_info as
select
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
from bronze.crm_cust_info;
go

create or alter view bronze.vw_crm_prd_info as
select
    prd_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
from bronze.crm_prd_info;
go

create or alter view bronze.vw_crm_sales_details as
select
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
from bronze.crm_sales_details;
go



