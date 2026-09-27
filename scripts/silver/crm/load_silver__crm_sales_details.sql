/*
 ==============================================
 Create load silver crm sales_details procedure
 ==============================================
 Script purposes:
    This scripts create procedure for load data into silver layer.
    and consider to create some logs for debug the process and show
    durations time.

 Problems:
    - Invalid date formats (e.g., negative values or incorrect length)
    - Missing or invalid unit prices and total sales
    - Negative or inconsistent sales totals compared to quantity * price

 Solutions:
    - Cast invalid dates to NULL
    - Derive missing unit prices using total_sales / quantity
    - Recalculate total_sales as abs(quantity) * unit_price if inconsistent or missing

 Warning:
    In the future the path of dataset should be dynamic, now it fix
    with local path.

 Usage Example:
    EXEC DataWareHouse.silver.t_sales_details
 */

create or alter procedure silver.t_sales_details as
begin
    with base_clean as (
        select
            sls_ord_num as order_number,
            sls_prd_key as product_key,
            sls_cust_id as customer_id,

            case
                when sls_order_dt < 0 or len(sls_order_dt) != 8 then null
                else cast(cast(sls_order_dt as VARCHAR) as DATE)
            end as order_date,

            case
                when sls_ship_dt < 0 or len(sls_ship_dt) != 8 then null
                else cast(cast(sls_ship_dt as VARCHAR) as DATE)
            end as shipped_date,

            case
                when sls_due_dt < 0 or len(sls_due_dt) != 8 then null
                else cast(cast(sls_due_dt as VARCHAR) as DATE)
            end as due_date,

            sls_sales as total_sales,
            sls_quantity as quantity,

            case
                when sls_price is null or sls_price <= 0
                    then sls_sales / nullif(sls_quantity, 0)
                else sls_price
            end as unit_price,

            dwh_create_at,
            dwh_update_at
        from bronze.crm_sales_details
    ),
    transformations as (
        select
            order_number,
            product_key,
            customer_id,

            order_date,
            shipped_date,
            due_date,

            case
                when total_sales <= 0 or total_sales is null or total_sales !=  quantity * unit_price
                    then abs(quantity) * unit_price
                else total_sales
            end as total_sales,

            quantity,
            unit_price,

            dwh_create_at,
            dwh_update_at
        from base_clean
    )

    insert into silver.crm_sales_details(
        order_number,
        product_key,
        customer_id,
        order_date,
        shipped_date,
        due_date,
        total_sales,
        quantity,
        unit_price,
        dwh_create_at,
        dwh_update_at
    )
    select * from transformations;
end;