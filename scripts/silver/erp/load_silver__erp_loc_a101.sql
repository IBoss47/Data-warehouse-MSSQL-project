with transformations as (
    select
        replace(cid, '-', '') as customer_key,

        case
            when upper(trim(cntry)) in ('USA', 'US', 'UNITED STATES') then 'United States'
            when upper(trim(cntry)) in ('DE', 'GERMANY') then 'Germany'
            when upper(trim(cntry)) in ('AU', 'AUS', 'AUSTRALIA') then 'Australia'
            when upper(trim(cntry)) in ('CA', 'CAN', 'CANADA') then 'Canada'
            when upper(trim(cntry)) in ('FR', 'FRA', 'FRANCE') then 'France'
            when trim(cntry) = '' or cntry is null then 'n/a'
            else trim(cntry)
        end as country,

        dwh_create_at,
        dwh_update_at

    from bronze.erp_loc_a101
)

insert into silver.erp_loc_a101(
    customer_key,
    country,
    dwh_create_at,
    dwh_update_at
)
select * from transformations;