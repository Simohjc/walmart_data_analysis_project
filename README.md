                                                               Walmart Sales Data Analysis 
                                                   SQL / PostgreSQL Exploratory Analysis Project Dataset            


<img width="1775" height="889" alt="walmart_project_infographic" src="https://github.com/user-attachments/assets/de934b1a-ecf2-4fa5-acbc-edf0ff2c608d" />       
# 🛒 Walmart Sales Data Analysis — SQL / PostgreSQL Project

An end-to-end SQL analysis of three years (2010–2012) of weekly sales data across 45 Walmart stores, built entirely in **PostgreSQL**. The project moves from raw CSV import and data cleaning through exploratory analysis, window functions, and business-question-driven insights.

---

## 📌 Project Overview

Retailers like Walmart generate huge volumes of weekly sales data across hundreds of stores. This project explores that data using SQL to answer real business questions — which stores perform best, how holidays affect sales, which weeks are strongest and weakest, and how sales trends move over time — using nothing but PostgreSQL queries.

**Goals:**
- Practice real-world SQL: aggregation, window functions, CTEs, `DISTINCT ON`, `UNION ALL`, conditional aggregation
- Clean and import a messy real-world CSV into a relational database
- Turn raw query output into clear, written business insights

---

## 🗂️ Dataset

| Column | Description |
|---|---|
| `store` | Store number (1–45) |
| `date` | Week-ending date |
| `weekly_sales` | Total sales for that store, that week |
| `holiday_flag` | 1 if the week includes a major holiday, else 0 |
| `temperature` | Average regional temperature that week |
| `fuel_price` | Regional fuel price that week |
| `cpi` | Consumer Price Index for the region |
| `unemployment` | Regional unemployment rate |

**Source:** Kaggle — Walmart weekly sales dataset (45 stores, 2010–2012)

---

## 🛠️ Tools Used

- **PostgreSQL** — database and query engine
- **pgAdmin** — SQL editor / client

---

## ⚙️ Setup

```sql
CREATE TABLE walmart_sales_data_45stores (
    store         INT,
    date          DATE,
    weekly_sales  NUMERIC,
    holiday_flag  INT,
    temperature   NUMERIC,
    fuel_price    NUMERIC,
    cpi           NUMERIC,
    unemployment  NUMERIC
);
```

```sql
-- Fix date parsing for DD-MM-YYYY formatted source files
SET DateStyle = 'DMY';

COPY walmart_sales_data_45stores
FROM '/path/to/walmart_sales_data_45stores.csv'
WITH (FORMAT csv, HEADER true);
```

---

## ❓ Business Questions Answered

This project was built around the following core business questions:

1. Which 5 stores have the highest total sales overall, and which 5 have the lowest?
2. What is the average weekly sales figure for holiday weeks vs. non-holiday weeks, across all stores?
3. Which store shows the largest drop in sales from a non-holiday week to the following holiday week?
4. Rank stores by total sales within each year using a window function.
5. Calculate a 4-week rolling average of sales per store to smooth out weekly noise.

Plus supporting exploratory queries on yearly, monthly, and weekly sales trends.

---

## 🔍 Key Queries & Insights

### 1. Year-over-Year Sales Ranking
```sql
SELECT year, yearly_sales,
       RANK() OVER (ORDER BY yearly_sales DESC) AS rank_year_sales
FROM (
    SELECT EXTRACT(YEAR FROM date) AS year,
           SUM(weekly_sales) AS yearly_sales
    FROM walmart_sales_data_45stores
    GROUP BY EXTRACT(YEAR FROM date)
) AS yearly_totals
ORDER BY yearly_sales DESC;
```
**Insight:** Sales performance is not evenly split across the three years. 2011 was the strongest year (~$2.45B), followed by 2010 (~$2.29B), with 2012 lowest (~$2.00B) — a clear top, middle, and bottom year rather than flat year-over-year performance.

---

### 2. Top 5 and Bottom 5 Stores by Total Sales
```sql
(SELECT store, SUM(weekly_sales) AS total_sales, 'Top 5' AS category
 FROM walmart_sales_data_45stores
 GROUP BY store ORDER BY total_sales DESC LIMIT 5)
UNION ALL
(SELECT store, SUM(weekly_sales) AS total_sales, 'Bottom 5' AS category
 FROM walmart_sales_data_45stores
 GROUP BY store ORDER BY total_sales ASC LIMIT 5);
```
**Insight:** Sales performance varies dramatically across the 45 stores. The top-performing store (Store 20, ~$301.4M) sold roughly **8x more** than the lowest-performing store (Store 33, ~$37.2M). The top 5 stores cluster tightly between $275M–$301M, suggesting a consistent group of high-volume "flagship" locations, while the bottom 5 range more widely ($37M–$55M) but remain in a clearly distinct tier — pointing to structural differences (store size, location, regional demand) rather than random variance.

---

### 3. Highest Sales Week Per Month
```sql
SELECT DISTINCT ON (year_month)
       year_month, date, sum_weekly_45stores
FROM (
    SELECT date,
           SUM(weekly_sales) AS sum_weekly_45stores,
           TO_CHAR(date, 'YYYY-MM') AS year_month
    FROM walmart_sales_data_45stores
    GROUP BY date
) sub
ORDER BY year_month, sum_weekly_45stores DESC;
```
**Insight:** December stands out sharply from every other month, consistent with Black Friday and pre-Christmas holiday shopping. Most other months show comparatively modest peak weeks.

---

### 4. Average Sales: Holiday vs. Non-Holiday Weeks
```sql
SELECT
    ROUND(AVG(CASE WHEN holiday_flag = 0 THEN weekly_sales END), 2) AS avg_non_holiday,
    ROUND(AVG(CASE WHEN holiday_flag = 1 THEN weekly_sales END), 2) AS avg_holiday,
    ROUND(
        (AVG(CASE WHEN holiday_flag = 1 THEN weekly_sales END)
       - AVG(CASE WHEN holiday_flag = 0 THEN weekly_sales END))
      / AVG(CASE WHEN holiday_flag = 0 THEN weekly_sales END) * 100
    , 2) AS pct_difference
FROM walmart_sales_data_45stores;
```
**Insight:** Holiday weeks average **$1,122,887.89** in sales vs. **$1,041,256.38** for non-holiday weeks — a **7.84%** lift. Holidays reliably drive a meaningful, measurable sales increase across stores.

---

### 5. Largest Drop: Non-Holiday Week → Following Holiday Week
```sql
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
```
**Insight:** All top 10 drops occur around **December 31** (New Year's week). The prior week's sales (~$2.7M–$3.8M, the Christmas rush) collapse to a much lower holiday-week figure (~$1.2M–$2M) — drops of $1.6M–$2.2M per store. This isn't holidays hurting sales in general; it's a predictable post-Christmas comedown that the massive pre-Christmas spike can't sustain into the New Year's week.

---

### 6. 4-Week Rolling Average Per Store
```sql
SELECT store, date, weekly_sales,
       ROUND(AVG(weekly_sales) OVER (
           PARTITION BY store ORDER BY date
           ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
       ), 2) AS rolling_4wk_avg
FROM walmart_sales_data_45stores
ORDER BY store, date;
```
**Insight:** The rolling average smooths out week-to-week noise, making the underlying sales trend easier to read than the raw weekly figures alone — useful for spotting genuine momentum rather than reacting to a single unusually high or low week.

---

## 🧠 SQL Techniques Used

- Aggregate functions (`SUM`, `AVG`, `MAX`, `MIN`, `COUNT`)
- `GROUP BY` and `EXTRACT(YEAR/MONTH FROM date)`
- Window functions: `RANK()`, `LAG()`, rolling `AVG() OVER (... ROWS BETWEEN ...)`
- `DISTINCT ON` for "top row per group" queries
- `CASE` expressions and conditional aggregation
- `UNION ALL` to combine result sets
- CTEs (`WITH`) for multi-step logic
- Subqueries and derived tables

---

## 📈 Summary of Findings

- Annual sales are not flat across 2010–2012 — 2011 was the strongest year, 2012 the weakest.
- Sales are heavily concentrated in a small group of high-performing "flagship" stores; the gap between top and bottom stores is roughly 8x.
- Holiday weeks drive a consistent, measurable sales lift (~7.8% on average).
- December is the strongest month every year, driven by Black Friday and pre-Christmas shopping.
- The week immediately following Christmas (New Year's week) sees the sharpest sales decline of the year — a predictable seasonal pattern, not a store-specific problem.
- Rolling averages reveal smoother underlying trends beneath noisy week-to-week sales figures.

---

## 🚀 Possible Next Steps

- Store segmentation (High / Mid / Low performance tiers)
- Correlation analysis: sales vs. temperature, fuel price, CPI, unemployment
- Year-over-year % change per store
- Interactive dashboard (Tableau / Power BI / Python) on top of the SQL output

---

## 📁 Files

- `walmart_sales_analysis.sql` — full set of queries used in this project
- `Walmart_Sales_Analysis_Project.docx` / `.pdf` — full write-up with results and insights

---

## 👤 Author

Feel free to fork, adapt, or reach out with questions or suggestions.

















 






