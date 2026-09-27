/*
 ==============================================
 Create load silver erp loc_a101 procedure
 ==============================================
 Script purposes:
    This scripts create procedure for load data into silver layer.
    and consider to create some logs for debug the process and show
    durations time.

 Problems:
    - In column cntry (country) have difference abbreviation
    - cid (customer_key) have symbol so that it show difference key to related customer table (cust_info)

 Solutions:
    - normalizations cntry columns
    - remove '-' symbol

 Warnings:
    In the future the path of dataset should be dynamic, now it fix
    with local path.
    If in source have another country it will be show another values or new abbreviation
    that mean this scripts it not cover that case.

 Usage Example:
    EXEC DataWareHouse.silver.t_loc_a101
 */

create or alter procedure silver.t_loc_a101 as
declare @start_time DATETIME, @end_time DATETIME;
begin
    set @start_time = GETDATE();
    print('----------------------------------------------');
    print('In process on table loc_a101...');
    with transformations as (
        select
            replace(cid, '-', '') as customer_key,

            case
                when upper(trim(cntry)) in ('USA', 'US', 'UNITED STATES') then 'United States'
                when upper(trim(cntry)) in ('DE', 'GERMANY') then 'Germany'
                when upper(trim(cntry)) in ('AU', 'AUS', 'AUSTRALIA') then 'Australia'
                when upper(trim(cntry)) in ('CA', 'CAN', 'CANADA') then 'Canada'
                when upper(trim(cntry)) in ('FR', 'FRA', 'FRANCE') then 'France'
                when trim(cntry) = '' or cntry is null then 'n/a'
                else trim(cntry)
            end as country,

            dwh_create_at,
            dwh_update_at

        from bronze.erp_loc_a101
    )

    insert into silver.erp_loc_a101(
        customer_key,
        country,
        dwh_create_at,
        dwh_update_at
    )
    select * from transformations;
    set @end_time = GETDATE();

    print('Successfully transformation on loc_a101 table.');
    print('>> Time Durations: ' + CAST(datediff(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
    print('----------------------------------------------');
end;