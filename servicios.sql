--4a) Proveer el mecanismo que crea más adecuado para que al ser invocado (una vez por mes),
--tome todos los servicios que son periódicos y genere la/s factura/s correspondiente/s.
--Indicar si se deben proveer parámetros adicionales para su generación.
--Explicar además cómo resolvería el tema de la invocación mensual (pero no lo implemente).


--El proceso de facturación debe ser el siguiente: a principio de mes se toman todos los
-- servicios periódicos que tenga cada cliente, junto con los remitos generados en el mes
-- anterior y confeccionar una o varias facturas. Vale la pena aclarar que, cuando se genera
-- la factura, los datos son copiados desde los remitos, servicios, etc. a la factura en sí;
-- esto es debido a que, si no se hiciera así, un cambio en el catálogo de servicios produciría
-- un cambio en todas las facturas.



CREATE OR REPLACE FUNCTION fn_4_a() RETURNS VOID AS $$
declare suma_servicios numeric(18,5);
        total numeric(18,5);
        fecha_actual timestamp;
        comprobante_factura int;
        aux_cliente int;
        equipos record;
        idcomp integer;
        linea int;
BEGIN
    fecha_actual = current_timestamp;
    comprobante_factura = (select id_tcomp from tipocomprobante where tipo like 'factura');

    -- consultamos la cantidad de comprobantes de tipo factura que estan cargados para generar una nueva clave
    -- que no se repita con las anteriores
    idcomp := (select count(*) from comprobante where id_tcomp = comprobante_factura);


    FOR aux_cliente IN(select distinct(c.id_cliente) from cliente c join equipo e on e.id_cliente = c.id_cliente)
        loop
              idcomp := idcomp + 1;
              linea := 1;
              suma_servicios := 0;

              -- insertamos en primer lugar el comprobante porque este es referenciado por las lineas de comprobante.
              -- El importe en principio vale 0
              insert into comprobante (id_comp, id_tcomp, fecha, comentario, estado, fecha_vencimiento, id_turno, importe, id_cliente)
              values (idcomp, comprobante_factura, fecha_actual, ' ', null, null, null, 0, aux_cliente);

              FOR equipos IN(select s.id_servicio as idservicio, s.costo as importeserv
                            from equipo e
                            join servicio s on s.id_servicio = e.id_servicio
                            where e.id_cliente = aux_cliente and s.periodico is true)
                    loop
                            insert into lineacomprobante (nro_linea, id_comp, id_tcomp, descripcion, cantidad, importe, id_servicio)
                            values (linea, idcomp, comprobante_factura, ' ', 1, equipos.importeserv, equipos.idservicio);
                            -- la cantidad es 1 porque un equipo puede tener asociado solo un tipo de servicio
                            linea := linea + 1;
                            suma_servicios := suma_servicios + equipos.importeserv;
                            -- a medida que insertamos las lineas de comprobante sumamos sus importes
                    END LOOP;

                -- finalmente modificamos el importe del comprobante con el valor de la suma de sus lineas
                update comprobante set importe = suma_servicios where id_comp = idcomp and id_tcomp = comprobante_factura;

        end loop;

END $$ LANGUAGE plpgsql;

select fn_4_a();

-----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--VERSION SIN REMITOS-----------------
-----------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_4_a() RETURNS VOID AS $$
declare suma_servicios numeric(18,5);
        suma_remitos numeric(18,5);
        total numeric(18,5);
        fecha_actual timestamp;
        comprobante_factura int;
        clientes int;
        equipos record;
        idcomp integer;
        linea int;
BEGIN
    fecha_actual = current_timestamp;

    comprobante_factura = (select id_tcomp from tipocomprobante where tipo like 'factura');

    idcomp := (select count(*) from comprobante where id_tcomp = comprobante_factura);

    FOR clientes IN(select distinct(e.id_cliente) from cliente c join equipo e on e.id_cliente = c.id_cliente)
        loop
              idcomp := idcomp + 1;
              linea := 1;

              insert into comprobante (id_comp, id_tcomp, fecha, comentario, estado, fecha_vencimiento, id_turno, importe, id_cliente)
              values (idcomp, comprobante_factura, fecha_actual, ' ', null, null, null, 0, clientes);


              FOR equipos IN(select s.id_servicio as idservicio, s.costo as importeserv
                            from equipo e
                            join servicio s on s.id_servicio = e.id_servicio
                            where e.id_cliente = clientes and s.periodico is true)
                    loop
                           insert into lineacomprobante (nro_linea, id_comp, id_tcomp, descripcion, cantidad, importe, id_servicio)
                           values (linea, idcomp, comprobante_factura, ' ', 1, equipos.importeserv, equipos.idservicio);
                           linea := linea + 1;
                    END LOOP;

                suma_servicios := (select sum(l.importe)
                             from lineacomprobante l
                             where l.id_comp = idcomp and l.id_tcomp = comprobante_factura);

                update comprobante set importe = suma_servicios where id_comp = idcomp and id_tcomp = comprobante_factura;

        end loop;

END $$ LANGUAGE plpgsql;

select fn_4_a();






--Las tareas programadas para que se ejecuten en cierto momento se llaman job.
--En PostgreSQL no existen los job como tal, con lo cual, para crear las tareas programadas tenemos que hacer uso de herramientas proporcionadas por el sistema operativo o con extensiones. De esta forma podemos crear los job dentro de una base de datos de nuestro servidor PostgreSQL.

--Herramientas del Sistema operativo: A nivel de sistema operativo, disponemos de herramientas diferentes dependiendo de la arquitectura utilizada. Para los sistemas operativos con arquitectura UNIX disponemos de la herramienta cron.
--Los sistemas operativos de Microsoft Windows tienen su propia herramienta, task manager, para poder crear las tareas programadas.

--Extensiones: Podemos utilizar herramientas externas para implementar job en PostgreSQL utilizando unas extensiones ya existentes.
--Estas herramientas permiten crear las tareas programadas directamente desde nuestra base de datos.


-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------

--4.b)Proveer el mecanismo que crea más adecuado para que al ser invocado retorne el inventario
-- consolidado de los equipos actualmente utilizados. Se necesita un listado que por lo menos tenga:
-- el nombre del equipo, el tipo, cantidad y si lo considera necesario puede agregar más datos.



CREATE OR REPLACE FUNCTION fn_4_B (out id_equipo int, out nombre varchar(80), out tipo_conexion varchar(20), out tipo_asignacion varchar(20), out cantidad integer)
RETURNS SETOF RECORD AS $$
    DECLARE
    lista RECORD;
BEGIN
    FOR lista IN(
                SELECT e.id_equipo as idequipo, e.nombre as nombre, e.tipo_conexion as tipoconexion, e.tipo_asignacion as tipoasignacion, count(*) as aux_cantidad
                FROM equipo e
                where e.fecha_baja is null or
                    (e.fecha_baja is not null and e.fecha_baja > current_timestamp)
                group by e.id_equipo, e.nombre, e.tipo_asignacion, e.tipo_conexion)
            loop
                id_equipo := lista.idequipo;
                nombre := lista.nombre;
                tipo_conexion := lista.tipoconexion;
                tipo_asignacion := lista.tipoasignacion;
                cantidad := lista.aux_cantidad;
            return next;
            end loop;
RETURN;
END$$ LANGUAGE plpgsql;


select * from fn_4_b ();

--4.c) Proveer el mecanismo que crea más adecuado para que al ser invocado entre dos fechas
-- cualesquiera dé un informe de los empleados junto con la cantidad de turnos resueltos por
-- localidad y los tiempos promedio y máximo del conjunto de cada uno.

--ASUMIMOS QUE EL CLIENTE SOLICITA UN TURNO DONDE EL PERSONAL PERTENCE A SU MISMA LOCALIDAD.
--ASUMIMOS QUE CUANDO EL ATRIBUTO 'HASTA' PERTENECIENTE A LA TABLA TURNO NO ES NULL ENTONCES EL TURNO FUE RESUELTO.
--ASUMIMOS QUE LOS TURNOS SE TERMINAN EN EL MISMO DIA, ES DECIR, TARDAN MENOS DE 24 HS.

CREATE OR REPLACE FUNCTION fn_4_c(fecha1 timestamp, fecha2 timestamp, out id_personal int, out turnos_resueltos_localidad int, out tiempo_promedio numeric(18,3), out turno_maximo_en_hs numeric(18,3))
RETURNS SETOF RECORD AS $$
    DECLARE

        lista RECORD;
BEGIN
    FOR lista IN(
                select p.id_personal as personal, count(*) as cantidad, avg(extract(hours from(t.hasta - t.desde))) as promedio, max(extract(hours from(t.hasta - t.desde))) as turno_mas_largo
                from personal p
                join turno t on p.id_personal = t.id_personal
                join direccion d on d.id_persona = p.id_personal
                join barrio b on d.id_barrio = b.id_barrio
                join ciudad c on b.id_ciudad = c.id_ciudad
                where t.hasta is not null
                and t.desde >= fecha1 and t.desde <= fecha2
                and t.hasta >= fecha1 and t.hasta <= fecha2
                group by p.id_personal, c.id_ciudad)
        loop
                id_personal := lista.personal;
                turnos_resueltos_localidad := lista.cantidad;
                tiempo_promedio := lista.promedio;
                turno_maximo_en_hs := lista.turno_mas_largo;
            return next;
    END LOOP;
    RETURN;
END$$ LANGUAGE plpgsql;

select * from fn_4_c ('2018-01-01', '2020-01-01');