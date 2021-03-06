﻿1.

----------------------------------------------------kmean final -----------------------------------------------


create or replace function TC(id integer )
returns table (x_r float,y_r float) AS $$ begin

DROP TABLE IF EXISTS centroid;
create table centroid (cid integer, xs float , ys float);

insert INTO centroid 
SELECT pid as cid,x as xs,y as ys FROM k_mean
ORDER BY RANDOM()
LIMIT id;

DROP TABLE IF EXISTS med;
create table med (cid integer, xs float, ys float);
insert INTO med 
SELECT pid as cid,x as xs,y as ys FROM k_mean
ORDER BY RANDOM()
LIMIT id;
--insert into med values(1,1.0,1.0);
--insert into med values(4,5.0,7.0);



while (select (select count(1) from (select xs,ys from centroid except select xs,ys from med) as diff) > 0)


loop
DROP TABLE IF EXISTS centroid;
create table centroid (cid integer, xs float, ys float);

insert into centroid
select cid,xs,ys from med;

DROP TABLE IF EXISTS dist;
create table dist (pid integer,x float,y float,cid integer);

insert into dist
select k.pid,k.x,k.y,cid  from k_mean k,centroid c
where round((sqrt(  (k.x-c.xs)*(k.x-c.xs)  + (k.y-c.ys)*(k.y-c.ys)  )) ::numeric,3) <= 
all( select round((sqrt(  (k.x-xs)*(k.x-xs) + (k.y-ys)*(k.y-ys) ) ) ::numeric,3) from centroid where c.xs <> xs and c.ys <> ys);



DROP TABLE IF EXISTS med;
create table med (cid integer, xs float, ys float);

insert into med
select cid,sum(x)/count(cid) as x ,sum(y)/count(cid) as y from dist
group by cid;

end loop;

return query select xs,ys from centroid;
 END; $$ LANGUAGE plpgsql;


select tc(2); -- set the value of k here


2.



    ---------start-------
drop table if exists node_hit;
create table node_hit(node integer,hubs float, auths float);

insert into node_hit
    select distinct source,1,1 from graph_hit
union
    select distinct target,1,1 from graph_hit where target not in (select source from graph_hit) ;
select hits_algo()
    --select * from node_hit 
  ------execute upper part together  


-------------- function hits_algo starts ---------------
create or replace function hits_algo()
returns table(node integer,hubs float,auths float) as
$$

declare n integer;
   --n:=0;
begin
select 10 into n;
while (n > 0) 
     loop
     --- for check auth sum--------
	drop table if exists step1;
	create table step1(node integer,hubs float, auths float);
	insert into step1
	    select n.node,n.hubs,sum( (select n1.hubs from node_hit n1 where n1.node = g.source)) as auths from node_hit n,graph_hit g where n.node = g.target
	    group by n.node,n.hubs

	    union  --- to handle case with no authorities
	    select n1.node, n1.hubs,0 as auths from node_hit n1 where n1.node not in ( select f.node 
	    from (select n.node,n.hubs,sum( (select n1.hubs from node_hit n1 where n1.node = g.source)) as auths from node_hit n,graph_hit g where n.node = g.target
	    group by n.node,n.hubs) as f);
	  ---------------------  


	--select * from step1

	  -- calculating norm auth
	drop table if exists authnorm;
	create table authnorm (norm_auth float );
	insert into authnorm
	select sqrt(sum(pow(n.auths,2))) as norm_auth from step1 n;

	--select * from authnorm
	---- adjusting tables with norm
	drop table normalizaed_auth ;
	create table normalizaed_auth(node integer,hubs float, auths float);
	insert into normalizaed_auth
	select n.node,n.hubs,(n.auths / s.norm_auth) as auths from step1 n,authnorm s
	order by n.node;


	    --- for check hub sum
	--select * from normalizaed_auth

	---------
	drop table if exists step2;
	create table step2(node integer,hubs float, auths float);
	insert into step2
	    select n.node,sum( (select n1.auths from normalizaed_auth n1 where n1.node = g.target)) as hubs,n.auths from normalizaed_auth n,graph_hit g where n.node = g.source
	    group by n.node,n.auths
	    union  --- to handle case pointting to no authorities
	    select n1.node, 0 as hubs,n1.auths from normalizaed_auth n1 where n1.node not in ( select f.node 
	    from (select n.node,sum( (select n1.auths from normalizaed_auth n1 where n1.node = g.target)) as hubs,n.auths from normalizaed_auth n,graph_hit g where n.node = g.source
	    group by n.node,n.auths) as f);

	--------
	--select * from step2

	--calculating norm hub
	drop table if exists hubnorm;
	create table hubnorm (norm_hub float );
	insert into hubnorm
	select sqrt(sum(pow(n.hubs,2))) as norm_hub from step2 n  ; 

	--select * from hubnorm

	---- adjusting tables with norm


	drop table if exists normalizaed_hub_final ;
	create table normalizaed_hub_final(node integer,hubs float, auths float);
	insert into normalizaed_hub_final
	select n.node,(n.hubs / s.norm_hub) as hubs, n.auths from step2 n,hubnorm s
	order by n.node;
	-----adjusting done----

	update node_hit	
	set hubs = n.hubs,auths = n.auths
	from normalizaed_hub_final n
	where node_hit.node = n.node;
	n := n-1;   
end loop;
return query  select f.node,f.hubs,f.auths from normalizaed_hub_final f;
END;
$$ language plpgsql;



--------------------end -------------------------







3.

 --------------------------------- parts one ------------------------  

 create or replace function findweight(partid integer)
 returns bigint as
$$

 
WITH RECURSIVE included_parts(pid, sid, quantity) AS (
    SELECT pid, sid, quantity FROM psubparts WHERE pid = partid
  UNION ALL
    SELECT p.pid, p.sid, p.quantity *(pr.quantity)
    FROM included_parts pr, psubparts p
    WHERE p.pid = pr.sid
  )
  
      insert into   sidq(sid , quantity )
       
SELECT sid, SUM(quantity) as total_quantity
  FROM included_parts
GROUP BY sid;

select sum(s.quantity * p.weight) from sidq s,parts p
where s.sid = p.pid

union

select sum(weight) from parts where pid = partid

$$ LANGUAGE sql;


drop table if exists sidq;
 create table sidq(sid integer, quantity integer);
select findweight(1)   — enter part blue here   

---------------------------------------------------------------------------



4.



create or replace  function RD(id integer,len integer)
returns integer as
 $$ 

with RECURSIVE root_distance(pid,cid,len) as (
  select pid,cid,0 as l from pc where cid= id

  union all
  
  select p.pid,p.cid,len+1 as l from pc p ,root_distance r where r.pid = p.cid
)

select max(len) + 1 from root_distance;

$$ LANGUAGE sql;


select p1.cid,p2.cid from pc p1,pc p2 where p1.cid <> p2.cid and RD(p1.cid,0) = RD(p2.cid,0)



5.

---- shortest path function
create or replace function SP()
returns table (source integer, target integer,weight integer) AS $$ begin

   drop table if exists SP;

   create table SP(source integer, target integer, weight integer);



   insert into SP        
   select edge.source, edge.target, edge.weight  
   from dks edge;
      while exists (( select tc_pair.source AS source, edge.target AS target,tc_pair.weight + edge.weight
   from   SP tc_pair, dks edge 

    where  tc_pair.target = edge.source AND  
       ((tc_pair.source, edge.target,(tc_pair.weight + edge.weight)) NOT IN  
   (select pair.source, pair.target,pair.weight   
    from SP pair))   )     )

    loop 
    insert into sp  
    ( select tc_pair.source AS source, edge.target AS target, (tc_pair.weight + edge.weight)  AS weight
    from   SP tc_pair, dks edge    
    where  tc_pair.target = edge.source AND    
    (tc_pair.source, edge.target,(tc_pair.weight + edge.weight)) NOT IN     
    (select pair.source, pair.target,pair.weight     
    from SP pair) );   
    end loop;
    
    select pair.source as s, pair.target as t,pair.weight as w from SP pair; 

    END; $$ LANGUAGE plpgsql;

----dijkastra function
	create or replace function dijkastra(source_input integer)
	returns table (source integer, target integer,weight integer) AS $$ 

	     select distinct  pair.source as s, pair.target as t,pair.weight as w from sp pair
	    where pair.source=source_input and pair.weight <=all ( select s.weight from SP s where s.target = pair.target and s.source = pair.source) and pair.source <> pair.target
	union

	select distinct pair.source as s, pair.target as t,source_input as w from sp pair where pair.source=5 and pair.source = pair.target

	union
	 select distinct source_input as s,d.source as t,100 from dks d where d.source not in 
	  (select  s.target from SP s where s.source = source_input);
	    $$ LANGUAGE sql;


select * from dijkastra(3); --- give input here
   
-------------------------------------------------------------------------



6.


-------------------projection ----------------------



CREATE OR REPLACE FUNCTION Map(A integer, B Integer)
RETURNS TABLE (ITEM Integer, one integer) AS $$ 
SELECT A, A

 $$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION Reduce(key_item integer, key_value INTEGER[]) 
RETURNS TABLE(sel_ans INTEGER,sel_val integer) AS 
$$
 SELECT key_item,1; 
$$ LANGUAGE SQL;


DROP TABLE IF EXISTS selection;   
SELECT s.item AS item, s.one AS one  
 INTO selection 
 FROM r sel, LATERAL(SELECT t.item, t.one FROM Map(sel.A,sel.B) t) s;


DROP TABLE IF EXISTS selection_reduce;
SELECT distinct s.item,(select array( select 1 from selection s1 where s1.item =s.item)) as one
INTO selection_reduce FROM selection s;


SELECT q.sel_ans,q.sel_ans FROM selection_reduce sr, LATERAL(SELECT * FROM reduce(sr.item,sr.one)) q order by item;
 --------------------projection end --------------------------------------------




7.



-------------------difference ----------------------



CREATE OR REPLACE FUNCTION Map(A integer, B Integer)
RETURNS TABLE (ITEM Integer, item_belongs integer) AS $$ 
SELECT A, 1
union
select B,2
 --FROM (SELECT UNNEST(bag_of_words) AS wd) w; 
 $$ LANGUAGE SQL;



CREATE OR REPLACE FUNCTION Reduce(key_item integer, bag_of_ones INTEGER[] ) 
RETURNS TABLE(key_item INTEGER, key_value INTEGER) AS 
$$
select key_item,key_item where array_length(bag_of_ones,1) = 1 and bag_of_ones[1] = 1
$$ LANGUAGE SQL;




DROP TABLE IF EXISTS difference;   
SELECT s.item AS item, s.item_belongs AS item_belongs  
 INTO difference 
 FROM r sel, LATERAL(SELECT t.item, t.item_belongs FROM Map(sel.A,sel.B) t) s;


DROP TABLE IF EXISTS difference_reduce;
SELECT distinct  s.item,(select array(select d.item_belongs from difference d where d.item = s.item) as belongsto)
INTO difference_reduce FROM difference s;



SELECT q.key_item,q.key_value FROM difference_reduce sr, LATERAL(SELECT * FROM reduce(sr.item,sr.belongsto)) q order by item;


---------------------------------done --- difference ---------------------------------------------------------------------



8.

CREATE OR REPLACE FUNCTION Map(njr ,njs )
RETURNS TABLE (common Integer, elements_b text[]) AS $$ 

select b, array(select 1 ::int||', ' || a::int)  b_arr from njr
union
select b, array(select 2 ::int||', ' || c::int)  b_arr from njs

 $$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION Reduce(key_item integer, bag text[] ) 
RETURNS TABLE(key_item INTEGER, key_value text,key_value1 text) AS 
$$

select key_item,(select regexp_split_to_array(bag[1], ','))[1],(select regexp_split_to_array(bag[2], ','))[1]
where array_length(bag) = 2 

$$ LANGUAGE SQL;



DROP TABLE IF EXISTS joining;   
SELECT distinct sf.common AS common, sf.elements_b AS elements_b  
 INTO joining 
 FROM njr r,njs s , LATERAL(SELECT t.common, t.elements_b FROM Map(r,s) t) sf;



DROP TABLE IF EXISTS joining_reduce;
SELECT distinct  s.common,(select array(select distinct d.elements_b from joining d where d.common = s.common 
  ))
INTO joining_reduce FROM joining s;



SELECT q.key_item,q.key_value,q.key_value2 FROM joining_reduce sr, LATERAL(SELECT * FROM reduce(sr.common,sr.elements_b)) q order by item;


