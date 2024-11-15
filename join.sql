-- Часть 1. Задание 1
/*
 * Необходимо найти клиента с самым долгим временем ожидания между 
 * заказом и доставкой
 * 
 * Выведем сначала одного клиента с самым долгим временем:
 */

select cn."name", age(on2.shipment_date, on2.order_date)
as "waiting time", on2.order_status 
from orders_new on2 join customers_new cn using(customer_id)
order by "waiting time" desc limit 1;

/* Вывод:

name         |waiting time|order_status|
-------------+------------+------------+
Robert Hansen|     10 days|Approved    |
 */

/* 
 * Так как в наших данных большое кол-во клиентов с одинаковым
 * вренем ожидания, то есть смысл вывести всех клиентов с максимальным
 * временем ожидания
 */ 

select cn."name", age(on2.shipment_date, on2.order_date)
as "waiting time", on2.order_status 
from orders_new on2 join customers_new cn using(customer_id)
where age(on2.shipment_date, on2.order_date) = (
select max(age(shipment_date, order_date))
from orders_new
)

/* Вывод:

name                 |waiting time|order_status|
---------------------+------------+------------+
David Hill           |     10 days|Cancel      |
Janet Quinn          |     10 days|Cancel      |
Mckenzie Sanders     |     10 days|Approved    |
Elizabeth Gilbert    |     10 days|Cancel      |
 */


-- Часть 1. Задание 2
/*
 * Найти клиентов, сделавших наибольшее кол-во заказов, и для каждого
 * найти среднее время между заказом и доставкой, также общую сумму всех их заказов
 */

select cn.name, count(order_id) as "orders_count",
avg(age(on2.shipment_date, on2.order_date)) as "avg_waiting_time",
sum(on2.order_ammount) as "total_amount"
from orders_new on2 join customers_new cn using(customer_id) 
group by cn.customer_id, cn.name
having count(order_id) = (
select count(order_id)
from orders_new
group by customer_id
order by 1 desc limit 1
)
order by "total_amount" desc;

/* Вывод:

name        |orders_count|avg_waiting_time|total_amount|
------------+------------+----------------+------------+
Rhonda Ochoa|           5| 5 days 19:12:00|       26447|
David Hill  |           5| 6 days 19:12:00|       21023|
 */


-- Часть 1. Задание 3
/*
 * Найти клиентов, у которых были заказы, доставленные с задержкой более
 * чем на 5 дней, и клиентов, у которых были отмененные заказы.
 * Для каждого клиента вывести имя, количество доставок 
 * с задержкой, количество отмененных заказов и их общую сумму. 
 */

select cn.name, count(case when 
date_part('days', age(shipment_date, order_date)) > 5 
then 1 end) as "days_with_delay",
count(case when order_status = 'Cancel' then 1 end)
as "canceled_orders",
sum(case when order_status = 'Cancel' then order_ammount else 0 end)
as "canceled_orders_ammount"
from orders_new on2 join customers_new cn using(customer_id) 
where on2.customer_id in (
select customer_id 
from orders_new 
where date_part('days', age(shipment_date, order_date)) > 5 
or order_status = 'Cancel'
)
group by cn.customer_id, cn.name
order by "canceled_orders_ammount" desc;

/* Вывод:

name                 |days_with_delay|canceled_orders|canceled_orders_ammount|
---------------------+---------------+---------------+-----------------------+
Elizabeth Gilbert    |              1|              3|                  17718|
David Hill           |              3|              4|                  17185|
Tony Hughes          |              2|              2|                  11533|
Tonya Watson         |              2|              2|                   9740|
 */


-- Часть 2. Задание 1
/*
 * Вычислить общую сумму продаж для каждой категории продуктов.
 */

select p.product_category, sum(order_ammount) as "total_amount"
from products p join orders o using(product_id)
group by p.product_category ;

/* Вывод:

product_category |total_amount|
-----------------+------------+
Молочные продукты|     2731243|
Овощи            |     1379235|
Мясо             |     2560614|
Фрукты           |     3867485|
 */


-- Часть 2. Задание 2
/*
 * Определить категорию продукта с наибольшей общей суммой продаж.
 */

select product_category
from (
select p.product_category, sum(order_ammount) as "total_amount"
from products p join orders o using(product_id)
group by p.product_category
) cat
order by "total_amount" desc
limit 1;

/* Вывод:

product_category|
----------------+
Напитки         |
 */


-- Часть 2. Задание 3
/*
 * Для каждой категории продуктов, определить продукт с
 * максимальной суммой продаж в этой категории.
 * 
 * Так как большинство названий продуктов повторяются в 
 * таблицу products, будем выводить не только название продукта,
 * но и его id
 * 
 * Первое решение: используя оконные функции (проще)
 */

select p.product_category ,
p.product_name ,
p.product_id ,
sum(o.order_ammount) as "total_ammount"
from products p join orders o using(product_id)
group by p.product_category ,
p.product_name,
p.product_id
order by rank() over (partition by p.product_category order by sum(o.order_ammount) desc)
limit (select count(distinct product_category) from products);

/* Вывод:

product_category |product_name|product_id|total_ammount|
-----------------+------------+----------+-------------+
Напитки          |Кофе        |       149|       411147|
Овощи            |Брокколи    |       107|       509213|
Зерновые         |Овсянка     |        94|       503965|
Мясо             |Курица      |         4|       529642|
 */

/*
 * Второе решение, не используя оконных функций (сложнее)
 */

select p.product_category,
p.product_name,
p.product_id,
prods."total_amount"
from products p join
(
select p.product_id, p.product_name, p.product_category, sum(order_ammount) as "total_amount"
from products p join orders o using(product_id)
group by p.product_id, p.product_name, p.product_category
) prods using(product_id)
where "total_amount" = (
select max("total_amount") from
(
select pr2.product_id, pr2.product_name, pr2.product_category, sum(order_ammount) as "total_amount"
from products pr2 join orders o2 using(product_id)
group by pr2.product_id, pr2.product_name, pr2.product_category
) tmp
where tmp.product_category = p.product_category
);

/* Вывод:

product_category |product_name|product_id|total_amount|
-----------------+------------+----------+------------+
Овощи            |Брокколи    |       107|      509213|
Молочные продукты|Масло       |         1|      249615|
Зерновые         |Овсянка     |        94|      503965|
Фрукты           |Банан       |       115|      453777|
 */




