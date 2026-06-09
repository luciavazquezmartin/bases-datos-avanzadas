-- ==========================================================
-- Script:      bd-postgresql-integrada-fdw.sql
-- SGBD:        PostgreSQL
-- Depende de:  bd_aeropuerto_esq1 (bd-postgresql-esquema1-p3.sql)
--              bd_aeropuerto_esq2 (bd-postgresql-esquema2-p3.sql)
-- Propósito:   Integración de los dos esquemas relacionales en una
--              vista unificada mediante postgres_fdw
-- Contenido:
--   1. Limpieza del entorno
--   2. Instalación de la extensión postgres_fdw
--   3. Configuración de servidores remotos y mapeos de usuario
--   4. Creación del esquema integrador aeropuerto_global
--   5. Importación de esquemas remotos como tablas foráneas
--   6. Creación de vistas unificadas sobre ambos esquemas
-- ==========================================================

-- ==========================================================
-- LIMPIEZA DEL ENTORNO
-- ==========================================================

-- Elimina las vistas globales si ya existían de una ejecución anterior
DROP VIEW IF EXISTS aeropuerto_global.persona CASCADE;
DROP VIEW IF EXISTS aeropuerto_global.pasajero CASCADE;
DROP VIEW IF EXISTS aeropuerto_global.tripulacion CASCADE;
DROP VIEW IF EXISTS aeropuerto_global.aerolinea CASCADE;
DROP VIEW IF EXISTS aeropuerto_global.aeropuerto CASCADE;
DROP VIEW IF EXISTS aeropuerto_global.vuelo CASCADE;
DROP VIEW IF EXISTS aeropuerto_global.reserva CASCADE;
DROP VIEW IF EXISTS aeropuerto_global.participa_en CASCADE;

-- Elimina los esquemas foráneos importados si ya existían
DROP SCHEMA IF EXISTS fdw_esq1 CASCADE;
DROP SCHEMA IF EXISTS fdw_esq2 CASCADE;

-- Elimina los servidores remotos si ya existían; CASCADE elimina también
-- los mapeos de usuario y las tablas foráneas asociadas
DROP SERVER IF EXISTS srv_esq1 CASCADE;
DROP SERVER IF EXISTS srv_esq2 CASCADE;

-- Elimina el esquema integrador si ya existía
DROP SCHEMA IF EXISTS aeropuerto_global CASCADE;

-- ==========================================================
-- EXTENSIÓN
-- ==========================================================

-- Instala postgres_fdw si no está instalada; esta extensión permite
-- acceder a tablas de bases de datos remotas como si fueran locales
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- ==========================================================
-- SERVIDORES REMOTOS
-- ==========================================================

-- Define el servidor remoto que apunta a la base de datos del esquema 1.
-- host=localhost indica que ambas bases de datos están en el mismo servidor
CREATE SERVER srv_esq1
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', dbname 'bd_aeropuerto_esq1', port '5432');

-- Define el servidor remoto que apunta a la base de datos del esquema 2
CREATE SERVER srv_esq2
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', dbname 'bd_aeropuerto_esq2', port '5432');

-- ==========================================================
-- MAPEOS DE USUARIO
-- ==========================================================

-- Asocia el usuario local 'alumno' con las credenciales necesarias
-- para conectarse al servidor remoto del esquema 1
CREATE USER MAPPING FOR alumno
    SERVER srv_esq1
    OPTIONS (user 'alumno', password 'alumno123');

-- Asocia el usuario local 'alumno' con las credenciales necesarias
-- para conectarse al servidor remoto del esquema 2
CREATE USER MAPPING FOR alumno
    SERVER srv_esq2
    OPTIONS (user 'alumno', password 'alumno123');

-- ==========================================================
-- ESQUEMA INTEGRADOR
-- ==========================================================

-- Crea el esquema donde vivirán las tablas foráneas importadas
-- y las vistas unificadas
CREATE SCHEMA aeropuerto_global;

-- Crear esquemas donde se importarán las tablas foráneas
CREATE SCHEMA fdw_esq1;
CREATE SCHEMA fdw_esq2;

-- ==========================================================
-- IMPORTACIÓN DE ESQUEMAS REMOTOS
-- ==========================================================

-- Importa todas las tablas del esquema aeropuerto_esq1 de la base de datos
-- remota como tablas foráneas accesibles bajo el esquema local fdw_esq1
IMPORT FOREIGN SCHEMA aeropuerto_esq1
    FROM SERVER srv_esq1
    INTO fdw_esq1;

-- Importa todas las tablas del esquema aeropuerto_esq2 de la base de datos
-- remota como tablas foráneas accesibles bajo el esquema local fdw_esq2
IMPORT FOREIGN SCHEMA aeropuerto_esq2
    FROM SERVER srv_esq2
    INTO fdw_esq2;

-- ==========================================================
-- VISTAS UNIFICADAS
-- ==========================================================

-- Vista unificada de personas de ambos esquemas.
-- El esquema 1 almacena nombre y apellidos en campos separados;
-- el esquema 2 los almacena en un único campo nombre_completo,
-- por lo que se descompone mediante split_part y array de palabras
CREATE OR REPLACE VIEW aeropuerto_global.persona AS
SELECT
    p.pasaporte,
    p.nombre,
    split_part(p.apellidos, ' ', 1) AS apellido1,
    CASE
        WHEN p.apellidos LIKE '% %'
        THEN substr(p.apellidos, length(split_part(p.apellidos, ' ', 1)) + 2)
        ELSE NULL
    END AS apellido2,
    p.telefono
FROM fdw_esq1.persona p

UNION

SELECT
    p2.num_pasaporte AS pasaporte,
    -- La primera palabra de nombre_completo se toma como nombre
    split_part(p2.nombre_completo, ' ', 1) AS nombre,
    -- La segunda palabra se toma como primer apellido
    CASE
        WHEN array_length(string_to_array(p2.nombre_completo, ' '), 1) >= 2
        THEN split_part(p2.nombre_completo, ' ', 2)
        ELSE NULL
    END AS apellido1,
    -- El resto de palabras a partir de la tercera se toman como segundo apellido
    CASE
        WHEN array_length(string_to_array(p2.nombre_completo, ' '), 1) >= 3
        THEN array_to_string((string_to_array(p2.nombre_completo, ' '))[3:], ' ')
        ELSE NULL
    END AS apellido2,
    p2.num_contacto AS telefono
FROM fdw_esq2.persona p2;

-- Vista unificada de pasajeros.
-- En el esquema 1 se filtra por tipo_persona = 'Pasajero';
-- en el esquema 2 los pasajeros tienen su propia tabla
CREATE OR REPLACE VIEW aeropuerto_global.pasajero AS
SELECT
    p.pasaporte,
    p.nacionalidad
FROM fdw_esq1.persona p
WHERE p.tipo_persona = 'Pasajero'

UNION

SELECT
    pa.num_pasaporte AS pasaporte,
    pa.nacionalidad
FROM fdw_esq2.pasajero pa;

-- Vista unificada de tripulación.
-- En el esquema 1 se filtra por tipo_persona = 'Tripulacion';
-- en el esquema 2 la tripulación tiene su propia tabla Miembro_tripulacion
CREATE OR REPLACE VIEW aeropuerto_global.tripulacion AS
SELECT
    p.pasaporte,
    p.puesto,
    p.anyos_experiencia
FROM fdw_esq1.persona p
WHERE p.tipo_persona = 'Tripulacion'

UNION

SELECT
    mt.num_pasaporte AS pasaporte,
    mt.puesto,
    mt.anyos_exp AS anyos_experiencia
FROM fdw_esq2.miembro_tripulacion mt;

-- Vista unificada de aerolíneas.
-- El esquema 1 usa el campo iata_aerolinea;
-- el esquema 2 usa codigo_oficial para el mismo concepto
CREATE OR REPLACE VIEW aeropuerto_global.aerolinea AS
SELECT
    a.iata_aerolinea AS codigo_aerolinea,
    a.nombre,
    a.pais
FROM fdw_esq1.aerolinea a

UNION

SELECT
    c.codigo_oficial AS codigo_aerolinea,
    c.nombre,
    c.pais
FROM fdw_esq2.compania_aerea c;

-- Vista unificada de aeropuertos.
-- Ambos esquemas tienen la misma estructura para aeropuertos,
-- solo difieren en el nombre del campo de la clave primaria
CREATE OR REPLACE VIEW aeropuerto_global.aeropuerto AS
SELECT
    a.iata_aeropuerto AS codigo_aeropuerto,
    a.nombre,
    a.ciudad,
    a.pais
FROM fdw_esq1.aeropuerto a

UNION

SELECT
    a2.codigo_aeropuerto,
    a2.nombre,
    a2.ciudad,
    a2.pais
FROM fdw_esq2.aeropuerto a2;

-- Vista unificada de vuelos.
-- El esquema 1 almacena fecha y hora por separado; se combinan mediante
-- el operador + para obtener un TIMESTAMP equivalente al del esquema 2
CREATE OR REPLACE VIEW aeropuerto_global.vuelo AS
SELECT
    v.codigo_vuelo,
    (v.fecha_salida + v.hora_salida) AS fecha_hora_salida,
    (v.fecha_llegada + v.hora_llegada) AS fecha_hora_llegada,
    v.iata_aerolinea AS codigo_aerolinea,
    v.iata_origen AS codigo_origen,
    v.iata_destino AS codigo_destino
FROM fdw_esq1.vuelo v

UNION

SELECT
    v2.num_vuelo AS codigo_vuelo,
    v2.datetime_salida AS fecha_hora_salida,
    v2.datetime_llegada AS fecha_hora_llegada,
    v2.codigo_oficial AS codigo_aerolinea,
    v2.codigo_origen,
    v2.codigo_destino
FROM fdw_esq2.vuelo v2;

-- Vista unificada de reservas y billetes.
-- El esquema 1 usa la tabla Reserva con los campos asiento y clase;
-- el esquema 2 usa Billete_emitido con butaca y categoria_viaje para el mismo concepto
CREATE OR REPLACE VIEW aeropuerto_global.reserva AS
SELECT
    r.pasaporte,
    r.codigo_vuelo,
    r.asiento,
    r.clase
FROM fdw_esq1.reserva r

UNION

SELECT
    b.num_pasaporte AS pasaporte,
    b.num_vuelo AS codigo_vuelo,
    b.butaca AS asiento,
    b.categoria_viaje AS clase
FROM fdw_esq2.billete_emitido b;

-- Vista unificada de participación de tripulación en vuelos.
-- El esquema 1 usa la tabla Participa_en con el campo rol;
-- el esquema 2 usa Asignacion_laboral con funcion_en_vuelo para el mismo concepto
CREATE OR REPLACE VIEW aeropuerto_global.participa_en AS
SELECT
    p.pasaporte,
    p.codigo_vuelo,
    p.rol
FROM fdw_esq1.participa_en p

UNION

SELECT
    a.num_pasaporte AS pasaporte,
    a.num_vuelo AS codigo_vuelo,
    a.funcion_en_vuelo AS rol
FROM fdw_esq2.asignacion_laboral a;