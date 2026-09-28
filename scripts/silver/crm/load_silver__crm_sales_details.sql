/*
 ==============================================
 Create load silver crm sales_details procedure
 ==============================================
 Script purposes:
    This scripts create procedure for load data into silver layer.
    and consider to create some logs for debug the process and show
    durations time.

    Principles of load process : Incremental load, using watermark

 Problems:
    - Invalid date formats (e.g., negative values or incorrect length)
    - Missing or invalid unit prices and total sales
    - Negative or inconsistent sales totals compared to quantity * price

 Solutions:
    - Cast invalid dates to NULL
    - Derive missing unit prices using total_sales / quantity
    - Recalculate total_sales as abs(quantity) * unit_price if inconsistent or missing

 Warning:
    In the future the path of dataset should be dynamic, now it fix
    with local path.

 Usage Example:
    EXEC DataWareHouse.silver.t_sales_details
 */

create or alter procedure silver.t_sales_details as
begin
    declare @start_time DATETIME, @end_time DATETIME;
    declare @last_watermark DATETIME2, @new_watermark DATETIME2;
    declare @state_name VARCHAR(100) = 'bronze_to_silver_sales_details';

    print('----------------------------------------------');
    print('Starting Incremental Process on table cst_info...');
    select
        @last_watermark = last_processed_timestamp
    from silver.system_watermark
    where state_name = @state_name;
    set @start_time = GETDATE();

    select
        @new_watermark = max(dwh_update_at)
    from bronze.crm_sales_details
    print('>> Last watermark : ' + cast(@last_watermark as NVARCHAR(30)));
    print('>> Current watermark : ' + cast(@new_watermark as NVARCHAR(30)));

    if @new_watermark <= @last_watermark
    begin
        print('>> No incremental data found...')
        print('----------------------------------------------')
        return;
    end

    print('In process on table sales_details...');
    with incremental as (
        select
            *
        from bronze.crm_sales_details
        where dwh_update_at > @last_watermark
    ),
    base_clean as (
        select
            sls_ord_num as order_number,
            sls_prd_key as product_key,
            sls_cust_id as customer_id,

            case
                when sls_order_dt < 0 or len(sls_order_dt) != 8 then null
                else cast(cast(sls_order_dt as VARCHAR) as DATE)
            end as order_date,

            case
                when sls_ship_dt < 0 or len(sls_ship_dt) != 8 then null
                else cast(cast(sls_ship_dt as VARCHAR) as DATE)
            end as shipped_date,

            case
                when sls_due_dt < 0 or len(sls_due_dt) != 8 then null
                else cast(cast(sls_due_dt as VARCHAR) as DATE)
            end as due_date,

            sls_sales as total_sales,
            sls_quantity as quantity,

            case
                when sls_price is null or sls_price <= 0
                    then sls_sales / nullif(sls_quantity, 0)
                else sls_price
            end as unit_price,

            dwh_create_at,
            dwh_update_at
        from incremental
    ),
    transformations as (
        select
            convert(
                varchar(64),
                hashbytes('SHA2_256', UPPER(TRIM(ISNULL(order_number, ''))) + '|' + UPPER(TRIM(ISNULL(product_key, '')))),
                2
            ) AS sales_key,

            order_number,
            product_key,
            customer_id,

            order_date,
            shipped_date,
            due_date,

            case
                when total_sales <= 0 or total_sales is null or total_sales !=  quantity * unit_price
                    then abs(quantity) * unit_price
                else total_sales
            end as total_sales,

            quantity,
            unit_price,

            dwh_create_at,
            dwh_update_at
        from base_clean
    )

    merge into silver.crm_sales_details as target
    using transformations as source
    on target.sale_id = source.sales_key
    when matched then
        update set
            target.sale_id = source.sales_key,
            target.order_number = source.order_number,
            target.product_key = source.product_key,
            target.customer_id = source.customer_id,
            target.order_date = source.order_date,
            target.shipped_date = source.shipped_date,
            target.due_date = source.due_date,
            target.total_sales = source.total_sales,
            target.quantity = source.quantity,
            target.unit_price = source.unit_price,
            target.dwh_create_at = source.dwh_create_at,
            target.dwh_update_at = source.dwh_update_at
    when not matched then
        insert (
            sale_id,
            order_number,
            product_key,
            customer_id,
            order_date,
            shipped_date,
            due_date,
            total_sales,
            quantity,
            unit_price,
            dwh_create_at,
            dwh_update_at
        )
        values (
            source.sales_key,
            source.order_number,
            source.product_key,
            source.customer_id,
            source.order_date,
            source.shipped_date,
            source.due_date,
            source.total_sales,
            source.quantity,
            source.unit_price,
            source.dwh_create_at,
            source.dwh_update_at
        );
    declare @total_rows INT = @@ROWCOUNT;

    update silver.system_watermark
    set last_processed_timestamp = @new_watermark, state_name = @state_name
    where state_name = @state_name

    set @end_time = GETDATE();
    print('Successfully transformation on sales_details table.');
    print('Total rows : ' + cast(@total_rows as NVARCHAR))
    print('>> Time Durations: ' + CAST(datediff(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
    print('----------------------------------------------');

end;