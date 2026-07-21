                                                               Walmart Sales Data Analysis 
                                                   SQL / PostgreSQL Exploratory Analysis Project Dataset            


<img width="1775" height="889" alt="walmart_project_infographic" src="https://github.com/user-attachments/assets/de934b1a-ecf2-4fa5-acbc-edf0ff2c608d" />       
 

Project Overview
This project explores three years (2010–2012) of weekly sales data across 45 Walmart stores using PostgreSQL. The goal is to understand sales trends over time — at the yearly, monthly, and weekly level — and identify patterns such as seasonality, peak sales periods, and year-over-year performance.
Dataset columns:
   Query 1: Rank each year by total sales -- (highest total sales = rank 1)
-- Rank each year by total sales using a window function -- (highest total sales = rank 1)

 SELECT year, yearly_sales,
        RANK() OVER (ORDER BY yearly_sales DESC) AS rank_year_sales 
FROM ( SELECT  EXTRACT(YEAR FROM date) AS year, 
               SUM(weekly_sales) AS yearly_sales 
       FROM walmart_sales_data_45stores 
       GROUP BY EXTRACT(YEAR FROM date)
) AS yearly_totals 
ORDER BY yearly_sales DESC;

Insight
Sales performance is not evenly split across the three years. Ranking total annual sales shows a clear top year, a middle year, and a bottom year, which suggests a broader trend 
-- top 5 and bottom 5 stores by total sales overall
(SELECT store, SUM(weekly_sales) AS total_sales, 'Top 5' AS category
 FROM walmart_sales_data_45stores
 GROUP BY store
 ORDER BY total_sales DESC  LIMIT 5)
UNION ALL
(SELECT store, SUM(weekly_sales) AS total_sales, 'Bottom 5' AS category
 FROM walmart_sales_data_45stores
 GROUP BY store
 ORDER BY total_sales ASC   LIMIT 5);

Insight
Sales performance varies dramatically across the 45 stores. The top-performing store (Store 20) generated approximately $301.4M in total sales, roughly eight times more than the lowest-performing store (Store 33) at $37.2M. The top 5 stores are tightly clustered between $275M and $301M, suggesting a consistent group of high-volume "flagship" locations rather than a single outlier. In contrast, the bottom 5 stores range more widely from $37M to $55M, but remain in a clearly distinct tier from the top performers. This wide gap points to structural differences between stores — such as size, location, or regional demand — rather than simple week-to-week variance, and suggests store segmentation could be a valuable next step for deeper analysis.
 




Query 2: Daily Sales Aggregation (All Stores Combined)
-- Aggregate weekly sales by date,
-- showing total sales and record count per date across all 45 stores
SELECT date,
       SUM(weekly_sales) AS sum_weekly_45stores,
       COUNT(weekly_sales) AS total_45stores
FROM walmart_sales_data_45stores
GROUP BY date
ORDER BY date;

 

Insight
This is the foundation for all later analysis — it collapses the 45 individual store rows for each week into a single combined sales figure per date. The record count column (total_45stores) is a useful sanity check: if it's consistently 45 for every date, it confirms the dataset is complete with no missing store-week records.




Query 3: Highest Sales Week Per Month
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

 

Insight
Looking at the peak week within each month highlights seasonality at a finer grain than annual totals alone. December months stand out sharply from the rest of the year, consistent with holiday shopping (Black Friday and pre-Christmas weeks), while most other months show comparatively modest peak weeks.
Query 4: Highest & Lowest Single Sales Week Per Year (Combined)
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

 

Insight
For all three years, the highest week (2010-12-24, 2011-12-23, 2012-04-06) is far above the lowest week of the same year, and the gap between a year's best and worst week is large relative to typical weekly sales. Interestingly, 2012's peak week fell in April rather than December, which stands out from 2010 and 2011 and may be worth investigating further (e.g. a major promotion or missing December data for that year).
Query 5: Highest & Lowest Weekly Sales Per Month (Value Only)
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

 

Insight
This view complements Query 3 by showing the spread (highest vs. lowest week) within every month, not just the single best week. Months with a wide gap between their highest and lowest week indicate more volatile sales within that month, while months with a narrow gap suggest more consistent week-to-week performance.
 Query 6: Average weekly sales: holiday vs. non-holiday weeks Compare average sales: holiday vs non-holiday weeks, with % difference

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


 




Insight
Holiday weeks average about $1,122,887.89 in sales, compared to $1,041,256.38 for non-holiday weeks — roughly 7.8% higher. This confirms holiday weeks reliably drive a meaningful sales lift across stores, reinforcing the seasonal pattern already seen in the December peak weeks.







Query 7: Largest drop from a non-holiday week to the following holiday week
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


 



Insight
All top 10 drops occurred around Dec 31 (New Year's week) or late-Dec 30, and every case shows the same pattern: the prior week's sales (~$2.7M–$3.8M, the Christmas rush) collapse to a much lower holiday-week figure (~$1.2M–$2M) — drops of roughly $1.6M–$2.2M per store. This isn't holidays hurting sales in general; it's a post-Christmas comedown, where the massive pre-Christmas spike simply can't be sustained into the New Year's week itself. Store 14 saw the single largest drop (~$2.19M), but the pattern is broadly consistent across the top 10, suggesting this is a predictable seasonal effect rather than a store-specific issue.
















Query 8: 4-week rolling average per store
--4-week rolling average per store
SELECT store, date, weekly_sales,
       ROUND(AVG(weekly_sales) OVER (
           PARTITION BY store ORDER BY date 
           ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
       ), 2) AS rolling_4wk_avg
FROM walmart_sales_data_45stores
ORDER BY store, date;

 



Insight
The rolling average is doing exactly what it's meant to — smoothing out the week-to-week noise in Store 1's sales. For example, weekly sales bounce around quite a bit (e.g., $1,643,690.90 → $1,409,727.59 → $1,594,968.28), but the 4-week rolling average moves much more gradually ($1,643,690.90 → $1,576,836.03 → $1,477,863.90), making the underlying trend easier to see. This is useful for spotting genuine momentum (sustained rises or declines) rather than reacting to a single unusually high or low week — and it's a good foundation for later comparing whether a store's rolling trend is climbing, flat, or declining heading into a holiday period.




