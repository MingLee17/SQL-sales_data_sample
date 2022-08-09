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
		SUM(SALES) AS Monetary
	FROM dbo.sales_data_sample
	GROUP BY CUSTOMERNAME 
	)
, rfm_rank AS (
	SELECT r.*,
		NTILE(3) OVER (ORDER BY Recency DESC) AS rfm_recency,
		NTILE(3) OVER (ORDER BY Frequency) AS rfm_frequency,
		NTILE(3) OVER (ORDER BY Monetary) AS rfm_monetary
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

select *
from rfm_segment_result

-- Apply the pareto principle to categorize customers into segments (80/20)
WITH rfm AS (
	SELECT 
		CUSTOMERNAME,
		MAX(ORDERDATE) AS last_order_date,
		(SELECT MAX(ORDERDATE) FROM dbo.sales_data_sample) AS max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM dbo.sales_data_sample)) AS Recency,
		COUNT(ORDERNUMBER) AS Frequency,
		SUM(SALES) AS Monetary
	FROM dbo.sales_data_sample
	GROUP BY CUSTOMERNAME 
	)
, percent_rank AS (
	SELECT r.*,
		ROUND(PERCENT_RANK() OVER (ORDER BY Frequency),2) AS frequency_percent_rank,
		ROUND(PERCENT_RANK() OVER (ORDER BY Monetary),2) AS monetar_percent_rank
	FROM rfm AS r
	)
, rfm_ranking AS (
	SELECT *,
	CASE
		WHEN percent_rank.Recency BETWEEN 0 AND 100 THEN 3
		WHEN percent_rank.Recency BETWEEN 100 AND 252 THEN 2
		WHEN percent_rank.Recency BETWEEN 252 AND 508 THEN 1
		ELSE 0
		END
		AS recency_rank
	,CASE
		WHEN percent_rank.frequency_percent_rank BETWEEN 0.8 AND 1 THEN 3
		WHEN percent_rank.frequency_percent_rank BETWEEN 0.5 AND 0.8 THEN 2
		WHEN percent_rank.frequency_percent_rank BETWEEN 0 AND 0.5 THEN 1
		ELSE 0
		END 
		AS frequency_rank
	,CASE 
		WHEN percent_rank.monetar_percent_rank BETWEEN 0.8 AND 1 THEN 3
		WHEN percent_rank.monetar_percent_rank BETWEEN 0.5 AND 0.8 THEN 2
		WHEN percent_rank.monetar_percent_rank BETWEEN 0 AND 0.5 THEN 1
		ELSE 0
		END 
		AS monetary_rank
	FROM percent_rank
	)
, rfm_rank_concat AS (
	SELECT *, 
		CONCAT(rfm_ranking.recency_rank, rfm_ranking.frequency_rank, rfm_ranking.monetary_rank) AS rfm_rank
	FROM rfm_ranking
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

--Overview
	SELECT rfm_segment_result.rfm_segment,COUNT(rfm_segment_result.rfm_segment)
	FROM rfm_segment_result
	GROUP BY rfm_segment_result.rfm_segment
	ORDER BY 2 