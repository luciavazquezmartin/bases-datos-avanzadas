-- 0. Limpieza previa para garantizar la reproducibilidad
DROP USER IF EXISTS consultor;
DROP USER IF EXISTS editor;
DROP USER IF EXISTS alumno;
DROP ROLE IF EXISTS rol_escritura;
DROP ROLE IF EXISTS rol_lectura;
DROP KEYSPACE IF EXISTS practica1_keyspace;

-- 1. Creación del espacio de nombres (Keyspace)
CREATE KEYSPACE practica1_keyspace 
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

-- 2. Creación de Roles lógicos
CREATE ROLE rol_lectura;
CREATE ROLE rol_escritura;

-- 3. Creación de Usuarios
CREATE USER alumno WITH PASSWORD 'alumno123' SUPERUSER;
CREATE USER editor WITH PASSWORD 'editor123';
CREATE USER consultor WITH PASSWORD 'consultor123';

-- 4. Asignación de Permisos a los ROLES
GRANT ALL PERMISSIONS ON KEYSPACE practica1_keyspace TO rol_escritura;
GRANT SELECT ON KEYSPACE practica1_keyspace TO rol_lectura;

-- 5. Asignación de Roles a los USUARIOS
GRANT rol_escritura TO editor;
GRANT rol_lectura TO consultor;