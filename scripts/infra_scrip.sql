/*
 ==============================================
 Create Database and Schemas
 ==============================================
 Script Purpose:
    This script creates a new database name 'DataWareHouse' after checking if it not already exists.
    If the database exists, it is dropped and recreated.

    And the script sets up three schemas within database: 'bronze', 'silver', 'gold' layers (medallion architecture).

Warning:
    Running this script will drop the entire 'DataWareHouse' database if it exists.
    All data in this database will be permanently deleted. Proceed with caution and
    ensure you have proper backups before running this script.
 */

use master;
go

-- Check database... if it exists will be drop database
if exists (select 1 from sys.databases where name = 'DataWareHouse')
begin
    use master;
    -- set only one user can access... another user will be disconnect database (rollback)
    alter database DataWareHouse set single_user with rollback immediate;
    drop database DataWareHouse;
end
go

create database DataWareHouse;
go
use DataWareHouse;
go

create schema bronze;
go
create schema silver;
go
create schema gold;
go

if OBJECT_ID('silver.system_watermark', 'U') is null
begin
    create table silver.system_watermark(
        state_name NVARCHAR(100) primary key,
        last_processed_timestamp DATETIME2,
        update_at DATETIME2
    );

    insert into silver.system_watermark(state_name, last_processed_timestamp, update_at)
    select src.state_name, src.last_processed_timestamp, src.update_at
    from (
        values
            ('bronze_to_silver_cst_info',       CAST('1900-01-01 00:00:00' AS DATETIME2), SYSDATETIME()),
            ('bronze_to_silver_prd_info',       CAST('1900-01-01 00:00:00' AS DATETIME2), SYSDATETIME()),
            ('bronze_to_silver_sales_details',  CAST('1900-01-01 00:00:00' AS DATETIME2), SYSDATETIME()),
            ('bronze_to_silver_cust_az12',      CAST('1900-01-01 00:00:00' AS DATETIME2), SYSDATETIME()),
            ('bronze_to_silver_loc_a101',       CAST('1900-01-01 00:00:00' AS DATETIME2), SYSDATETIME()),
            ('bronze_to_silver_px_cat_g1v2',    CAST('1900-01-01 00:00:00' AS DATETIME2), SYSDATETIME())
    ) as src(state_name, last_processed_timestamp, update_at)
    where not exists (
        select 1 from silver.system_watermark target where target.state_name = src.state_name
    );
end;
go






