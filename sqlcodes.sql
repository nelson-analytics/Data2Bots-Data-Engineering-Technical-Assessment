-- Finding the total number of orders placed on a public holiday every month, for the past year.

SELECT DATE_PART('month',O.order_date) AS Month, COUNT(*) AS total_order
FROM orders O
INNER JOIN dim_date D ON O.order_date = D.calender_dt
WHERE working_day = 'false' and DATE_PART('year', O.order_date) = '2021' 
AND D.day_of_the_week_num BETWEEN 1 AND 5
GROUP BY Month
ORDER BY Month;

-- Creating the agg_puplic_holiday table

CREATE TABLE agg_puplic_holiday
(
    ingestion_date date NOT NULL,
    tt_order_hol_jan integer NOT NULL,
    tt_order_hol_feb integer NOT NULL,
    tt_order_hol_mar integer NOT NULL,
    tt_order_hol_apr integer NOT NULL,
    tt_order_hol_may integer NOT NULL,
    tt_order_hol_jun integer NOT NULL,
    tt_order_hol_jul integer NOT NULL,
    tt_order_hol_aug integer NOT NULL,
    tt_order_hol_sep integer NOT NULL,
    tt_order_hol_oct integer NOT NULL,
    tt_order_hol_nov integer NOT NULL,
    tt_order_hol_dec integer NOT NULL,
    PRIMARY KEY (ingestion_date)
);

-- Inserting values into agg_puplic_holiday
INSERT INTO agg_puplic_holiday
VALUES('2022-10-27', 20, 0, 16, 20, 0, 0, 0, 18, 0, 16, 12, 0);

--finding Total number of late shipments
-- The total no of late shipment is 175
WITH CTE AS(
SELECT O.order_id, O.order_date , S.shipment_date, 
(S.shipment_date - O.order_date) Day_diff, S.delivery_date
FROM shipments_deliveries S
INNER JOIN orders O
ON O.order_id = S.order_id
)
SELECT COUNT(*) AS Total_Late_Shipment
from CTE 
WHERE day_diff >= 6 AND delivery_date ISNULL;

-- finding Total number of undelivered shipments
-- The total no of undelivered shipments is 6757
WITH CTE AS( 
SELECT O.order_id, O.order_date , S.shipment_date, S.delivery_date
FROM shipments_deliveries S
INNER JOIN orders O
ON O.order_id = S.order_id
) 
SELECT COUNT(*) AS total_undelivered_shipments FROM CTE
WHERE delivery_date ISNULL AND shipment_date ISNULL

-- Creating the agg_shipments table 
CREATE TABLE agg_shipments
(
    ingestion_date date NOT NULL,
    tt_late_shipments integer NOT NULL,
    tt_undelivered_items integer NOT NULL,
    PRIMARY KEY (ingestion_date)
);
-- Inserting Values into agg_shipments
INSERT INTO agg_shipments
VALUES('2022-10-27', 175, 6757);

-- Finding the product with the highest reviews
-- The product with the highest review is Screwdriver and the product ID is 23
WITH CTE as ( 
SELECT product_id, COUNT(review) No_Of_Reviews
FROM reviews
GROUP BY product_id
ORDER BY No_Of_Reviews DESC
limit 1
) 
SELECT product_category,No_Of_Reviews
FROM CTE
INNER JOIN dim_products P
ON P.product_id = CTE.product_id

-- Finding the day it was ordered the most
-- The day it was ordered the most was on 2022-03-06

SELECT order_date, product_id,
COUNT(*) OVER(PARTITION BY order_date ) AS Total_Orders
FROM orders
WHERE product_id = 23
ORDER BY Total_Orders DESC
LIMIT 1

-- Finding it that day was a public holiday
-- Yes, that day was a public holiday
SELECT calender_dt, working_day
FROM dim_date
where calender_dt = '2022-03-06'

-- Finding the total review points
-- The total total review points is 940
SELECT product_id, SUM(review) AS Total_Review_Points
FROM reviews
WHERE product_id = 23
GROUP BY product_id
ORDER BY Total_Review_Points

-- Finding the percentage distribution of the review points of the product
WITH CTE AS ( 
SELECT review, COUNT(review) AS Total_Points
FROM reviews
WHERE product_id = 23
GROUP BY review
	)	
SELECT * ,
CASE
WHEN review = 1 THEN (Total_Points * 100/316 ::DECIMAL)
WHEN review = 2 THEN (Total_Points * 100/316 ::DECIMAL) 
WHEN review = 3 THEN (Total_Points * 100/316 ::DECIMAL) 
WHEN review = 4 THEN (Total_Points * 100/316 ::DECIMAL) 
WHEN review = 5 THEN (Total_Points * 100/316 ::DECIMAL) 
END AS pct_star_review
FROM CTE 
ORDER BY review

-- Let's find total early shipments
-- The total early shipment is 1834
WITH CTE AS(
SELECT O.order_id, O.order_date , S.shipment_date, 
(S.shipment_date - O.order_date) Day_diff, S.delivery_date
FROM shipments_deliveries S
INNER JOIN orders O
ON O.order_id = S.order_id
)
SELECT COUNT(*) AS Total_Late_Shipment
from CTE 
WHERE day_diff < 6 AND delivery_date NOTNULL;

-- Let's find total early shipments of the product
-- The total early shipment of the product is 72

WITH CTE AS(
SELECT O.order_id, O.order_date , S.shipment_date, 
(S.shipment_date - O.order_date) Day_diff, S.delivery_date
FROM shipments_deliveries S
INNER JOIN orders O
ON O.order_id = S.order_id
	WHERE product_id = 23
)
SELECT COUNT(*) AS Total_Late_Shipment
from CTE 
WHERE day_diff < 6 AND delivery_date NOTNULL;

-- To find the percentage distribution of early shipments of the product:
-- 72* 100/1834 = 3.92584


--- let's find the total late shipment of the product;
-- The total late shipment of the product is 10
WITH CTE AS(
SELECT O.order_id, O.order_date , S.shipment_date, 
(S.shipment_date - O.order_date) Day_diff, S.delivery_date
FROM shipments_deliveries S
INNER JOIN orders O
ON O.order_id = S.order_id
	WHERE product_id = 23
)
SELECT COUNT(*) AS Total_Late_Shipment
from CTE 
WHERE day_diff >= 6 AND delivery_date ISNULL;

-- finding the percentage distribution of late shipments
-- 10*100/175 = 5.71428

-- Creating the best_performing_product table
CREATE TABLE best_performing_product (
	ingestion_date DATE NOT NULL,
	product_name VARCHAR NOT NULL,
	most_ordered_day DATE NOT NULL,
	is_public_holiday bool NOT NULL,
	pct_one_star_review FLOAT NOT NULL,
	pct_two_star_review FLOAT NOT NULL,
	pct_three_star_review FLOAT NOT NULL,
	pct_four_star_review FLOAT NOT NULL,
	pct_five_star_review FLOAT NOT NULL,
	pct_early_shipments FLOAT NOT NULL,
	pct_late_shipments FLOAT NOT NULL,
	PRIMARY KEY(ingestion_date)

);

-- Inserting values into best_performing_product;
INSERT INTO best_performing_product
VALUES('2022-10-27', 'screwdriver',  '2022-03-06','true', 18.67088, 23.41772, 18.67088, 20.25316, 18.98734,3.92584,5.71428 );



select * from public.best_performing_product

