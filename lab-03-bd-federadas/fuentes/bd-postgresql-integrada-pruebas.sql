-- ==========================================================
-- Script:      bd-postgresql-integrada-pruebas.sql
-- SGBD:        PostgreSQL
-- Depende de:  aeropuerto_global (bd-postgresql-integrada-fdw.sql
--              o bd-postgresql-integrada-dblink.sql)
--              bd_aeropuerto_esq1 con datos de prueba cargados
--              bd_aeropuerto_esq2 con datos de prueba cargados
-- Propósito:   Consultas de prueba sobre el esquema global integrado
-- Contenido:
--   1. Consultas simples sobre cada vista
--   2. Consultas con filtros WHERE
--   3. Consultas con JOIN entre vistas
--   4. Consultas con agregaciones y GROUP BY
-- Nota: Este script es válido tanto para la versión fdw
--       como para la versión dblink, ya que las vistas
--       globales tienen los mismos nombres en ambos casos
-- ==========================================================

-- Establece el esquema por defecto para todas las consultas del script,
-- evitando tener que escribir el prefijo aeropuerto_global. en cada una.
-- Aunque el script se ejecute conectado a la base de datos aeropuerto_global,
-- el search_path por defecto de PostgreSQL apunta a 'public', por lo que
-- sin esta línea las consultas no encontrarían las vistas del esquema.
SET search_path TO aeropuerto_global;


-- ==========================================================
-- CONSULTAS SIMPLES SOBRE CADA VISTA
-- ==========================================================

-- Todas las personas registradas en ambos esquemas
SELECT * FROM persona
ORDER BY pasaporte;

-- Todos los pasajeros registrados en ambos esquemas
SELECT * FROM pasajero
ORDER BY pasaporte;

-- Todos los miembros de tripulación registrados en ambos esquemas
SELECT * FROM tripulacion
ORDER BY pasaporte;

-- Todas las aerolíneas registradas en ambos esquemas
SELECT * FROM aerolinea
ORDER BY codigo_aerolinea;

-- Todos los aeropuertos registrados en ambos esquemas
SELECT * FROM aeropuerto
ORDER BY codigo_aeropuerto;

-- Todos los vuelos registrados en ambos esquemas
SELECT * FROM vuelo
ORDER BY fecha_hora_salida;

-- Todas las reservas y billetes registrados en ambos esquemas
SELECT * FROM reserva
ORDER BY pasaporte, codigo_vuelo;

-- Todas las participaciones de tripulación en vuelos de ambos esquemas
SELECT * FROM participa_en
ORDER BY pasaporte, codigo_vuelo;


-- ==========================================================
-- CONSULTAS CON FILTROS WHERE
-- ==========================================================

-- Pasajeros con nacionalidad española
SELECT pa.pasaporte, pe.nombre, pe.apellido1, pe.apellido2
FROM pasajero pa
JOIN persona pe ON pa.pasaporte = pe.pasaporte
WHERE pa.nacionalidad = 'Española'
ORDER BY pe.apellido1, pe.nombre;

-- Miembros de tripulación con el puesto de Piloto
SELECT t.pasaporte, pe.nombre, pe.apellido1, t.anyos_experiencia
FROM tripulacion t
JOIN persona pe ON t.pasaporte = pe.pasaporte
WHERE t.puesto = 'Piloto'
ORDER BY pe.apellido1, pe.nombre;

-- Miembros de tripulación con más de 5 años de experiencia
SELECT t.pasaporte, pe.nombre, pe.apellido1, t.puesto, t.anyos_experiencia
FROM tripulacion t
JOIN persona pe ON t.pasaporte = pe.pasaporte
WHERE t.anyos_experiencia > 5
ORDER BY t.anyos_experiencia DESC;

-- Vuelos que salen del aeropuerto de Madrid (MAD)
SELECT * FROM vuelo
WHERE codigo_origen = 'MAD'
ORDER BY fecha_hora_salida;

-- Vuelos operados por Iberia (IB)
SELECT * FROM vuelo
WHERE codigo_aerolinea = 'IB'
ORDER BY fecha_hora_salida;

-- Vuelos programados para una fecha concreta
SELECT * FROM vuelo
WHERE fecha_hora_salida::DATE = '2025-06-01'
ORDER BY fecha_hora_salida;

-- Reservas en clase Business o Primera
SELECT * FROM reserva
WHERE clase IN ('Business', 'Primera')
ORDER BY clase, pasaporte;

-- Participaciones en vuelos con rol de Comandante
SELECT * FROM participa_en
WHERE rol = 'Comandante'
ORDER BY codigo_vuelo;


-- ==========================================================
-- CONSULTAS CON JOIN ENTRE VISTAS
-- ==========================================================

-- Datos completos de cada reserva: nombre del pasajero, vuelo,
-- aeropuertos de origen y destino, asiento y clase
SELECT
    pe.nombre,
    pe.apellido1,
    r.asiento,
    r.clase,
    v.codigo_vuelo,
    v.codigo_origen,
    v.codigo_destino,
    v.fecha_hora_salida,
    v.fecha_hora_llegada
FROM reserva r
JOIN persona pe ON r.pasaporte    = pe.pasaporte
JOIN vuelo v    ON r.codigo_vuelo = v.codigo_vuelo
ORDER BY v.fecha_hora_salida;

-- Tripulación asignada a cada vuelo con sus datos personales y función
SELECT
    pe.nombre,
    pe.apellido1,
    t.puesto,
    t.anyos_experiencia,
    p.rol,
    v.codigo_vuelo,
    v.codigo_origen,
    v.codigo_destino,
    v.fecha_hora_salida
FROM participa_en p
JOIN persona pe    ON p.pasaporte    = pe.pasaporte
JOIN tripulacion t ON p.pasaporte    = t.pasaporte
JOIN vuelo v       ON p.codigo_vuelo = v.codigo_vuelo
ORDER BY v.fecha_hora_salida, pe.apellido1;

-- Vuelos con información completa del aeropuerto de origen y destino
SELECT
    v.codigo_vuelo,
    v.fecha_hora_salida,
    v.fecha_hora_llegada,
    a_origen.nombre  AS aeropuerto_origen,
    a_origen.ciudad  AS ciudad_origen,
    a_destino.nombre AS aeropuerto_destino,
    a_destino.ciudad AS ciudad_destino,
    al.nombre        AS aerolinea
FROM vuelo v
JOIN aeropuerto a_origen  ON v.codigo_origen    = a_origen.codigo_aeropuerto
JOIN aeropuerto a_destino ON v.codigo_destino   = a_destino.codigo_aeropuerto
JOIN aerolinea al         ON v.codigo_aerolinea = al.codigo_aerolinea
ORDER BY v.fecha_hora_salida;

-- Pasajeros con sus reservas y el nombre de la aerolínea del vuelo
SELECT
    pe.nombre,
    pe.apellido1,
    pa.nacionalidad,
    r.clase,
    r.asiento,
    al.nombre AS aerolinea,
    v.codigo_origen,
    v.codigo_destino
FROM reserva r
JOIN persona pe   ON r.pasaporte        = pe.pasaporte
JOIN pasajero pa  ON r.pasaporte        = pa.pasaporte
JOIN vuelo v      ON r.codigo_vuelo     = v.codigo_vuelo
JOIN aerolinea al ON v.codigo_aerolinea = al.codigo_aerolinea
ORDER BY pe.apellido1, pe.nombre;


-- ==========================================================
-- CONSULTAS CON AGREGACIONES Y GROUP BY
-- ==========================================================

-- Número total de personas registradas en el esquema global
SELECT COUNT(*) AS total_personas
FROM persona;

-- Número de pasajeros por nacionalidad en el esquema global
SELECT
    nacionalidad,
    COUNT(*) AS total_pasajeros
FROM pasajero
GROUP BY nacionalidad
ORDER BY total_pasajeros DESC, nacionalidad;

-- Número de miembros de tripulación por puesto y media de experiencia
SELECT
    puesto,
    COUNT(*) AS total,
    ROUND(AVG(anyos_experiencia), 1) AS media_experiencia
FROM tripulacion
GROUP BY puesto
ORDER BY total DESC, puesto;

-- Número de vuelos por aerolínea
SELECT
    al.nombre AS aerolinea,
    COUNT(*) AS total_vuelos
FROM vuelo v
JOIN aerolinea al ON v.codigo_aerolinea = al.codigo_aerolinea
GROUP BY al.nombre
ORDER BY total_vuelos DESC, al.nombre;

-- Número de vuelos por aeropuerto de origen
SELECT
    a.nombre AS aeropuerto,
    a.ciudad,
    COUNT(*) AS vuelos_salientes
FROM vuelo v
JOIN aeropuerto a ON v.codigo_origen = a.codigo_aeropuerto
GROUP BY a.nombre, a.ciudad
ORDER BY vuelos_salientes DESC, a.nombre;

-- Número de reservas por clase en el esquema global
SELECT
    clase,
    COUNT(*) AS total_reservas
FROM reserva
GROUP BY clase
ORDER BY total_reservas DESC, clase;

-- Número de reservas por vuelo, mostrando solo los vuelos
-- con más de un pasajero reservado
SELECT
    r.codigo_vuelo,
    v.codigo_origen,
    v.codigo_destino,
    v.fecha_hora_salida,
    COUNT(*) AS total_pasajeros
FROM reserva r
JOIN vuelo v ON r.codigo_vuelo = v.codigo_vuelo
GROUP BY r.codigo_vuelo, v.codigo_origen, v.codigo_destino, v.fecha_hora_salida
HAVING COUNT(*) > 1
ORDER BY total_pasajeros DESC, v.fecha_hora_salida;

-- Número de vuelos en los que ha participado cada miembro de tripulación
SELECT
    pe.nombre,
    pe.apellido1,
    t.puesto,
    COUNT(*) AS vuelos_realizados
FROM participa_en p
JOIN persona pe    ON p.pasaporte = pe.pasaporte
JOIN tripulacion t ON p.pasaporte = t.pasaporte
GROUP BY pe.nombre, pe.apellido1, t.puesto
ORDER BY vuelos_realizados DESC, pe.apellido1;