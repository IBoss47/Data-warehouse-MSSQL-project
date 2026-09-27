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
declare @start_time DATETIME, @end_time DATETIME;
begin
    set @start_time = GETDATE();
    print('----------------------------------------------');
    print('In process on table cst_info...');
    with latest_data as (
        select
            *,
            row_number() over(
                partition by cst_id
                order by dwh_create_at desc, cst_create_date desc
            ) as rn
        from bronze.crm_cust_info
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

    insert into silver.crm_cust_info(
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
    select * from transformation;
    set @end_time = GETDATE();
    print('Successfully transformation on cst_info table.');
    print('>> Time Durations: ' + CAST(datediff(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
    print('----------------------------------------------');
end;