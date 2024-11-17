-- Часть 1
/*
 * Необходимо вывести список сотрудников с именами сотрудников, получающих
 * самую высокую зарплату в отделе
 * 
 * 1 вариант: без оконных функций, самая высокая зарплата и низкая зарплаты
 */

--самая высокая
select s.first_name , s.last_name , s.salary, s.industry,
(
select s4.first_name
from salary s4
where s4.industry = s.industry and 
s4.salary = s3."max_for_cat"
) as "name_highest_sal"
from salary s
join (
select s2.industry, max(s2.salary) as "max_for_cat"
from salary s2
group by s2.industry
) s3 using(industry);

/* Вывод:

first_name|last_name |salary|industry                 |name_highest_sal|
----------+----------+------+-------------------------+----------------+
Layla     |Ross      |   183|Publishing               |Emily           |
Brandon   |Kelly     |   242|Construction             |Haley           |
Laura     |Evans     |   213|Consumer Goods           |Laura           |
Nathan    |Stewart   |   151|Apparel                  |Rachel          |
 */

--самая низкая
select s.first_name , s.last_name , s.salary, s.industry,
(
select s4.first_name
from salary s4
where s4.industry = s.industry and 
s4.salary = s3."min_for_cat"
) as "name_lowest_sal"
from salary s
join (
select s2.industry, min(s2.salary) as "min_for_cat"
from salary s2
group by s2.industry
) s3 using(industry);

/* Вывод:

first_name|last_name |salary|industry                 |name_lowest_sal|
----------+----------+------+-------------------------+---------------+
Layla     |Ross      |   183|Publishing               |Melissa        |
Brandon   |Kelly     |   242|Construction             |Elizabeth      |
Laura     |Evans     |   213|Consumer Goods           |Austin         |
Nathan    |Stewart   |   151|Apparel                  |Jonathan       |
 */

/*
 * С помощью оконных функций
 * Здесь также выведу фамилию, чтоб было видно различие
 */

--самая высокая
select s.first_name , s.last_name , s.salary, s.industry,
first_value(concat(s.first_name, ' ', s.last_name)) over (partition by s.industry order by s.salary desc)
as "name_highest_sal"
from salary s;

/* Вывод:

first_name|last_name |salary|industry            |name_highest_sal  |
----------+----------+------+--------------------+------------------+
Nathan    |Hayes     |   191|Accounting          |Nathan Hayes      |
Justin    |Harris    |   139|Accounting          |Nathan Hayes      |
Joseph    |Bell      |    98|Accounting          |Nathan Hayes      |
Nathan    |Jenkins   |    57|Accounting          |Nathan Hayes      |
 */

--самая низкая
select s.first_name , s.last_name , s.salary, s.industry,
last_value(concat(s.first_name, ' ', s.last_name)) over (partition by s.industry order by s.salary desc
rows between unbounded preceding and unbounded following) as "name_lowest_sal"
from salary s;

/* Вывод:

first_name|last_name |salary|industry            |name_lowest_sal  |
----------+----------+------+--------------------+-----------------+
Nathan    |Hayes     |   191|Accounting          |Nathan Jenkins   |
Justin    |Harris    |   139|Accounting          |Nathan Jenkins   |
Joseph    |Bell      |    98|Accounting          |Nathan Jenkins   |
Nathan    |Jenkins   |    57|Accounting          |Nathan Jenkins   |
 */


--Часть 2. Задание 1
/*
 * Необходимо отобрать данные по продажам за 2.01.2016.
 * Указать для каждого магазина адрес, сумму проданных товаров в штуках,
 * сумму проданных товаров в рублях
 * 
 * Сумму в рублях будем расчитывать как произведение "QTY" - количество товара
 * на его стоимость - "PRICE"
 */

select distinct sh."SHOPNUMBER", sh."CITY", sh."ADDRESS",
sum(s."QTY") over (partition by sh."SHOPNUMBER") as "SUM_QTY",
sum(g."PRICE" * s."QTY") over (partition by sh."SHOPNUMBER") as "SUM_QTY_PRICE"
from sales s join shops sh using("SHOPNUMBER") join goods g using("ID_GOOD")
where s."DATE" = to_date('2016-01-02', 'YYYY-MM-DD')
order by 1;

/* Вывод:

SHOPNUMBER|CITY|ADDRESS         |SUM_QTY|SUM_QTY_PRICE|
----------+----+----------------+-------+-------------+
         1|СПб |Ленина, 5       |    690|        49650|
         2|МСК |Пушкина, 10     |   1530|       230200|
         3|НВГ |Ленина, 10      |   3900|       340500|
         4|МСК |Лермонтова, 12  |   2380|       224450|
 */


--Часть 2. Задание 2
/*
 * Необходимо отобрать за каждую дату долю суммарных продаж (в рублях на дату)
 * Расчеты производить только по товарам направления 'чистота'
 * 
 * Столбцы в результирующей таблице: DATE_, CITY, SUM_SALES_REL
 * 
 * Как я понял, нужно для каждой даты и для каждого города вывести долю суммарных продаж
 * этого города относительно этой даты
 */

select distinct "DATE", "CITY", round( (sum("QTY" * "PRICE") over (partition by "DATE", "CITY"))::numeric / 
(sum("QTY" * "PRICE") over (partition by "DATE"))::numeric , 3) as "SUM_SALES_REL"
from sales s join shops sh using("SHOPNUMBER") join goods g using("ID_GOOD")
where "CATEGORY" = 'ЧИСТОТА';

/* Вывод:

DATE      |CITY|SUM_SALES_REL|
----------+----+-------------+
2016-01-01|МРМ |        0.100|
2016-01-01|МСК |        0.054|
2016-01-01|НВГ |        0.107|
2016-01-01|СПб |        0.739|
2016-01-02|МРМ |        0.064|
 */

--Часть 2. Задание 3
/*
 * Необходимо вывести информацию о топ-3 товарах по продажам в штуках
 * в каждом магазине в каждую дату
 * 
 * 1 вариант решения: выведем в столбце ID_GOOD сразу все топ-3 товара
 */

select g_rnk."DATE" , g_rnk."SHOPNUMBER" , string_agg(g_rnk."ID_GOOD"::text ,', ')
as "ID_GOOD"
from (
	select s."DATE" , sh."SHOPNUMBER", s."ID_GOOD",
	rank() over (partition by s."DATE" , sh."SHOPNUMBER" order by sum(s."QTY") desc) as "rnk"
	from sales s join shops sh using("SHOPNUMBER") join goods g using("ID_GOOD")
	group by s."DATE" , sh."SHOPNUMBER", s."ID_GOOD"
) g_rnk
where g_rnk."rnk" <= 3
group by g_rnk."DATE", g_rnk."SHOPNUMBER";

/* Вывод

DATE      |SHOPNUMBER|ID_GOOD                  |
----------+----------+-------------------------+
2016-01-01|         1|1234575, 1234574, 1234573|
2016-01-01|         2|1234579, 1234578, 1234577|
2016-01-01|         3|1234574, 1234573, 1234572|
2016-01-01|         4|1234579, 1234578, 1234577|
 */

/*
 * 2 вариант решения: выведем топ-3 товара по отдельности
 */

select g_rnk."DATE", g_rnk."SHOPNUMBER", g_rnk."ID_GOOD"
from(
select s."DATE" , sh."SHOPNUMBER", s."ID_GOOD",
rank() over (partition by s."DATE" , sh."SHOPNUMBER" order by sum(s."QTY") desc) as "rnk"
from sales s join shops sh using("SHOPNUMBER") join goods g using("ID_GOOD")
group by s."DATE" , sh."SHOPNUMBER", s."ID_GOOD") g_rnk
where g_rnk."rnk" <= 3;

/* Вывод:

DATE      |SHOPNUMBER|ID_GOOD|
----------+----------+-------+
2016-01-01|         1|1234575|
2016-01-01|         1|1234574|
2016-01-01|         1|1234573|
2016-01-01|         2|1234579|
 */


--Часть 2. Задание 4
/*
 * Необходимо вывести для каждого магазина и товарного направления сумму
 * продаж в рублях за предыдущую дату. Только для магазинов Санкт-Петербурга.
 */

select s."DATE", sh."SHOPNUMBER", g."CATEGORY" , 
lag(sum(g."PRICE" * s."QTY"), 1, 0) over (partition by g."CATEGORY" , sh."SHOPNUMBER" order by s."DATE")
as "PREV_SALES"
from sales s join shops sh using("SHOPNUMBER") join goods g using("ID_GOOD")
where sh."CITY" = 'СПб'
group by s."DATE", g."CATEGORY" , sh."SHOPNUMBER" ;

/* Вывод:

DATE      |SHOPNUMBER|CATEGORY|PREV_SALES|
----------+----------+--------+----------+
2016-01-01|         1|ДЕКОР   |         0|
2016-01-03|         1|ДЕКОР   |    286000|
2016-01-01|         6|ДЕКОР   |         0|
2016-01-02|         6|ДЕКОР   |    186000|
 */


--Часть 3
/*
 * Для начала создадим таблицу с необходимыми столбцами
 */

create table query (
	searchid serial primary key,
	"year" int,
	"month" int,
	"day" int,
	userid int,
	ts bigint,
	devicetype varchar(30),
	deviceid int,
	query text
);

/*
 * Затем заполним ее данными
 */

--select date_part('epoch', current_timestamp)::int;

insert into query ("year", "month", "day", userid, ts, devicetype, deviceid, query) values
(2024, 11, 17, 5, 1731795488, 'android', 20, 'купить куртку черную'),
(2024, 11, 17, 5, 1731795599, 'android', 20, 'куртка черную'),
(2024, 11, 17, 5, 1731795860, 'android', 20, 'куртка'),
(2024, 11, 17, 6, 1731795661, 'laptop', 13, 'офисное кресло'),
(2024, 11, 17, 7, 1731795737, 'android', 15, 'синяя гелевая ручка'),
(2024, 11, 17, 8, 1731795779, 'android', 22, 'игрушка для кота'),
(2024, 11, 17, 8, 1731796325, 'android', 22, 'кошачий домик'),
(2024, 11, 17, 9, 1731795865, 'android', 53, 'футбольный мяч'),
(2024, 11, 17, 9, 1731796917, 'android', 54, 'перчатки футбольные'),
(2024, 11, 17, 10, 1731796011, 'android', 33, 'regbnm cnjk'),
(2024, 11, 17, 10, 1731796017, 'android', 33, 'купить стол'),
(2024, 11, 17, 10, 1731796057, 'android', 33, 'купить стол игровой'),
(2024, 11, 17, 11, 1731796120, 'laptop', 26, 'Стихи Пушкина'),
(2024, 11, 17, 12, 1731796150, 'laptop', 71, 'свитер теплый'),
(2024, 11, 17, 13, 1731796196, 'android', 88, 'тетрадь в клетку'),
(2024, 11, 17, 13, 1731796292, 'android', 88, 'тетрадь в линейку'),
(2024, 11, 17, 14, 1731796370, 'laptop', 42, 'органайзер'),
(2024, 11, 17, 15, 1731796416, 'laptop', 94, 'кухонные ножи'),
(2024, 11, 17, 16, 1731796333, 'android', 68, 'брюки школьные'),
(2024, 11, 17, 16, 1731796370, 'android', 68, 'галстук');

/*
 * Выведем данные о запросах, у которых сформированный столбец
 * is_final пользователей android равен 1 или 2
 */

with next_queries as ( 
	select searchid, "year", "month", "day", userid, ts, devicetype, deviceid, q."query",
		lead(ts, 1) over w as "next_ts",
		lead(length(q."query"), 1) over w as "next_length",
		lead(q."query", 1, '') over w as "next_query"
	from query q 
	where devicetype = 'android' and 
		"year" = 2024 and "month" = 11 and "day" = 17
	window w as (partition by userid, deviceid order by ts)
),
is_final_queris as (
	select searchid, "year", "month", "day", userid, ts, devicetype, deviceid, nq."query",
	nq."next_query",
		case 
			when "next_ts" is null then 1
			when ("next_ts" - ts) > 180 then 1
			when length(nq."query") > "next_length" and ("next_ts" - ts) > 60 then 2
			else 0
		end as "is_final"
	from next_queries nq
)
select "year", "month", "day", userid, ts, devicetype, deviceid, ifq."query", ifq."next_query",
	ifq."is_final"
from is_final_queris ifq
where "is_final" in (1, 2);

/* Вывод:

year|month|day|userid|ts        |devicetype|deviceid|query               |next_query   |is_final|
----+-----+---+------+----------+----------+--------+--------------------+-------------+--------+
2024|   11| 17|     5|1731795488|android   |      20|купить куртку черную|куртка черную|       2|
2024|   11| 17|     5|1731795599|android   |      20|куртка черную       |куртка       |       1|
2024|   11| 17|     5|1731795860|android   |      20|куртка              |             |       1|
2024|   11| 17|     7|1731795737|android   |      15|синяя гелевая ручка |             |       1|
2024|   11| 17|     8|1731795779|android   |      22|игрушка для кота    |кошачий домик|       1|
 */