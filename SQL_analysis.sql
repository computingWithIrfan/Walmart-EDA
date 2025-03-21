SELECT top 5 * FROM [walmart_sales];
-- Transactions through each payment methods
SELECT w.payment_method,COUNT(w.invoice_id)
  FROM walmart_sales w
  GROUP BY w.payment_method;

-- No of total branches
SELECT COUNT(DISTINCT branch) FROM walmart_sales;

--Total Sales
SELECT 
    SUM(total) as total_sales,
    SUM(profit) as total_profit,
	'$'+STR(SUM(total-profit))  as cost_price,
	'Rs'+STR(SUM((profit)*284))  as profit_PKR
	FROM walmart_sales;

-- Business Problem's Answers 
--1. Find number of transactions, and quantity sold by each payment method
SELECT 
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart_sales
GROUP BY payment_method;

--2. Identify the highest-rated category in each branch. Display the branch, category, and avg rating
SELECT branch, category, avg_rating
FROM (
    SELECT 
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank
    FROM walmart_sales
    GROUP BY branch, category
) AS ranked
WHERE rank = 1;

--3. Identify the busiest day for each branch based on the number of transactions
WITH RankedDays AS (
    SELECT 
        branch,
        DATENAME(WEEKDAY, CAST(date AS DATE)) AS day_name, -- Convert date & extract weekday
        COUNT(*) AS no_transactions,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart_sales
    GROUP BY branch, DATENAME(WEEKDAY, CAST(date AS DATE))
)
SELECT branch, day_name, no_transactions
FROM RankedDays
WHERE rnk = 1;

-- Sales each day
SELECT  DATENAME(WEEKDAY, CAST(date AS DATE)) AS day_name, -- Convert date & extract weekday
        COUNT(*) AS no_transactions
    FROM walmart_sales
    GROUP BY DATENAME(WEEKDAY, CAST(date AS DATE));

--4. Calculate the total quantity of items sold per payment method
SELECT 
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM walmart_sales
GROUP BY payment_method;

--5: Determine the average, minimum, and maximum rating of categories for each city
SELECT 
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    ROUND(AVG(rating),2) AS avg_rating
FROM walmart_sales
GROUP BY city, category;

--6: Calculate the total profit for each category
SELECT 
    category,
    SUM(profit) AS total_profit
FROM walmart_sales
GROUP BY category
ORDER BY total_profit DESC;

--7: Determine the most common payment method for each branch
WITH cte AS (
    SELECT 
        branch,
        payment_method,
        COUNT(*) AS total_trans,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart_sales
    GROUP BY branch, payment_method
)
SELECT branch, payment_method AS preferred_payment_method
FROM cte
WHERE rank = 1;

--8: Categorize sales into Morning, Afternoon, and Evening shifts
SELECT
    branch,
    CASE 
        WHEN DATEPART(HOUR, time) < 12 THEN 'Morning'
        WHEN DATEPART(HOUR, time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS num_transactions
FROM walmart_sales
GROUP BY branch, 
    CASE 
        WHEN DATEPART(HOUR, time) < 12 THEN 'Morning'
        WHEN DATEPART(HOUR, time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END
ORDER BY branch, num_transactions DESC;

--9: Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023)
WITH yearly_sales AS (
    SELECT 
        branch, 
        DATENAME(YEAR, date) AS _year_, 
        SUM(total) AS sales
    FROM walmart_sales 
    WHERE DATENAME(YEAR, date) IN ('2022', '2023')  -- Filter only required years
    GROUP BY branch, DATENAME(YEAR, date)
)
SELECT TOP 5 
    s2022.branch, 
    s2022.sales AS sales_2022, 
    s2023.sales AS sales_2023, 
    ((s2022.sales - s2023.sales) * 100.0 / NULLIF(s2022.sales, 0)) AS decrease_ratio
FROM yearly_sales s2022
LEFT JOIN yearly_sales s2023 
    ON s2022.branch = s2023.branch AND s2022._year_ = '2022' AND s2023._year_ = '2023'
WHERE s2022.sales > s2023.sales  -- Consider only branches with revenue decrease
ORDER BY decrease_ratio DESC;