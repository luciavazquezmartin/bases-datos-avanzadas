-- Conectamos al Keyspace de la práctica
USE practica1_keyspace;

-- 0. Limpieza previa de las tablas
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS historial_prestamos;

-- 1. Creación de la tabla para pruebas de seguridad
CREATE TABLE productos (
    id int PRIMARY KEY,
    nombre text,
    precio float
);

-- 2. Creación del esquema desnormalizado (sin relaciones/Foreign Keys)
CREATE TABLE historial_prestamos (
    dni_lector text,
    fecha_prestamo date,
    nombre_lector text,
    titulo_libro text,
    PRIMARY KEY (dni_lector, fecha_prestamo)
);

-- 3. Inserción de datos manuales (DML)
INSERT INTO productos (id, nombre, precio) 
VALUES (1, 'Ratón Gamer', 45.99);

INSERT INTO historial_prestamos (dni_lector, fecha_prestamo, nombre_lector, titulo_libro) 
VALUES ('12345678A', '2026-02-20', 'Laura Gómez', 'Cien años de soledad');