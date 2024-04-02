
select * from dim_customer;
-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

Select market
from dim_customer 
where customer = "Atliq Exclusive" and region = "APAC" 
group by market  
order by market;


-- Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields, customer_code customer average_discount_percentage


select dc.customer_code ,customer , round(avg(pre_invoice_discount_pct),2) as average_discount_pct 
from dim_customer dc join fact_pre_invoice_deductions fpd
on dc.customer_code = fpd.customer_code
where fiscal_year = 2021 and market = "India"
group by customer_code
order by average_discount_pct DESC
limit 5;


-- What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
-- unique_products_2020 unique_products_2021 percentage_chg

select X.A as unique_products_2020 , Y.B as unique_products_2021 , Round((B-A)*100/A,2) As pct_chng
From (
(select count(distinct fs.product_code) as A from fact_sales_monthly fs join fact_gross_price g on fs.product_code = g.product_code
 where g.fiscal_year = 2020) X ,
(select count(distinct fs.product_code) as B from fact_sales_monthly fs join fact_gross_price g on fs.product_code = g.product_code 
where g.fiscal_year = 2021) Y
);

/*
 Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains
 2 fields,segment product_count
*/

select count(distinct product_code) as product_count , segment 
from dim_product 
group by segment 
order by product_count DESC ;

/*
Which segment had the most increase in unique products 2021 vs 2020? The final output contains these fields, segment
product_count_2020 product_count_2021 difference
*/

With CTE1 As (
select P.segment as C ,count(distinct P.product_code) as unique_poduct_2020
from fact_sales_monthly f join dim_product P 
On f.product_code = P.product_code
join fact_gross_price g on f.product_code = g.product_code
where g.fiscal_year = 2020
group by segment
),
 CTE2 As (
 Select  P.segment as D,count(distinct P.product_code) as unique_product_2021
 from fact_sales_monthly f join dim_product P 
 On f.product_code = P.product_code
 join fact_gross_price g on f.product_code = g.product_code
 where g.fiscal_year = 2021
 group by segment
 ) 
 select   C as segments ,unique_poduct_2020, unique_product_2021 , (unique_product_2021-unique_poduct_2020) as difference 
 from CTE1 join CTE2 On CTE1.C = CTE2.D
;

/*
Get the products that have the highest and lowest manufacturing costs.The final output should contain these fields,
product_code product manufacturing_cost
*/

select product ,P.product_code , FMC.manufacturing_cost
 from fact_manufacturing_cost FMC
join dim_product P On FMC.product_code = P.product_code
where manufacturing_cost In (
(select Max(manufacturing_cost)from fact_manufacturing_cost),
(select MIn(manufacturing_cost) from fact_manufacturing_cost)
)
Order by manufacturing_cost DESC ;



/*
Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,customer_code customer average_discount_percentage

*/

select customer , C.customer_code , Round(avg(pre_invoice_discount_pct),4)as avg_disc_pct from 
dim_customer C  join fact_pre_invoice_deductions fpd
On C.customer_code = fpd.customer_code 
where fiscal_year = 2021 and market = "India"
group by customer_code
order by avg_disc_pct DESC
limit 5;

/*
Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.The final report contains these columns:Month Year Gross sales Amount
*/

select concat(monthname(fs.date) ,'(',year(fs.date),')') as 'Month' , g.fiscal_year , 
 round(sum(sold_quantity * gross_price),3) as gross_sales_amount 
from fact_gross_price g 
join fact_sales_monthly fs on g.product_code = fs.product_code 
join dim_customer C on fs.customer_code = C.customer_code
where customer = "Atliq exclusive"
group by Month , g.fiscal_year
order by g.fiscal_year ;


/*
In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
*/

WITH temp_table AS (
  SELECT date,month(date_add(date,interval 4 month)) AS period, g.fiscal_year,sold_quantity 
FROM fact_sales_monthly fs join fact_gross_price g on fs.product_code = g.product_code
)
SELECT CASE 
   when period/3 <= 1 then "Q1"
   when period/3 <= 2 and period/3 > 1 then "Q2"
   when period/3 <=3 and period/3 > 2 then "Q3"
   when period/3 <=4 and period/3 > 3 then "Q4" END quarter,
 round(sum(sold_quantity)/1000000,2) as total_sold_quanity_in_millions FROM temp_table
WHERE fiscal_year = 2020
GROUP BY quarter
ORDER BY total_sold_quanity_in_millions DESC ;



/*
Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
channel gross_sales_mln percentage
*/

With Output as(
 select c.channel , Round(sum(sold_quantity * gross_price/1000000),2) as gross_price_mln 
 from fact_sales_monthly fs join dim_customer c on fs.customer_code = c.customer_code
 join fact_gross_price g on g.product_code = fs.product_code
 where fs.fiscal_year = 2021
 group by channel
)
select channel , concat(gross_price_mln , 'M') as gross_sales_mln ,concat(round(gross_price_mln*100/total,2),'%') as percantage 
from (
(select sum(gross_price_mln) as total from output) A ,
(select * from output ) B
)
order by percantage DESC;



/*
Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields
,division product_code , product ,total_sold_quantity rank_order
*/


with output1 AS(
select p.product , p.product_code , p.division , sum(f.sold_quantity) as total_sold_quantity
from dim_product p join fact_sales_monthly f on f.product_code = p.product_code
join fact_gross_price g on g.product_code = f.product_code
where g.fiscal_year = 2021
group by p.product_code , p.division ,p.product
),
output2 as (
select division , product_code ,product ,total_sold_quantity,
Rank () over(partition by division order by total_sold_quantity DESC) AS Rank_order
from output1
)
select output1.division , output1.product_code , output1.product ,output2.total_sold_quantity ,output2.Rank_order 
from output1 join output2  on
output1.product_code = output2.product_code
where output2.Rank_order In(1,2,3)
;



select avg(manufacturing_cost) from fact_manufacturing_cost;





with cte_1 as (
select count(distinct(p.product_code)) as unique_product_2021 ,p.segment as C from  dim_product p
join fact_sales_monthly f on f.product_code = p.product_code
where fiscal_year = 2021
),
cte_2 As (
select count(distinct(p.product_code)) as unique_product_2020 ,p.segment as D from dim_product p
join fact_sales_monthly f on f.product_code = p.product_code 
where fiscal_year = 2020
)
select unique_product_2021 , unique_product_2020 , 
concat(((unique_product_2021 -  unique_product_2020)*100) / unique_product_2020 ,'%') as Pct_chng
from cte_1 join cte_2 on cte_1.c= cte_2.D;



/*
Which segment had the most increase in unique products 2021 vs 2020? The final output contains these fields, segment
product_count_2020 product_count_2021 difference
*/

with cte_1 as (
select count(distinct p.product_code) as unique_product_2021 , p.segment as C 
from dim_product p join fact_sales_monthly f on p.product_code = f.product_code
where fiscal_year = 2021
group by segment
),
cte_2 as (
select count(distinct p.product_code) as unique_product_2020 , p.segment as D 
from dim_product p join fact_sales_monthly f on f.product_code = p.product_code
where fiscal_year = 2020
group by segment
)
select  C as segment , unique_product_2021 , unique_product_2020 , (unique_product_2021 - unique_product_2020) as difference
from cte_1 join cte_2 on cte_1.c = cte_2.D



