/*
 ==============================================
 View: gold.dim_customers
 ==============================================
 Description:
 - Creates a dimension view for customers in the gold layer.
 - Integrates data from CRM (customer info) and ERP (demographics, location) systems.
 - Resolves conflicts (e.g., prioritizing CRM gender data).
 - Generates a sequential surrogate key (customer_number).
*/

create view gold.dim_customers as
select
    row_number() over(order by customer_id) as customer_number,
    ci.customer_id,
    ci.customer_key as customer_key,
    ci.first_name,
    ci.last_name,

    case
        when ci.gender != 'n/a' then ci.gender -- Because CRM is the master of gender
        else coalesce(ca.gender, 'n/a')
    end as gender,

    ci.marital_status,
    la.country,
    ca.birth_day,
    ci.source_create_date as create_date
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca on ci.customer_key = ca.customer_key
left join silver.erp_loc_a101 la on ci.customer_key = la.customer_key;

