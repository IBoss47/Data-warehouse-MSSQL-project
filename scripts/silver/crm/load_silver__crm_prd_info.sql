/*
 Problems
    - Duplicated prd_key
    + Solve deduplicated with ranking the newest row, used column prd_start_dt

 Warnings:
    When prd_line have another value, it will be display n/a.
 */

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