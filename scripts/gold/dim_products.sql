
create view gold.dim_products as
select
    row_number() over(order by product_start_time, product_key) as product_number,
    p.product_id,
    p.product_category_key,
    p.product_key,
    p.product_name,
    pc.category,
    pc.sub_category,
    pc.maintenance,
    p.product_price,
    p.product_line,
    p.product_start_time
from silver.crm_prd_info p
left join silver.erp_px_cat_g1v2 pc on pc.category_id = p.category_key
where product_end_time is null; -- Filter out all historical data