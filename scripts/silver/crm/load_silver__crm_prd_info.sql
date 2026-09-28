/*
 ==============================================
 Create load silver crm prd_info procedure
 ==============================================
 Script purposes:
    This scripts create procedure for load data into silver layer.
    and consider to create some logs for debug the process and show
    durations time.

 Problems:
    - Duplicated prd_key
    - Unstandardized product line values
    - Missing product prices
    - Needs end date calculated from next start date

 Solutions:
    - Deduplicate by ranking the newest row using prd_start_dt
    - Map product line to standard names (Mountain, Road, etc.)
    - Use isnull for product prices
    - Use lead function to calculate product_end_date

 Warning:
    In the future the path of dataset should be dynamic, now it fix
    with local path.
    When prd_line have another value, it will be display n/a.

 Usage Example:
    EXEC DataWareHouse.silver.t_prd_info
 */

create or alter procedure silver.t_prd_info as
begin
    declare @start_time DATETIME, @end_time DATETIME;
    declare @last_watermark DATETIME2, @new_watermark DATETIME2
    declare @state_name NVARCHAR(100) = 'bronze_to_silver_prd_info'

    print('----------------------------------------------');
    print('Starting Incremental Process on table cst_info...');
    select
        @last_watermark = last_processed_timestamp
    from silver.system_watermark
    where state_name = @state_name

    select
        @new_watermark = max(dwh_update_at)
    from bronze.crm_prd_info
    print('>> Last watermark : ' + cast(@last_watermark as NVARCHAR(30)));
    print('>> Current watermark : ' + cast(@new_watermark as NVARCHAR(30)));

    if @new_watermark <= @last_watermark
    begin
        print('>> No incremental data found...')
        print('----------------------------------------------')
        return;
    end

    set @start_time = GETDATE();
    print('In process on table prd_info...');
    ;with incremental as (
        select
            *
        from bronze.crm_prd_info
        where dwh_update_at > @last_watermark
    ),
    transformations as (
        select
            prd_id as product_id,
            prd_key as product_category_key,
            replace(substring(trim(prd_key), 1, 5), '-', '_') as category_key,
            substring(trim(prd_key), 7, len(prd_key)) as product_key,
            trim(lower(prd_nm)) as product_name,
            isnull(prd_cost, 0) as product_price,

            case upper(trim(prd_line))
                when 'M' then 'Mountain'
                when 'S' then 'Other sales'
                when 'R' then 'Road'
                when 'T' then 'Touring'
                else 'n/a'
            end as product_line,

            cast(prd_start_dt as DATE) as product_start_date,
            cast(
                dateadd(
                    day,
                    -1,
                    lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)
                ) as DATE
            ) as product_end_date,
            dwh_create_at,
            dwh_update_at
        from incremental
    )
    merge into silver.crm_prd_info as target
    using transformations as source
    on target.product_id = source.product_id
    when matched then
        update set
            target.product_id = source.product_id,
            target.product_category_key = source.product_category_key,
            target.category_key = source.category_key,
            target.product_key = source.product_key,
            target.product_name = source.product_name,
            target.product_price = source.product_price,
            target.product_line = source.product_line,
            target.product_start_time = source.product_start_date,
            target.product_end_time = source.product_end_date,
            target.dwh_create_at = source.dwh_create_at,
            target.dwh_update_at = source.dwh_update_at
    when not matched then
        insert (
            product_id,
            product_category_key,
            category_key,
            product_key,
            product_name,
            product_price,
            product_line,
            product_start_time,
            product_end_time,
            dwh_create_at,
            dwh_update_at
        )
        values (
            source.product_id,
            source.product_category_key,
            source.category_key,
            source.product_key,
            source.product_name,
            source.product_price,
            source.product_line,
            source.product_start_date,
            source.product_end_date,
            source.dwh_create_at,
            source.dwh_update_at
        );
    declare @total_rows INT = @@ROWCOUNT;

    update silver.system_watermark
    set last_processed_timestamp = @new_watermark, update_at = SYSDATETIME()
    where state_name = @state_name;

    set @end_time = GETDATE();
    print('Successfully transformation on prd_info table.');
    print('Total rows : ' + cast(@total_rows as NVARCHAR))
    print('>> Time Durations: ' + CAST(datediff(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
    print('----------------------------------------------');
end;