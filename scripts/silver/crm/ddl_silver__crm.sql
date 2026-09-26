/*
 ==============================================
 Create Table and Timestamp
 ==============================================
 Script Purposes:
    This scrips create table that store the data and create timestamp
    for tracking newest data and choose them in intermediate layer

    Timestamp (dwh_create_at, dwh_update_at) will be stamp when
    data load from view and it auto generate timestamp

 Workflows:
    Source --> view --> table (timestamp saved)
 */

use DataWareHouse;
go

if OBJECT_ID('silver.crm_prd_info', 'U') is null
begin
    create table silver.crm_prd_info (
        prd_id       INT,
        prd_key      NVARCHAR(50),
        prd_nm       NVARCHAR(50),
        prd_cost     INT,
        prd_line     NVARCHAR(50),
        prd_start_dt NVARCHAR(50),
        prd_end_dt   NVARCHAR(50),

        dwh_create_at datetime,
        dwh_update_at datetime
    );
end;
go

if OBJECT_ID('silver.crm_sales_details', 'U') is null
begin
    create table silver.crm_sales_details (
        sls_ord_num  NVARCHAR(50),
        sls_prd_key  NVARCHAR(50),
        sls_cust_id  INT,
        sls_order_dt INT,
        sls_ship_dt  INT,
        sls_due_dt   INT,
        sls_sales    INT,
        sls_quantity INT,
        sls_price    INT,

        dwh_create_at datetime,
        dwh_update_at datetime
    );
end;
go

if OBJECT_ID('silver.crm_cust_info', 'U') is null
begin
    CREATE TABLE silver.crm_cust_info (
        customer_id              INT,
        customer_key             NVARCHAR(50),
        first_name       NVARCHAR(50),
        last_name        NVARCHAR(50),
        marital_status  NVARCHAR(50),
        gender            NVARCHAR(50),
        source_create_date     DATE,

        dwh_create_at datetime,
        dwh_update_at datetime
    );
end;
go







