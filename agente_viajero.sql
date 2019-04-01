----SI TENEMOS MULTIPUNTO CONVERTIR A PUNTO, ¡¡¡CUIDADO!! DICHO QUERY TOMA EL PRIMER PUNTO, SI TIENES MÁS YA VASLITESS

ALTER TABLE red_chiapas_vertices_pgr
    ALTER COLUMN geom TYPE geometry(Point,32615) USING ST_GeometryN(geom, 1);




---- PROBLEMA DEL VENDEDOR VIAJERO
	--- SE ELIGEN LOS VALORES DE LOS NODOS A VISITAR (35490, 2441, 2438, 3571, 2445)
		---- DECIDIR EL NODO DE INICIO Y EL DE TÉRMINO
		
SELECT seq, id1, id2, round(cost::numeric, 2) AS cost
FROM pgr_tsp(
  'select id::int, st_x(geom) as x, st_y(geom) as y FROM
   red_chiapas_vertices_pgr  where id in (35490, 2441, 2438, 3571, 2445)',
  35490)

----- CREAR LA TABLA CON LA SECUENCIA DE NODOS A VISITAR

CREATE TABLE ruta as (
select p.id, orden.seq, p.geom
  from (SELECT seq, id1, id2,round(cost::numeric, 2) AS cost
  FROM pgr_tsp(
    'select id::int,
     st_x(geom) as x,
     st_y(geom) as y
     FROM red_chiapas_vertices_pgr where
     id in (5358, 18473, 11334, 2520, 2290)', 2290, 5358)) as orden
  join red_chiapas_vertices_pgr p
  on p.id = orden.id2)

---- VERIFICAR QUE NOS SALIÓ BIEN
SELECT * FROM ruta LIMIT 10

---- CREAR LA RUTA DESDE VARIOS NODOS. UNO A MUCHOS, MUCHOS A UNO, MUCHOS A MUCHOS

SELECT  b.geom, a.*
		from (select node, edge as id, cost
						from pgr_bdDijkstra('SELECT  id::int4, source::int4 ,target::int4 as target,  tiempo_2::float8 AS cost FROM  red_chiapas',
														 ARRAY[1111,111], ARRAY [2222,2222] ,FALSE)
												)  as a join red_chiapas b on a.id = b.id
								
----- UNIR LAS RUTAS

CREATE TABLE ruta_reparte as
(WITH path_1 AS (
        SELECT  b.geom, a.*
		from (select node, edge as id, cost
						from pgr_bdDijkstra('SELECT  id::int4, source::int4 ,target::int4 as target,  tiempo_2::float8 AS cost FROM  red_chiapas',
														 2290, 18473 ,FALSE)
												)  as a join red_chiapas b on a.id = b.id
		), path_2 AS (
        SELECT  b.geom, a.*
		from (select node, edge as id, cost
						from pgr_bdDijkstra('SELECT  id::int4, source::int4 ,target::int4 as target,  tiempo_2::float8 AS cost FROM  red_chiapas',
														 18473,11334,FALSE)
												)  as a join red_chiapas b on a.id = b.id 
		), path_3 AS (
        SELECT  b.geom, a.*
		from (select node, edge as id, cost
						from pgr_bdDijkstra('SELECT  id::int4, source::int4 ,target::int4 as target,  tiempo_2::float8 AS cost FROM  red_chiapas',
														 11334, 2520,FALSE)
												)  as a join red_chiapas b on a.id = b.id 
		),path_4 AS (
        SELECT  b.geom, a.*
		from (select node, edge as id, cost
						from pgr_bdDijkstra('SELECT  id::int4, source::int4 ,target::int4 as target,  tiempo_2::float8 AS cost FROM  red_chiapas',
														 2520,5358, FALSE)
												)  as a join red_chiapas b on a.id = b.id 
		)
SELECT * FROM path_1
union
SELECT * FROM  path_2
union
SELECT * FROM path_3
union
SELECT * FROM  path_4  )

--- FIN

