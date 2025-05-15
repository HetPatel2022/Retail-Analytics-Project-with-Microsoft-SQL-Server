/* ===================================================
   =============== Retail Analytics Project ==========
   ===================================================

   Author: Hetkumar Patel
   Description: SQL scripts for Retail Analytics Project
   - Create schema
   - Clean data ETL
   - Core analysis queries

   Database: RetailAnalytics

   =================================================== */


/* ===================================================
   === Step 1: Create Database and Tables ============
   =================================================== */

PRINT('=== Creating Database and Tables ===');

-- Create database if not exists
IF DB_ID('RetailAnalytics') IS NULL
    CREATE DATABASE RetailAnalytics;
GO

USE RetailAnalytics;
GO

-- Drop tables if exist to start fresh
IF OBJECT_ID('dbo.Raw_OnlineRetail', 'U') IS NOT NULL DROP TABLE dbo.Raw_OnlineRetail;
IF OBJECT_ID('dbo.Cleaned_OnlineRetail', 'U') IS NOT NULL DROP TABLE dbo.Cleaned_OnlineRetail;
GO

-- Create raw table with loose types for initial import
CREATE TABLE dbo.Raw_OnlineRetail (
    InvoiceNo NVARCHAR(50),
    StockCode NVARCHAR(50),
    Description NVARCHAR(255),
    Quantity NVARCHAR(50),       -- temporarily as NVARCHAR
    InvoiceDate NVARCHAR(50),    -- keep as NVARCHAR for import
    UnitPrice NVARCHAR(50),
    CustomerID NVARCHAR(50),
    Country NVARCHAR(100)
);
GO

-- Create cleaned table with correct data types
CREATE TABLE dbo.Cleaned_OnlineRetail (
    InvoiceNo NVARCHAR(50),
    StockCode NVARCHAR(50),
    Description NVARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice FLOAT,
    CustomerID INT,
    Country NVARCHAR(100)
);
GO


/* ===================================================
   === Step 2: ETL - Clean and Load Data ============
   =================================================== */

PRINT('=== ETL: Cleaning and Loading Data ===');

-- Insert cleaned data from Raw_OnlineRetail (or data) into Cleaned_OnlineRetail
INSERT INTO dbo.Cleaned_OnlineRetail (InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country)
SELECT
    InvoiceNo,
    StockCode,
    Description,
    TRY_CAST(Quantity AS INT),
    TRY_CONVERT(DATETIME, InvoiceDate, 105), -- Format: dd-mm-yyyy hh:mm
    TRY_CAST(UnitPrice AS FLOAT),
    TRY_CAST(CustomerID AS INT),
    Country
FROM dbo.Raw_OnlineRetail
WHERE 
    TRY_CAST(Quantity AS INT) IS NOT NULL AND
    TRY_CONVERT(DATETIME, InvoiceDate, 105) IS NOT NULL AND
    TRY_CAST(UnitPrice AS FLOAT) IS NOT NULL;
GO


/* ===================================================
   === Step 3: Data Validation =======================
   =================================================== */

PRINT('=== Data Validation Queries ===');

-- Quick look at cleaned data
SELECT TOP 10 * FROM dbo.Cleaned_OnlineRetail;
GO

-- Total rows loaded
SELECT COUNT(*) AS TotalCleanedRows FROM dbo.Cleaned_OnlineRetail;
GO


/* ===================================================
   === Step 4: Core Analytical Queries ================
   =================================================== */

PRINT('=== Running Core Analytics Queries ===');

-- 1. Total Revenue
SELECT 
    ROUND(SUM(Quantity * UnitPrice), 2) AS TotalRevenue
FROM dbo.Cleaned_OnlineRetail;
GO

-- 2. Top 10 Best-Selling Products
SELECT 
    Description,
    SUM(Quantity) AS TotalQuantitySold
FROM dbo.Cleaned_OnlineRetail
GROUP BY Description
ORDER BY TotalQuantitySold DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
GO

-- 3. Monthly Sales Trend
SELECT 
    FORMAT(InvoiceDate, 'yyyy-MM') AS Month,
    ROUND(SUM(Quantity * UnitPrice), 2) AS Revenue
FROM dbo.Cleaned_OnlineRetail
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM')
ORDER BY Month;
GO

-- 4. Sales by Country
SELECT 
    Country,
    ROUND(SUM(Quantity * UnitPrice), 2) AS TotalRevenue
FROM dbo.Cleaned_OnlineRetail
GROUP BY Country
ORDER BY TotalRevenue DESC;
GO

-- 5. Top 5 Customers by Spend
SELECT 
    CustomerID,
    ROUND(SUM(Quantity * UnitPrice), 2) AS TotalSpent
FROM dbo.Cleaned_OnlineRetail
GROUP BY CustomerID
ORDER BY TotalSpent DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
GO

-- 6. Number of Unique Customers
SELECT 
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM dbo.Cleaned_OnlineRetail;
GO

-- 7. Most Returned Products (Negative Quantities)
SELECT 
    Description,
    SUM(Quantity) AS TotalReturns
FROM dbo.Cleaned_OnlineRetail
WHERE Quantity < 0
GROUP BY Description
ORDER BY TotalReturns;
GO

-- 8. Average Order Value (AOV)
SELECT 
    ROUND(AVG(TotalInvoiceAmount), 2) AS AverageOrderValue
FROM (
    SELECT 
        InvoiceNo,
        SUM(Quantity * UnitPrice) AS TotalInvoiceAmount
    FROM dbo.Cleaned_OnlineRetail
    GROUP BY InvoiceNo
) AS OrderTotals;
GO

/* ===================================================
   =============== End of Script ======================
   =================================================== */

PRINT('=== Retail Analytics SQL Script Complete! ===');
