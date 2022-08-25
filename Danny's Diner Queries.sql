---DANNY'S DINER


---Create Sales table
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
)

---Insert values into Sales able
INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3')
 

 ---Create Menu Table
CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
)

---Insert values into Menu Table
INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12')
  
---Create a Members Table
CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
)

---Insert values into Members Table
INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09')
 

----(1)What is the total amount each customer spent at the restaurant?

SELECT customer_id, SUM(price) AS TotalAmountSpent
FROM sales
LEFT JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY sales.customer_id


-----(2) How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT sales.order_date) as NumberOfDaysVisited
FROM sales
LEFT JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY customer_id


----- (3)What was the first item from the menu purchased by each customer?

WITH ordered_cte AS
(
SELECT DISTINCT sales.customer_id, menu.product_name, order_date, MIN(order_date)
OVER (PARTITION BY sales.customer_id
	ORDER BY sales.order_date) as First_order_date
FROM sales
LEFT JOIN menu
	ON sales.product_id = menu.product_id
)

SELECT * FROM ordered_cte
WHERE order_date = First_order_date



-----(4) What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 menu.product_name, COUNT(sales.product_id) AS TimesPurchased
FROM sales
LEFT JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY TimesPurchased DESC


--- (5) Which Item was the most popular for each customer?

WITH most_popular_cte AS
(
SELECT sales.customer_id, menu.product_name, COUNT(sales.product_id) AS TimesPurchased,
DENSE_RANK() OVER(PARTITION BY sales.customer_id
  ORDER BY COUNT(sales.customer_id) DESC) AS position
FROM sales
LEFT JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY menu.product_name, customer_id
)

SELECT * FROM most_popular_cte
WHERE position = 1


--- (6)  Which item was purchased first by the customer after they became a member?

WITH sales_member_cte AS
(SELECT sales.customer_id, sales.product_id, sales.order_date, members.join_date,
MIN(order_date)	OVER (PARTITION BY sales.customer_id) 
AS first_order 

FROM sales 
LEFT JOIN members
	ON sales.customer_id = members.customer_id
	WHERE order_date > = join_date)

SELECT sales_member_cte.customer_id, menu.product_name, join_date, first_order
FROM sales_member_cte
JOIN menu
	ON sales_member_cte.product_id = menu.product_id
WHERE first_order = order_date
ORDER BY first_order


--- (7) Which Item was purchased just before the customer became a member?
WITH sales_member_cte AS
(SELECT sales.customer_id, sales.product_id, sales.order_date, members.join_date,
MAX(order_date)	OVER (PARTITION BY sales.customer_id) 
AS last_order 

FROM sales 
LEFT JOIN members
	ON sales.customer_id = members.customer_id
	WHERE order_date < join_date)

SELECT sales_member_cte.customer_id, menu.product_name, join_date, last_order
FROM sales_member_cte
JOIN menu
	ON sales_member_cte.product_id = menu.product_id
WHERE last_order = order_date
ORDER BY last_order

--- (8) What is the total items and amount spent for each member before they became a member?
WITH sales_member_cte AS
(SELECT sales.customer_id, sales.product_id, sales.order_date,  members.join_date

FROM sales 
FULL OUTER JOIN members
	ON sales.customer_id = members.customer_id
	 WHERE order_date < join_date
	 OR sales.customer_id = 'C') -- Customer C is not yet a member.

SELECT sales_member_cte.customer_id, menu.product_name,sales_member_cte.order_date, join_date, COUNT(sales_member_cte.customer_id) 
OVER(PARTITION BY sales_member_cte.customer_id) AS number_of_items, SUM(price)
OVER(PARTITION BY sales_member_cte.customer_id) AS total_amount_spent
FROM sales_member_cte
JOIN menu
	ON sales_member_cte.product_id = menu.product_id


--- (9) If each $1 spent equates to 10 points, and sushi has a 2x points multiplier, How many 
--- points would each customer have?

SELECT customer_id, SUM(points) AS TotalPoints
FROM(
SELECT customer_id, product_name,
CASE
	WHEN product_name = 'sushi' 
		THEN price * 2 * 10
	ELSE price * 10
END AS points
FROM sales
LEFT JOIN menu
	ON sales.product_id = menu.product_id
) A
GROUP BY customer_id


--- (10) In the first week after a customer joins the program (including their join date) 
---  they earn 2X points on all items, not just sushi. How many points do customer A and B have at the end of January?

WITH sales_member_cte AS
(SELECT sales.customer_id, sales.product_id, sales.order_date, members.join_date,
CASE
	WHEN product_name = 'sushi'
	OR order_date BETWEEN join_date AND DATEADD(week,1,join_date)
		THEN price * 10 * 2
	ELSE price * 10
END AS points
FROM sales 
JOIN members
	ON sales.customer_id = members.customer_id
JOIN menu
	ON sales.product_id = menu.product_id
WHERE order_date BETWEEN '2021-01-01' AND '2021-01-31')


SELECT customer_id, SUM(points)
FROM sales_member_cte
GROUP BY customer_id





