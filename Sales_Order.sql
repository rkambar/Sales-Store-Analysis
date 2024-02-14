USE Sales_Order

DELETE FROM Orders$
WHERE [Order ID] IN (SELECT [Order ID] FROM Returns$);


/* 1.	Find the top 5 customers with the highest lifetime value (LTV), 
where LTV is calculated as the sum of their profits divided by the number of years they have been customer*/

WITH CustomerProfits AS (	
SELECT [Customer Name], SUM([Profit]) AS TotalProfit
FROM Orders$
GROUP BY [Customer Name]),
CustomerYears AS (
SELECT [Customer Name], DATEDIFF(YEAR, MIN([Order Date]), MAX([Order Date])) AS YearsAsCustomer
FROM Orders$
GROUP BY [Customer Name])
SELECT TOP 5 c.[Customer Name], ROUND(c.TotalProfit / NULLIF(d.YearsAsCustomer, 0), 2) AS LifetimeValue
FROM CustomerProfits c
JOIN CustomerYears d 
ON c.[Customer Name] = d.[Customer Name]
ORDER BY LifetimeValue DESC;

/* 2. Create a pivot table to show total sales by product category and sub-category. */ 

SELECT Category, [Sub-Category], ROUND(SUM(Sales), 2) AS Total_Sales
FROM Orders$
GROUP BY Category, [Sub-Category]
ORDER BY Total_Sales DESC;


/*3. Find the customer who has made the maximum number of orders in each category:*/

SELECT [Category], [Customer Name], MAX(OrderCount) AS MaxOrders
FROM (SELECT [Category], [Customer Name], COUNT(*) AS OrderCount, 
ROW_NUMBER() OVER (PARTITION BY Category ORDER BY COUNT(*) DESC) AS rn
FROM Orders$
GROUP BY    [Category], [Customer Name]) AS RankedOrders
WHERE rn = 1
GROUP BY [Category], [Customer Name];


/* 4.	Find the top 3 products in each category based on their sales.  */

WITH RankedProducts AS (SELECT [Category], [Sub-Category], [Product Name], ROUND(SUM(Sales), 2) AS Total_Sales,
ROW_NUMBER() OVER (PARTITION BY [Category] ORDER BY SUM(Sales) DESC) AS rn
FROM Orders$
GROUP BY [Category], [Sub-Category], [Product Name])
SELECT [Category], [Sub-Category], [Product Name], Total_Sales
FROM RankedProducts
WHERE rn <= 3
ORDER BY [Category], [Sub-Category], Total_Sales DESC;

/* 5.	In the table Orders with columns OrderID, CustomerID, OrderDate, TotalAmount. 
You need to create a stored procedure Get_Customer_Orders that takes a CustomerID as input and returns a table with the following columns, 
you will need to create a function also that calculates the number of days between two dates.  
OrderDate
TotalAmount
TotalOrders: The total number of orders made by the customer.
AvgAmount: The average total amount of orders made by the customer.
LastOrderDate: The date of the customer's most recent order.
DaysSinceLastOrder: The number of days since the customer's most recent order. */


/* Here First we will create the function to calculate days between two dates */
CREATE FUNCTION dbo.CalculateDaysBetweenDates
(
  @StartDate DATE, 
  @EndDate DATE
)
RETURNS INT
AS
BEGIN
RETURN DATEDIFF(DAY, @StartDate, @EndDate);
END;

/* Now we have to create the stored procedure Get_Customer_Orders */

CREATE PROCEDURE Get_Customer_Orders
    @CustomerID VARCHAR(50)
AS
BEGIN
SELECT [Order Date],[Sales],
        COUNT([Order ID]) AS TotalOrders,
        AVG([Sales]) AS AvgAmount,
        MAX([Order Date]) AS LastOrderDate,
        dbo.CalculateDaysBetweenDates(MAX([Order Date]), GETDATE()) AS DaysSinceLastOrder
    FROM Orders$
    WHERE [Customer ID] = @CustomerID
    GROUP BY [Order Date], [Sales];
END;


/*  Verifying if the stored procedure is working with an example for CustomerID CG-12520, DV-13045 */

EXEC dbo.Get_Customer_Orders @CustomerID = 'DV-13045';





