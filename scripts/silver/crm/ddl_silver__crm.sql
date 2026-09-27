/*
 ==============================================
 Create Table CRM
 ==============================================
 Script Purposes:
    This scrips are created table for store data after transformations
    and do some normalize
    for instead :
        - rename of columns
        - cast data type
 */

use DataWareHouse;
go

create or alter procedure silver.ddl_crm_scripts as
begin
    if OBJECT_ID('silver.crm_prd_info', 'U') is null
    begin
        create table silver.crm_prd_info (
            product_id         INT,
            product_category_key      NVARCHAR(50),
            category_key       NVARCHAR(50),
            product_key        NVARCHAR(50),
            product_name       NVARCHAR(50),
            product_price      INT,
            product_line       NVARCHAR(50),
            product_start_time DATE,
            product_end_time   DATE,

            dwh_create_at DATETIME,
            dwh_update_at DATETIME
        );
    end;

    if OBJECT_ID('silver.crm_sales_details', 'U') is null
    begin
        create table silver.crm_sales_details (
            order_number  NVARCHAR(50),
            product_key   NVARCHAR(50),
            customer_id   INT,
            order_date    DATE,
            shipped_date  DATE,
            due_date      DATE,
            total_sales   INT,
            quantity      INT,
            unit_price    INT,

            dwh_create_at DATETIME,
            dwh_update_at DATETIME
        );
    end;

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

            dwh_create_at DATETIME,
            dwh_update_at DATETIME
        );
    end;
end;
go







