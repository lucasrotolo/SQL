--CONSULTA 1
-- Mostrar el listado de todos los clientes registrados en el sistema
-- (id, apellido y nombre, tipo y número de documento, fecha de nacimiento)
-- junto con la cantidad de equipos registrados que cada uno dispone, ordenado por apellido y nombre.

select c.id_cliente, (p.apellido || ' ' || p.nombre) as apellido_nombre, (p.tipodoc || ' ' || p.nrodoc) as documento, p.fecha_nacimiento, count(*) as cantidad_equipos
from cliente c
join persona p on c.id_cliente = p.id_persona
join equipo e on c.id_cliente = e.id_cliente
group by c.id_cliente, p.apellido, p.nombre, p.tipodoc, p.nrodoc, p.fecha_nacimiento
order by p.apellido, p.nombre;


--CONSULTA 2
-- Realizar un ranking (de mayor a menor) de la cantidad de equipos instalados
-- y aún activos, durante los últimos 24 meses, según su distribución geográfica,
-- mostrando: nombre de ciudad, id de la ciudad, nombre del barrio, id del barrio y cantidad de equipos.


select c.nombre, c.id_ciudad, b.nombre, b.id_barrio, count(*)
from cliente cl
join direccion d on d.id_persona = cl.id_cliente
join barrio b on d.id_barrio = b.id_barrio
join ciudad c on b.id_ciudad = c.id_ciudad
join equipo e on cl.id_cliente = e.id_cliente
group by c.nombre, c.id_ciudad, b.nombre, b.id_barrio, e.fecha_baja, e.fecha_alta
having (e.fecha_baja is null or e.fecha_baja > current_timestamp) and age(e.fecha_alta) <= '2 years'
order by count(*) desc;


--CONSULTA 3
--Visualizar el Top-3 de los lugares donde se ha realizado la mayor cantidad de servicios
--periódicos durante los últimos 3 años.

select c.id_ciudad, c.nombre, count(*)
from equipo e
join servicio s on s.id_servicio = e.id_servicio
join direccion d on e.id_cliente = d.id_persona
join barrio b on d.id_barrio = b.id_barrio
join ciudad c on b.id_ciudad = c.id_ciudad
where s.periodico is true and age(e.fecha_alta) <= '3years'
group by c.id_ciudad, c.nombre
order by count(*) desc
limit 3;

-- CONSULTA 4
-- Indicar el nombre, apellido, tipo y número de documento de los clientes
-- que han contratado todos los servicios periódicos cuyo intervalo se encuentra entre 5 y 10


select p.nombre, p.apellido, p.tipodoc, p.nrodoc, count (distinct(e.id_servicio))
from persona p
join equipo e on p.id_persona = e.id_cliente
join servicio s on s.id_servicio = e.id_servicio
where (periodico = 'yes') and (intervalo >= 5) and (intervalo <= 10)
group by p.nombre, p.apellido, p.tipodoc, p.nrodoc
having count (distinct(e.id_servicio)) = (select count(*)
                   from servicio
                   where (periodico = 'yes') and (intervalo >= 5) and (intervalo <= 10)
                  );
