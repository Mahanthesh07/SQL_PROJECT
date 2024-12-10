use manufacrure
select * from DIM_CUSTOMER
select * from DIM_LOCATION
select * from DIM_MANUFACTURER
select * from DIM_MODEL
select * from FACT_TRANSACTIONS
----Q1---1.List all the states in which we have customers who have bought cellphones from 2005 till today.
---ANS1---
select distinct  state from DIM_LOCATION as dl inner join FACT_TRANSACTIONS AS ft ON dl.IDLocation= ft.IDLocation
where year(date)>2005
                 ---OR---
select distinct State from DIM_LOCATION as d inner join FACT_TRANSACTIONS as f on d.IDLocation=f.IDLocation
inner join DIM_CUSTOMER as c on f.IDCustomer=c.IDCustomer
inner join  DIM_MODEL as dm on f.IDModel=dm.IDModel
inner join DIM_MANUFACTURER as m on dm.IDManufacturer=m.IDManufacturer
where date between '01-01-2005' and getdate()

----Q2.What state in the US is buying more 'Samsung' cell phones?
select top 1 state,country,manufacturer_name,sum(Quantity ) as no_of_quantity from  DIM_LOCATION as dm inner join  FACT_TRANSACTIONS as ft on dm.IDLocation=ft.IDLocation
inner join  DIM_MODEL as  d on ft.IDModel=d.IDModel
inner join DIM_MANUFACTURER as mf on d.IDManufacturer=mf.IDManufacturer
where Country='us' and  Manufacturer_Name='samsung'
group by state,country,manufacturer_name
order by no_of_quantity desc

----Q3.Show the number of transactions for each model per zip code per state.
---ANS3--
select top 3 state ,model_name,zipcode,count(C.IDCustomer) as no_of_transaction  from DIM_LOCATION as dm 
inner join FACT_TRANSACTIONS as ft on dm.IDLocation=ft.IDLocation
inner join DIM_CUSTOMER as  c on ft.IDCustomer=c.IDCustomer
inner join DIM_MODEL as d on ft.IDModel=d.IDModel
group by  state ,model_name,zipcode
order by  no_of_transaction desc

----Q4.Show the cheapest cellphone
--ans4--
select top 1 manufacturer_name,model_name ,sum(unit_price) as price from DIM_MANUFACTURER as dm 
inner join DIM_MODEL as m on dm.IDManufacturer=m.IDManufacturer
group by manufacturer_name,model_name
order by price asc
----Q5.Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.
--ans5--
select top 5 Model_name,manufacturer_name ,avg(unit_price) as avg_price,sum(Quantity) as number_of_qty from  DIM_MODEL as d
inner join FACT_TRANSACTIONS as ft on d.IDModel=ft.IDModel
inner join DIM_MANUFACTURER as dm on d.IDManufacturer=dm.IDManufacturer
group by Model_name,manufacturer_name
order by avg_price desc
                                     -----OR-----
with top_manufacturers as (
      select top 5 fm.Manufacturer_Name,fm.IDManufacturer,sum(Quantity) as total_quantity from FACT_TRANSACTIONS as ft 
	  inner join DIM_MODEL as dm on ft.IDModel=dm.IDModel
	  inner join DIM_MANUFACTURER as fm on dm.IDManufacturer=fm.IDManufacturer
	  group by fm.Manufacturer_Name,fm.IDManufacturer
	  order by total_quantity desc)
select dm.Model_Name,tm.Manufacturer_Name ,sum(Quantity) as total_quantity,avg(unit_price) as avg_price from FACT_TRANSACTIONS as ft 
	  inner join DIM_MODEL as dm on ft.IDModel=dm.IDModel
	  inner join DIM_MANUFACTURER as fm on dm.IDManufacturer=fm.IDManufacturer
	  inner join  top_manufacturers as tm ON dm.IDManufacturer = tm.IDManufacturer
	  group by dm.Model_name,tm.manufacturer_name
	  having tm.manufacturer_name='apple'---this step for checking 
      order by avg_price DESC;
---------------------- OR-----------------------------------------------------
with rank_manuf as (select top 5 fm.Manufacturer_Name,fm.IDManufacturer,
sum(quantity) as total_quantity,
rank() over (order by sum(quantity) desc ) as rnk from FACT_TRANSACTIONS as ft 
inner join DIM_MODEL as dm on ft.IDModel=dm.IDModel
inner join DIM_MANUFACTURER as fm on dm.IDManufacturer=fm.IDManufacturer
where fm.Manufacturer_Name='apple'
group by fm.Manufacturer_Name,fm.IDManufacturer)
select dm.model_name,rm.Manufacturer_Name,sum(quantity) as total_quantity,avg(unit_price) as avg_price from FACT_TRANSACTIONS as ft
inner join DIM_MODEL as dm on ft.IDModel=dm.IDModel
inner join DIM_MANUFACTURER as fm on dm.IDManufacturer=fm.IDManufacturer
inner join rank_manuf as rm on dm.IDManufacturer=fm.IDManufacturer
where rnk<=5
group by dm.model_name,rm.Manufacturer_Name
order by avg_price desc
----------------------------------------------------------------------------------------------------------------------------

----Q6.List the names of the customers and the average amount spent in 2009, where the average is higher than 500
--ans6--
select customer_name,avg(totalprice) as avg_price from DIM_CUSTOMER as c
inner join FACT_TRANSACTIONS as ft on c.IDCustomer=ft.IDCustomer
where year(date)=2009
group by Customer_Name
having avg(totalprice)>500
order by avg_price desc
--ans7--.List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010
---ANS7--
with my8 as (
select top 5 m.[Model_Name] from[dbo].[FACT_TRANSACTIONS] as t
inner join [dbo].[DIM_MODEL] as m on t.IDModel=m.IDModel
where year(t.[date])=2008
group by m.[Model_Name]
order by sum(t.[Quantity]) desc
),
my9 as(
select top 5 m.[Model_Name] from[dbo].[FACT_TRANSACTIONS] as t
inner join [dbo].[DIM_MODEL] as m on t.IDModel=m.IDModel
where year(t.[date])=2009
group by m.[Model_Name]
order by sum(t.[Quantity]) desc
),
my10 as(
select top 5 m.[Model_Name] from[dbo].[FACT_TRANSACTIONS] as t
inner join [dbo].[DIM_MODEL] as m on t.IDModel=m.IDModel
where year(t.[date])=2010
group by m.[Model_Name]
order by sum(t.[Quantity]) desc
)
select my8.model_name from my8
inner join my9 on my8.Model_Name=my9.Model_Name
inner join my10 on my9.Model_Name=my10.Model_Name

----Q8.Show the manufacturer with the 2nd top sales in the year of 2009 and the 
---manufacturer with the 2nd top sales in the year of 2010.
--ans8--
with rank_manufacture as(select Manufacturer_Name,year(date) as year,sum(totalprice)as total_sales
,row_number() over (partition by year(date) order by sum(totalprice) desc ) as rnk from DIM_MANUFACTURER as dm
inner join DIM_MODEL as d on dm.IDManufacturer=d.IDManufacturer
inner join FACT_TRANSACTIONS as ft on d.IDModel=ft.IDModel
where year(date) in (2009,2010)
group by Manufacturer_Name,year(date))
select Manufacturer_Name,year,total_sales from rank_manufacture
 where rnk<=2
----Q9.Show the manufacturers that sold cellphone in 2010 but didn’t in 2009.
---ANS9--
SELECT MANUFACTURER_NAME FROM DIM_MANUFACTURER 
INNER JOIN DIM_MODEL ON [dbo].[DIM_MANUFACTURER].IDManufacturer= [dbo].[DIM_MODEL].IDManufacturer
INNER JOIN [dbo].[FACT_TRANSACTIONS]  ON [dbo].[DIM_MODEL].IDModel=[dbo].[FACT_TRANSACTIONS].IDModel
WHERE YEAR(date) = 2010 
EXCEPT 
SELECT MANUFACTURER_NAME FROM DIM_MANUFACTURER 
INNER JOIN DIM_MODEL ON [dbo].[DIM_MANUFACTURER].IDManufacturer= [dbo].[DIM_MODEL].IDManufacturer
INNER JOIN [dbo].[FACT_TRANSACTIONS]  ON [dbo].[DIM_MODEL].IDModel=[dbo].[FACT_TRANSACTIONS].IDModel
WHERE YEAR(date) = 2009
----OR--
WITH Sales2010 AS (
    SELECT DISTINCT dm.IDManufacturer, dm.manufacturer_name
    FROM DIM_MANUFACTURER AS dm
    INNER JOIN DIM_MODEL AS d ON dm.IDManufacturer = d.IDManufacturer
    INNER JOIN FACT_TRANSACTIONS AS ft ON d.IDModel = ft.IDModel
    WHERE YEAR(date) = 2010
),

Sales2009 AS (
    SELECT DISTINCT dm.IDManufacturer
    FROM DIM_MANUFACTURER AS dm
    INNER JOIN DIM_MODEL AS d ON dm.IDManufacturer = d.IDManufacturer
    INNER JOIN FACT_TRANSACTIONS AS ft ON d.IDModel = ft.IDModel
    WHERE YEAR(date) = 2009
)
-- Find manufacturers that sold cellphones in 2010 but not in 2009
SELECT s.manufacturer_name
FROM Sales2010 AS s
LEFT JOIN Sales2009 AS s2 ON s.IDManufacturer = s2.IDManufacturer
WHERE s2.IDManufacturer IS NULL;


 ----Q10.Find top 100 customers and their average spend, average quantity by each year.
----Also find the percentage of change in their spend.
Select top 100 IDcustomer,year(date) as years,avg(totalprice) as avg_spend,avg(Quantity) as avg_qty,
 (avg(totalprice)-lag(avg(totalprice))over(partition by IDCustomer order by year (date)))/ nullif(lag(avg(totalprice))
 over(partition by IDCustomer order by year (date)),0)*100 as per_send 
 from FACT_TRANSACTIONS as ft  
 group by IDcustomer,year(date)
 where IDcustomer in (select IDcustomer from (select top 100 IDcustomer,sum(totalprice) as total_spend 
 from FACT_TRANSACTIONS
 group by IDcustomer
 order by sum(totalprice) desc) a)
 group by IDcustomer,year(date)



 -- Step 1: Select the top 100 customers based on total spend
WITH top_customers AS (
    SELECT TOP 100 
        IDcustomer, 
        SUM(totalprice) AS total_spend
    FROM 
        FACT_TRANSACTIONS
    GROUP BY 
        IDcustomer
    ORDER BY 
        total_spend DESC
),

-- Step 2: Calculate average spend and quantity by each year for top customers
yearly_spend AS (
    SELECT 
        ft.IDcustomer,
        YEAR(ft.date) AS years,
        AVG(ft.totalprice) AS avg_spend,
        AVG(ft.Quantity) AS avg_qty
    FROM 
        FACT_TRANSACTIONS AS ft
    WHERE 
        ft.IDcustomer IN (SELECT tc.IDcustomer FROM top_customers AS tc)
    GROUP BY 
        ft.IDcustomer, 
        YEAR(ft.date)
),

-- Step 3: Calculate the percentage change in spend
spend_change AS (
    SELECT 
        ys.IDcustomer,
        ys.years,
        ys.avg_spend,
        ys.avg_qty,
        LAG(ys.avg_spend) OVER(PARTITION BY ys.IDcustomer ORDER BY ys.years) AS prev_avg_spend,
        (ys.avg_spend - LAG(ys.avg_spend) OVER(PARTITION BY ys.IDcustomer ORDER BY ys.years)) 
            / NULLIF(LAG(ys.avg_spend) OVER(PARTITION BY ys.IDcustomer ORDER BY ys.years), 0) * 100 AS per_spend_change
    FROM 
        yearly_spend AS ys
)

-- Final step: Select the results
SELECT 
    sc.IDcustomer,
    sc.years,
    sc.avg_spend,
    sc.avg_qty,
    sc.per_spend_change
FROM 
    spend_change AS sc
ORDER BY 
    sc.IDcustomer, 
    sc.years;

 
