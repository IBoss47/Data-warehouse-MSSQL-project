/*
 ==============================================
 Create load silver erp px_cat_g1v2 procedure
 ==============================================
 Script purposes:
    This scripts create procedure for load data into silver layer.
    and consider to create some logs for debug the process
    This scripts will be load data 1:1 from bronze layer to silver layer
    on px_cat_g1v2 table.

    Principles of load process : Incremental load, using watermark

 Problems:
    - None

 Solutions:
    - 1:1 Load from bronze to silver layer

 Warning:
    In the future the path of dataset should be dynamic, now it fix
    with local path.

 Usage Example:
    EXEC DataWareHouse.silver.t_px_cat_g1v2
 */

create or alter procedure silver.t_px_cat_g1v2 as
begin
    declare @start_time DATETIME, @end_time DATETIME;
    declare @new_watermark DATETIME2, @last_watermark DATETIME2;
    declare @state_name NVARCHAR(100) = 'bronze_to_silver_px_cat_g1v2';

    print('----------------------------------------------');
    print('Starting Incremental Process on table cst_info...');
    select
        @last_watermark = last_processed_timestamp
    from silver.system_watermark
    where state_name = @state_name;

    select
        @new_watermark = max(dwh_update_at)
    from bronze.erp_px_cat_g1v2

    print('>> Last watermark : ' + cast(@last_watermark as NVARCHAR(30)));
    print('>> Current watermark : ' + cast(@new_watermark as NVARCHAR(30)));

    if @new_watermark <= @last_watermark
    begin
        print('>> No incremental data found...')
        print('----------------------------------------------')
        return;
    end

    set @start_time = GETDATE();
    print('In process on table px_cat_g1v2...');
    ;with incremental as (
        select
            *
        from bronze.erp_px_cat_g1v2
        where dwh_update_at > @last_watermark
    )

    merge into silver.erp_px_cat_g1v2 as target
    using incremental as source
    on target.category_id = source.id
    when matched then
        update set
            target.category_id = source.id,
            target.category = source.cat,
            target.sub_category = source.subcat,
            target.maintenance = source.maintenance,
            target.dwh_create_at = source.dwh_create_at,
            target.dwh_update_at = source.dwh_update_at
    when not matched then
        insert (
            category_id,
            category,
            sub_category,
            maintenance,
            dwh_create_at,
            dwh_update_at
        )
        values (
            source.id,
            source.cat,
            source.subcat,
            source.maintenance,
            source.dwh_create_at,
            source.dwh_update_at
        );
    declare @total_rows INT = @@ROWCOUNT;

    update silver.system_watermark
    set last_processed_timestamp = @new_watermark, update_at = SYSDATETIME()
    where state_name = @state_name;

    set @end_time = GETDATE();

    print('Successfully transformation on px_cat_g1v2 table.');
    print('Total rows : ' + cast(@total_rows as NVARCHAR))
    print('>> Time Durations: ' + CAST(datediff(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
    print('----------------------------------------------');
end;