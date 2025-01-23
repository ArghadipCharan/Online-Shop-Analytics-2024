create database Online_Shoping_2024;
select * from orders;

-- Customer Insights

-- 1. Which customer demographics contribute the most to total sales (top 5)?

select c.address, round(SUM(o.total_price), 2) AS total_sales
from customers c
join orders o on c.customer_id = o.customer_id
group by c.address
order by total_sales desc
limit 5;

-- 2. What is the average order value (aov) for returning vs. new customers?

select 
    case when order_count > 1 then 'returning' else 'new' end as customer_type,
    round(avg(o.total_price), 2) as average_order_value
from (
    select c.customer_id, count(o.order_id) as order_count
    from customers c
    join orders o on c.customer_id = o.customer_id
    group by c.customer_id
) as customer_orders
join orders o on customer_orders.customer_id = o.customer_id
group by customer_type;

-- 3. Which customers are the most valuable in terms of lifetime spending (top 10)?

select 
	c.customer_id, c.address,
	concat(c.first_name," ", c.last_name) as Customer_name, 
    round(sum(o.total_price), 2) as lifetime_spending
from customers c
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.first_name, c.last_name
order by lifetime_spending desc
limit 10;

-- Product Performance

-- 4. Which product categories generate the highest revenue?

select 
	p.category, 
    round(sum(oi.quantity * oi.price_at_purchase), 2) as total_revenue
from products p
join order_items oi on p.product_id = oi.product_id
group by p.category
order by total_revenue desc;

-- 5. What is the relationship between product ratings and sales?

with S as (
select 
	p.product_id, 
    p.product_name, 
    r.rating as customer_rating, 
    round(sum(oi.quantity * oi.price_at_purchase),2) as sales
from products p
join order_items oi on p.product_id = oi.product_id
join reviews r on p.product_id = r.product_id
group by p.product_id, p.product_name, customer_rating
)
select customer_rating, round(sum(sales),2) as total_sales
from S 
group by customer_rating
order by customer_rating asc ;


-- 6. Which products have the highest number of reviews, and do those reviews correlate with sales performance?

with CTE as (
select 
	p.product_id, 
    p.product_name, 
    count(r.review_id) as review, 
    round(sum(oi.quantity * oi.price_at_purchase), 2) as sales
from products p
join reviews r on p.product_id = r.product_id
join order_items oi on p.product_id = oi.product_id
group by p.product_id, p.product_name
order by review desc, sales desc
)
select 
	product_name, 
	sum(review) as review_count, 
    round(sum(sales), 2) as total_sales
from CTE
group by product_name
order by review_count desc
limit 10;

-- order trend

-- 7. Which time periods have the highest sales volume ?

select monthname(o.order_date) as order_month,
       round(sum(o.total_price),2) as total_sales
from orders o
group by monthname(o.order_date)
order by order_month ;


-- 8. What is the average order quantity per product category?

select p.category, avg(oi.quantity) as average_order_quantity
from products p
join order_items oi on p.product_id = oi.product_id
group by p.category
order by average_order_quantity desc;

-- 9. Are there specific patterns in high-value orders (e.g., bulk buying, seasonal purchases)?

with M as (
select o.order_id, 
       monthname(o.order_date) as order_month, 
       sum(oi.quantity) as total_items,
       o.total_price
from orders o
join order_items oi on o.order_id = oi.order_id
join customers c on o.customer_id = c.customer_id
where o.total_price > 1000
group by o.order_id, o.order_date, c.first_name, 
	c.last_name, o.total_price
having sum(oi.quantity) > 10
order by total_price desc
)
select order_id, order_month, total_items, sum(total_price)
from M
group by order_id, order_month, total_items
order by total_items desc;


-- supplier and Inventory Management

-- 10. Which suppliers contribute to the most profitable products? (top 10)

select 
	s.supplier_id, s.supplier_name, 
	round(sum(oi.quantity * oi.price_at_purchase),2) as total_revenue
from suppliers s
join products p on s.supplier_id = p.supplier_id
join order_items oi on p.product_id = oi.product_id
group by s.supplier_id, s.supplier_name
order by total_revenue desc
limit 10;

-- 11. What is the avg. lead time for product shipments of each carrier ?

with c as (
select s.shipment_id,
       s.carrier,
       datediff(s.delivery_date, s.shipment_date) as lead_time,
       s.shipment_status
from shipments s
where s.shipment_status = 'Delivered'
)
select carrier, round(avg(lead_time)) as avg_lead_time_in_days
from c
group by carrier
order by avg_lead_time_in_days asc ;


-- 12. Are there any patterns of product stockouts or delays in shipment?

select shipment_status, count(*) as count
from shipments
group by shipment_status
order by count desc;

select s.shipment_id,
       datediff(s.delivery_date, s.shipment_date) as delay_days,
       s.shipment_status
from shipments s
where s.delivery_date > s.shipment_date
   and s.shipment_status != 'Cancelled';
   
-- Payments and financial

-- 13. . What is the impact of discounts (price_at_purchase vs. regular price) on sales?

select 
    p.product_id,
    p.product_name,
    p.price as regular_price,
    round(avg(oi.price_at_purchase),2) as avg_purchase_price,
    round((p.price - avg(oi.price_at_purchase)) / p.price * 100) as discount_percentage,
    sum(oi.quantity) as total_sales
from 
    products p
join 
    order_items oi on p.product_id = oi.product_id
group by 
    p.product_id, p.product_name, p.price
order by 
    discount_percentage desc;
    
-- 14. Which payment methods are the most popular?

select payment_method, count(*) as method_count
from payment
group by payment_method
order by method_count desc;

select *
from payment;

-- 15. What percentage of payments experience delays or failures?

select 
	transaction_status, 
	round(count(*) * 100.0 / (select count(*) from payment),0) as percentage
from payment
group by transaction_status;

    
-- 16. How does transaction status impact shipment ?
select p.transaction_status, s.shipment_status, count(*) as count
from payment p
join shipments s on p.order_id = s.order_id
group by p.transaction_status, s.shipment_status;

select * from reviews;

-- shipping and logistic

-- 17. Which carriers are the most reliable in terms of on-time delivery?

select 
    shipment_status,
    count(*) as shipment_count,
    round(count(*) * 100.0 / (select count(*) from shipments), 2) as percentage
from shipments
where shipment_status in ('Cancelled', 'Pending')
group by shipment_status
order by shipment_count desc;

-- 22. What is the frequency of canceled or delayed shipments?
select shipment_status, count(*) as status_count
from shipments
group by shipment_status
order by status_count desc;







