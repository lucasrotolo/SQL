-- A)Realice una vista que contenga el saldo de cada uno de los clientes que tengan domicilio en la ciudad ‘X’

create or replace view cliente_dom_x as
  select c.id_cliente, c.saldo
  from cliente c
  where c.id_cliente in (select id_persona
						from direccion
                         where id_barrio in (select barrio.id_barrio 
											from barrio
											where id_ciudad in (select id_ciudad 
																from ciudad
																where nombre like 'X')))
  with local check option ;



--A) Esta vista es actualizable porque:
   --conserva todas las columnas de la clave primaria (id_cliente)
   --no contiene funciones de agregación o información derivada (no hay ensamble de tablas)
   --no incluye la cláusula DISTINCT
   --no incluye subconsultas en el SELECT

--Si la vista no tiene chequeo de opciones(local o cascaded), procede y lo inserta en la tabla base
--(migracion de tupla), sin controlar las restricciones que la vista tenga.
--Si la vista tiene chequeo local o en cascada, verifica que cumpla las restricciones de la vista.
--Si cumple propaga la insercion a la tabla base, de lo contrario no procede.
--Para la siguiente sentencia la cual no pertenece a la ciudad 'x', para el primer caso procede, pero
-- para el segunda caso no procede.
insert into cliente_dom_x values (6,0);




-- B)Realice una vista con la lista de servicios activos que posee cada cliente
-- junto con el costo del mismo al momento de consultar la vista.


create or replace view cliente_activo_costo as
   select e.id_cliente, s.id_servicio, s.nombre, s.periodico, s.costo, s.intervalo, s.tipo_intervalo, s.activo, s.id_cat
   from equipo e
   join servicio s on e.id_servicio = s.id_servicio
   where s.activo is true;

-- B) No es automaticamente actualizable en PostgreSQL por ensamble de tablas.


create or replace function fn_cliente_activo_costo_insert() returns trigger AS $$
begin
    if(new.activo is true) then
        insert into servicio values (new.id_servicio, new.nombre, new.periodico, new.costo, null, null, true,  new.id_cat);
    end if;

    return new;
end $$ language 'plpgsql';

create trigger tg_insert_cliente_activo_costo
   instead of insert on cliente_activo_costo
   for each row execute procedure fn_cliente_activo_costo_insert();


insert into cliente_activo_costo (id_cliente, id_servicio, nombre, periodico, costo, intervalo, tipo_intervalo, activo, id_cat)                              values (6, 1, ' ', true, 300, null, null, true, 1111);
-- Suponemos que el Servicio no existe y la Categoria si, caso contrario saltaria error de RIR.
-- Cuando se ejecute la sentencia de insert, se activa el trigger "tg_insert_cliente_activo_costo"
-- que ejecuta la funcion "fn_cliente_activo_costo_insert()" la cual insertara sobre la tabla servicio siempre y cuando
-- el servicio que se inserta este activo.




create or replace function fn_cliente_activo_costo_delete() returns trigger AS $$
begin
   delete from servicio s where s.id_servicio = old.id_servicio;
    return old;
end $$ language 'plpgsql';

create trigger tg_delete_cliente_activo_costo
   instead of delete on cliente_activo_costo
   for each row execute procedure fn_cliente_activo_costo_delete();

delete from cliente_activo_costo where id_servicio = 100;

-- Suponemos que el Servicio existe, caso contrario saltaria error de RIR.
-- Cuando se ejecuta la sentencia de delete, se activa el trigger "tg_delete_cliente_activo_costo"
-- que ejecuta la funcion "fn_cliente_activo_costo_delete()" la cual elimina sobre la tabla servicio.


create or replace function fn_cliente_activo_costo_update() returns trigger AS $$
declare
    aux_equipo int;
    lineacomp record;
begin
        update servicio set
                id_servicio = new.id_servicio,
                nombre = new.nombre,
                periodico = new.periodico,
                costo = new.costo,
                intervalo = new.intervalo,
                tipo_intervalo = new.tipo_intervalo,
                id_cat = new.id_cat
        where id_servicio = new.id_servicio;


        if (old.id_servicio <> new.id_servicio) then
            FOR aux_equipo IN(select id_equipo from equipo where id_servicio = old.id_servicio)
            loop
                  update equipo set id_servicio = new.id_servicio where id_equipo = aux_equipo;
            end loop;

            FOR lineacomp IN(select nro_linea as nrolinea, id_comp as idcomp, id_tcomp as idtcomp
                            from lineacomprobante
                            where id_servicio = old.id_servicio)
            loop
                  update lineacomprobante set id_servicio = new.id_servicio where nro_linea = lineacomp.nrolinea
                                                                                    and id_comp = lineacomp.idcomp
                                                                                         and id_tcomp = lineacomp.idtcomp;
            end loop;

        end if;

    return new;
end $$ language 'plpgsql';

create trigger tg_update_cliente_activo_costo
   instead of update on cliente_activo_costo
   for each row execute procedure fn_cliente_activo_costo_update();
   

update cliente_activo_costo set id_servicio = 101 where id_servicio = 100;   
   
-- Suponemos que el serivicio 100 y 101 existen, caso contrario saltaria error de RIR.
-- Cuando se ejecuta la sentencia de update, se activa el trigger "tg_update_cliente_activo_costo"
-- que ejecuta la funcion "fn_cliente_activo_costo_update()" la cual modifica sobre la tabla servicio.



-- C)Realice una vista que contenga, por cada uno de los servicios periódicos
-- registrados, el monto facturado mensualmente durante los últimos 5 años ordenado
-- por servicio, año, mes y monto.

create or replace view vw_3_c as
  select extract(month from c.fecha)as mes, l.id_servicio, sum(l.importe * l.cantidad)as importe_total
  from tipocomprobante t join comprobante c on t.id_tcomp = c.id_tcomp
  join lineacomprobante l on c.id_comp = l.id_comp and c.id_tcomp = l.id_tcomp
  where l.id_servicio in (select s.id_servicio
                          from servicio s
                          where s.periodico is true) and c.fecha >= current_date-INTERVAL '5 year' and
                                                     t.tipo like 'factura'
  group by extract(month from c.fecha), l.id_servicio, extract(year from c.fecha)
  order by l.id_servicio, extract(year from c.fecha), extract(month from c.fecha), sum(l.importe);

-- C) No es automaticamente actualizable en PostgreSQL por ensamble de tablas y por usar una funcion de agregacion.
-- Ante una accion de actualizacion sobre la tabla, el DBMS no es capaz de determinar la tabla de base a ser actualizada.