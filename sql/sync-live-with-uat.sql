-- ============================================
-- Sync FSMonitoringDB (LIVE) with FSMonitoringDB_UAT
-- Generated: January 26, 2026
-- ============================================

USE FSMonitoringDB;
GO

-- ============================================
-- 1. CREATE MISSING TABLES
-- ============================================

-- ATPBranches
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ATPBranches' AND xtype='U')
BEGIN
    CREATE TABLE ATPBranches (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(255) NOT NULL,
        is_active BIT DEFAULT 1,
        created_at DATETIME DEFAULT GETDATE()
    );
    PRINT 'Created table: ATPBranches';
END
GO

-- DryStoreBranches
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='DryStoreBranches' AND xtype='U')
BEGIN
    CREATE TABLE DryStoreBranches (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(255) NOT NULL,
        is_active BIT DEFAULT 1,
        created_at DATETIME DEFAULT GETDATE()
    );
    PRINT 'Created table: DryStoreBranches';
END
GO

-- HygieneChecklistSessions
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='HygieneChecklistSessions' AND xtype='U')
BEGIN
    CREATE TABLE HygieneChecklistSessions (
        id INT IDENTITY(1,1) PRIMARY KEY,
        document_number NVARCHAR(50) NOT NULL UNIQUE,
        checklist_id INT NOT NULL,
        store_id INT NULL,
        check_date DATE NOT NULL,
        shift NVARCHAR(20) NULL,
        filled_by NVARCHAR(100) NOT NULL,
        status NVARCHAR(20) DEFAULT 'Pending',
        verified BIT DEFAULT 0,
        verified_by NVARCHAR(100) NULL,
        verified_at DATETIME NULL,
        comments NVARCHAR(500) NULL,
        created_at DATETIME DEFAULT GETDATE(),
        updated_at DATETIME DEFAULT GETDATE()
    );
    PRINT 'Created table: HygieneChecklistSessions';
END
GO

-- HygieneSettings
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='HygieneSettings' AND xtype='U')
BEGIN
    CREATE TABLE HygieneSettings (
        id INT IDENTITY(1,1) PRIMARY KEY,
        setting_key NVARCHAR(100) NOT NULL UNIQUE,
        setting_value NVARCHAR(500) NULL,
        updated_at DATETIME DEFAULT GETDATE()
    );
    PRINT 'Created table: HygieneSettings';
END
GO

-- QCR_Suppliers
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='QCR_Suppliers' AND xtype='U')
BEGIN
    CREATE TABLE QCR_Suppliers (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(255) NOT NULL,
        is_active BIT DEFAULT 1,
        created_at DATETIME DEFAULT GETDATE()
    );
    PRINT 'Created table: QCR_Suppliers';
END
GO

-- QCR_Documents
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='QCR_Documents' AND xtype='U')
BEGIN
    CREATE TABLE QCR_Documents (
        id INT IDENTITY(1,1) PRIMARY KEY,
        document_number NVARCHAR(50) NOT NULL UNIQUE,
        receiving_date DATE NOT NULL,
        supplier_id INT NULL,
        supplier_name NVARCHAR(255) NULL,
        invoice_number NVARCHAR(100) NULL,
        filled_by NVARCHAR(100) NOT NULL,
        status NVARCHAR(20) DEFAULT 'Active',
        verified BIT DEFAULT 0,
        verified_by NVARCHAR(100) NULL,
        verified_at DATETIME NULL,
        comments NVARCHAR(500) NULL,
        created_at DATETIME DEFAULT GETDATE(),
        updated_at DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (supplier_id) REFERENCES QCR_Suppliers(id)
    );
    PRINT 'Created table: QCR_Documents';
END
GO

-- QCR_Entries
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='QCR_Entries' AND xtype='U')
BEGIN
    CREATE TABLE QCR_Entries (
        id INT IDENTITY(1,1) PRIMARY KEY,
        document_id INT NOT NULL,
        product_name NVARCHAR(255) NOT NULL,
        quantity NVARCHAR(100) NULL,
        unit NVARCHAR(50) NULL,
        temperature DECIMAL(5,2) NULL,
        expiry_date DATE NULL,
        packaging_condition NVARCHAR(50) NULL,
        quality_status NVARCHAR(50) NULL,
        comments NVARCHAR(500) NULL,
        FOREIGN KEY (document_id) REFERENCES QCR_Documents(id)
    );
    PRINT 'Created table: QCR_Entries';
END
GO

-- ============================================
-- 2. ADD MISSING COLUMNS TO EXISTING TABLES
-- ============================================

-- CookingCoolingReadings: Add 'status' column
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CookingCoolingReadings' AND COLUMN_NAME = 'status')
BEGIN
    ALTER TABLE CookingCoolingReadings ADD status NVARCHAR(20) NOT NULL DEFAULT 'submitted';
    PRINT 'Added column: CookingCoolingReadings.status';
END
GO

-- Also make cooling columns nullable for draft support
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CookingCoolingReadings' AND COLUMN_NAME = 'cooling_start_time' AND IS_NULLABLE = 'NO')
BEGIN
    ALTER TABLE CookingCoolingReadings ALTER COLUMN cooling_start_time TIME NULL;
    ALTER TABLE CookingCoolingReadings ALTER COLUMN cooling_start_temp DECIMAL(5,2) NULL;
    ALTER TABLE CookingCoolingReadings ALTER COLUMN cooling_end_time TIME NULL;
    ALTER TABLE CookingCoolingReadings ALTER COLUMN cooling_end_temp DECIMAL(5,2) NULL;
    ALTER TABLE CookingCoolingReadings ALTER COLUMN total_cooling_time INT NULL;
    ALTER TABLE CookingCoolingReadings ALTER COLUMN cooling_method NVARCHAR(100) NULL;
    PRINT 'Made cooling columns nullable in CookingCoolingReadings';
END
GO

-- DryStoreReadings: Add 'time_am' and 'time_pm' columns
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DryStoreReadings' AND COLUMN_NAME = 'time_am')
BEGIN
    ALTER TABLE DryStoreReadings ADD time_am NVARCHAR(10) NULL;
    PRINT 'Added column: DryStoreReadings.time_am';
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DryStoreReadings' AND COLUMN_NAME = 'time_pm')
BEGIN
    ALTER TABLE DryStoreReadings ADD time_pm NVARCHAR(10) NULL;
    PRINT 'Added column: DryStoreReadings.time_pm';
END
GO

-- FoodSafetyVerificationRecords: Add 'item_name' column
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FoodSafetyVerificationRecords' AND COLUMN_NAME = 'item_name')
BEGIN
    ALTER TABLE FoodSafetyVerificationRecords ADD item_name NVARCHAR(200) NULL;
    PRINT 'Added column: FoodSafetyVerificationRecords.item_name';
END
GO

-- VegFruitWashDocuments: Add second check columns
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'VegFruitWashDocuments' AND COLUMN_NAME = 'check_time_2')
BEGIN
    ALTER TABLE VegFruitWashDocuments ADD check_time_2 NVARCHAR(50) NULL;
    PRINT 'Added column: VegFruitWashDocuments.check_time_2';
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'VegFruitWashDocuments' AND COLUMN_NAME = 'concentration_2')
BEGIN
    ALTER TABLE VegFruitWashDocuments ADD concentration_2 NVARCHAR(50) NULL;
    PRINT 'Added column: VegFruitWashDocuments.concentration_2';
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'VegFruitWashDocuments' AND COLUMN_NAME = 'comments_2')
BEGIN
    ALTER TABLE VegFruitWashDocuments ADD comments_2 NVARCHAR(500) NULL;
    PRINT 'Added column: VegFruitWashDocuments.comments_2';
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'VegFruitWashDocuments' AND COLUMN_NAME = 'log_date_2')
BEGIN
    ALTER TABLE VegFruitWashDocuments ADD log_date_2 DATE NULL;
    PRINT 'Added column: VegFruitWashDocuments.log_date_2';
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'VegFruitWashDocuments' AND COLUMN_NAME = 'filled_by_2')
BEGIN
    ALTER TABLE VegFruitWashDocuments ADD filled_by_2 NVARCHAR(100) NULL;
    PRINT 'Added column: VegFruitWashDocuments.filled_by_2';
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'VegFruitWashDocuments' AND COLUMN_NAME = 'verified_by')
BEGIN
    ALTER TABLE VegFruitWashDocuments ADD verified_by NVARCHAR(100) NULL;
    PRINT 'Added column: VegFruitWashDocuments.verified_by';
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'VegFruitWashDocuments' AND COLUMN_NAME = 'verified_at')
BEGIN
    ALTER TABLE VegFruitWashDocuments ADD verified_at DATETIME NULL;
    PRINT 'Added column: VegFruitWashDocuments.verified_at';
END
GO

-- ============================================
-- 3. SUMMARY
-- ============================================
PRINT '';
PRINT '============================================';
PRINT 'Database sync complete!';
PRINT '============================================';
PRINT '';
PRINT 'Tables created:';
PRINT '  - ATPBranches';
PRINT '  - DryStoreBranches';
PRINT '  - HygieneChecklistSessions';
PRINT '  - HygieneSettings';
PRINT '  - QCR_Suppliers';
PRINT '  - QCR_Documents';
PRINT '  - QCR_Entries';
PRINT '';
PRINT 'Columns added:';
PRINT '  - CookingCoolingReadings.status';
PRINT '  - DryStoreReadings.time_am, time_pm';
PRINT '  - FoodSafetyVerificationRecords.item_name';
PRINT '  - VegFruitWashDocuments: check_time_2, concentration_2, comments_2, log_date_2, filled_by_2, verified_by, verified_at';
GO
