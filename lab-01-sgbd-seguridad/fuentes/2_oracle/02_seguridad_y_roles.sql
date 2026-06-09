-- Cambio a la base de datos enchufable (Pluggable Database)
ALTER SESSION SET CONTAINER = XEPDB1;

-- 0. Limpieza previa (Ignora errores si los usuarios/roles no existen aún)
BEGIN EXECUTE IMMEDIATE 'DROP USER alumno CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP USER editor CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP USER consultor CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE rol_escritura'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE rol_lectura'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- 1. Creación de roles
CREATE ROLE rol_lectura;
CREATE ROLE rol_escritura;

-- 2. Asignación de permisos a los roles
GRANT CREATE SESSION TO rol_lectura;
GRANT rol_lectura TO rol_escritura;
GRANT RESOURCE TO rol_escritura;
GRANT CREATE TABLE TO rol_escritura;

-- 3. Creación y asignación de usuarios
CREATE USER alumno IDENTIFIED BY alumno123;
GRANT DBA TO alumno;

CREATE USER editor IDENTIFIED BY editor123;
GRANT rol_escritura TO editor;
ALTER USER editor QUOTA UNLIMITED ON USERS;

CREATE USER consultor IDENTIFIED BY consultor123;
GRANT rol_lectura TO consultor;