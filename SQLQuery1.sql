-- Table overview
SELECT *
FROM dbo.sales_data_sample

-- By product line
SELECT PRODUCTLINE, SUM(sales) revenue
FROM dbo.sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

-- By year
SELECT YEAR_ID, SUM(sales) revenue
FROM dbo.sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC

-- By dealsize
SELECT DEALSIZE, SUM(sales) revenue
FROM dbo.sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC

-- Best month in each year
SELECT MONTH_ID, SUM(sales) revenue, COUNT(ORDERNUMBER) frequency
FROM dbo.sales_data_sample
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY 2 desc


-- Simple analysis of the best month (Nov) 
SELECT MONTH_ID, PRODUCTLINE, SUM(sales) revenue, COUNT(ORDERNUMBER) frequency
FROM dbo.sales_data_sample
WHERE YEAR_ID = 2003 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC

-- Best customer (with RFM)
WITH rfm AS (
	SELECT 
		CUSTOMERNAME,
		MAX(ORDERDATE) AS last_order_date,
		(SELECT MAX(ORDERDATE) FROM dbo.sales_data_sample) AS max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM dbo.sales_data_sample)) AS Recency,
		COUNT(ORDERNUMBER) AS Frequency,
		SUM(SALES) AS Monetary,
		AVG(SALES) AS AvgMonetary
	FROM dbo.sales_data_sample
	GROUP BY CUSTOMERNAME 
	)
, rfm_rank AS (
	SELECT r.*,
		NTILE(3) OVER (ORDER BY Recency DESC) AS rfm_recency,
		NTILE(3) OVER (ORDER BY Frequency) AS rfm_frequency,
		NTILE(3) OVER (ORDER BY AvgMonetary) AS rfm_monetary
	FROM rfm AS r
	)
, rfm_rank_concat AS (
	SELECT *, 
		CONCAT(rfm_rank.rfm_recency,rfm_rank.rfm_frequency,rfm_rank.rfm_monetary) AS rfm_rank
	FROM rfm_rank
	)
, rfm_segment_result AS(
	SELECT * ,
		CASE 
			WHEN rfm_rank IN ('333','323') THEN 'Best customers'
			WHEN rfm_rank IN ('223','123','213','133') THEN 'High purchasing'
			WHEN rfm_rank IN ('332','313','312','321') THEN 'Promising customers'
			WHEN rfm_rank IN ('331','231','232','233','322','132') THEN 'Loyal customer'
			WHEN rfm_rank IN ('222','311','131') THEN 'Normal'
			WHEN rfm_rank IN ('221','121','122') THEN 'Almost lost'
			WHEN rfm_rank IN ('111','112','113','212','211') THEN 'Lost Customers'
			END AS rfm_segment
	FROM rfm_rank_concat
	)

SELECT 
	rfm_segment_result.rfm_segment,
	COUNT(rfm_segment_result.rfm_segment) AS number_of_customers
FROM rfm_segment_result
GROUP BY rfm_segment_result.rfm_segment
ORDER by 2



