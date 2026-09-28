create view gold.fact_sales as
select
    sd.sale_id,
    sd.order_number,
    dp.product_number,
    dc.customer_id,
    sd.order_date,
    sd.shipped_date,
    sd.due_date,
    sd.total_sales,
    sd.quantity,
    sd.unit_price
from silver.crm_sales_details sd
left join gold.dim_products dp on dp.product_key = sd.product_key
left join gold.dim_customers dc on dc.customer_id = sd.customer_id;
