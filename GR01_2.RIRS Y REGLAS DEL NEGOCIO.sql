-- RESTRICCIONES Y TRIGGERS

-- 2.A)
-- Si una persona está inactiva debe tener establecida una fecha
-- de baja, la cual se debe controlar que sea al menos 18 años posterior a la de nacimiento.
alter table Persona add constraint CHK_inactividad
check (((activo = 'false') and (fecha_baja is not null) and ((age(fecha_nacimiento) - age(fecha_baja)) >= '18 years'))
   or ((activo = 'true') and (fecha_baja is null)));

-- RESTRICCION DE TUPLA A LA TABLA PERSONA PARA LOS ATRIBUTOS ACTIVO, FECHA_BAJA, FECHA_NACIMIENTO

--Por ejemplo: los siguientes inserts no son aceptados
-- insert into persona values (1, 'Cliente', 'DNI', '40634222', 'Juan', 'Perez', '1995-07-07', null, null, false);
-- insert into persona values (2, 'Cliente', 'DNI', '40634222', 'Juan', 'Perez', '1995-07-07', '1996-07-07', null, false);
-- insert into persona values (3, 'Cliente', 'DNI', '40634222', 'Juan', 'Perez', '1995-07-07', '1996-07-07', null, true);

-- los siguientes inserts si los acepta
-- insert into persona values (4, 'Cliente', 'DNI', '40634222', 'Juan', 'Perez', '1995-07-07', null, null, true);
-- insert into persona values (5, 'Cliente', 'DNI', '40634222', 'Juan', 'Perez', '1995-07-07', '2019-07-07', null, false);



-- 2.B)
--  El importe de un comprobante debe coincidir con la suma
--  de los importes de sus líneas (si las tuviera).
create assertion CHK_importe_comprobante
check (NOT EXISTS (
                    select 1
                    from comprobante c
                    where c.importe != ( select coalesce(sum(lc.importe * lc.cantidad), 0)
                                         from lineacomprobante lc
                                         where c.id_comp = lc.id_comp and c.id_tcomp = lc.id_tcomp
                                         group by lc.id_comp, lc.id_tcomp);
					
-- Es una restriccion general por involucrar mas de una tabla. La manera de implementar este tipo de restricciones en Postgre
-- es con triggers y su correspondiente funcion

-- TABLA COMPROBANTE
                -- INSERT = NO
                -- UPDATE = SI --> IMPORTE
                -- DELETE = NO
-- TABLA LINEACOMPROBANTE
                -- INSERT = SI
                -- UPDATE = SI --> IMPORTE
                               --> ID_COMP
                               --> ID_TCOMP
                -- DELETE = SI


-- 2.C)
-- UN equipo puede tener asignada un IP, y en este caso, la MAC resulta requerida.
alter table Equipo add constraint CHK_ip_mac
check ((ip is not null) and (mac is not null)
   or (ip is null) and (mac is not null)
   or (ip is null) and (mac is null)
   );
-- RESTRICCION DE TUPLA A LA TABLA EQUIPO PARA LOS ATRIBUTOS IP, MAC

-- El siguiente insert no lo acepta
-- insert into equipo values (1000, 'router1', null, '192.168.1.1', 'ap1000', 100, 1, '2020-03-22', null, 'pptp', 'dhcp');

--Los siguientes inserts si los acepta
-- insert into equipo values (1003, 'router1', null, null, 'ap1000', 100, 1, '2020-03-22', null, 'pptp', 'dhcp');
-- insert into equipo values (1004, 'router1', '00:1A:33:11:3A:A7', null, 'ap1000', 100, 1, '2020-03-22', null, 'pptp', 'dhcp');


-- 2.D)
-- Las IPs asignadas a los equipos no pueden ser compartidas entre clientes.
alter table chk_clientes_IP
check (not exist (
    select 1
    from equipo e1
    join equipo e2 on e1.id_cliente != e2.id_cliente
    where e1.ip = e2.ip
)

create or replace function fn_ips_asignadas() returns trigger as $$
declare aux_ip equipo.ip%type;
begin
    select e.ip into aux_ip
    from equipo e
    where e.id_cliente != new.id_cliente;
    if (aux_ip = new.ip) then
       raise exception 'ERROR AL ACTUALIZAR YA EXISTE EL IP ASIGNADO A OTRO CLIENTE';
   end if;
   return new;
end; $$ LANGUAGE 'plpgsql';


create trigger tr_ips_asignadas
    before update of ip, id_cliente or insert
    on equipo
    for each row
    execute procedure fn_ips_asignadas();

-- ASUMIMOS QUE UN MISMO CLIENTE PUEDE TENER EQUIPOS CON IPS IGUALES Y DISTINTAS

-- TABLA EQUIPO
            -- INSERT = SI
            -- UPDATE = SI --> IP
                           --> ID_CLIENTE
            -- DELETE = NO

-- EN CASO DE MODIFICARSE LA IP DE UN EQUIPO QUE YA ESTA CARGADO DEBE VERIFICARSE QUE ESTA NO PERTENEZCA
-- A OTRO CLIENTE

-- EN CASO DE QUE EL EQUIPO PASE A PERTENECER A OTRO CLIENTE DEBE CHEQUEARSE QUE LA IP DE ESTE EQUIPO NO
-- EXISTA ENTRE LAS IPS DEL CLIENTE ANTERIOR

-- Ejemplo insert: Si cargamos dos equipos con clientes diferentes (cliente 1 y 2) e ips iguales (192.168.1.1), rechaza la operacion
-- insert into equipo values (1001, 'router2', '00:1A:33:11:3A:A7', '192.168.1.1', 'ap1001', 100, 1, '2020-04-15', null, 'pptp', 'dhcp');
-- insert into equipo values (1002, 'router2', '00:1A:33:11:3A:A7', '192.168.1.1', 'ap1001', 100, 2, '2020-04-15', null, 'pptp', 'dhcp'); 

-- Ejemplo update ip: en caso de quererle cambiar la ip al equipo del cliente 2 por la ip del cliente 1, rechaza la operacion
-- insert into equipo values (1001, 'router2', '00:1A:33:11:3A:A7', '192.168.1.1', 'ap1001', 100, 1, '2020-04-15', null, 'pptp', 'dhcp');
-- insert into equipo values (1002, 'router2', '00:1A:33:11:3A:A7', '192.168.1.2', 'ap1001', 100, 2, '2020-04-15', null, 'pptp', 'dhcp');
-- update equipo set ip = '192.168.1.1' where id_equipo = 1002;

-- Ejemplo update id_cliente: al querer cambiarle el cliente a un equipo, no permite que conserve la misma ip del cliente anterior
-- insert into equipo values (1000, 'router1', '00:1A:33:11:3A:A7', '192.168.1.1', 'ap1000', 100, 1, '2020-03-22', null, 'pptp', 'dhcp');
-- insert into equipo values (1001, 'router2', '00:1A:33:11:3A:A7', '192.168.1.1', 'ap1001', 100, 1, '2020-04-15', null, 'pptp', 'dhcp');
-- update equipo set id_cliente = 2 where id_equipo = 1001;


-- 2.E)
-- No se pueden instalar más de 25 equipos por Barrio.
CREATE ASSERTION CHK_CANT_EQUIPOS_BARRIOR
CHECK(NOT EXIST(
    select d.id_barrio, count(*)
    from equipo e
    join direccion d on d.id_persona = e.id_cliente
    group by d.id_barrio
    having count(*) > 25;
    )
)

create or replace function fn_cant_equipo_barrio() returns trigger as $$
begin
    if (exists (
            select d.id_barrio, count(*)
            from equipo e
            join direccion d on d.id_persona = e.id_cliente
            where d.id_persona = new.id_cliente
            group by d.id_barrio
            -- compara por menor igual por usar before en el trigger
            having count(*) >= 25
        )   ) then
       raise exception 'ERROR AL ACTUALIZAR SUPERA LA CANTIDAD DE EQUIPOS POR BARRIO';
    end if;
   return new;
end; $$ LANGUAGE 'plpgsql';


create trigger tr_cant_equipo_barrio
    before update of id_cliente or insert
    on equipo
    for each row
    execute procedure fn_cant_equipo_barrio();
	
	-- TABLA EQUIPO
            -- INSERT = SI
            -- UPDATE = SI --> ID_CLIENTE
            -- DELETE = NO