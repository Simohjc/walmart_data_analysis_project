                                                               Walmart Sales Data Analysis 
                                                   SQL / PostgreSQL Exploratory Analysis Project Dataset            


<img width="1775" height="889" alt="walmart_project_infographic" src="https://github.com/user-attachments/assets/de934b1a-ecf2-4fa5-acbc-edf0ff2c608d" />       
 Project Overview 
This project explores three years (2010–2012) of weekly sales data across 45 Walmart stores using PostgreSQL. The goal 
is to understand sales trends over time — at the yearly, monthly, and weekly level — and identify patterns such as 
seasonality, peak sales periods, and year-over-year performance. 
Dataset columns: 
<img width="572" height="271" alt="image" src="https://github.com/user-attachments/assets/17d6e471-718e-44f2-9174-e7f9dec48235" />

Query 1: Rank each year by total sales -- (highest total sales = rank 1) -- Rank each year by total sales using a window function -- (highest total sales = rank 1) 
 
 SELECT year, yearly_sales, 
        RANK() OVER (ORDER BY yearly_sales DESC) AS rank_year_sales  
FROM ( SELECT  EXTRACT(YEAR FROM date) AS year,  
               SUM(weekly_sales) AS yearly_sales  
       FROM walmart_sales_data_45stores  
       GROUP BY EXTRACT(YEAR FROM date) 
) AS yearly_totals  
ORDER BY yearly_sales DESC; 
<img width="637" height="222" alt="image" src="https://github.com/user-attachments/assets/1b430530-9e6e-4238-9e70-31f93a59c97d" />

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

 <img width="638" height="267" alt="image" src="https://github.com/user-attachments/assets/2f28fbea-2447-4ed7-b6ce-92cd52c9579b" />

 Query 2: Daily Sales Aggregation (All Stores Combined) -- Aggregate weekly sales by date, -- showing total sales and record count per date across all 45 stores 
SELECT date, 
       SUM(weekly_sales) AS sum_weekly_45stores, 
       COUNT(weekly_sales) AS total_45stores 
FROM walmart_sales_data_45stores 
GROUP BY date 
ORDER BY date; 

<img width="343" height="397" alt="image" src="https://github.com/user-attachments/assets/939dabba-5de9-45d1-9c8e-7c84aeb8710e" />
<img width="627" height="95" alt="image" src="https://github.com/user-attachments/assets/39a7dbcb-c5a1-4483-9669-c1b208949b8d" />

Query 3: Highest Sales Week Per Month -- Highest sales week per month  
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

<img width="328" height="455" alt="image" src="https://github.com/user-attachments/assets/4db05a09-5ec5-4215-ba32-3cc59e854bc0" />
<img width="625" height="91" alt="image" src="https://github.com/user-attachments/assets/898fd874-450c-462f-84a9-4329883fb9f7" />

Query 4: Highest & Lowest Single Sales Week Per Year (Combined) -- Combine each year's highest and lowest single sales week into one table -- Highest single sales week in each year (2010, 2011, 2012) 
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
UNION ALL  --combine both lowest and highest result in one table  -- lowest single sales week in each year (2010, 2011, 2012) 
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

<img width="633" height="316" alt="image" src="https://github.com/user-attachments/assets/9d6d916a-3563-4bc6-be74-ddbfc394606b" />








 






