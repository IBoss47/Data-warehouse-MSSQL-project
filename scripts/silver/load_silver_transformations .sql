use DataWareHouse;
go

create or alter procedure silver.load_silver as
begin
    begin try
        exec silver.ddl_crm_scripts;
        exec silver.ddl_erp_scripts;

        exec silver.t_prd_info;
        exec silver.t_cst_info;
        exec silver.t_sales_details;
        exec silver.t_cust_az12;
        exec silver.t_px_cat_g1v2;
        exec silver.t_loc_a101;
    end try
    begin catch

    end catch
end;
go
