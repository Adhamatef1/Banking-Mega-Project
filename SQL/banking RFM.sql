use Banking


--Data Quality and Integration : •	Are there any CustomerIDs in other tables not in Customers? 

SELECT DISTINCT a.CustomerID 
FROM Accounts a
LEFT JOIN Customers c ON a.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;

--------------------------------------------------------------------------------------------------------
--RFM Analysis:
--Recency:How recently they made a transaction
--Frequancy:How often they transact
--Montery:How much money they transact

CREATE VIEW RFM_View AS
WITH CustomerTransactions AS (
    SELECT 
        c.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
        MAX(t.TransactionDate) AS LastTransactionDate,
        COUNT(t.TransactionID) AS Frequency,
        SUM(t.Amount) AS Monetary
    FROM Customers c
    JOIN Accounts a ON c.CustomerID = a.CustomerID
    JOIN Transactions t ON a.AccountID = t.AccountID
    GROUP BY c.CustomerID, c.FirstName, c.LastName
)
SELECT 
    ct.CustomerID,
    ct.CustomerName,
    DATEDIFF(DAY, ct.LastTransactionDate, GETDATE()) AS Recency,
    ct.Frequency,
    ct.Monetary
FROM CustomerTransactions ct;


-- Get top 10 high-value customers(chiampions)
SELECT TOP 10 *
FROM RFM_View
ORDER BY Recency ASC, Frequency DESC, Monetary DESC;


-- Get the 5 lowest RFM customers ( At Risk customers)

SELECT TOP 5 *
FROM RFM_View
ORDER BY  Recency desc, Frequency asc, Monetary asc;;


------------------------------------------------------------------------------------------------
--Monthly new customers
SELECT 
    DATENAME(MONTH, JoinDate) AS MonthName,
    DATEPART(MONTH, JoinDate) AS MonthNumber,  -- ensures correct order if needed
    COUNT(DISTINCT CustomerID) AS [Total Number of Customers]
FROM Customers
GROUP BY DATENAME(MONTH, JoinDate), DATEPART(MONTH, JoinDate)
ORDER BY MonthNumber;

----------------------------------------------------------------------------------------------
--Top Transaction Type
select TransactionType,
       count(TransactionID) AS Total_Number_of_Transactions,
	   sum(Amount) AS Total_Amount
from transactions
group by  TransactionType
order by  2 desc, 3 desc ;

--------------------------------------------------------------------------------------------------
--Fraud or anomaly detection (high-value or frequent transfers) 
-- Step 1: Calculate mean and standard deviation for amount and transaction count per account
WITH AccountTransferStats AS (
    SELECT 
        AccountID,
        COUNT(*) AS TransactionCount,
        AVG(Amount) AS AvgAmount
    FROM Transactions
    WHERE TransactionType = 'Transfer'
    GROUP BY AccountID
),
StatsSummary AS (
    SELECT 
        AVG(TransactionCount * 1.0) AS MeanTransactionCount,
        STDEV(TransactionCount * 1.0) AS StdDevTransactionCount,
        AVG(AvgAmount) AS MeanAvgAmount,
        STDEV(AvgAmount) AS StdDevAvgAmount
    FROM AccountTransferStats
)

-- Step 2: Select accounts that exceed thresholds
SELECT ats.*
FROM AccountTransferStats ats
CROSS JOIN StatsSummary ss
WHERE 
    ats.TransactionCount > ss.MeanTransactionCount + 3 * ss.StdDevTransactionCount
    OR ats.AvgAmount > ss.MeanAvgAmount + 3 * ss.StdDevAvgAmount
ORDER BY ats.AvgAmount DESC, ats.TransactionCount DESC;


----------------------------------------------------------------------------------------------------------------
--Upcoming maturity trends (loans ending this year) 
select distinct loantype,
       
	
	   datepart(month,loanenddate) as month_no,
	   datename(month,loanenddate) as MaturityMonth,
	   sum(loanamount) as total_amount_of_loans,
	    count(loanid)   as total_no_of_loans
	 
from loans
where loanenddate between '2025-01-01' and '2025-12-31'
group by  loantype , datename(month,loanenddate),datepart(month,loanenddate) 
order by 4 desc,5 desc,2 asc;

-----------------------------------------------------------------------------------------------------
--Resolution rate by issue type

SELECT 
    IssueType,
    COUNT(*) AS TotalCalls,
    SUM(CASE WHEN Resolved = 1 THEN 1 ELSE 0 END) AS ResolvedCalls,
    ROUND(
        100.0 * SUM(CASE WHEN Resolved = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 
        2
    ) AS ResolutionRatePercent
FROM 
    supportcalls
GROUP BY 
    IssueType
ORDER BY 
    ResolutionRatePercent DESC;





	  



