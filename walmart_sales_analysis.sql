-- Rank each year by total sales using a window function
-- (highest total sales = rank 1)
SELECT
    year,
    yearly_sales,
    RANK() OVER (ORDER BY yearly_sales DESC) AS rank_year_sales

FROM (
    SELECT
        EXTRACT(YEAR FROM date) AS year,
        SUM(weekly_sales) AS yearly_sales
    FROM walmart_sales_data_45stores
    GROUP BY EXTRACT(YEAR FROM date)
) AS yearly_totals
ORDER BY yearly_sales DESC;


-- top 5 and bottom 5 stores by total sales overall
(SELECT store, SUM(weekly_sales) AS total_sales, 'Top 5' AS category
 FROM walmart_sales_data_45stores
 GROUP BY store
 ORDER BY total_sales DESC
 LIMIT 5)
UNION ALL
(SELECT store, SUM(weekly_sales) AS total_sales, 'Bottom 5' AS category
 FROM walmart_sales_data_45stores
 GROUP BY store
 ORDER BY total_sales ASC
 LIMIT 5);



-- Aggregate weekly sales by date,
-- showing total sales and record count per date across all 45 stores
SELECT date,
       SUM(weekly_sales) AS sum_weekly_45stores,
       COUNT(weekly_sales) AS total_45stores
FROM walmart_sales_data_45stores
GROUP BY date
ORDER BY date;


-- Highest sales week per month 
SELECT DISTINCT ON (year_month)
       year_month,
       date,
       sum_weekly_45stores
FROM (
    SELECT date,
           SUM(weekly_sales) AS sum_weekly_45stores,
           TO_CHAR(date, 'YYYY-MM') AS year_month
    FROM walmart_sales_data_45stores
    GROUP BY date
) sub
ORDER BY year_month, sum_weekly_45stores DESC;


-- Combine each year's highest and lowest single sales week into one table
-- Highest single sales week in each year (2010, 2011, 2012)
SELECT year, date, sum_weekly_45stores, 'Highest Week in the Year' AS week_type
FROM (
    SELECT DISTINCT ON (year)
       year,
       date,
       sum_weekly_45stores
   FROM (
       SELECT date,
           SUM(weekly_sales) AS sum_weekly_45stores,
           EXTRACT(YEAR FROM date) AS year
    FROM walmart_sales_data_45stores
    GROUP BY date
   ) sub
   ORDER BY year, sum_weekly_45stores DESC
) highest_week_each_year

UNION ALL  --combine both lowest and highest result in one table 

-- lowest single sales week in each year (2010, 2011, 2012)
SELECT year, date, sum_weekly_45stores, 'Lowest Week in the Year' AS week_type
FROM (
    SELECT DISTINCT ON (year)
       year,
       date,
       sum_weekly_45stores
   FROM (
       SELECT date,
           SUM(weekly_sales) AS sum_weekly_45stores,
           EXTRACT(YEAR FROM date) AS year
    FROM walmart_sales_data_45stores
    GROUP BY date
   ) sub
   ORDER BY year, sum_weekly_45stores
) highest_week_each_year
ORDER BY year, sum_weekly_45stores DESC;


-- For each year/month, find the highest and lowest 
-- weekly total sales (across all 45 stores) recorded in that month
SELECT
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(MONTH FROM date) AS month,
    MAX(sum_weekly_45stores) AS highest_week,
    MIN(sum_weekly_45stores) AS lowest_week
FROM (
    SELECT date,
           SUM(weekly_sales) AS sum_weekly_45stores
    FROM walmart_sales_data_45stores
    GROUP BY date
) sub
GROUP BY EXTRACT(YEAR FROM date), EXTRACT(MONTH FROM date)
ORDER BY year, month;


--Average weekly sales: holiday vs. non-holiday weeks
SELECT 
    CASE WHEN holiday_flag = 1 THEN 'Holiday Week' ELSE 'Non-Holiday Week' END AS week_type,
    ROUND(AVG(weekly_sales), 2) AS avg_weekly_sales
	
FROM walmart_sales_data_45stores
GROUP BY holiday_flag;


-- Compare average sales: holiday vs non-holiday weeks, with % difference
SELECT 
    ROUND(AVG(CASE WHEN holiday_flag = 0 THEN weekly_sales END), 2) AS avg_non_holiday,
    ROUND(AVG(CASE WHEN holiday_flag = 1 THEN weekly_sales END), 2) AS avg_holiday,
    ROUND(
        (AVG(CASE WHEN holiday_flag = 1 THEN weekly_sales END) 
         - AVG(CASE WHEN holiday_flag = 0 THEN weekly_sales END)) 
        / AVG(CASE WHEN holiday_flag = 0 THEN weekly_sales END) * 100
    , 2) AS pct_difference
FROM walmart_sales_data_45stores;


--Largest drop from a non-holiday week to the following holiday week
WITH weekly AS (
    SELECT store, date, weekly_sales, holiday_flag,
           LAG(weekly_sales) OVER (PARTITION BY store ORDER BY date) AS prev_sales,
           LAG(holiday_flag) OVER (PARTITION BY store ORDER BY date) AS prev_holiday_flag
    FROM walmart_sales_data_45stores
)
SELECT store, date AS holiday_week, prev_sales AS prior_week_sales, 
       weekly_sales AS holiday_week_sales,
       (prev_sales - weekly_sales) AS sales_drop
FROM weekly
WHERE holiday_flag = 1 AND prev_holiday_flag = 0
ORDER BY sales_drop DESC
LIMIT 10;


--4-week rolling average per store
SELECT store, date, weekly_sales,
       ROUND(AVG(weekly_sales) OVER (
           PARTITION BY store ORDER BY date 
           ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
       ), 2) AS rolling_4wk_avg
FROM walmart_sales_data_45stores
ORDER BY store, date;