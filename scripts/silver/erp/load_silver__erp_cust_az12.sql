/*
 ==============================================
 Create load silver erp cust_az12 procedure
 ==============================================
 Script purposes:
    This scripts create procedure for load data into silver layer.
    and consider to create some logs for debug the process and show
    durations time.

 Problems:
    - cid have useless prefix like 'NAS'
    - bdate have outliner or trash data like birth day in the future
    - gender have difference value but it same meaning

 Solutions:
    - remove prefix use substring functions
    - remove invalid birth day values and instead of null
    - normalizations gender columns

 Warnings:
    In the future the path of dataset should be dynamic, now it fix
    with local path.
    If in another case cid have difference pattern like suffix not prefix.
    This scripts will do wrong then create trash data

 Usage Example:
    EXEC DataWareHouse.silver.t_cust_az12
 */


create or alter procedure silver.t_cust_az12 as
begin
    declare @start_time DATETIME, @end_time DATETIME;
    declare @new_watermark DATETIME2, @last_watermark DATETIME2;
    declare @state_name NVARCHAR(100) = 'bronze_to_silver_cust_az12';

    print('----------------------------------------------');
    print('Starting Incremental Process on table cst_info...');
    select
        @last_watermark = last_processed_timestamp
    from silver.system_watermark
    where state_name = @state_name;

    select
        @new_watermark = max(dwh_update_at)
    from bronze.erp_cust_az12

    print('>> Last watermark : ' + cast(@last_watermark as NVARCHAR(30)));
    print('>> Current watermark : ' + cast(@new_watermark as NVARCHAR(30)));

    if @new_watermark <= @last_watermark
    begin
        print('>> No incremental data found...')
        print('----------------------------------------------')
        return;
    end

    set @start_time = GETDATE();
    print('In process on table cust_az12...');
    with incremental as (
        select
            *
        from bronze.erp_cust_az12
        where dwh_update_at > @last_watermark
    ),
    transformations as (
        select
            case
                when len(cid) != 10 then substring(cid, 4, len(cid))
                else cid
            end as customer_key,

            case
                when bdate > GETDATE() then NULL
                else bdate
            end as birth_day,

            case
                when upper(trim(gen)) in ('M', 'MALE') then 'Male'
                when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
                else 'n/a'
            end as gender,

            dwh_create_at,
            dwh_update_at

        from incremental
    )
    merge into silver.erp_cust_az12 as target
    using transformations as source
    on target.customer_key = source.customer_key
    when matched then
        update set
            target.customer_key = source.customer_key,
            target.birth_day = source.birth_day,
            target.gender = source.gender,
            target.dwh_create_at = source.dwh_create_at,
            target.dwh_update_at = source.dwh_update_at
    when not matched then

        insert (
            customer_key,
            birth_day,
            gender,
            dwh_create_at,
            dwh_update_at
        )
        values (
            source.customer_key,
            source.birth_day,
            source.gender,
            source.dwh_create_at,
            source.dwh_update_at
        );
    declare @total_rows INT = @@ROWCOUNT;

    update silver.system_watermark
    set last_processed_timestamp = @new_watermark, update_at = SYSDATETIME()
    where state_name = @state_name;

    set @end_time = GETDATE();

    print('Successfully transformation on cust_az12 table.');
    print('Total rows : ' + cast(@total_rows as NVARCHAR))
    print('>> Time Durations: ' + CAST(datediff(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
    print('----------------------------------------------');
end;
