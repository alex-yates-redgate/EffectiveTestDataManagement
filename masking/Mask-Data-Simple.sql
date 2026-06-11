-- Mask-Data-Simple.sql
-- Simple data masking using basic SQL replacements
-- Masks all sensitive columns with placeholder values

-- Sales.Customers
UPDATE [Sales].[Customers] SET 
    [ContactName] = 'Masked Customer',
    [Address] = 'xxx',
    [PostalCode] = 'xxx',
    [Phone] = '(555) 555-5555',
    [Fax] = '(555) 555-5555',
    [Email] = 'masked@example.com'
WHERE [ContactName] IS NOT NULL

-- HR.Employees
UPDATE [HR].[Employees] SET
    [FirstName] = 'Employee',
    [LastName] = 'Masked',
    [BirthDate] = '1900-01-01',
    [Address] = 'xxx',
    [PostalCode] = 'xxx',
    [HomePhone] = '(555) 555-5555',
    [Email] = 'masked@example.com',
    [SSN] = 'xxx-xx-xxxx'
WHERE [FirstName] IS NOT NULL

-- Inventory.Suppliers
UPDATE [Inventory].[Suppliers] SET
    [ContactName] = 'Masked Supplier',
    [Address] = 'xxx',
    [PostalCode] = 'xxx',
    [Phone] = '(555) 555-5555',
    [Fax] = '(555) 555-5555'
WHERE [ContactName] IS NOT NULL

-- Sales.Orders
UPDATE [Sales].[Orders] SET
    [ShipName] = 'Masked Recipient',
    [ShipAddress] = 'xxx',
    [ShipPostalCode] = 'xxx'
WHERE [ShipName] IS NOT NULL
