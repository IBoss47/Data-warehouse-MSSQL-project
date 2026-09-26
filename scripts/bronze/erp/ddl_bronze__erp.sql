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

if OBJECT_ID('bronze.erp_loc_a101', 'U') is null
begin
    create table bronze.erp_loc_a101(
        cid NVARCHAR(50),
        cntry NVARCHAR(50),

        dwh_create_at datetime default GETDATE(),
        dwh_update_at datetime default GETDATE()
    );
end;
go

if OBJECT_ID('bronze.erp_cust_az12', 'U') is null
begin
    CREATE TABLE bronze.erp_cust_az12 (
        cid    NVARCHAR(50),
        bdate  NVARCHAR(50),
        gen    NVARCHAR(50),

        dwh_create_at datetime default GETDATE(),
        dwh_update_at datetime default GETDATE()
    );
end;
go

if OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') is null
begin
    CREATE TABLE bronze.erp_px_cat_g1v2 (
        id           NVARCHAR(50),
        cat          NVARCHAR(50),
        subcat       NVARCHAR(50),
        maintenance  NVARCHAR(50),

        dwh_create_at datetime default GETDATE(),
        dwh_update_at datetime default GETDATE()
    );
end;
go
