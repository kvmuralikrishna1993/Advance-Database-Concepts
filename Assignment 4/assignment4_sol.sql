﻿


1.

WITH
 E1 as (SELECT "a" as a1, "b" as b1 FROM "W"), 
 E2 as (SELECT * FROM "W" w, E1), 
 E3 as (SELECT * FROM E2 where "a"="a1" and "b"<>"b1"), 
 E4 as (SELECT "a", "b" from "W"  except select "a","b" FROM E2) 
 (SELECT "a" from E3)  union (SELECT "a" FROM E4) ;


2

(a)

WITH
E1 as (SELECT distinct C."BookNo" FROM "Cites" C ),
E2 as (SELECT S."Sid",B."BookNo" FROM "Student" S INNER JOIN "Buys" B ON S."Sid" = B."Sid") ,
E3 as (SELECT E2."Sid"   FROM E1 INNER JOIN E2 ON E1."BookNo" = E2."BookNo")
SELECT distinct "Sid"FROM E3;

(b)

WITH
E1 as (SELECT distinct M."Sid" FROM "Major" M, "Major" M1 WHERE M."Sid" = M1."Sid" and M."Major" <> M1."Major"),
E2 as (SELECT S."Sid",S."Sname" FROM "Student" S INNER JOIN E1 ON S."Sid" = E1."Sid") 
SELECT distinct "Sid" , "Sname" FROM E2;

(c)

WITH
E1 as (SELECT distinct B."Sid" FROM "Buys" B, "Buys" B1 WHERE B."Sid" = B1."Sid" and B."BookNo" <> B1."BookNo"),
E2 as (SELECT S."Sid",S."Sname" FROM "Student" S INNER JOIN E1 ON S."Sid" = E1."Sid") ,
E3 as (SELECT S."Sid" FROM "Student" S INNER JOIN "Buys" B  ON  S."Sid" = B."Sid"),
E4 as ( SELECT "Sid" FROM E3 EXCEPT  SELECT "Sid" FROM E2)
SELECT distinct "Sid" FROM E4;

(d)

WITH
E1 as (SELECT distinct B."BookNo" FROM "Book" B, "Book" B1 WHERE  B."price" > B1."price" ),
E2 as (select b2."BookNo" from "Book" b2  except select * from E1)
SELECT distinct "BookNo" FROM E2;

(e)
WITH
E1 as (SELECT  B."BookNo" FROM "Book" B INNER JOIN "Cites" C ON C."BookNo" = B."BookNo" WHERE B."price" > '50'),
E2 as (SELECT BK."BookNo" FROM "Book" BK except select * from E1)
SELECT distinct  "BookNo" FROM E2

(f)

WITH
E1 as (SELECT  B."BookNo" FROM "Book" B WHERE B."price" >= '30'),
E2 as (SELECT  B."Sid" FROM "Buys" B INNER JOIN E1 ON B."BookNo" = E1."BookNo"),
E3 as ( SELECT  B."Sid" FROM "Buys" B  except  SELECT "Sid" FROM E2)
SELECT distinct "Sid" FROM E3


(g)

WITH
E1 as (select b."Sid",b."BookNo" from "Buys" b inner join "Major" m on b."Sid" = m."Sid" and m."Major" = 'CS' ),
E2 as ( select distinct * from E1),
E3 as (select distinct e1."Sid" from E1 e1 ),
E4 as (select bk."BookNo" from "Book" bk ),
E5 as (select * from E3 ,E4),
E6 as (select * from E5 except select * from E2)
(select distinct "BookNo" from E6);


 Queries with Aggregate Functions

1.

(a)
SELECT (SELECT count(1)
FROM ((SELECT a."x" FROM "A" a) except
(SELECT b."x" FROM "B" b)) Q ) = 0 AS "PropertySatisfied";



(b)
SELECT (SELECT count(1)
FROM ((SELECT a."x" FROM "A" a) except
(SELECT b."x" FROM "B" b)) Q ) = 0   

and

 (SELECT count(1)
FROM ((SELECT b."x" FROM "B" b) except
(SELECT a."x" FROM "A" a)) Q ) = 0 
AS "PropertySatisfied";



(c)
SELECT( SELECT count(1) 
FROM((SELECT a."x" FROM "A" a) intersect (SELECT b."x" FROM "B" b) ) Q ) >= 2 AS "PropertySatisfied";



(d)
SELECT(  
SELECT count(1) FROM (
(SELECT count(*) from "A") intersect (SELECT x from "B")) Q
 )  > 0 AS "PropertySatisfied";











2.1


(a) GROUP BY METHOD

SELECT distinct s."Sid" , count(bk."BookNo") as No_of_books
FROM "Buys" b, "Student" s,"Book" bk
WHERE s."Sid" = b."Sid" and b."BookNo" = bk."BookNo" and bk."price" BETWEEN 20 and 40
GROUP BY s."Sid"

union

SELECT Q."Sid" , 0 as No_of_books
FROM (SELECT s."Sid" 
FROM "Student" s

except

SELECT s."Sid" 
FROM "Buys" b, "Student" s,"Book" bk
WHERE s."Sid" = b."Sid" and b."BookNo" = bk."BookNo" and bk."price" BETWEEN 20 and 40) Q


(b) FUNCTION METHOD

create function numofbook_in_20_40(student integer)
returns bigint as
$$
SELECT distinct count(bk."BookNo")
FROM "Buys" b,"Book" bk
WHERE student = b."Sid" and b."BookNo" = bk."BookNo" and bk."price" BETWEEN 20 and 40
$$ language sql

SELECT s."Sid" ,numofbook_in_20_40(s."Sid" ) as no_of_books
FROM "Student" s




2.2

(a) FUNCTION METHOD

create function not_cited(bk integer )
returns bigint as
$$

SELECT count(c."CitedBookNo") FROM "Cites" c WHERE bk = c."CitedBookNo"

$$ language sql

SELECT b."BookNo"
FROM "Book" b
Where not_cited(b."BookNo") = 0

(b) LATERAL  METHOD


SELECT distinct  b."BookNo"
FROM "Book" b ,LATERAL (SELECT count(c."CitedBookNo") as num FROM "Cites" c WHERE b."BookNo" = c."CitedBookNo") ntcite
WHERE ntcite."num" = 0;




2.3


SELECT S."Sid",S."Sname"
FROM "Student" S
WHERE ( SELECT COUNT(1) FROM ((SELECT M."Sid" FROM "Major" M where M."Sid" = S."Sid" )) Q )>=2 and (SELECT COUNT(1) FROM ((

SELECT b."BookNo" FROM "Buys" b WHERE b."Sid" = S."Sid"  except SELECT c."CitedBookNo" FROM "Cites" c
) ) Q1 ) = 0



2.4
(a) FUNCTION METHOD

create function numofbook_g_30(student integer)
returns bigint as
$$
SELECT COUNT(1) FROM ( SELECT b."BookNo" FROM "Buys" b WHERE b."Sid" = student  EXCEPT SELECT bk."BookNo" FROM "Book" bk WHERE bk."price" > 30 ) Q1
$$ language sql

SELECT s."Sid",m."Major"
FROM "Student" s ,"Major" m,"Buys" b
Where m."Sid"=s."Sid" and s."Sid"= b."Sid" 
GROUP BY s."Sid",m."Major"
having numofbook_g_30(s."Sid") = 0


(b)

SELECT s."Sid",m."Major"
FROM "Student" s ,"Major" m, lateral ( SELECT COUNT(1) as num FROM ( SELECT b."BookNo" 
FROM "Buys" b WHERE b."Sid" = s."Sid"  EXCEPT SELECT bk."BookNo" FROM "Book" bk WHERE bk."price" > 30 ) Q1) booknum
where m."Sid"=s."Sid" and booknum."num" = 0


2.5
(a) COUNT IN SELECT

SELECT s."Sid",s1."Sid"
FROM "Student" s ,"Student" s1 
WHERE s."Sid" <> s1."Sid"  and ( SELECT COUNT(1) FROM( SELECT b."BookNo" from "Buys" b where b."Sid"=s."Sid" ) Q ) >=

( SELECT COUNT(1) FROM( SELECT b."BookNo" from "Buys" b where b."Sid"=s1."Sid" ) Q )


(b) GROUP BY METHOD

SELECT s."Sid",s1."Sid"
FROM "Student" s ,"Student" s1
WHERE s."Sid" <> s1."Sid"  

group by s."Sid",s1."Sid"
having ( SELECT COUNT(1) FROM( SELECT b."BookNo" from "Buys" b where b."Sid"=s."Sid" ) Q ) >=

( SELECT COUNT(1) FROM( SELECT b."BookNo" from "Buys" b where b."Sid"=s1."Sid" ) Q )




2.6

SELECT bk."BookNo"
FROM "Book" bk, Lateral ( SELECT COUNT(1) as num from( SELECT b."Sid" FROM "Buys" b where b."BookNo"=bk."BookNo") Q) cnt
WHERE cnt."num" = ( SELECT COUNT(*)-1 FROM "Student")









2. Jaccard function 



create or replace function c_book(cbook integer) 
returns table (books integer) AS
 $$ 
select c."CitedBookNo"
from "Cites" c
where c."BookNo" = cbook
 
 $$ LANGUAGE SQL


create or replace function Jaccardd(l float, u float) 
returns table (book1 integer, book2 integer, val double precision) AS
 $$ 
select b."BookNo",b1."BookNo", ((Select count(1) as num from (select * from c_book(b."BookNo") intersect select * from c_book(b1."BookNo")) Q)/ 
(Select cast (count(1) as float) from (select * from c_book(b."BookNo") union select * from c_book(b1."BookNo")) R)) S

from "Cites" b,"Cites" b1

where b."BookNo" <> b1."BookNo"  and ((Select count(1) as num from (select * from c_book(b."BookNo") intersect select * from c_book(b1."BookNo")) Q)/ 
(Select cast (count(1) as float) from (select * from c_book(b."BookNo") union select * from c_book(b1."BookNo")) R)) >=l

and

((Select count(1) as num from (select * from c_book(b."BookNo") intersect select * from c_book(b1."BookNo")) Q)/ 
(Select cast (count(1) as float) from (select * from c_book(b."BookNo") union select * from c_book(b1."BookNo")) R)) <= u

 
 $$ LANGUAGE SQL




select distinct Jaccardd(1,1)




3. simpson function

1.

create or replace function Simpson(student integer) 
returns float AS $$ 

 select  (select cast ((count(1) /(count(1)- 1.0)) as float ) from (select distinct  s."topic" from "sd" s)q) * ( 1 - sum(power(s2."percentage"/100.0,2))) 
  from "sd" s2 where s2."sid" = student

$$ LANGUAGE SQL


2.

select distinct s."sid",Simpson(s."sid")
 from "sd" s

3.

create or replace function SimpsonRange(l float, u float) 
returns table(students integer) AS
 $$ 
 select s."sid"
 from "sd" s
 where Simpson(s."sid") >=l and Simpson(s."sid")<=u
 $$ LANGUAGE SQL

select distinct SimpsonRange(0.5,1)