-- Northwind-Data.sql
-- ===========================
-- Sample production data for Northwind database
-- Contains realistic PII for masking demonstration
-- ===========================

SET NOCOUNT ON
GO

-- ============================================
-- Categories
-- ============================================
PRINT N'Inserting Categories...'
GO

SET IDENTITY_INSERT [Inventory].[Categories] ON
GO

INSERT INTO [Inventory].[Categories] ([CategoryID], [CategoryName], [Description]) VALUES
(1, N'Beverages', N'Soft drinks, coffees, teas, beers, and ales'),
(2, N'Condiments', N'Sweet and savory sauces, relishes, spreads, and seasonings'),
(3, N'Confections', N'Desserts, candies, and sweet breads'),
(4, N'Dairy Products', N'Cheeses'),
(5, N'Grains/Cereals', N'Breads, crackers, pasta, and cereal'),
(6, N'Meat/Poultry', N'Prepared meats'),
(7, N'Produce', N'Dried fruit and bean curd'),
(8, N'Seafood', N'Seaweed and fish')
GO

SET IDENTITY_INSERT [Inventory].[Categories] OFF
GO

-- ============================================
-- Region
-- ============================================
PRINT N'Inserting Regions...'
GO

INSERT INTO [Sales].[Region] ([RegionID], [RegionDescription]) VALUES
(1, N'Eastern'),
(2, N'Western'),
(3, N'Northern'),
(4, N'Southern')
GO

-- ============================================
-- Shippers
-- ============================================
PRINT N'Inserting Shippers...'
GO

SET IDENTITY_INSERT [Shipping].[Shippers] ON
GO

INSERT INTO [Shipping].[Shippers] ([ShipperID], [CompanyName], [Phone]) VALUES
(1, N'Speedy Express', N'(503) 555-9831'),
(2, N'United Package', N'(503) 555-3199'),
(3, N'Federal Shipping', N'(503) 555-9931')
GO

SET IDENTITY_INSERT [Shipping].[Shippers] OFF
GO

-- ============================================
-- Suppliers - Contains PII
-- ============================================
PRINT N'Inserting Suppliers...'
GO

SET IDENTITY_INSERT [Inventory].[Suppliers] ON
GO

INSERT INTO [Inventory].[Suppliers] ([SupplierID], [CompanyName], [ContactName], [ContactTitle], [Address], [City], [Region], [PostalCode], [Country], [Phone], [Fax]) VALUES
(1, N'Exotic Liquids', N'Charlotte Cooper', N'Purchasing Manager', N'49 Gilbert St.', N'London', NULL, N'EC1 4SD', N'UK', N'(171) 555-2222', NULL),
(2, N'New Orleans Cajun', N'Shelley Burke', N'Order Administrator', N'P.O. Box 78934', N'New Orleans', N'LA', N'70117', N'USA', N'(100) 555-4822', NULL),
(3, N'Grandma Kellys', N'Regina Murphy', N'Sales Representative', N'707 Oxford Rd.', N'Ann Arbor', N'MI', N'48104', N'USA', N'(313) 555-5735', N'(313) 555-3349'),
(4, N'Tokyo Traders', N'Yoshi Nagase', N'Marketing Manager', N'9-8 Sekimai Musashino', N'Tokyo', NULL, N'100', N'Japan', N'(03) 3555-5011', NULL),
(5, N'Cooperativa Quesos', N'Antonio del Valle', N'Export Administrator', N'Calle del Rosal 4', N'Oviedo', N'Asturias', N'33007', N'Spain', N'(98) 598 76 54', NULL),
(6, N'Mayumis', N'Mayumi Ohno', N'Marketing Representative', N'92 Setsuko Chuo-ku', N'Osaka', NULL, N'545', N'Japan', N'(06) 431-7877', NULL),
(7, N'Pavlova Ltd.', N'Ian Devling', N'Marketing Manager', N'74 Rose St. Moonie Ponds', N'Melbourne', N'Victoria', N'3058', N'Australia', N'(03) 444-2343', N'(03) 444-6588'),
(8, N'Specialty Biscuits', N'Peter Wilson', N'Sales Representative', N'29 Kings Way', N'Manchester', NULL, N'M14 GSD', N'UK', N'(161) 555-4448', NULL)
GO

SET IDENTITY_INSERT [Inventory].[Suppliers] OFF
GO

-- ============================================
-- Products
-- ============================================
PRINT N'Inserting Products...'
GO

SET IDENTITY_INSERT [Inventory].[Products] ON
GO

INSERT INTO [Inventory].[Products] ([ProductID], [ProductName], [SupplierID], [CategoryID], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [ReorderLevel], [Discontinued]) VALUES
(1, N'Chai', 1, 1, N'10 boxes x 20 bags', 18.00, 39, 0, 10, 0),
(2, N'Chang', 1, 1, N'24 - 12 oz bottles', 19.00, 17, 40, 25, 0),
(3, N'Aniseed Syrup', 1, 2, N'12 - 550 ml bottles', 10.00, 13, 70, 25, 0),
(4, N'Chef Antons Cajun', 2, 2, N'48 - 6 oz jars', 22.00, 53, 0, 0, 0),
(5, N'Chef Antons Gumbo', 2, 2, N'36 boxes', 21.35, 0, 0, 0, 1),
(6, N'Grandmas Spread', 3, 2, N'12 - 8 oz jars', 25.00, 120, 0, 25, 0),
(7, N'Uncle Bobs Pears', 3, 7, N'12 - 1 lb pkgs.', 30.00, 15, 0, 10, 0),
(8, N'Northwoods Cranberry', 3, 2, N'12 - 12 oz jars', 40.00, 6, 0, 0, 0),
(9, N'Mishi Kobe Niku', 4, 6, N'18 - 500 g pkgs.', 97.00, 29, 0, 0, 1),
(10, N'Ikura', 4, 8, N'12 - 200 ml jars', 31.00, 31, 0, 0, 0)
GO

SET IDENTITY_INSERT [Inventory].[Products] OFF
GO

-- ============================================
-- Customers - Contains PII
-- ============================================
PRINT N'Inserting Customers...'
GO

INSERT INTO [Sales].[Customers] ([CustomerID], [CompanyName], [ContactName], [ContactTitle], [Address], [City], [Region], [PostalCode], [Country], [Phone], [Fax], [Email]) VALUES
(N'ALFKI', N'Alfreds Futterkiste', N'Maria Anders', N'Sales Representative', N'Obere Str. 57', N'Berlin', NULL, N'12209', N'Germany', N'030-0074321', N'030-0076545', N'maria.anders@alfreds.de'),
(N'ANATR', N'Ana Trujillo Emparedados', N'Ana Trujillo', N'Owner', N'Avda. de la Constitución 2222', N'México D.F.', NULL, N'05021', N'Mexico', N'(5) 555-4729', N'(5) 555-3745', N'ana.trujillo@emparedados.mx'),
(N'ANTON', N'Antonio Moreno Taquería', N'Antonio Moreno', N'Owner', N'Mataderos 2312', N'México D.F.', NULL, N'05023', N'Mexico', N'(5) 555-3932', NULL, N'antonio@taqueria.mx'),
(N'AROUT', N'Around the Horn', N'Thomas Hardy', N'Sales Representative', N'120 Hanover Sq.', N'London', NULL, N'WA1 1DP', N'UK', N'(171) 555-7788', N'(171) 555-6750', N'thomas.hardy@aroundthehorn.co.uk'),
(N'BERGS', N'Berglunds snabbköp', N'Christina Berglund', N'Order Administrator', N'Berguvsvägen 8', N'Luleå', NULL, N'S-958 22', N'Sweden', N'0921-12 34 65', N'0921-12 34 67', N'christina@berglunds.se'),
(N'BLAUS', N'Blauer See Delikatessen', N'Hanna Moos', N'Sales Representative', N'Forsterstr. 57', N'Mannheim', NULL, N'68306', N'Germany', N'0621-08460', N'0621-08924', N'hanna.moos@blauersee.de'),
(N'BLONP', N'Blondesddsl père et fils', N'Frédérique Citeaux', N'Marketing Manager', N'24, place Kléber', N'Strasbourg', NULL, N'67000', N'France', N'88.60.15.31', N'88.60.15.32', N'frederique@blondesddsl.fr'),
(N'BOLID', N'Bólido Comidas preparadas', N'Martín Sommer', N'Owner', N'C/ Araquil, 67', N'Madrid', NULL, N'28023', N'Spain', N'(91) 555 22 82', N'(91) 555 91 99', N'martin.sommer@bolido.es'),
(N'BONAP', N'Bon app''', N'Laurence Lebihan', N'Owner', N'12, rue des Bouchers', N'Marseille', NULL, N'13008', N'France', N'91.24.45.40', N'91.24.45.41', N'laurence@bonapp.fr'),
(N'BOTTM', N'Bottom-Dollar Markets', N'Elizabeth Lincoln', N'Accounting Manager', N'23 Tsawassen Blvd.', N'Tsawassen', N'BC', N'T2F 8M4', N'Canada', N'(604) 555-4729', N'(604) 555-3745', N'elizabeth.lincoln@bottomdollar.ca'),
(N'BSBEV', N'B''s Beverages', N'Victoria Ashworth', N'Sales Representative', N'Fauntleroy Circus', N'London', NULL, N'EC2 5NT', N'UK', N'(171) 555-1212', NULL, N'victoria@bsbev.co.uk'),
(N'CACTU', N'Cactus Comidas para llevar', N'Patricio Simpson', N'Sales Agent', N'Cerrito 333', N'Buenos Aires', NULL, N'1010', N'Argentina', N'(1) 135-5555', N'(1) 135-4892', N'patricio@cactus.ar'),
(N'CENTC', N'Centro comercial Moctezuma', N'Francisco Chang', N'Marketing Manager', N'Sierras de Granada 9993', N'México D.F.', NULL, N'05022', N'Mexico', N'(5) 555-3392', N'(5) 555-7293', N'francisco.chang@centc.mx'),
(N'CHOPS', N'Chop-suey Chinese', N'Yang Wang', N'Owner', N'Hauptstr. 29', N'Bern', NULL, N'3012', N'Switzerland', N'0452-076545', NULL, N'yang.wang@chopsuey.ch'),
(N'COMMI', N'Comércio Mineiro', N'Pedro Afonso', N'Sales Associate', N'Av. dos Lusíadas, 23', N'Sao Paulo', N'SP', N'05432-043', N'Brazil', N'(11) 555-7647', NULL, N'pedro.afonso@cmineiro.br')
GO

-- ============================================
-- Employees - Contains PII including SSN
-- ============================================
PRINT N'Inserting Employees...'
GO

SET IDENTITY_INSERT [HR].[Employees] ON
GO

INSERT INTO [HR].[Employees] ([EmployeeID], [LastName], [FirstName], [Title], [TitleOfCourtesy], [BirthDate], [HireDate], [Address], [City], [Region], [PostalCode], [Country], [HomePhone], [Extension], [Notes], [ReportsTo], [Email], [SSN]) VALUES
(1, N'Davolio', N'Nancy', N'Sales Representative', N'Ms.', '1968-12-08', '1992-05-01', N'507 - 20th Ave. E. Apt. 2A', N'Seattle', N'WA', N'98122', N'USA', N'(206) 555-9857', N'5467', N'Education includes a BA in psychology.', NULL, N'nancy.davolio@northwind.com', N'123-45-6789'),
(2, N'Fuller', N'Andrew', N'Vice President, Sales', N'Dr.', '1952-02-19', '1992-08-14', N'908 W. Capital Way', N'Tacoma', N'WA', N'98401', N'USA', N'(206) 555-9482', N'3457', N'Andrew received his BTS commercial degree in 1974.', NULL, N'andrew.fuller@northwind.com', N'234-56-7890'),
(3, N'Leverling', N'Janet', N'Sales Representative', N'Ms.', '1963-08-30', '1992-04-01', N'722 Moss Bay Blvd.', N'Kirkland', N'WA', N'98033', N'USA', N'(206) 555-3412', N'3355', N'Janet has a BS degree in chemistry from Boston College.', 2, N'janet.leverling@northwind.com', N'345-67-8901'),
(4, N'Peacock', N'Margaret', N'Sales Representative', N'Mrs.', '1958-09-19', '1993-05-03', N'4110 Old Redmond Rd.', N'Redmond', N'WA', N'98052', N'USA', N'(206) 555-8122', N'5176', N'Margaret holds a BA in English literature.', 2, N'margaret.peacock@northwind.com', N'456-78-9012'),
(5, N'Buchanan', N'Steven', N'Sales Manager', N'Mr.', '1955-03-04', '1993-10-17', N'14 Garrett Hill', N'London', NULL, N'SW1 8JR', N'UK', N'(71) 555-4848', N'3453', N'Steven Buchanan graduated from St. Andrews University.', 2, N'steven.buchanan@northwind.com', N'567-89-0123'),
(6, N'Suyama', N'Michael', N'Sales Representative', N'Mr.', '1963-07-02', '1993-10-17', N'Coventry House Miner Rd.', N'London', NULL, N'EC2 7JR', N'UK', N'(71) 555-7773', N'428', N'Michael is a graduate of Sussex University.', 5, N'michael.suyama@northwind.com', N'678-90-1234'),
(7, N'King', N'Robert', N'Sales Representative', N'Mr.', '1960-05-29', '1994-01-02', N'Edgeham Hollow Winchester Way', N'London', NULL, N'RG1 9SP', N'UK', N'(71) 555-5598', N'465', N'Robert King served in the Peace Corps.', 5, N'robert.king@northwind.com', N'789-01-2345'),
(8, N'Callahan', N'Laura', N'Inside Sales Coordinator', N'Ms.', '1958-01-09', '1994-03-05', N'4726 - 11th Ave. N.E.', N'Seattle', N'WA', N'98105', N'USA', N'(206) 555-1189', N'2344', N'Laura received a BA in psychology from the University of Washington.', 2, N'laura.callahan@northwind.com', N'890-12-3456'),
(9, N'Dodsworth', N'Anne', N'Sales Representative', N'Ms.', '1969-07-02', '1994-11-15', N'7 Houndstooth Rd.', N'London', NULL, N'WG2 7LT', N'UK', N'(71) 555-4444', N'452', N'Anne has a BA degree in English from St. Lawrence College.', 5, N'anne.dodsworth@northwind.com', N'901-23-4567')
GO

SET IDENTITY_INSERT [HR].[Employees] OFF
GO

-- ============================================
-- Territories
-- ============================================
PRINT N'Inserting Territories...'
GO

INSERT INTO [Sales].[Territories] ([TerritoryID], [TerritoryDescription], [RegionID]) VALUES
(N'01581', N'Westboro', 1),
(N'01730', N'Bedford', 1),
(N'01833', N'Georgetown', 1),
(N'02116', N'Boston', 1),
(N'02139', N'Cambridge', 1),
(N'02184', N'Braintree', 1),
(N'02903', N'Providence', 1),
(N'03049', N'Hollis', 3),
(N'03801', N'Portsmouth', 3),
(N'06897', N'Wilton', 1)
GO

-- ============================================
-- EmployeeTerritories
-- ============================================
PRINT N'Inserting EmployeeTerritories...'
GO

INSERT INTO [HR].[EmployeeTerritories] ([EmployeeID], [TerritoryID]) VALUES
(1, N'01581'),
(1, N'01730'),
(1, N'01833'),
(2, N'02116'),
(2, N'02139'),
(3, N'02184'),
(3, N'02903'),
(4, N'03049'),
(4, N'03801'),
(5, N'06897')
GO

-- ============================================
-- Orders - Contains PII in shipping fields
-- ============================================
PRINT N'Inserting Orders...'
GO

SET IDENTITY_INSERT [Sales].[Orders] ON
GO

INSERT INTO [Sales].[Orders] ([OrderID], [CustomerID], [EmployeeID], [OrderDate], [RequiredDate], [ShippedDate], [ShipVia], [Freight], [ShipName], [ShipAddress], [ShipCity], [ShipRegion], [ShipPostalCode], [ShipCountry]) VALUES
(10248, N'ALFKI', 5, '1996-07-04', '1996-08-01', '1996-07-16', 3, 32.38, N'Maria Anders', N'Obere Str. 57', N'Berlin', NULL, N'12209', N'Germany'),
(10249, N'ANATR', 6, '1996-07-05', '1996-08-16', '1996-07-10', 1, 11.61, N'Ana Trujillo', N'Avda. de la Constitución 2222', N'México D.F.', NULL, N'05021', N'Mexico'),
(10250, N'ANTON', 4, '1996-07-08', '1996-08-05', '1996-07-12', 2, 65.83, N'Antonio Moreno', N'Mataderos 2312', N'México D.F.', NULL, N'05023', N'Mexico'),
(10251, N'AROUT', 3, '1996-07-08', '1996-08-05', '1996-07-15', 1, 41.34, N'Thomas Hardy', N'120 Hanover Sq.', N'London', NULL, N'WA1 1DP', N'UK'),
(10252, N'BERGS', 4, '1996-07-09', '1996-08-06', '1996-07-11', 2, 51.30, N'Christina Berglund', N'Berguvsvägen 8', N'Luleå', NULL, N'S-958 22', N'Sweden'),
(10253, N'BLAUS', 3, '1996-07-10', '1996-07-24', '1996-07-16', 2, 58.17, N'Hanna Moos', N'Forsterstr. 57', N'Mannheim', NULL, N'68306', N'Germany'),
(10254, N'BLONP', 5, '1996-07-11', '1996-08-08', '1996-07-23', 2, 22.98, N'Frédérique Citeaux', N'24, place Kléber', N'Strasbourg', NULL, N'67000', N'France'),
(10255, N'BOLID', 9, '1996-07-12', '1996-08-09', '1996-07-15', 3, 148.33, N'Martín Sommer', N'C/ Araquil, 67', N'Madrid', NULL, N'28023', N'Spain'),
(10256, N'BONAP', 3, '1996-07-15', '1996-08-12', '1996-07-17', 2, 13.97, N'Laurence Lebihan', N'12, rue des Bouchers', N'Marseille', NULL, N'13008', N'France'),
(10257, N'BOTTM', 4, '1996-07-16', '1996-08-13', '1996-07-22', 3, 81.91, N'Elizabeth Lincoln', N'23 Tsawassen Blvd.', N'Tsawassen', N'BC', N'T2F 8M4', N'Canada'),
(10258, N'BSBEV', 1, '1996-07-17', '1996-08-14', '1996-07-23', 1, 140.51, N'Victoria Ashworth', N'Fauntleroy Circus', N'London', NULL, N'EC2 5NT', N'UK'),
(10259, N'CACTU', 4, '1996-07-18', '1996-08-15', '1996-07-25', 3, 3.25, N'Patricio Simpson', N'Cerrito 333', N'Buenos Aires', NULL, N'1010', N'Argentina'),
(10260, N'CENTC', 4, '1996-07-19', '1996-08-16', '1996-07-29', 1, 55.09, N'Francisco Chang', N'Sierras de Granada 9993', N'México D.F.', NULL, N'05022', N'Mexico'),
(10261, N'CHOPS', 4, '1996-07-19', '1996-08-16', '1996-07-30', 2, 3.05, N'Yang Wang', N'Hauptstr. 29', N'Bern', NULL, N'3012', N'Switzerland'),
(10262, N'COMMI', 8, '1996-07-22', '1996-08-19', '1996-07-25', 3, 48.29, N'Pedro Afonso', N'Av. dos Lusíadas, 23', N'Sao Paulo', N'SP', N'05432-043', N'Brazil')
GO

SET IDENTITY_INSERT [Sales].[Orders] OFF
GO

-- ============================================
-- Order Details
-- ============================================
PRINT N'Inserting Order Details...'
GO

INSERT INTO [Sales].[OrderDetails] ([OrderID], [ProductID], [UnitPrice], [Quantity], [Discount]) VALUES
(10248, 1, 14.00, 12, 0),
(10248, 2, 9.80, 10, 0),
(10248, 3, 34.80, 5, 0),
(10249, 4, 18.60, 9, 0),
(10249, 5, 42.40, 40, 0),
(10250, 1, 14.00, 10, 0),
(10250, 6, 17.45, 35, 0.15),
(10250, 7, 7.75, 15, 0.15),
(10251, 2, 15.60, 6, 0.05),
(10251, 8, 15.60, 15, 0.05),
(10252, 1, 14.00, 40, 0.05),
(10252, 9, 77.60, 25, 0.05),
(10252, 10, 24.80, 40, 0),
(10253, 3, 8.00, 20, 0),
(10253, 4, 17.60, 42, 0),
(10254, 5, 17.00, 15, 0),
(10254, 6, 19.50, 21, 0),
(10255, 7, 24.00, 20, 0),
(10255, 8, 32.00, 35, 0),
(10256, 9, 77.60, 15, 0),
(10257, 10, 24.80, 25, 0),
(10258, 1, 14.00, 50, 0.2),
(10258, 2, 15.60, 65, 0.2),
(10259, 3, 8.00, 10, 0),
(10260, 4, 17.60, 16, 0.25),
(10261, 5, 17.00, 20, 0),
(10262, 6, 19.50, 12, 0.2),
(10262, 7, 24.00, 15, 0)
GO

PRINT N'Data load complete!'
GO
