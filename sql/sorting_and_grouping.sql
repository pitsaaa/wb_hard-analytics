-- Часть 1. Задание 1
/*
 * Необходимо для каждого города вывести число покупателей,
 * сгруппированных по возрастным категориям
 * 
 * Выведем сначала покупателей, при условии, что за
 * возрастную категорию считаем возраст человека в полных годах
 */ 

select "city",
"age",
count(*) as "count"
from users
group by "city", "age"
order by 2, 3 desc;

/* Первые строки вывода:

city            |age|count|
----------------+---+-----+
Swedesburg      | 25|    1|
Plato Center    | 63|    1|
Colonial Heights| 19|    1|
Gainestown      | 31|    1|
 */

/*
 * Теперь разобьем пользователей по другому принципу:
 * три возрастные категории: young, adult и old
 */

select "city",
CASE 
	when age between 0 and 20 then 'young'
	when age between 21 and 49 then 'adult'
	when age >= 50 then 'old'
END as "age_category",
count(*) as "count"
from users
group by "city", "age_category"
order by 2, 3 desc;

/* Первые строки вывода:

city            |age_category|count|
----------------+------------+-----+
Solen           |adult       |    1|
Ocala           |adult       |    1|
West Branch     |adult       |    1|
Royalston       |adult       |    1|
 */


-- Часть 1. Задание 2
/*
 * Необходимо рассчитать среднюю цену товаров для категорий,
 * в названии товаров которых присутствуют слова "hair" или "home"
 * 
 * Рассчитаем среднюю цену для категорий, учитывая только товары
 * с указанным условием
 */

select p.category,
round(avg(p.price), 2) as "avg_price"
from products p
where lower(p.name) LIKE '%hair%' OR
lower(p.name) LIKE '%home%'
group by p.category ;

/* Вывод:

category|avg_price|
--------+---------+
Beauty  |   124.00|
Home    |   101.00|
 */


/*
 * Теперь рассчитаем среднюю цену для категорий, внутри которых есть
 * товары с указанным условием, но при расчете средней цены будем
 * учитывать все товары в этой категории, а не только товары с нашим условием
 */

select p.category,
round(avg(p.price), 2) as "avg_price"
from products p
where p.category in 
(
select DISTINCT(p2.category)
from products p2
where lower(p2.name) LIKE '%hair%' OR
lower(p2.name) LIKE '%home%'
)
group by p.category;

/* Вывод:

category|avg_price|
--------+---------+
Home    |   103.21|
Beauty  |    99.70|
 */


-- Часть 2. Задание 1

/*
 * Необходимо вывести для каждого продавца количество категорий, средний
 * рейтинг среди категорий, суммарную выручку и метку 'poor' или 'rich'
 * в зависимости от суммарной выручки
 * 
 * Продавцов, которые продают только одну категорию товаров учитывать не будем, исходя из условия
 */

select seller_id, count(distinct category) as "total_categ",
round(avg(rating), 2) as "avg_rating", sum(revenue) as "total_revenue",
case 
	when sum(revenue) > 50000 then 'rich'
	else 'poor'
end as "seller_type"
from sellers
where category <> 'Bedding'
group by seller_id
having count(distinct category) > 1;

/* Вывод:

seller_id|total_categ|avg_rating|total_revenue|seller_type|
---------+-----------+----------+-------------+-----------+
        0|          2|      5.50|        87790|rich       |
        2|          6|      3.00|       213564|rich       |
        5|          7|      4.50|       250719|rich       |
        6|          3|      1.80|       150053|rich       |
        7|          2|      4.00|        49197|poor       |
 */


-- Часть 2. Задание 2

/*
 * Для всех неуспешных продавцов посчитаем, сколько полных месяцов прошло
 * с даты их регистрации. Также выведем для них разницу между максимальным и минимальным
 * сроками доставки 
 * 
 * Под 'неуспешным' продавцов будем понимать метку poor из предыдущего задания, то есть
 * продавцы с более чем одной категорией товаров, но суммарной выручкой менее 50000
 * 
 * За дату регистрации возьмем самую раннюю date_reg для каждого продавца
 * 
 * Рассчитаем кол-во месяцев двумя способами: сначала как в условии - 
 * 1 месяц - 30 дней, посчитаем кол-во пройденных дней и поделим на 30
 */

select seller_id,
(current_date - min(date_reg)) / 30 as "month_from_registration", 
max(delivery_days) - min(delivery_days) as "max_delivery_difference"
from sellers
where category <> 'Bedding'
group by seller_id
having count(distinct category) > 1 and 
sum(revenue) <= 50000;

/* Вывод:

seller_id|month_from_registration|max_delivery_difference|
---------+-----------------------+-----------------------+
        7|                    135|                      6|
        8|                     82|                      2|
       20|                    102|                      1|
       29|                    159|                      7|
 */

/*
 * Другой способ - посчитаем сколько фактически календарных месяцев прошло
 * с момента регистрации
 */

select seller_id, 
(date_part('year', age(current_date, min(date_reg))) * 12 +
date_part('month', age(current_date, min(date_reg))))::integer
as "month_from_registration",
max(delivery_days) - min(delivery_days) as "max_delivery_difference"
from sellers
where category <> 'Bedding'
group by seller_id
having count(distinct category) > 1 and 
sum(revenue) <= 50000;

/* Вывод:

seller_id|month_from_registration|max_delivery_difference|
---------+-----------------------+-----------------------+
        7|                    133|                      6|
        8|                     81|                      2|
       20|                    101|                      1|
       29|                    156|                      7|
 */


-- Часть 2. Задание 3

/*
 * Необходимо вывести продавцов, зарегестрированных в 2022 году 
 * и продающих ровно 2 категории товаров с суммарной выручкой, превышающей 75000
 * Также нужно для каждого продавца вывести пару категорий которые он продает
 * 
 * Если взять за дату регистрации - минимальную date_reg, то запрос ничего не выдаст:
 * продавцов с датой регистрации в 2022 году, вычисленной таким образом нет
 */

select seller_id, string_agg(category, ' - ' order by category) as "category_pair" 
from sellers
group by seller_id, category
having date_part('year', min(date_reg)) = 2022 and 
count(distinct category) = 2 and 
sum(revenue) > 75000;

/* Вывод:

seller_id|category_pair|
---------+-------------+
 */


/*
 * Посчитаем по-другому: допустим у каждого продавца есть несколько дат регистрации:
 * минимальные date_reg для каждой пары seller - category
 * Тогда будем считать что продавец зарегистрировался в 2022 году, если хотя бы одна 
 * из его дат регистрации выполняет условие
 */
select seller_id, string_agg(category, ' - ' order by category) as "category_pair"
from sellers s
where seller_id in (
select seller_id 
from sellers s2 
group by seller_id, category
having min(date_part('year', date_reg)) = 2022
)
group by seller_id 
having sum(revenue) > 75000
and count(distinct category) = 2

/* Вывод:

seller_id|category_pair|
---------+-------------+
      133|Book - Dog   |
 */

