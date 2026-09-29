# Variables
CONTAINER_NAME=sql_server_container
DB_USER=sa
DB_PASS='MyPass1234!'
SQLCMD=docker exec -i $(CONTAINER_NAME) /opt/mssql-tools18/bin/sqlcmd -S localhost -U $(DB_USER) -P $(DB_PASS) -C

.PHONY: help up down init bronze silver gold run-all

help:
	@echo "Available commands:"
	@echo "  make up          - Start the SQL Server container"
	@echo "  make down        - Stop and remove the SQL Server container"
	@echo "  make init        - Run infrastructure setup (creates database and schemas)"
	@echo "  make bronze      - Load data into the Bronze layer"
	@echo "  make silver      - Transform and load data into the Silver layer"
	@echo "  make gold        - Create Dimension and Fact views in the Gold layer"
	@echo "  make run-all     - Run everything from start to finish (init -> bronze -> silver -> gold)"

up:
	docker-compose up -d
	@echo "Waiting for SQL Server to start..."
	@sleep 10
	@echo "SQL Server is ready!"

down:
	docker-compose down

init:
	@echo "Initializing Infrastructure (Warning: This resets the DataWareHouse DB)..."
	@$(SQLCMD) -d master -i /dev/stdin < scripts/infra_scrip.sql

bronze:
	@echo "Loading Bronze Layer..."
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/bronze/crm/ddl_bronze__crm.sql
	@$(SQLCMD) -d DataWareHouse -Q "EXEC bronze.ddl_create_table_crm;"
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/bronze/crm/ingest_bronze__crm.sql
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/bronze/erp/ddl_bronze__erp.sql
	@$(SQLCMD) -d DataWareHouse -Q "EXEC bronze.ddl_create_table_erp;"
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/bronze/erp/ingest_bronze__erp.sql
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/bronze/load_bronze.sql
	@$(SQLCMD) -d DataWareHouse -Q "EXEC bronze.load_bronze;"

silver:
	@echo "Loading Silver Layer..."
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/silver/crm/ddl_silver__crm.sql
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/silver/erp/ddl_silver__erp.sql

	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/silver/crm/load_silver__crm_cst_info.sql
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/silver/crm/load_silver__crm_prd_info.sql
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/silver/crm/load_silver__crm_sales_details.sql

	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/silver/erp/load_silver__erp_cust_az12.sql
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/silver/erp/load_silver__erp_loc_a101.sql
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/silver/erp/load_silver__erp_px_cat_g1v2.sql

	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/silver/load_silver_transformations.sql
	@$(SQLCMD) -d DataWareHouse -Q "EXEC silver.load_silver;"

gold:
	@echo "Loading Gold Layer..."
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/gold/dim_customers.sql
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/gold/dim_products.sql
	@$(SQLCMD) -d DataWareHouse -i /dev/stdin < scripts/gold/fct_sales.sql

run-all: init bronze silver gold
	@echo "All pipelines executed successfully!"
