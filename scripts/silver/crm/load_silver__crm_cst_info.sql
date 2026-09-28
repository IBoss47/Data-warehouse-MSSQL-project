/*
 ==============================================
 Create load silver crm cst_info procedure
 ==============================================
 Script purposes:
    This scripts create procedure for load data into silver layer.
    and consider to create some logs for debug the process and show
    durations time.

 Problems:
    - Duplicated cst_id and cst_key
    - Unstandardized marital_status and gender values
    - Extra spaces and mixed casing in names

 Solutions:
    - Solve deduplication by ranking the newest row using cst_create_date
    - Standardize marital_status ('M'/'S') and gender ('M'/'F')
    - Trim and lower names

 Warning:
    In the future the path of dataset should be dynamic, now it fix
    with local path.

 Usage Example:
    EXEC DataWareHouse.silver.t_cst_info
 */

create or alter procedure silver.t_cst_info as
begin
    declare @start_time DATETIME, @end_time DATETIME;
    declare @new_watermark DATETIME2, @last_watermark DATETIME2;
    declare @state_name NVARCHAR(100) = 'bronze_to_silver_cst_info';

    print('----------------------------------------------');
    print('Starting Incremental Process on table cst_info...');
    select
        @last_watermark = last_processed_timestamp
    from silver.system_watermark
    where state_name = @state_name;

    select
        @new_watermark = max(dwh_update_at)
    from bronze.crm_cust_info

    print('>> Last watermark : ' + cast(@last_watermark as NVARCHAR(30)));
    print('>> Current watermark : ' + cast(@new_watermark as NVARCHAR(30)));

    if @new_watermark <= @last_watermark
    begin
        print('>> No incremental data found...')
        print('----------------------------------------------')
        return;
    end

    set @start_time = GETDATE();
    print('In process on table cst_info...');
    ;with incremental as (
        select
            *
        from bronze.crm_cust_info
        where dwh_update_at > @last_watermark
    ),
    latest_data as (
        select
            *,
            row_number() over(
                partition by cst_id
                order by dwh_update_at desc, dwh_create_at desc, cst_create_date desc
            ) as rn
        from incremental
    ),
    filter_data as (
        select
            *
        from latest_data
        where rn = 1 and cst_id is not null
    ),
    transformation as (
        select
            cst_id as customer_id,
            cst_key as customer_key,
            trim(lower(cst_firstname)) as first_name,
            trim(lower(cst_lastname)) as last_name,

            case upper(trim(cst_marital_status))
                when 'S' then 'Single'
                when 'M' then 'Married'
                else 'n/a'
            end as marital_status,

            case upper(trim(cst_gndr))
                when 'F' then 'Female'
                when 'M' then 'Male'
                else 'n/a'
            end as gender,

            cast(cst_create_date as date) as source_create_date,
            dwh_create_at,
            dwh_update_at

        from filter_data
    )

    merge into silver.crm_cust_info as target
    using transformation as source
    on target.customer_id = source.customer_id
    when matched then
        update set
            target.customer_key       = source.customer_key,
            target.first_name         = source.first_name,
            target.last_name          = source.last_name,
            target.marital_status     = source.marital_status,
            target.gender             = source.gender,
            target.source_create_date = source.source_create_date,
            target.dwh_create_at      = source.dwh_create_at,
            target.dwh_update_at      = source.dwh_update_at
    when not matched then
        insert (
            customer_id,
            customer_key,
            first_name,
            last_name,
            marital_status,
            gender,
            source_create_date,
            dwh_create_at,
            dwh_update_at
        )
        values (
            source.customer_id,
            source.customer_key,
            source.first_name,
            source.last_name,
            source.marital_status,
            source.gender,
            source.source_create_date,
            source.dwh_create_at,
            source.dwh_update_at
        );
    declare @total_rows INT = @@ROWCOUNT;

    update silver.system_watermark
    set last_processed_timestamp = @new_watermark, update_at = SYSDATETIME()
    where state_name = @state_name;

    set @end_time = GETDATE();
    print('Successfully transformation on cst_info table.');
    print('Total rows : ' + cast(@total_rows as NVARCHAR))
    print('>> Time Durations: ' + CAST(datediff(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
    print('----------------------------------------------');
end;