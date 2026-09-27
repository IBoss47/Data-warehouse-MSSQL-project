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
declare @start_time DATETIME, @end_time DATETIME;
begin
    set @start_time = GETDATE();
    print('----------------------------------------------');
    print('In process on table cust_az12...');
    with transformations as (
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

        from bronze.erp_cust_az12
    )

    insert into silver.erp_cust_az12(
        customer_key,
        birth_day,
        gender,
        dwh_create_at,
        dwh_update_at
    )
    select * from transformations;
    set @end_time = GETDATE();

    print('Successfully transformation on cust_az12 table.');
    print('>> Time Durations: ' + CAST(datediff(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
    print('----------------------------------------------');
end;
