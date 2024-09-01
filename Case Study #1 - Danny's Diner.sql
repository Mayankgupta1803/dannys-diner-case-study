# SQL Case Study #1 - Danny's Diner

# Task 1
-- What is the total amount each customer spent at the restaurant?

select s.customer_id, sum(m.price) total_spent from sales s
join menu m
on s.product_id = m.product_id
group by s.customer_id;


# Task 2
-- How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date) from sales
group by customer_id;
 

# Task 3
-- What was the first item from the menu purchased by each customer?

with cte as (select s.customer_id, m.product_id, m.product_name,
		row_number() over(partition by customer_id order by order_date Asc) rnk
	-- 	first_value(product_id) over(partition by customer_id order by order_date ASC) 
from sales s
join menu m
on s.product_id = m.product_id)
select customer_id,product_name from cte
where rnk =1;


# Task 4
-- What is the most purchased item on the menu and how many times was it purchased by all customers?

select product_id from sales
group by product_id
order by count(product_id) Desc
limit 1;

select customer_id , count(product_id) from sales
where product_id = (select product_id from sales
					group by product_id
					order by count(product_id) Desc
					limit 1)
group by customer_id;


# Task 5
-- Which item was the most popular for each customer?

with cte as (
select customer_id, product_id ,
		Count(*) total_purchase,
        dense_rank() over(PARTITION BY customer_id order by count(*) desc) rnk
from sales
group by customer_id, product_id
)
select customer_id,product_id as top_products from cte
where rnk = 1;


# Task 6
-- Which item was purchased first by the customer after they became a member?

with cte as (
select members.customer_id, members.join_date,sales.order_date,sales.product_id, 
		row_number() over(partition by customer_id order by order_date) rnk
from members
left join sales
on members.customer_id = sales.customer_id
where members.join_date<= sales.order_date
)
select customer_id, join_date, order_date,product_id as first_purchase_product from cte 
where rnk =1;


# Task 7
-- Which item was purchased just before the customer became a member?

with cte as (
select members.customer_id, members.join_date,sales.order_date,sales.product_id, 
		dense_rank() over(partition by customer_id order by order_date desc) rnk
from members
left join sales
on members.customer_id = sales.customer_id
where members.join_date> sales.order_date
)
select customer_id, join_date, order_date,product_id as first_purchase_product from cte 
where rnk =1;


# Task 8
-- What is the total items and amount spent for each member before they became a member?

with cte as (
select mem.customer_id, s.product_id,m.product_name,m.price from members mem
left join sales s
on mem.customer_id = s.customer_id
join menu m
on m.product_id = s.product_id
where join_date>order_date
)
select customer_id, count(product_id), sum(price)
from cte
group by customer_id;


# Task 9
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with cte as (
select m.product_id,product_name,price,customer_id,order_date,
		case when product_name = 'sushi' then price*10*2 
             when product_name = 'curry' then price*10 
             when product_name = 'ramen' then price*10
             else price*10 
		end as points
from menu m
join sales s
on m.product_id = s.product_id)

select customer_id, sum(points)
from cte
group by customer_id;


# Task 10
-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?

with cte as (
select mem.customer_id,mem.join_date,s.order_date,s.product_id,m.product_name,m.price from members mem
left join sales s
on mem.customer_id = s.customer_id
join menu m
on m.product_id = s.product_id
),
tble as (select *,
		case when order_date between join_date and date_add(join_date, interval 6 day) then price*2*10
			 when order_date not between join_date and date_add(join_date, interval 6 day) then price*10
		end as points
from cte
)
select customer_id, sum(points)
from tble
where order_date <= '2021-01-31'
group by customer_id
order by customer_id;


