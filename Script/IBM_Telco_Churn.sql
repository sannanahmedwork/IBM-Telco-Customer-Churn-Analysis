-- Creating a seperate database for the project:
CREATE DATABASE portfolio_project;

USE portfolio_project;

-- Renaming tables for convenience in subsequent querying:

RENAME TABLE telco_customer_churn_status TO status;
RENAME TABLE telco_customer_churn_demographics TO demographics;
RENAME TABLE telco_customer_churn_location TO location;
RENAME TABLE telco_customer_churn_population TO population;
RENAME TABLE telco_customer_churn_services TO services;

-- Removing spaces between column names. The use OF BACKTICKS IS IMPORTANT HERE!!

ALTER TABLE status CHANGE `Churn Label` Churn_Label VARCHAR(255);
ALTER TABLE status CHANGE `Customer Status` Customer_Status VARCHAR(255);
ALTER TABLE status CHANGE `Satisfaction Score` Satisfaction_Score VARCHAR(255);
ALTER TABLE status CHANGE `Churn Value` Churn_Value VARCHAR(255);
ALTER TABLE status CHANGE `Churn Score` Churn_Score VARCHAR(255);
ALTER TABLE status CHANGE `Churn Category` Churn_Category VARCHAR(255);
ALTER TABLE status CHANGE `Churn Reason` Churn_Reason VARCHAR(255);

-- Similarly done for all other columns of all other tables; the code has been erased after running it to save space and avoid clutter

-- Query 1: Considering the top 5 groups with the highest average monthly charges among churned customers: 
-- how can personalized offers be tailored based on age,gender, and contract type to potentially improve customer retention rates?

Select 
	d.gender, s.contract, round(avg(s.monthly_charge),2) as avg_monthly_charge, round(avg(s.tenure_in_months),2) as avg_tenure,
    Case 
		when d.age < 30 then "Under 30"
        when d.age between 30 and 50 then "30-50"
        when d.age between 51 and 70 then "50-70"
        else "above 70" end as age_group
	
from status as st
join services as s on st.customer_id = s.customer_id
join demographics as d on st.customer_id = d.customer_id 
where st.churn_label = "yes"
group by age_group, d.gender, s.contract     
order by avg_monthly_charge desc
limit 5;    

    
-- Query 2: What are the feedback or complaints from those churned customers    

select * from status;

select churn_category, churn_reason, count(customer_id) as customer_count,
		rank() over(partition by churn_category order by count(customer_id) desc) as category_rank
from status
where churn_label = "Yes"
group by churn_category, churn_reason
order by churn_category, category_rank;		

-- calculating the running customer total by churn category:

with t1 as (
select churn_category, churn_reason, count(customer_id) as customer_count
from status
where churn_label = "Yes"
group by churn_category, churn_reason
)

select churn_category, churn_reason, customer_count,
		sum(customer_count) over (partition by churn_category order by churn_reason) as running_total
from t1
order by churn_category, churn_reason;  


-- Query 3: How does the payment method influence churn behavior?

with t1 as (
select customer_id from status
where churn_label = "yes"
)

select s.payment_method, count(s.customer_id) as customer_count, round(sum(s.total_revenue), 2) as TotalRevenue_PMT_Method 
from services as s
join t1 as t1 on s.customer_id = t1.customer_id
group by payment_method
order by TotalRevenue_PMT_Method desc;

-- Churn % across pmt methods
-- CTE for total customers
with TotalCustomers as (
select customer_id, payment_method from services
),

-- CTE for churned customers
ChurnedCustomers as (
select customer_id from status
where churn_label = "yes"
)

select 
	t1.payment_method, count(t1.customer_id) as total_customers, count(t2.customer_id) as churned_customers,
    round((count(t2.customer_id)/count(t1.customer_id) *100), 2) as churn_rate_percentage
from TotalCustomers as t1 
left join ChurnedCustomers as t2 on t1.customer_id = t2.customer_id  -- left join to include all results from t1 and not just the common ones B/w t1 & t2
group by t1.payment_method
order by churn_rate_percentage desc;


