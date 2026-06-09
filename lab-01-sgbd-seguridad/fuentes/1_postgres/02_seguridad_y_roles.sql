-- 0. Limpieza previa para evitar errores de roles/usuarios ya existentes
DO $$
BEGIN
    -- Borramos los usuarios primero (y revocamos sus dependencias)
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'consultor') THEN
        DROP OWNED BY consultor;
        DROP ROLE consultor;
    END IF;

    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'editor') THEN
        DROP OWNED BY editor;
        DROP ROLE editor;
    END IF;

    -- Luego borramos los roles (y revocamos sus dependencias)
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'rol_escritura') THEN
        DROP OWNED BY rol_escritura;
        DROP ROLE rol_escritura;
    END IF;

    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'rol_lectura') THEN
        DROP OWNED BY rol_lectura;
        DROP ROLE rol_lectura;
    END IF;
END
$$;

-- 1. Creación de roles
CREATE ROLE rol_lectura;
CREATE ROLE rol_escritura;

-- 2. Asignación de permisos a los roles --> permisos de lectura (base) 
GRANT CONNECT ON DATABASE practica1_db TO rol_lectura;
GRANT USAGE ON SCHEMA public TO rol_lectura;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_lectura;

-- Permisos de escritura (Hereda de lectura y añade modificaciones)
GRANT rol_lectura TO rol_escritura;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO rol_escritura;

-- Permiso para usar contadores automáticos (SERIAL/SEQUENCES)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_escritura;

-- 3. Creación y asignación de usuarios 
-- consultor solo lectura, mientras que editor tanto lectura como escritura
CREATE USER consultor WITH PASSWORD 'consultor123';
GRANT rol_lectura TO consultor;

CREATE USER editor WITH PASSWORD 'editor123';
GRANT rol_escritura TO editor;