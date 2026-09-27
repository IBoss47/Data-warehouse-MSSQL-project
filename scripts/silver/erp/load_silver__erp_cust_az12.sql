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

