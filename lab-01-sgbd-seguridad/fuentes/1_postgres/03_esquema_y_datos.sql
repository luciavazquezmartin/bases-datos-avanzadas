-- 0. Limpieza previa para que el script sea reproducible
DROP TABLE IF EXISTS prestamos CASCADE;
DROP TABLE IF EXISTS lectores CASCADE;
DROP TABLE IF EXISTS libros CASCADE;

-- 1. Definición del esquema relacional
CREATE TABLE lectores (
    dni VARCHAR(15) PRIMARY KEY,
    nombre VARCHAR(50),
    email VARCHAR(50)
);

CREATE TABLE libros (
    isbn VARCHAR(20) PRIMARY KEY,
    titulo VARCHAR(100),
    autor VARCHAR(50)
);

CREATE TABLE prestamos (
    id SERIAL PRIMARY KEY,
    dni_lector VARCHAR(15) REFERENCES lectores(dni),
    isbn_libro VARCHAR(20) REFERENCES libros(isbn),
    fecha_prestamo DATE
);

-- 2. Inserción de datos (Simulando la salida de un script de Mockaroo)
INSERT INTO lectores VALUES ('12345678A', 'Laura Gómez', 'laura@email.com');
INSERT INTO libros VALUES ('978-84-376-0494-7', 'Cien años de soledad', 'Gabriel García Márquez');
INSERT INTO prestamos (dni_lector, isbn_libro, fecha_prestamo) 
VALUES ('12345678A', '978-84-376-0494-7', '2026-02-20');

-- 3. Consulta de prueba (Verificación de relaciones mediante JOIN)
SELECT l.nombre AS Lector, b.titulo AS Libro, p.fecha_prestamo 
FROM prestamos p
JOIN lectores l ON p.dni_lector = l.dni
JOIN libros b ON p.isbn_libro = b.isbn;
