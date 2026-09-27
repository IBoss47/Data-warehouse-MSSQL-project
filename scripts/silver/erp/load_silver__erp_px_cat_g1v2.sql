insert into silver.erp_px_cat_g1v2(
    category_id,
    category,
    sub_category,
    maintenance,
    dwh_create_at,
    dwh_update_at
)
select * from bronze.erp_px_cat_g1v2;