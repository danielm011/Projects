---------------------------------------------------------------------------
--------------------          Advanced SQL        -------------------------												
---------------------------------------------------------------------------

USE AdventureWorks2019

--1: Show products that were never purchased
--   Show Columns: ProductID, ProductName, Color, ListPrice, Size

SELECT [ProductID],
       [Name] AS ProductName,
	   [Color],
	   [ListPrice],
	   [Size]
FROM [Production].[Product]
WHERE ProductID NOT IN (SELECT DISTINCT ProductID
						FROM Sales.SalesOrderDetail)

--UPDATES (necessary before answering question 2)
update sales.customer set personid=customerid    
where customerid <=290 

update sales.customer set personid=customerid+1700     
where customerid >= 300 and customerid<=350 

update sales.customer set personid=customerid+1700    
where customerid >= 352 and customerid<=701 


--2: Show customers that have not placed any orders
--   Show columns: CustomerID, Firstname, LastName in ascending order
--   If there is missing data in columns FirstName and LastName - show value "Unkown"

SELECT C.[CustomerID],
	   IIF(P.[FirstName] IS NULL, 'Unkown', P.[FirstName]) AS FirstName,  
	   IIF(P.[LastName] IS NULL, 'Unkown', P.[LastName]) AS LastName
FROM [Sales].[Customer] C FULL JOIN [Person].[Person] P
ON C.PersonID = P.BusinessEntityID
WHERE C.CustomerID NOT IN (SELECT DISTINCT CustomerID
					       FROM Sales.SalesOrderHeader)
ORDER BY C.CustomerID



--3: Show the 10 customers that have placed the most orders
--   Show columns: CustomerID, FirstName, LastName and the amount of orders in descending order

SELECT TOP 10 SOH.[CustomerID],
			  P.[FirstName],
			  P.[LastName],
			  COUNT(SOH.[CustomerID]) AS CountOfOrders
FROM [Sales].[SalesOrderHeader] SOH LEFT JOIN [Sales].[Customer] C
ON SOH.CustomerID = C.CustomerID
JOIN [Person].[Person] P 
ON C.PersonID = P.BusinessEntityID
GROUP BY SOH.[CustomerID],P.[FirstName],P.[LastName]
ORDER BY CountOfOrders DESC


--4: Show data regarding employees and their job titles
--   Show columns: FirstName, LastName, JobTitle, HireDate and the amount of employees that share the same job title

SELECT P.FirstName,
	   P.LastName,
	   E.JobTitle,
	   E.HireDate,
	   COUNT(E.BusinessEntityID) OVER (PARTITION BY E.JobTitle) AS 'JobTitleCount'
FROM [Person].[Person] P JOIN [HumanResources].[Employee] E
ON P.BusinessEntityID = E.BusinessEntityID


--5: For every customer, show their most recent order date and the second most recent order date.
--   Show columns: SalesOrderID, CustomerID, LastName, FirstName, LastOrder, PreviousOrder

WITH CTE
AS
(SELECT  SalesOrderID, soh.CustomerID, OrderDate as 'LastOrder',
 LAG(OrderDate,1) OVER (PARTITION BY c.personid ORDER BY orderdate) as 'PreviousOrder',
 DENSE_RANK () OVER (PARTITION BY soh.customerid ORDER BY orderdate DESC) s
 FROM Sales.SalesOrderHeader soh join sales.Customer c
 ON soh.CustomerID = c.CustomerID)

 SELECT SalesOrderID, c.CustomerID, LastName, FirstName, LastOrder, PreviousOrder
 FROM CTE w join sales.Customer c
 ON w.CustomerID = c.CustomerID
 join Person.Person p
 ON c.PersonID = p.BusinessEntityID
 WHERE s = 1


--6: For every year, Show the order with the highest total payment and which customer placed the order
--   Show columns: Year, SalesOrderID, LastName, FirstName, Total

WITH CTE
AS (SELECT Year(Soh.OrderDate) AS 'Year',
		   Soh.SalesOrderID, Soh.CustomerID,
		   SUM(UnitPrice *(1-UnitPriceDiscount)* OrderQty) AS 'Total',
		   DENSE_RANK() OVER (PARTITION BY YEAR(Soh.OrderDate)
	ORDER BY SUM(UnitPrice *(1-UnitPriceDiscount)* OrderQty)DESC) 'W'
	FROM Sales.SalesOrderDetail sod JOIN Sales.SalesOrderHeader soh
	ON sod.SalesOrderID = soh.SalesOrderID
    GROUP BY YEAR(soh.OrderDate),soh.SalesOrderID, soh.CustomerID)
SELECT d.year,
	   d.SalesOrderID,
	   p.LastName,
	   p.FirstName,Total
FROM CTE d JOIN Sales.Customer c 
ON d.CustomerID = c.CustomerID
JOIN Person.Person p
ON p.BusinessEntityID = c.PersonID
WHERE W = 1


--7: Show the number of orders for by month, for every year
--   Show Columns: Month and a column for every year

SELECT * 
FROM (SELECT YEAR(OrderDate) AS 'Year',
	  MONTH(OrderDate) AS 'Month',
	  SalesOrderID
	  FROM Sales.SalesOrderHeader) s
	  PIVOT (COUNT(Salesorderid) FOR YEAR IN([2011],[2012],[2013],[2014])) p
ORDER BY Month


--8: Show a monthly and yearly sales total and also include a row for the grand total
--   Show Columns: Year, Month, Sum_Price, Money

WITH CTE
AS (SELECT YEAR(OrderDate) AS 'Year',
		   MONTH(OrderDate) AS 'Month',
		   ROUND(SUM(SubTotal),2) AS 'MonthTotal',
		   ROUND(SUM(SUM(Subtotal)) OVER(PARTITION BY YEAR(OrderDate) ORDER BY MONTH(OrderDate)),2) AS 'Total'
	FROM Sales.SalesOrderHeader
	GROUP BY YEAR(Orderdate),MONTH(OrderDate))

SELECT Year,
	   CONVERT(nvarchar(11),Month) as Month,
	   Monthtotal as Sum_Price,
	   total as Money
FROM CTE

UNION ALL

SELECT YEAR,'GrandTotal',Null,Sum(MonthTotal) as Money
FROM CTE
GROUP BY Year
ORDER BY Year,Money


--9: Show employees sorted by their hire date in every department from most to least recent, name and hire date for the last employee hired before them 
--   and the number of days between the two hire dates
--   Show Columns: DepartmentName, EmployeeID, EmployeeFullName, HireDate, Seniority, PreviousEmpName, PreviousEmpHDate, DiffDays

SELECT [Name] as 'DepartmentName',
	   E.BusinessEntityID as 'EmployeeID',
	   CONCAT(P.FirstName, ' ' ,P.LastName) as 'EmployeeFullName',
	   HireDate,
	   DATEDIFF(mm,HireDate,GETDATE()) as 'Seniority',
	   LAG(CONCAT(P.FirstName, ' ' ,P.LastName),1) OVER(Order by e.BusinessEntityID) AS 'PreviousEmpName',
	   LAG(HireDate,1) OVER(Partition by D.name Order by e.businessentityid) AS 'PreviousEmpDate',
	   DATEDIFF(dd,LAG(HireDate,1) OVER(ORDER BY e.businessentityID),HireDate) AS DiffDays
FROM [HumanResources].[Employee] E JOIN [HumanResources].[EmployeeDepartmentHistory] DH
ON E.BusinessEntityID = DH.BusinessEntityID
JOIN [HumanResources].[Department] D
ON DH.DepartmentID = D.DepartmentID
JOIN Person.Person P
ON P.BusinessEntityID = dh.BusinessEntityID
ORDER BY Name,e.BusinessEntityID DESC, HireDate


--10: Show the names and IDs of employees within each department and for each hire date
--	  Show columns: HireDate, DepartmentID, Name+ID

WITH CTE
AS
(SELECT e.HireDate, d.DepartmentID, CONCAT(p.BusinessEntityID, ' ', p.LastName, ' ', p.FirstName) as a
 FROM HumanResources.employee e JOIN Person.Person p
 ON e.BusinessEntityID = p.BusinessEntityID
 JOIN HumanResources.EmployeeDepartmentHistory edh
 ON e.BusinessEntityID = edh.BusinessEntityID 
 JOIN HumanResources.Department d
 ON edh.DepartmentID = d.DepartmentID
 WHERE edh.EndDate is null)
 
 SELECT g.HireDate, g.DepartmentID, STRING_AGG(g.a,',') AS "Name+ID"
 FROM CTE AS g
 GROUP BY g.HireDate, g.DepartmentID
 ORDER BY g.HireDate
