use DataWareHouse;
go

create or alter procedure silver.load_silver as
declare @total_start_durations DATETIME, @total_end_durations DATETIME;
begin
    begin try
        set @total_start_durations = GETDATE();
        print('==============================================');
        print('Starting transformations process...');
        exec silver.ddl_crm_scripts;
        exec silver.ddl_erp_scripts;

        exec silver.t_prd_info;
        exec silver.t_cst_info;
        exec silver.t_sales_details;
        exec silver.t_cust_az12;
        exec silver.t_px_cat_g1v2;
        exec silver.t_loc_a101;
        set @total_end_durations = GETDATE();
        print('Transformations process successfully...');
        print('>> Total durations : ' + CAST(datediff(second, @total_start_durations, @total_end_durations) AS VARCHAR) + ' seconds');
        print('==============================================');

    end try
    begin catch
        print('==============================================');
        print('ERROR OCCURRED DURING LOAD PROCESS');
        print('Error Message: ' + ERROR_MESSAGE());
        print('==============================================');
    end catch
end;
go
