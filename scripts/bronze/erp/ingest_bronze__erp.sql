/*
 ==============================================
 Create View
 ==============================================
 Script Purposes:
    This scripts create view for each table, and load from source
    just copy 1:1 not include data warehouse timestamp.
*/

use DataWareHouse;
go

-- erp_cust_az12
create or alter view bronze.vw_erp_cust_az12 as
select
    cid,
    bdate,
    gen
from bronze.erp_cust_az12;
go

-- erp_loc_a101
create or alter view bronze.vw_erp_loc_a101 as
select
    cid,
    cntry
from bronze.erp_loc_a101;
go

-- px_cat_g1v1
create or alter view bronze.vw_erp_px_cat_g1v2 as
select
    id,
    cat,
    subcat,
    maintenance
from bronze.erp_px_cat_g1v2
go





