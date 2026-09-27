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
declare @start_time DATETIME, @end_time DATETIME;
begin
    set @start_time = GETDATE();
    print('----------------------------------------------');
    print('In process on table prd_info...');
    with transformations as (
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
        from bronze.crm_prd_info
    )

    insert into silver.crm_prd_info(
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
    select * from transformations;
    set @end_time = GETDATE();
    print('Successfully transformation on prd_info table.');
    print('>> Time Durations: ' + CAST(datediff(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
    print('----------------------------------------------');
end;