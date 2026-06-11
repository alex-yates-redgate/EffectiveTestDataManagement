-- V001__Baseline.sql
-- ===========================
-- Baseline migration for Northwind database
-- Contains full initial schema so Flyway can build from empty DBs
-- ===========================

-- Northwind-Schema.sql
-- ===========================
-- Northwind database schema for Effective Test Data Management demo
-- Adapted from the classic Northwind sample database
-- ===========================

SET NOCOUNT ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET DATEFORMAT mdy
GO

-- ============================================
-- Create Schemas
-- ============================================
PRINT N'Creating schemas...'
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Sales')
    EXEC('CREATE SCHEMA [Sales] AUTHORIZATION [dbo]')
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'HR')
    EXEC('CREATE SCHEMA [HR] AUTHORIZATION [dbo]')
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Inventory')
    EXEC('CREATE SCHEMA [Inventory] AUTHORIZATION [dbo]')
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Shipping')
    EXEC('CREATE SCHEMA [Shipping] AUTHORIZATION [dbo]')
GO

-- ============================================
-- Customers - Contains PII
-- ============================================
PRINT N'Creating [Sales].[Customers]...'
GO

CREATE TABLE [Sales].[Customers]
(
    [CustomerID] NCHAR(5) NOT NULL,
    [CompanyName] NVARCHAR(40) NOT NULL,
    [ContactName] NVARCHAR(30) NULL,          -- PII: Name
    [ContactTitle] NVARCHAR(30) NULL,
    [Address] NVARCHAR(60) NULL,              -- PII: Address
    [City] NVARCHAR(15) NULL,
    [Region] NVARCHAR(15) NULL,
    [PostalCode] NVARCHAR(10) NULL,           -- PII: Postal Code
    [Country] NVARCHAR(15) NULL,
    [Phone] NVARCHAR(24) NULL,                -- PII: Phone
    [Fax] NVARCHAR(24) NULL,
    [Email] NVARCHAR(100) NULL,               -- PII: Email
    CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([CustomerID])
)
GO

CREATE NONCLUSTERED INDEX [IX_Customers_City] ON [Sales].[Customers] ([City])
GO
CREATE NONCLUSTERED INDEX [IX_Customers_CompanyName] ON [Sales].[Customers] ([CompanyName])
GO
CREATE NONCLUSTERED INDEX [IX_Customers_PostalCode] ON [Sales].[Customers] ([PostalCode])
GO

-- ============================================
-- Employees - Contains PII
-- ============================================
PRINT N'Creating [HR].[Employees]...'
GO

CREATE TABLE [HR].[Employees]
(
    [EmployeeID] INT NOT NULL IDENTITY(1, 1),
    [LastName] NVARCHAR(20) NOT NULL,         -- PII: Name
    [FirstName] NVARCHAR(10) NOT NULL,        -- PII: Name
    [Title] NVARCHAR(30) NULL,
    [TitleOfCourtesy] NVARCHAR(25) NULL,
    [BirthDate] DATETIME NULL,                -- PII: Date of Birth
    [HireDate] DATETIME NULL,
    [Address] NVARCHAR(60) NULL,              -- PII: Address
    [City] NVARCHAR(15) NULL,
    [Region] NVARCHAR(15) NULL,
    [PostalCode] NVARCHAR(10) NULL,           -- PII: Postal Code
    [Country] NVARCHAR(15) NULL,
    [HomePhone] NVARCHAR(24) NULL,            -- PII: Phone
    [Extension] NVARCHAR(4) NULL,
    [Photo] IMAGE NULL,
    [Notes] NTEXT NULL,
    [ReportsTo] INT NULL,
    [Email] NVARCHAR(100) NULL,               -- PII: Email
    [SSN] NVARCHAR(11) NULL,                  -- PII: SSN (highly sensitive!)
    CONSTRAINT [PK_Employees] PRIMARY KEY CLUSTERED ([EmployeeID]),
    CONSTRAINT [CK_Employees_BirthDate] CHECK ([BirthDate] < GETDATE())
)
GO

CREATE NONCLUSTERED INDEX [IX_Employees_LastName] ON [HR].[Employees] ([LastName])
GO
CREATE NONCLUSTERED INDEX [IX_Employees_PostalCode] ON [HR].[Employees] ([PostalCode])
GO

-- ============================================
-- Suppliers - Contains PII
-- ============================================
PRINT N'Creating [Inventory].[Suppliers]...'
GO

CREATE TABLE [Inventory].[Suppliers]
(
    [SupplierID] INT NOT NULL IDENTITY(1, 1),
    [CompanyName] NVARCHAR(40) NOT NULL,
    [ContactName] NVARCHAR(30) NULL,          -- PII: Name
    [ContactTitle] NVARCHAR(30) NULL,
    [Address] NVARCHAR(60) NULL,              -- PII: Address
    [City] NVARCHAR(15) NULL,
    [Region] NVARCHAR(15) NULL,
    [PostalCode] NVARCHAR(10) NULL,           -- PII: Postal Code
    [Country] NVARCHAR(15) NULL,
    [Phone] NVARCHAR(24) NULL,                -- PII: Phone
    [Fax] NVARCHAR(24) NULL,
    [HomePage] NTEXT NULL,
    CONSTRAINT [PK_Suppliers] PRIMARY KEY CLUSTERED ([SupplierID])
)
GO

CREATE NONCLUSTERED INDEX [IX_Suppliers_CompanyName] ON [Inventory].[Suppliers] ([CompanyName])
GO
CREATE NONCLUSTERED INDEX [IX_Suppliers_PostalCode] ON [Inventory].[Suppliers] ([PostalCode])
GO

-- ============================================
-- Categories
-- ============================================
PRINT N'Creating [Inventory].[Categories]...'
GO

CREATE TABLE [Inventory].[Categories]
(
    [CategoryID] INT NOT NULL IDENTITY(1, 1),
    [CategoryName] NVARCHAR(15) NOT NULL,
    [Description] NTEXT NULL,
    [Picture] IMAGE NULL,
    CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED ([CategoryID])
)
GO

CREATE NONCLUSTERED INDEX [IX_Categories_CategoryName] ON [Inventory].[Categories] ([CategoryName])
GO

-- ============================================
-- Products
-- ============================================
PRINT N'Creating [Inventory].[Products]...'
GO

CREATE TABLE [Inventory].[Products]
(
    [ProductID] INT NOT NULL IDENTITY(1, 1),
    [ProductName] NVARCHAR(40) NOT NULL,
    [SupplierID] INT NULL,
    [CategoryID] INT NULL,
    [QuantityPerUnit] NVARCHAR(20) NULL,
    [UnitPrice] MONEY NULL CONSTRAINT [DF_Products_UnitPrice] DEFAULT (0),
    [UnitsInStock] SMALLINT NULL CONSTRAINT [DF_Products_UnitsInStock] DEFAULT (0),
    [UnitsOnOrder] SMALLINT NULL CONSTRAINT [DF_Products_UnitsOnOrder] DEFAULT (0),
    [ReorderLevel] SMALLINT NULL CONSTRAINT [DF_Products_ReorderLevel] DEFAULT (0),
    [Discontinued] BIT NOT NULL CONSTRAINT [DF_Products_Discontinued] DEFAULT (0),
    CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED ([ProductID]),
    CONSTRAINT [CK_Products_UnitPrice] CHECK ([UnitPrice] >= 0),
    CONSTRAINT [CK_Products_UnitsInStock] CHECK ([UnitsInStock] >= 0),
    CONSTRAINT [CK_Products_UnitsOnOrder] CHECK ([UnitsOnOrder] >= 0),
    CONSTRAINT [CK_Products_ReorderLevel] CHECK ([ReorderLevel] >= 0)
)
GO

CREATE NONCLUSTERED INDEX [IX_Products_CategoryID] ON [Inventory].[Products] ([CategoryID])
GO
CREATE NONCLUSTERED INDEX [IX_Products_ProductName] ON [Inventory].[Products] ([ProductName])
GO
CREATE NONCLUSTERED INDEX [IX_Products_SupplierID] ON [Inventory].[Products] ([SupplierID])
GO

-- ============================================
-- Shippers
-- ============================================
PRINT N'Creating [Shipping].[Shippers]...'
GO

CREATE TABLE [Shipping].[Shippers]
(
    [ShipperID] INT NOT NULL IDENTITY(1, 1),
    [CompanyName] NVARCHAR(40) NOT NULL,
    [Phone] NVARCHAR(24) NULL,
    CONSTRAINT [PK_Shippers] PRIMARY KEY CLUSTERED ([ShipperID])
)
GO

-- ============================================
-- Region
-- ============================================
PRINT N'Creating [Sales].[Region]...'
GO

CREATE TABLE [Sales].[Region]
(
    [RegionID] INT NOT NULL,
    [RegionDescription] NCHAR(50) NOT NULL,
    CONSTRAINT [PK_Region] PRIMARY KEY NONCLUSTERED ([RegionID])
)
GO

-- ============================================
-- Territories
-- ============================================
PRINT N'Creating [Sales].[Territories]...'
GO

CREATE TABLE [Sales].[Territories]
(
    [TerritoryID] NVARCHAR(20) NOT NULL,
    [TerritoryDescription] NCHAR(50) NOT NULL,
    [RegionID] INT NOT NULL,
    CONSTRAINT [PK_Territories] PRIMARY KEY NONCLUSTERED ([TerritoryID])
)
GO

-- ============================================
-- EmployeeTerritories
-- ============================================
PRINT N'Creating [HR].[EmployeeTerritories]...'
GO

CREATE TABLE [HR].[EmployeeTerritories]
(
    [EmployeeID] INT NOT NULL,
    [TerritoryID] NVARCHAR(20) NOT NULL,
    CONSTRAINT [PK_EmployeeTerritories] PRIMARY KEY NONCLUSTERED ([EmployeeID], [TerritoryID])
)
GO

-- ============================================
-- Orders - Contains PII in shipping fields
-- ============================================
PRINT N'Creating [Sales].[Orders]...'
GO

CREATE TABLE [Sales].[Orders]
(
    [OrderID] INT NOT NULL IDENTITY(1, 1),
    [CustomerID] NCHAR(5) NULL,
    [EmployeeID] INT NULL,
    [OrderDate] DATETIME NULL,
    [RequiredDate] DATETIME NULL,
    [ShippedDate] DATETIME NULL,
    [ShipVia] INT NULL,
    [Freight] MONEY NULL CONSTRAINT [DF_Orders_Freight] DEFAULT (0),
    [ShipName] NVARCHAR(40) NULL,             -- PII: Name
    [ShipAddress] NVARCHAR(60) NULL,          -- PII: Address
    [ShipCity] NVARCHAR(15) NULL,
    [ShipRegion] NVARCHAR(15) NULL,
    [ShipPostalCode] NVARCHAR(10) NULL,       -- PII: Postal Code
    [ShipCountry] NVARCHAR(15) NULL,
    CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED ([OrderID])
)
GO

CREATE NONCLUSTERED INDEX [IX_Orders_CustomerID] ON [Sales].[Orders] ([CustomerID])
GO
CREATE NONCLUSTERED INDEX [IX_Orders_EmployeeID] ON [Sales].[Orders] ([EmployeeID])
GO
CREATE NONCLUSTERED INDEX [IX_Orders_OrderDate] ON [Sales].[Orders] ([OrderDate])
GO
CREATE NONCLUSTERED INDEX [IX_Orders_ShippedDate] ON [Sales].[Orders] ([ShippedDate])
GO
CREATE NONCLUSTERED INDEX [IX_Orders_ShipPostalCode] ON [Sales].[Orders] ([ShipPostalCode])
GO
CREATE NONCLUSTERED INDEX [IX_Orders_ShipVia] ON [Sales].[Orders] ([ShipVia])
GO

-- ============================================
-- Order Details
-- ============================================
PRINT N'Creating [Sales].[OrderDetails]...'
GO

CREATE TABLE [Sales].[OrderDetails]
(
    [OrderID] INT NOT NULL,
    [ProductID] INT NOT NULL,
    [UnitPrice] MONEY NOT NULL CONSTRAINT [DF_OrderDetails_UnitPrice] DEFAULT (0),
    [Quantity] SMALLINT NOT NULL CONSTRAINT [DF_OrderDetails_Quantity] DEFAULT (1),
    [Discount] REAL NOT NULL CONSTRAINT [DF_OrderDetails_Discount] DEFAULT (0),
    CONSTRAINT [PK_OrderDetails] PRIMARY KEY CLUSTERED ([OrderID], [ProductID]),
    CONSTRAINT [CK_OrderDetails_UnitPrice] CHECK ([UnitPrice] >= 0),
    CONSTRAINT [CK_OrderDetails_Quantity] CHECK ([Quantity] > 0),
    CONSTRAINT [CK_OrderDetails_Discount] CHECK ([Discount] >= 0 AND [Discount] <= 1)
)
GO

CREATE NONCLUSTERED INDEX [IX_OrderDetails_OrderID] ON [Sales].[OrderDetails] ([OrderID])
GO
CREATE NONCLUSTERED INDEX [IX_OrderDetails_ProductID] ON [Sales].[OrderDetails] ([ProductID])
GO

-- ============================================
-- Foreign Keys
-- ============================================
PRINT N'Adding foreign keys...'
GO

ALTER TABLE [HR].[Employees] ADD CONSTRAINT [FK_Employees_Employees] 
    FOREIGN KEY ([ReportsTo]) REFERENCES [HR].[Employees] ([EmployeeID])
GO

ALTER TABLE [HR].[EmployeeTerritories] ADD CONSTRAINT [FK_EmployeeTerritories_Employees] 
    FOREIGN KEY ([EmployeeID]) REFERENCES [HR].[Employees] ([EmployeeID])
GO

ALTER TABLE [HR].[EmployeeTerritories] ADD CONSTRAINT [FK_EmployeeTerritories_Territories] 
    FOREIGN KEY ([TerritoryID]) REFERENCES [Sales].[Territories] ([TerritoryID])
GO

ALTER TABLE [Inventory].[Products] ADD CONSTRAINT [FK_Products_Categories] 
    FOREIGN KEY ([CategoryID]) REFERENCES [Inventory].[Categories] ([CategoryID])
GO

ALTER TABLE [Inventory].[Products] ADD CONSTRAINT [FK_Products_Suppliers] 
    FOREIGN KEY ([SupplierID]) REFERENCES [Inventory].[Suppliers] ([SupplierID])
GO

ALTER TABLE [Sales].[Orders] ADD CONSTRAINT [FK_Orders_Customers] 
    FOREIGN KEY ([CustomerID]) REFERENCES [Sales].[Customers] ([CustomerID])
GO

ALTER TABLE [Sales].[Orders] ADD CONSTRAINT [FK_Orders_Employees] 
    FOREIGN KEY ([EmployeeID]) REFERENCES [HR].[Employees] ([EmployeeID])
GO

ALTER TABLE [Sales].[Orders] ADD CONSTRAINT [FK_Orders_Shippers] 
    FOREIGN KEY ([ShipVia]) REFERENCES [Shipping].[Shippers] ([ShipperID])
GO

ALTER TABLE [Sales].[OrderDetails] ADD CONSTRAINT [FK_OrderDetails_Orders] 
    FOREIGN KEY ([OrderID]) REFERENCES [Sales].[Orders] ([OrderID])
GO

ALTER TABLE [Sales].[OrderDetails] ADD CONSTRAINT [FK_OrderDetails_Products] 
    FOREIGN KEY ([ProductID]) REFERENCES [Inventory].[Products] ([ProductID])
GO

ALTER TABLE [Sales].[Territories] ADD CONSTRAINT [FK_Territories_Region] 
    FOREIGN KEY ([RegionID]) REFERENCES [Sales].[Region] ([RegionID])
GO

PRINT N'Schema creation complete!'
GO

