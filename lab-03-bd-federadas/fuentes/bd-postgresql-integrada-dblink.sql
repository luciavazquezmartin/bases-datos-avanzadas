-- ==========================================================
-- Script:      bd-postgresql-integrada-dblink.sql
-- SGBD:        PostgreSQL
-- Depende de:  bd_aeropuerto_esq1 (bd-postgresql-esquema1-p3.sql)
--              bd_aeropuerto_esq2 (bd-postgresql-esquema2-p3.sql)
-- Propósito:   Integración de los dos esquemas relacionales en una
--              vista unificada mediante dblink
-- Contenido:
--   1. Limpieza del entorno
--   2. Instalación de la extensión dblink
--   3. Creación del esquema integrador aeropuerto_global
--   4. Creación de vistas unificadas sobre ambos esquemas
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

-- Elimina el esquema integrador si ya existía
DROP SCHEMA IF EXISTS aeropuerto_global CASCADE;

-- ==========================================================
-- EXTENSIÓN
-- ==========================================================

-- Instala dblink si no está instalada; esta extensión permite ejecutar
-- consultas SQL en bases de datos remotas mediante conexiones explícitas
CREATE EXTENSION IF NOT EXISTS dblink;

-- ==========================================================
-- ESQUEMA INTEGRADOR
-- ==========================================================

-- Crea el esquema donde vivirán las vistas unificadas
CREATE SCHEMA aeropuerto_global;

-- ==========================================================
-- VISTAS UNIFICADAS
-- ==========================================================
-- A diferencia de postgres_fdw, dblink no importa tablas foráneas
-- de forma permanente. Cada vista abre su propia conexión al servidor
-- remoto en tiempo de consulta y ejecuta el SQL como texto.
-- La cadena de conexión y la consulta remota se pasan como argumentos
-- a la función dblink(), que devuelve un conjunto de filas que hay
-- que tipar explícitamente en la cláusula AS.

-- Vista unificada de personas de ambos esquemas.
-- El esquema 1 almacena nombre y apellidos en campos separados;
-- el esquema 2 los almacena en un único campo nombre_completo,
-- por lo que se descompone mediante split_part y array de palabras
CREATE OR REPLACE VIEW aeropuerto_global.persona AS
SELECT
    pasaporte,
    nombre,
    split_part(apellidos, ' ', 1) AS apellido1,
    CASE
        WHEN apellidos LIKE '% %'
        THEN substr(apellidos, length(split_part(apellidos, ' ', 1)) + 2)
        ELSE NULL
    END AS apellido2,
    telefono
FROM dblink(
    'dbname=bd_aeropuerto_esq1 user=alumno password=alumno123',
    'SELECT pasaporte, nombre, apellidos, telefono
     FROM aeropuerto_esq1.persona'
) AS t(
    pasaporte    VARCHAR(20),
    nombre       VARCHAR(100),
    apellidos    VARCHAR(150),
    telefono     VARCHAR(20)
)

UNION

SELECT
    num_pasaporte AS pasaporte,
    -- La primera palabra de nombre_completo se toma como nombre
    split_part(nombre_completo, ' ', 1) AS nombre,
    -- La segunda palabra se toma como primer apellido
    CASE
        WHEN array_length(string_to_array(nombre_completo, ' '), 1) >= 2
        THEN split_part(nombre_completo, ' ', 2)
        ELSE NULL
    END AS apellido1,
    -- El resto de palabras a partir de la tercera se toman como segundo apellido
    CASE
        WHEN array_length(string_to_array(nombre_completo, ' '), 1) >= 3
        THEN array_to_string((string_to_array(nombre_completo, ' '))[3:], ' ')
        ELSE NULL
    END AS apellido2,
    num_contacto AS telefono
FROM dblink(
    'dbname=bd_aeropuerto_esq2 user=alumno password=alumno123',
    'SELECT num_pasaporte, nombre_completo, num_contacto
     FROM aeropuerto_esq2.persona'
) AS t(
    num_pasaporte    VARCHAR(20),
    nombre_completo  VARCHAR(150),
    num_contacto     VARCHAR(20)
);

-- Vista unificada de pasajeros.
-- En el esquema 1 se filtra por tipo_persona = 'Pasajero' directamente
-- en la consulta remota para reducir los datos transferidos por la conexión;
-- en el esquema 2 los pasajeros tienen su propia tabla
CREATE OR REPLACE VIEW aeropuerto_global.pasajero AS
SELECT
    pasaporte,
    nacionalidad
FROM dblink(
    'dbname=bd_aeropuerto_esq1 user=alumno password=alumno123',
    'SELECT pasaporte, nacionalidad
     FROM aeropuerto_esq1.persona
     WHERE tipo_persona = ''Pasajero'''
) AS t(
    pasaporte    VARCHAR(20),
    nacionalidad VARCHAR(50)
)

UNION

SELECT
    num_pasaporte AS pasaporte,
    nacionalidad
FROM dblink(
    'dbname=bd_aeropuerto_esq2 user=alumno password=alumno123',
    'SELECT num_pasaporte, nacionalidad
     FROM aeropuerto_esq2.pasajero'
) AS t(
    num_pasaporte VARCHAR(20),
    nacionalidad  VARCHAR(50)
);

-- Vista unificada de tripulación.
-- En el esquema 1 se filtra por tipo_persona = 'Tripulacion';
-- en el esquema 2 la tripulación tiene su propia tabla Miembro_tripulacion
CREATE OR REPLACE VIEW aeropuerto_global.tripulacion AS
SELECT
    pasaporte,
    puesto,
    anyos_experiencia
FROM dblink(
    'dbname=bd_aeropuerto_esq1 user=alumno password=alumno123',
    'SELECT pasaporte, puesto, anyos_experiencia
     FROM aeropuerto_esq1.persona
     WHERE tipo_persona = ''Tripulacion'''
) AS t(
    pasaporte         VARCHAR(20),
    puesto            VARCHAR(50),
    anyos_experiencia INTEGER
)

UNION

SELECT
    num_pasaporte AS pasaporte,
    puesto,
    anyos_exp AS anyos_experiencia
FROM dblink(
    'dbname=bd_aeropuerto_esq2 user=alumno password=alumno123',
    'SELECT num_pasaporte, puesto, anyos_exp
     FROM aeropuerto_esq2.miembro_tripulacion'
) AS t(
    num_pasaporte VARCHAR(20),
    puesto        VARCHAR(50),
    anyos_exp     INTEGER
);

-- Vista unificada de aerolíneas.
-- El esquema 1 usa el campo iata_aerolinea;
-- el esquema 2 usa codigo_oficial para el mismo concepto
CREATE OR REPLACE VIEW aeropuerto_global.aerolinea AS
SELECT
    iata_aerolinea AS codigo_aerolinea,
    nombre,
    pais
FROM dblink(
    'dbname=bd_aeropuerto_esq1 user=alumno password=alumno123',
    'SELECT iata_aerolinea, nombre, pais
     FROM aeropuerto_esq1.aerolinea'
) AS t(
    iata_aerolinea VARCHAR(2),
    nombre         VARCHAR(100),
    pais           VARCHAR(100)
)

UNION

SELECT
    codigo_oficial AS codigo_aerolinea,
    nombre,
    pais
FROM dblink(
    'dbname=bd_aeropuerto_esq2 user=alumno password=alumno123',
    'SELECT codigo_oficial, nombre, pais
     FROM aeropuerto_esq2.compania_aerea'
) AS t(
    codigo_oficial VARCHAR(2),
    nombre         VARCHAR(100),
    pais           VARCHAR(100)
);

-- Vista unificada de aeropuertos.
-- Ambos esquemas tienen la misma estructura para aeropuertos,
-- solo difieren en el nombre del campo de la clave primaria
CREATE OR REPLACE VIEW aeropuerto_global.aeropuerto AS
SELECT
    iata_aeropuerto AS codigo_aeropuerto,
    nombre,
    ciudad,
    pais
FROM dblink(
    'dbname=bd_aeropuerto_esq1 user=alumno password=alumno123',
    'SELECT iata_aeropuerto, nombre, ciudad, pais
     FROM aeropuerto_esq1.aeropuerto'
) AS t(
    iata_aeropuerto VARCHAR(3),
    nombre          VARCHAR(100),
    ciudad          VARCHAR(100),
    pais            VARCHAR(100)
)

UNION

SELECT
    codigo_aeropuerto,
    nombre,
    ciudad,
    pais
FROM dblink(
    'dbname=bd_aeropuerto_esq2 user=alumno password=alumno123',
    'SELECT codigo_aeropuerto, nombre, ciudad, pais
     FROM aeropuerto_esq2.aeropuerto'
) AS t(
    codigo_aeropuerto VARCHAR(3),
    nombre            VARCHAR(100),
    ciudad            VARCHAR(100),
    pais              VARCHAR(100)
);

-- Vista unificada de vuelos.
-- El esquema 1 almacena fecha y hora por separado; se combinan mediante
-- el operador + para obtener un TIMESTAMP equivalente al del esquema 2
CREATE OR REPLACE VIEW aeropuerto_global.vuelo AS
SELECT
    codigo_vuelo,
    fecha_hora_salida,
    fecha_hora_llegada,
    codigo_aerolinea,
    codigo_origen,
    codigo_destino
FROM dblink(
    'dbname=bd_aeropuerto_esq1 user=alumno password=alumno123',
    'SELECT codigo_vuelo,
            (fecha_salida + hora_salida) AS fecha_hora_salida,
            (fecha_llegada + hora_llegada) AS fecha_hora_llegada,
            iata_aerolinea AS codigo_aerolinea,
            iata_origen AS codigo_origen,
            iata_destino AS codigo_destino
     FROM aeropuerto_esq1.vuelo'
) AS t(
    codigo_vuelo       VARCHAR(20),
    fecha_hora_salida  TIMESTAMP,
    fecha_hora_llegada TIMESTAMP,
    codigo_aerolinea   VARCHAR(2),
    codigo_origen      VARCHAR(3),
    codigo_destino     VARCHAR(3)
)

UNION

SELECT
    num_vuelo AS codigo_vuelo,
    datetime_salida AS fecha_hora_salida,
    datetime_llegada AS fecha_hora_llegada,
    codigo_oficial AS codigo_aerolinea,
    codigo_origen,
    codigo_destino
FROM dblink(
    'dbname=bd_aeropuerto_esq2 user=alumno password=alumno123',
    'SELECT num_vuelo, datetime_salida, datetime_llegada,
            codigo_oficial, codigo_origen, codigo_destino
     FROM aeropuerto_esq2.vuelo'
) AS t(
    num_vuelo        VARCHAR(20),
    datetime_salida  TIMESTAMP,
    datetime_llegada TIMESTAMP,
    codigo_oficial   VARCHAR(2),
    codigo_origen    VARCHAR(3),
    codigo_destino   VARCHAR(3)
);

-- Vista unificada de reservas y billetes.
-- El esquema 1 usa la tabla Reserva con los campos asiento y clase;
-- el esquema 2 usa Billete_emitido con butaca y categoria_viaje para el mismo concepto
CREATE OR REPLACE VIEW aeropuerto_global.reserva AS
SELECT
    pasaporte,
    codigo_vuelo,
    asiento,
    clase
FROM dblink(
    'dbname=bd_aeropuerto_esq1 user=alumno password=alumno123',
    'SELECT pasaporte, codigo_vuelo, asiento, clase
     FROM aeropuerto_esq1.reserva'
) AS t(
    pasaporte    VARCHAR(20),
    codigo_vuelo VARCHAR(20),
    asiento      VARCHAR(10),
    clase        VARCHAR(20)
)

UNION

SELECT
    num_pasaporte AS pasaporte,
    num_vuelo AS codigo_vuelo,
    butaca AS asiento,
    categoria_viaje AS clase
FROM dblink(
    'dbname=bd_aeropuerto_esq2 user=alumno password=alumno123',
    'SELECT num_pasaporte, num_vuelo, butaca, categoria_viaje
     FROM aeropuerto_esq2.billete_emitido'
) AS t(
    num_pasaporte   VARCHAR(20),
    num_vuelo       VARCHAR(20),
    butaca          VARCHAR(10),
    categoria_viaje VARCHAR(20)
);

-- Vista unificada de participación de tripulación en vuelos.
-- El esquema 1 usa la tabla Participa_en con el campo rol;
-- el esquema 2 usa Asignacion_laboral con funcion_en_vuelo para el mismo concepto
CREATE OR REPLACE VIEW aeropuerto_global.participa_en AS
SELECT
    pasaporte,
    codigo_vuelo,
    rol
FROM dblink(
    'dbname=bd_aeropuerto_esq1 user=alumno password=alumno123',
    'SELECT pasaporte, codigo_vuelo, rol
     FROM aeropuerto_esq1.participa_en'
) AS t(
    pasaporte    VARCHAR(20),
    codigo_vuelo VARCHAR(20),
    rol          VARCHAR(50)
)

UNION

SELECT
    num_pasaporte AS pasaporte,
    num_vuelo AS codigo_vuelo,
    funcion_en_vuelo AS rol
FROM dblink(
    'dbname=bd_aeropuerto_esq2 user=alumno password=alumno123',
    'SELECT num_pasaporte, num_vuelo, funcion_en_vuelo
     FROM aeropuerto_esq2.asignacion_laboral'
) AS t(
    num_pasaporte    VARCHAR(20),
    num_vuelo        VARCHAR(20),
    funcion_en_vuelo VARCHAR(50)
);