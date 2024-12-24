# SQL
Trabajo final de la material Bases de datos

El Trabajo Práctico Especial (TPE) consiste en la resolución de un conjunto de controles y servicios sobre una base de datos que mantiene un sistema para un Wireless Internet Service Provider, según las consignas y pautas que se indican.

Descripción resumida del Sistema:

- La empresa posee clientes dispersos en diferentes localidades de la provincia; adicionalmente cada cliente puede poseer varios puntos de conexión (equipos).
- De cada punto de conexión a la red, es necesario registrar las características del equipo: nombre (marca, modelo, etc.), tipo de conexión (PPTP, PPPoE) y tipo de asignación IP (DHCP, IP FIJA).
- Es necesario mantener todos los datos de los clientes, a fin de poder registrar los servicios que deberán ser abonados cada mes. En cualquier momento el cliente puede solicitar la baja, quedando inactivo, siempre y cuando no adeude ningún servicio.
- El sistema tiene un catálogo de todos los servicios que ofrece. Estos son de 2 tipos: unos que se cobran en forma periódica y otros que se cobran por única vez cuando se realizan. Por ejemplo, son servicios periódicos los servicios de internet de diferentes anchos de banda, direcciones IP, antivirus, los cuales tendrán un importe por mes; entre los no periódicos están incluidos los de reparación de equipos y el servicio técnico al domicilio de instalación, entre otros.
- El sistema contempla la facturación de los servicios que provee la empresa, estos son: los servicios de cobro periódico y de cobro por única vez.
- El sistema maneja comprobantes de varios tipos, entre los cuales se destacan los siguientes: facturas, recibos y remitos.
  - Una Factura es el documento que se le da al cliente detallando un cobro por parte de la empresa; cada línea de esta detalla lo que se le está cobrando.
  - Un Recibo es el comprobante que se le da al cliente por el dinero que ingresa a la empresa; este dinero junto con las facturas conformarán la cuenta corriente del mismo.
  - Los Remitos son documentos que se entregan a los clientes por trabajos realizados que luego serán facturados. Por ejemplo, si un técnico va al domicilio de instalación del servicio, genería un remito potencialmente con dos líneas: una con la visita en sí y otra con la reparación que hizo. El costo de cada servicio deberá estar especificado en el catálogo de servicios.

El proceso de facturación debe ser el siguiente: a principio de mes se toman todos los servicios periódicos que tenga cada cliente, junto con los remitos generados en el mes anterior y se confeccionan una o varias facturas. Vale la pena aclarar que, cuando se genera la factura, los datos son copiados desde los remitos, servicios, etc. a la factura en sí; esto es debido a que, si no se hiciera así, un cambio en el catálogo de servicios produciría un cambio en todas las facturas.

A partir del anterior esquema de la BD se requiere resolver los siguientes ítems:

1. **Consultas**
   Resolver las siguientes consultas SQL:

   a. Mostrar el listado de todos los clientes registrados en el sistema (id, apellido y nombre, tipo y número de documento, fecha de nacimiento) junto con la cantidad de equipos registrados que cada uno dispone, ordenado por apellido y nombre.

   b. Realizar un ranking (de mayor a menor) de la cantidad de equipos instalados y aún activos, durante los últimos 24 meses, según su distribución geográfica, mostrando: nombre de ciudad, id de la ciudad, nombre del barrio, id del barrio y cantidad de equipos.

   c. Visualizar el Top-3 de los lugares donde se ha realizado la mayor cantidad de servicios periódicos durante los últimos 3 años.

   d. Indicar el nombre, apellido, tipo y número de documento de los clientes que han contratado todos los servicios periódicos cuyo intervalo se encuentra entre 5 y 10.

2. **Elaboración de restricciones y reglas del negocio**

   Para cada una de las restricciones/reglas del negocio en el esquema de datos:

   - Escribir la restricción de la manera que considere más apropiada en SQL estándar declarativo, indicando su tipo y justificación correspondiente.
   - Para los 3 últimos controles (c, d, e), implementar la restricción en PostgreSQL de la forma más adecuada, según las posibilidades que ofrece el DBMS.

   a. Si una persona está inactiva debe tener establecida una fecha de baja, la cual se debe controlar que sea al menos 18 años posterior a la de nacimiento.
   
   b. El importe de un comprobante debe coincidir con la suma de los importes de sus líneas (si las tuviera).

   c. Un equipo puede tener asignada un IP, y en este caso, la MAC resulta requerida.

   d. Las IPs asignadas a los equipos no pueden ser compartidas entre clientes.

   e. No se pueden instalar más de 25 equipos por Barrio.

3. **Definición de vistas**

   Escribir la sentencia SQL para crear las vistas detalladas a continuación. Indicar y justificar si es actualizable o no en PostgreSQL, indicando la/s causa/s.

   - Para la/s vista/s actualizable/s, provea una sentencia que provoque diferente comportamiento según la vista tenga o no especificada la opción With Check Option, y analice dichos comportamientos.

   - Para una de la/s vista/s no actualizable/s, implemente los triggers "instead of" necesarios para su actualización. Plantee una sentencia que provoque su activación y explique la propagación de dicha actualización.

   a. Realice una vista que contenga el saldo de cada uno de los clientes que tengan domicilio en la ciudad ‘X’.

   b. Realice una vista con la lista de servicios activos que posee cada cliente junto con el costo del mismo al momento de consultar la vista.

   c. Realice una vista que contenga, por cada uno de los servicios periódicos registrados, el monto facturado mensualmente durante los últimos 5 años, ordenado por servicio, año, mes y monto.

4. **Servicios (utilizando Vistas, Procedimientos y/o Funciones)**

   a. Proveer el mecanismo que crea más adecuado para que al ser invocado (una vez por mes), tome todos los servicios que son periódicos y genere la/s factura/s correspondiente/s. Indicar si se deben proveer parámetros adicionales para su generación. Explicar además cómo resolvería el tema de la invocación mensual (pero no lo implemente).

   b. Proveer el mecanismo que crea más adecuado para que al ser invocado retorne el inventario consolidado de los equipos actualmente utilizados. Se necesita un listado que por lo menos tenga: el nombre del equipo, el tipo, cantidad y si lo considera necesario puede agregar más datos.

   c. Proveer el mecanismo que crea más adecuado para que al ser invocado entre dos fechas cualesquiera dé un informe de los empleados junto con la cantidad de turnos resueltos por localidad y los tiempos promedio y máximo del conjunto de cada uno.

