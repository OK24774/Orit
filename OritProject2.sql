use AdventureWorks2019

go


  --- Question 1 -----------------------------------------

SELECT Prod.ProductID,Prod.Name,Prod.Color,Prod.ListPrice,Prod.Size 
FROM production.Product Prod
	 Left Join Sales.SalesOrderDetail Sod
	 ON Prod.ProductID=Sod.ProductID
WHERE Sod.ProductID is null
ORDER BY Prod.ProductID

go


--- Question 2 --------------------------------------------------------

SELECT Cus.CustomerID,
	   ISNULL(Per.LastName,'Unknown') AS LastName,
	   ISNULL(Per.FirstName,'Unknown') AS Firstname
FROM  Sales.Customer Cus
	Left Join person.Person Per
	ON Cus.CustomerID=Per.BusinessEntityID
WHERE Cus.CustomerID NOT IN (
							SELECT CustomerID
							FROM Sales.SalesOrderHeader)
ORDER BY Cus.CustomerID 

go

---- Question 3

SELECT TOP 10 
    Cus.CustomerID, 
    Per.LastName, 
    Per.FirstName, 
    COUNT(Sod.SalesOrderID) AS CountOfOrders
FROM 
    Sales.SalesOrderHeader Sod
	JOIN Sales.Customer Cus ON Sod.CustomerID = Cus.CustomerID
	JOIN Person.Person Per ON Cus.PersonID = Per.BusinessEntityID
GROUP BY 
   Cus.CustomerID,Per.LastName,Per.FirstName
ORDER BY 
    CountOfOrders DESC

go

	---- Question 4 ---------------------------------------------------------------------

SELECT Per.FirstName,Per.LastName,HR.JobTitle,HR.HireDate
	,Count (*) OVER(PARTITION BY HR.JobTitle) AS CountTitle
FROM Person.Person Per
	JOIN HumanResources.Employee HR ON Per.BusinessEntityID=HR.BusinessEntityID
ORDER BY HR.JobTitle

go

 --- Question 5 --------------------------------------------------------------------

 WITH RankedOrdersCTE AS (
    SELECT 
        soh.SalesOrderID,
        cus.CustomerID,
        per.LastName,
        per.FirstName,
        soh.OrderDate AS LastOrder,
        LAG(soh.OrderDate) OVER (PARTITION BY cus.CustomerID ORDER BY soh.OrderDate) AS PreviousOrder,
        RANK() OVER (PARTITION BY cus.CustomerID ORDER BY soh.OrderDate DESC) AS RO
    FROM 
        Sales.SalesOrderHeader soh
    JOIN 
        Sales.Customer cus ON soh.CustomerID = cus.CustomerID
    JOIN 
        Person.Person per ON cus.PersonID = per.BusinessEntityID
)
SELECT 
    CustomerID,
    LastName,
    FirstName,
    LastOrder,
    PreviousOrder
FROM 
    RankedOrdersCTE
WHERE 
    RO = 1
ORDER BY 
    CustomerID Desc

go

	------ QUESTION 6 -----------------------------------------------

	WITH MostExOrderCTE AS (
    SELECT 
        YEAR(SOH.OrderDate) AS Year,
        SOH.SalesOrderID,
        PP.LastName,
        PP.FirstName,
        SUM((SD.UnitPrice*(1-SD.UnitPriceDiscount))*SD.OrderQty) AS Total,
        ROW_NUMBER() OVER (PARTITION BY YEAR(SOH.OrderDate) ORDER BY SUM((SD.UnitPrice * (1 - SD.UnitPriceDiscount)) * SD.OrderQty) DESC) AS RN
    FROM 
        Sales.SalesOrderHeader SOH
    JOIN
        Sales.SalesOrderDetail SD ON SOH.SalesOrderID = SD.SalesOrderID
    JOIN
        Sales.Customer CUS ON SOH.CustomerID = CUS.CustomerID
    JOIN 
        Person.Person PP ON CUS.PersonID = PP.BusinessEntityID
    GROUP BY 
        YEAR(SOH.OrderDate),
        SOH.SalesOrderID,
        PP.LastName,
        PP.FirstName
) 

SELECT 
	MostExOrderCTE.Year,
    MostExOrderCTE.SalesOrderID,
    MostExOrderCTE.LastName,
    MostExOrderCTE.FirstName,
    FORMAT(Total, '#,##0.00') AS Total

FROM 
    MostExOrderCTE 
WHERE 
    MostExOrderCTE.RN = 1
go

	----- question 7 --------------------------------------------------

SELECT 
    DATEPART(MM, OrderDate) AS Month,
    SUM(
		CASE WHEN DATEPART(YY, OrderDate) = 2011 THEN 1 ELSE 0 END) AS '2011',
    SUM(
		CASE WHEN DATEPART(YY, OrderDate) = 2012 THEN 1 ELSE 0 END) AS '2012',
    SUM(
		CASE WHEN DATEPART(YY, OrderDate) = 2013 THEN 1 ELSE 0 END) AS '2013',
    SUM(
		CASE WHEN DATEPART(YY, OrderDate) = 2014 THEN 1 ELSE 0 END) AS '2014'
FROM 
    Sales.SalesOrderHeader
GROUP BY 
    DATEPART(MM, OrderDate)
ORDER BY 
    DATEPART(MM, OrderDate)
go

----- question 8 ------------------------------------------

WITH SumPriceCTE AS (
						SELECT YEAR(SOH.OrderDate) AS Years
							   ,MONTH(SOH.OrderDate) AS Months
					        	,ROUND(SUM(UnitPrice*(1-UnitPriceDiscount)),2) AS Sum_Price
						FROM Sales.SalesOrderDetail SOD
							JOIN Sales.SalesOrderHeader SOH
							ON SOD.SalesOrderID=SOH.SalesOrderID
						GROUP BY YEAR(SOH.OrderDate),MONTH(SOH.OrderDate))
,
CumulatedCTE AS (
						SELECT Years,CAST(Months AS NVARCHAR) AS Months,Sum_Price
							,SUM(Sum_Price)OVER(PARTITION BY Years ORDER BY Months) AS CumSum
							,ROW_NUMBER()OVER(PARTITION BY Years ORDER BY Months) AS RN
						FROM SumPriceCTE
						GROUP BY Years,Months,Sum_Price
					UNION
						SELECT YEAR(SOH.OrderDate) AS Years
						,'Grand_Total',NULL
						,ROUND(SUM(UnitPrice*(1-UnitPriceDiscount)),2) AS Sum_Price
						,13
						FROM Sales.SalesOrderDetail SOD
							JOIN Sales.SalesOrderHeader SOH
							ON SOD.SalesOrderID=SOH.SalesOrderID
						GROUP BY YEAR(SOH.OrderDate))
SELECT Years,Months,Sum_Price,CumSum
FROM CumulatedCTE
ORDER BY Years,RN

go

	--------------------------------------------   Question 9 -----------------------------


	WITH EmpRank AS (
    SELECT 
        HRD.Name AS DepartmentName,
        Emp.BusinessEntityID AS employeesid,
        CONCAT(PP.FirstName, ' ', PP.LastName) AS EmployeesFullName,
        Emp.HireDate AS HireDate,
        DATEDIFF(MM,Emp.HireDate, GETDATE()) AS Seniority,
        LAG(CONCAT(PP.FirstName, ' ', PP.LastName)) OVER (PARTITION BY EDH.DepartmentID ORDER BY Emp.HireDate DESC) AS PreviousEmpName,
        LAG(Emp.HireDate) OVER (PARTITION BY Emp.HireDate  ORDER BY EDH.DepartmentID  DESC) AS PreviousEmpHDate,
        ABS(DATEDIFF(DAY, LAG(Emp.HireDate) OVER (PARTITION BY EDH.DepartmentID ORDER BY Emp.HireDate DESC), Emp.HireDate)) AS DiffDays
    FROM 
        HumanResources.Employee AS Emp
    JOIN 
        HumanResources.EmployeeDepartmentHistory AS EDH ON Emp.BusinessEntityID = EDH.BusinessEntityID
    JOIN 
        Person.Person AS PP ON Emp.BusinessEntityID = PP.BusinessEntityID
    JOIN 
        HumanResources.Department AS HRD ON EDH.DepartmentID = HRD.DepartmentID
)
SELECT 
    DepartmentName, employeesid, EmployeesFullName, HireDate, Seniority,PreviousEmpName, PreviousEmpHDate, DiffDays
FROM 
    EmpRank
ORDER BY 
    DepartmentName,
    Seniority
go

	-------------------------------------------------- Question 10 ----------------------------------

WITH EmpFullIDCTE
	AS(	SELECT Emp.HireDate,ED.DepartmentID
				,CONCAT_WS(' ',Emp.BusinessEntityID,PP.LastName,PP.FirstName) AS EmpFullID
		FROM HumanResources.Employee Emp
				JOIN Person.Person PP
					ON Emp.BusinessEntityID=PP.BusinessEntityID
				JOIN HumanResources.EmployeeDepartmentHistory ED
					ON ED.BusinessEntityID=Emp.BusinessEntityID
		WHERE ED.EndDate IS NULL)
SELECT HireDate,DepartmentID,
	   STRING_AGG(EmpFullID,', ')WITHIN GROUP(ORDER BY HireDate) AS TeamEmployees

FROM EmpFullIDCTE

GROUP BY HireDate,DepartmentID

ORDER BY HireDate DESC

go


			-------------------------- The end and Thank you ----------------------------