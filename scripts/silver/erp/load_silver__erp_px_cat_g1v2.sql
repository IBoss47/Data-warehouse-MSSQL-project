/*
 ==============================================
 Create load silver erp px_cat_g1v2 procedure
 ==============================================
 Script purposes:
    This scripts create procedure for load data into silver layer.
    and consider to create some logs for debug the process
    This scripts will be load data 1:1 from bronze layer to silver layer
    on px_cat_g1v2 table.

 Problems:
    - None

 Solutions:
    - 1:1 Load from bronze to silver layer

 Warning:
    In the future the path of dataset should be dynamic, now it fix
    with local path.

 Usage Example:
    EXEC DataWareHouse.silver.t_px_cat_g1v2
 */

create or alter procedure silver.t_px_cat_g1v2 as
begin
    insert into silver.erp_px_cat_g1v2(
        category_id,
        category,
        sub_category,
        maintenance,
        dwh_create_at,
        dwh_update_at
    )
    select * from bronze.erp_px_cat_g1v2;
end;