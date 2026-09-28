/*
 ==============================================
 Create load silver erp loc_a101 procedure
 ==============================================
 Script purposes:
    This scripts create procedure for load data into silver layer.
    and consider to create some logs for debug the process and show
    durations time.

    Principles of load process : Incremental load, using watermark

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
begin
    declare @start_time DATETIME, @end_time DATETIME;
    declare @new_watermark DATETIME2, @last_watermark DATETIME2;
    declare @state_name NVARCHAR(100) = 'bronze_to_silver_loc_a101';

    print('----------------------------------------------');
    print('Starting Incremental Process on table cst_info...');
    select
        @last_watermark = last_processed_timestamp
    from silver.system_watermark
    where state_name = @state_name;

    select
        @new_watermark = max(dwh_update_at)
    from bronze.erp_loc_a101

    print('>> Last watermark : ' + cast(@last_watermark as NVARCHAR(30)));
    print('>> Current watermark : ' + cast(@new_watermark as NVARCHAR(30)));

    if @new_watermark <= @last_watermark
    begin
        print('>> No incremental data found...')
        print('----------------------------------------------')
        return;
    end

    set @start_time = GETDATE();
    print('In process on table loc_a101...');
    with incremental as (
        select
            *
        from bronze.erp_loc_a101
        where dwh_update_at > @last_watermark
    ),
    transformations as (
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

        from incremental
    )

    merge into silver.erp_loc_a101 as target
    using transformations as source
    on target.customer_key = source.customer_key
    when matched then
        update set
            target.customer_key = source.customer_key,
            target.country = source.country,
            target.dwh_create_at = source.dwh_create_at,
            target.dwh_update_at = source.dwh_update_at
    when not matched then
        insert (
            customer_key,
            country,
            dwh_create_at,
            dwh_update_at
        )
        values (
            source.customer_key,
            source.country,
            source.dwh_create_at,
            source.dwh_update_at
        );
    declare @total_rows INT = @@ROWCOUNT;

    update silver.system_watermark
    set last_processed_timestamp = @new_watermark, update_at = SYSDATETIME()
    where state_name = @state_name;

    set @end_time = GETDATE();

    print('Successfully transformation on loc_a101 table.');
    print('Total rows : ' + cast(@total_rows as NVARCHAR))
    print('>> Time Durations: ' + CAST(datediff(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
    print('----------------------------------------------');
end;