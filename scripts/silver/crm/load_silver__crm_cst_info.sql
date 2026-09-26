/*
 Problems
    - Duplicated cst_id and cst_key
    + Solve deduplicated with ranking the newest row, used column cst_create_date
 */

with latest_data as (
    select
        *,
        row_number() over(
            partition by cst_id
            order by dwh_create_at, cst_create_date
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

        case
            when upper(trim(cst_marital_status)) = 'S' then 'Single'
            when upper(trim(cst_marital_status)) = 'M' then 'Married'
            else 'n/a'
        end as marital_status,

        case
            when upper(trim(cst_gndr)) = 'F' then 'Female'
            when upper(trim(cst_gndr)) = 'M' then 'Male'
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