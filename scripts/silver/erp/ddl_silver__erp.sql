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

if OBJECT_ID('silver.erp_loc_a101', 'U') is null
begin
    create table silver.erp_loc_a101(
        customer_key NVARCHAR(50),
        country NVARCHAR(50),

        dwh_create_at datetime,
        dwh_update_at datetime 
    );
end;
go

if OBJECT_ID('silver.erp_cust_az12', 'U') is null
begin
    CREATE TABLE silver.erp_cust_az12 (
        customer_key    NVARCHAR(50),
        birth_day  NVARCHAR(50),
        gender    NVARCHAR(50),

        dwh_create_at datetime,
        dwh_update_at datetime 
    );
end;
go

if OBJECT_ID('silver.erp_px_cat_g1v2', 'U') is null
begin
    CREATE TABLE silver.erp_px_cat_g1v2 (
        category_id        NVARCHAR(50),
        category           NVARCHAR(50),
        sub_category       NVARCHAR(50),
        maintenance        NVARCHAR(50),

        dwh_create_at datetime,
        dwh_update_at datetime 
    );
end;
go
