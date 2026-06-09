CONNECT TO PRACTDB2;

-- 0. Limpieza previa de tablas para garantizar la reproducibilidad
DROP TABLE IF EXISTS prestamos;
DROP TABLE IF EXISTS libros;
DROP TABLE IF EXISTS lectores;
DROP TABLE IF EXISTS pruebas_final;

-- ====================================================================
-- 1. ESQUEMA DE PRUEBAS DE SEGURIDAD
-- ====================================================================
CREATE TABLE pruebas_final (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dato VARCHAR(100)
);

INSERT INTO pruebas_final (dato) VALUES ('Dato visible 1');
INSERT INTO pruebas_final (dato) VALUES ('Dato visible 2');

-- Aplicamos la restricción de seguridad descubierta en la práctica:
-- Damos solo permiso SELECT al rol de lectura a nivel de tabla.
GRANT SELECT ON TABLE pruebas_final TO ROLE ROL_LECTURA;


-- ====================================================================
-- 2. ESQUEMA DE LA BIBLIOTECA
-- ====================================================================
CREATE TABLE lectores (
    dni VARCHAR(15) NOT NULL PRIMARY KEY,
    nombre VARCHAR(50)
);

CREATE TABLE libros (
    isbn VARCHAR(20) NOT NULL PRIMARY KEY,
    titulo VARCHAR(100)
);

CREATE TABLE prestamos (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dni_lector VARCHAR(15) REFERENCES lectores(dni),
    isbn_libro VARCHAR(20) REFERENCES libros(isbn),
    fecha_prestamo DATE
);

-- Inserción de catálogo base
INSERT INTO lectores (dni, nombre) VALUES ('12345678A', 'Laura Gómez');
INSERT INTO libros (isbn, titulo) VALUES ('978-84', 'Cien años de soledad');

-- Inserción manual de prueba para validar la restricción
INSERT INTO prestamos (dni_lector, isbn_libro, fecha_prestamo) 
VALUES ('12345678A', '978-84', CURRENT DATE);

-- Concesión de lectura sobre las tablas de la biblioteca
GRANT SELECT ON TABLE lectores TO ROLE ROL_LECTURA;
GRANT SELECT ON TABLE libros TO ROLE ROL_LECTURA;
GRANT SELECT ON TABLE prestamos TO ROLE ROL_LECTURA;

-- ====================================================================
-- NOTA SOBRE LA CARGA MASIVA (IMPORT):
-- Para importar los datos generados masivamente, se ejecutaría:
-- IMPORT FROM prestamos_generados.csv OF DEL INSERT INTO prestamos;
-- ====================================================================

TERMINATE;