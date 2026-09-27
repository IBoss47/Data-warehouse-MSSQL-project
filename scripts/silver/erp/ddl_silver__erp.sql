/*
 ==============================================
 Create Table ERP
 ==============================================
 Script Purposes:
    This scrips are created table for store data after transformations
    and do some normalize
    for instead :
        - rename of columns
        - cast data type
 */

create or alter procedure silver.ddl_erp_scripts as
begin
    if OBJECT_ID('silver.erp_loc_a101', 'U') is null
    begin
        create table silver.erp_loc_a101(
            customer_key NVARCHAR(50),
            country NVARCHAR(50),

            dwh_create_at datetime,
            dwh_update_at datetime
        );
    end;

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
end;
go
