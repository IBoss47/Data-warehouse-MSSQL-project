/*
 ==============================================
 Create Table and Timestamp
 ==============================================
 Script Purposes:
    This scrips create table that store the data and create timestamp
    for tracking newest data and choose them in silver layer

    Timestamp (dwh_create_at, dwh_update_at) will be stamp when
    data load from view and it auto generate timestamp

 Workflows:
    Source --> view --> table (timestamp saved)
 */

create or alter procedure bronze.ddl_create_table_crm as
begin
    if OBJECT_ID('bronze.crm_prd_info', 'U') is null
    begin
        create table bronze.crm_prd_info (
            prd_id       INT,
            prd_key      NVARCHAR(50),
            prd_nm       NVARCHAR(50),
            prd_cost     INT,
            prd_line     NVARCHAR(50),
            prd_start_dt NVARCHAR(50),
            prd_end_dt   NVARCHAR(50),

            dwh_create_at datetime default GETDATE(),
            dwh_update_at datetime default GETDATE()
        );
    end;

    if OBJECT_ID('bronze.crm_sales_details', 'U') is null
    begin
        create table bronze.crm_sales_details (
            sls_ord_num  NVARCHAR(50),
            sls_prd_key  NVARCHAR(50),
            sls_cust_id  INT,
            sls_order_dt INT,
            sls_ship_dt  INT,
            sls_due_dt   INT,
            sls_sales    INT,
            sls_quantity INT,
            sls_price    INT,

            dwh_create_at datetime default GETDATE(),
            dwh_update_at datetime default GETDATE()
        );
    end;

    if OBJECT_ID('bronze.crm_cust_info', 'U') is null
    begin
        CREATE TABLE bronze.crm_cust_info (
            cst_id              INT,
            cst_key             NVARCHAR(50),
            cst_firstname       NVARCHAR(50),
            cst_lastname        NVARCHAR(50),
            cst_marital_status  NVARCHAR(50),
            cst_gndr            NVARCHAR(50),
            cst_create_date     NVARCHAR(50),

            dwh_create_at datetime default GETDATE(),
            dwh_update_at datetime default GETDATE()
        );
    end;
end;







