/*
 ==============================================
 Create load bronze procedure
 ==============================================
 Script purposes:
    This scripts create procedure for load data into bronze layer.
    and consider to create some logs for debug the process and show
    durations time.

 Warning:
    In the future the path of dataset should be dynamic, now it fix
    with local path.
 */

create or alter procedure bronze.load_bronze as
declare @total_duration_start DATETIME, @total_duration_end DATETIME;
begin
    set @total_duration_start = GETDATE();
    declare @start_time DATETIME, @end_time DATETIME;
    begin try
        set nocount on;
        print('============================================');
        print('Starting Load data into bronze layer....');
        print('============================================');

        print('Loading "cust_info" from source crm...');

        set @start_time = GETDATE();
        bulk insert bronze.vw_crm_cust_info
        from '/var/opt/mssql/data/source_crm/cust_info.csv'
        with(
            firstrow = 2,
            fieldterminator = ',',
            rowterminator = '\r\n',
            tablock
        );
        set @end_time = GETDATE();

        print('Successfully load "cust_info" to crm_cust_info table.');
        print('>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as NVARCHAR) + ' seconds');
        print('--------------------------------------------');

        print('Loading "prd_info" from source crm...');

        set @start_time = GETDATE();
        bulk insert bronze.vw_crm_prd_info
        from '/var/opt/mssql/data/source_crm/prd_info.csv'
        with(
            firstrow = 2,
            fieldterminator = ',',
            rowterminator = '\r\n',
            tablock
        );
        set @end_time = GETDATE();

        print('Successfully load "prd_info" to crm_prd_info table.');
        print('>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as NVARCHAR) + ' seconds');
        print('--------------------------------------------');

        print('Loading "sales_details" from source crm...');

        set @start_time = GETDATE();
        bulk insert bronze.vw_crm_sales_details
        from '/var/opt/mssql/data/source_crm/sales_details.csv'
        with(
            firstrow = 2,
            fieldterminator = ',',
            rowterminator = '\r\n',
            tablock
        );
        set @end_time = GETDATE();

        print('Successfully load "sales_details" to crm_sales_details table.');
        print('>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as NVARCHAR) + ' seconds');
        print('--------------------------------------------');

        print('Loading "cust_az12" from source erp...');

        set @start_time = GETDATE();
        bulk insert bronze.vw_erp_cust_az12
        from '/var/opt/mssql/data/source_erp/CUST_AZ12.csv'
        with(
            firstrow = 2,
            fieldterminator = ',',
            rowterminator = '\r\n',
            tablock
        );
        set @end_time = GETDATE();

        print('Successfully load "cust_az12" to erp_cust_az12 table.');
        print('>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as NVARCHAR) + ' seconds');
        print('--------------------------------------------');

        print('Loading "loc_a101" from source erp...');

        set @start_time = GETDATE();
        bulk insert bronze.vw_erp_loc_a101
        from '/var/opt/mssql/data/source_erp/LOC_A101.csv'
        with(
            firstrow = 2,
            fieldterminator = ',',
            rowterminator = '\r\n',
            tablock
        );
        set @end_time = GETDATE();

        print('Successfully load "loc_a101" to erp_loc_a101 table.');
        print('>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as NVARCHAR) + ' seconds');
        print('--------------------------------------------');

        print('Loading "px_cat_g1v2" from source erp...');

        set @start_time = GETDATE();
        bulk insert bronze.vw_erp_px_cat_g1v2
        from '/var/opt/mssql/data/source_erp/PX_CAT_G1V2.csv'
        with(
            firstrow = 2,
            fieldterminator = ',',
            rowterminator = '\r\n',
            tablock
        );
        set @end_time = GETDATE();
        print('Successfully load "px_cat_g1v2" to erp_px_cat_g1v2 table.');
        print('>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as NVARCHAR) + ' seconds');
        print('--------------------------------------------');
    end try
    begin catch
        print('============================================');
        print('ERROR OCCURRED DURING LOADING BRONZE LAYER.');
        print('Error message: ' + ERROR_MESSAGE());
        print('Number of Error: ' + cast(ERROR_NUMBER() as NVARCHAR));
        print('Occur State: ' + cast(ERROR_STATE() as NVARCHAR));
        print('============================================');
    end catch
    set @total_duration_end = GETDATE();

    print('Total duration time: ' + cast(datediff(second, @total_duration_start, @total_duration_end) as NVARCHAR));
end