-- ==========================================================
-- Script:      bd-postgresql-esquema2-p3.sql
-- SGBD:        PostgreSQL
-- Depende de:  ninguno (script autónomo)
-- Propósito:   Modelo relacional de gestión aeroportuaria con
--              especialización de persona en subtipos disjuntos
--              y restricciones de integridad mediante triggers
-- Contenido:
--   1. Eliminación de tablas previas (idempotente)
--   2. Creación de tablas: Aeropuerto, Compania_aerea, Persona,
--      Pasajero, Miembro_tripulacion, Vuelo, Billete_emitido
--      y Asignacion_laboral
--   3. Restricciones de integridad mediante CHECK y UNIQUE
--   4. Claves foráneas con eliminación en cascada
--   5. Triggers para garantizar la especialización disjunta
--      y detectar solapamientos de vuelos
-- ==========================================================

-- Establece el esquema por defecto para todas las sentencias del script.
-- Sin esta línea PostgreSQL crearía las tablas en 'public' en lugar de
-- en aeropuerto_esq2, ya que ese es el search_path por defecto.
SET search_path TO aeropuerto_esq2;

-- ==========================================================
-- LIMPIEZA DEL ENTORNO
-- ==========================================================

-- Se añade CASCADE para forzar la eliminación automática de cualquier 
-- objeto que dependa de la tabla (como vistas o claves foráneas),
-- garantizando un borrado limpio aunque cambie el orden
DROP TABLE IF EXISTS Asignacion_laboral CASCADE;
DROP TABLE IF EXISTS Billete_emitido CASCADE;
DROP TABLE IF EXISTS Vuelo CASCADE;
DROP TABLE IF EXISTS Miembro_tripulacion CASCADE;
DROP TABLE IF EXISTS Pasajero CASCADE;
DROP TABLE IF EXISTS Persona CASCADE;
DROP TABLE IF EXISTS Compania_aerea CASCADE;
DROP TABLE IF EXISTS Aeropuerto CASCADE;

-- ==========================================================
-- TABLAS BASE (sin dependencias)
-- ==========================================================

CREATE TABLE Aeropuerto (
    Codigo_aeropuerto VARCHAR(3) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Ciudad VARCHAR(100) NOT NULL,
    Pais VARCHAR(100) NOT NULL,

    -- Rechaza cualquier código que no sean exactamente 3 letras mayúsculas
    CONSTRAINT chk_codigo_aeropuerto
        CHECK (Codigo_aeropuerto ~ '^[A-Z]{3}$')
);

CREATE TABLE Compania_aerea (
    Codigo_oficial VARCHAR(2) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Pais VARCHAR(100) NOT NULL,

    -- Rechaza cualquier código que no sean exactamente 2 caracteres alfanuméricos en mayúsculas
    CONSTRAINT chk_codigo_oficial
        CHECK (Codigo_oficial ~ '^[A-Z0-9]{2}$')
);

-- Tabla raíz de la especialización: almacena los atributos comunes a
-- pasajeros y miembros de tripulación. Las subclases (Pasajero y
-- Miembro_tripulacion) extienden esta tabla mediante clave foránea
CREATE TABLE Persona (
    Num_pasaporte VARCHAR(20) PRIMARY KEY,
    Nombre_completo VARCHAR(150) NOT NULL,
    Num_contacto VARCHAR(20) NOT NULL
);

-- ==========================================================
-- TABLAS DEPENDIENTES
-- ==========================================================

-- Subtipo de Persona que representa a los pasajeros.
-- La clave primaria es también clave foránea hacia Persona,
-- de modo que cada pasajero debe existir primero como persona
CREATE TABLE Pasajero (
    Num_pasaporte VARCHAR(20) PRIMARY KEY,
    Nacionalidad VARCHAR(50) NOT NULL,

    -- Si se elimina la persona, el pasajero asociado se elimina en cascada
    CONSTRAINT fk_pasajero_persona
        FOREIGN KEY (Num_pasaporte)
        REFERENCES Persona(Num_pasaporte)
        ON DELETE CASCADE
);

-- Subtipo de Persona que representa a los miembros de tripulación.
-- Al igual que Pasajero, su clave primaria referencia a Persona.
-- La especialización es disjunta: una persona no puede ser a la vez
-- pasajero y tripulación
CREATE TABLE Miembro_tripulacion (
    Num_pasaporte VARCHAR(20) PRIMARY KEY,
    Puesto VARCHAR(50) NOT NULL,    -- 'Piloto' o 'Auxiliar de vuelo'
    Anyos_exp INTEGER NOT NULL,     -- debe ser >= 0

    -- Si se elimina la persona, el miembro de tripulación se elimina en cascada
    CONSTRAINT fk_trip_persona
        FOREIGN KEY (Num_pasaporte)
        REFERENCES Persona(Num_pasaporte)
        ON DELETE CASCADE,

    -- Solo se admiten estos dos puestos operativos
    CONSTRAINT chk_puesto
        CHECK (Puesto IN ('Piloto', 'Auxiliar de vuelo')),

    -- Los años de experiencia no pueden ser negativos
    CONSTRAINT chk_anyos_exp
        CHECK (Anyos_exp >= 0)
);

-- Usa TIMESTAMP en lugar de fecha y hora separadas,
-- lo que simplifica la comparación de intervalos en los triggers
CREATE TABLE Vuelo (
    Num_vuelo VARCHAR(20) PRIMARY KEY,
    Datetime_salida TIMESTAMP NOT NULL,
    Datetime_llegada TIMESTAMP NOT NULL,
    Codigo_oficial VARCHAR(2) NOT NULL,   -- compañía aérea que opera el vuelo
    Codigo_origen VARCHAR(3) NOT NULL,    -- aeropuerto de salida
    Codigo_destino VARCHAR(3) NOT NULL,   -- aeropuerto de llegada

    -- Asegura que la compañía aérea referenciada existe en Compania_aerea
    CONSTRAINT fk_vuelo_compania
        FOREIGN KEY (Codigo_oficial)
        REFERENCES Compania_aerea(Codigo_oficial),

    -- Asegura que el aeropuerto de origen existe en Aeropuerto
    CONSTRAINT fk_vuelo_origen
        FOREIGN KEY (Codigo_origen)
        REFERENCES Aeropuerto(Codigo_aeropuerto),

    -- Asegura que el aeropuerto de destino existe en Aeropuerto
    CONSTRAINT fk_vuelo_destino
        FOREIGN KEY (Codigo_destino)
        REFERENCES Aeropuerto(Codigo_aeropuerto),

    -- Un vuelo no puede tener el mismo aeropuerto como origen y destino
    CONSTRAINT chk_origen_destino
        CHECK (Codigo_origen <> Codigo_destino),

    -- La llegada debe ser estrictamente posterior a la salida
    CONSTRAINT chk_datetime
        CHECK (Datetime_llegada > Datetime_salida)
);

-- Registra el billete emitido a un pasajero para un vuelo concreto.
-- La clave primaria compuesta (num_pasaporte, num_vuelo) impide que un
-- mismo pasajero tenga dos billetes para el mismo vuelo
CREATE TABLE Billete_emitido (
    Num_pasaporte VARCHAR(20),
    Num_vuelo VARCHAR(20),
    Butaca VARCHAR(10) NOT NULL,
    Categoria_viaje VARCHAR(20) NOT NULL,

    PRIMARY KEY (Num_pasaporte, Num_vuelo),

    -- Si se elimina el pasajero, sus billetes se eliminan en cascada
    CONSTRAINT fk_billete_pasajero
        FOREIGN KEY (Num_pasaporte)
        REFERENCES Pasajero(Num_pasaporte)
        ON DELETE CASCADE,

    -- Si se elimina el vuelo, sus billetes se eliminan en cascada
    CONSTRAINT fk_billete_vuelo
        FOREIGN KEY (Num_vuelo)
        REFERENCES Vuelo(Num_vuelo)
        ON DELETE CASCADE,

    -- Solo se admiten estas tres categorías de viaje
    CONSTRAINT chk_categoria
        CHECK (Categoria_viaje IN ('Turista', 'Business', 'Primera')),

    -- Dos pasajeros distintos no pueden ocupar la misma butaca en el mismo vuelo
    CONSTRAINT uq_butaca_vuelo UNIQUE (Num_vuelo, Butaca)
);

-- Registra la asignación de un miembro de tripulación a un vuelo con una función concreta.
-- La clave primaria compuesta (num_pasaporte, num_vuelo) impide que la misma persona
-- aparezca dos veces en el mismo vuelo
CREATE TABLE Asignacion_laboral (
    Num_pasaporte VARCHAR(20),
    Num_vuelo VARCHAR(20),
    Funcion_en_vuelo VARCHAR(50) NOT NULL,  -- función desempeñada en el vuelo

    PRIMARY KEY (Num_pasaporte, Num_vuelo),

    -- Si se elimina el miembro de tripulación, sus asignaciones se eliminan en cascada
    CONSTRAINT fk_asignacion_trip
        FOREIGN KEY (Num_pasaporte)
        REFERENCES Miembro_tripulacion(Num_pasaporte)
        ON DELETE CASCADE,

    -- Si se elimina el vuelo, sus asignaciones se eliminan en cascada
    CONSTRAINT fk_asignacion_vuelo
        FOREIGN KEY (Num_vuelo)
        REFERENCES Vuelo(Num_vuelo)
        ON DELETE CASCADE,

    -- Solo se admiten estos tres roles operativos
    CONSTRAINT chk_funcion
        CHECK (Funcion_en_vuelo IN ('Comandante', 'Copiloto', 'Auxiliar de vuelo'))
);

-- ==========================================================
-- TRIGGER: ESPECIALIZACIÓN DISJUNTA DE PERSONA
-- ==========================================================
-- Función que impide que una misma persona figure simultáneamente
-- como pasajero y como miembro de tripulación.
-- Usa TG_TABLE_NAME para saber desde qué subtipo se disparó:
--    - Si se inserta en Pasajero, comprueba que no exista ya en Miembro_tripulacion
--    - Si se inserta en Miembro_tripulacion, comprueba que no exista ya en Pasajero
CREATE OR REPLACE FUNCTION aeropuerto_esq2.check_disjuncion_persona()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'pasajero' THEN
        IF EXISTS (
            SELECT 1 
            FROM aeropuerto_esq2.Miembro_tripulacion
            WHERE Num_pasaporte = NEW.Num_pasaporte
        ) THEN
            RAISE EXCEPTION 'La persona ya pertenece a la tripulación';
        END IF;
    ELSE
        IF EXISTS (
            SELECT 1 
            FROM aeropuerto_esq2.Pasajero
            WHERE Num_pasaporte = NEW.Num_pasaporte
        ) THEN
            RAISE EXCEPTION 'La persona ya es pasajero';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Registra el trigger de disjunción en Pasajero
DROP TRIGGER IF EXISTS trg_disjuncion_pasajero ON aeropuerto_esq2.Pasajero;
CREATE TRIGGER trg_disjuncion_pasajero
BEFORE INSERT OR UPDATE ON aeropuerto_esq2.Pasajero
FOR EACH ROW
EXECUTE FUNCTION aeropuerto_esq2.check_disjuncion_persona();

-- Registra el mismo trigger en Miembro_tripulacion;
-- TG_TABLE_NAME dentro de la función distinguirá cuál de los dos lo disparó
DROP TRIGGER IF EXISTS trg_disjuncion_tripulacion ON aeropuerto_esq2.Miembro_tripulacion;
CREATE TRIGGER trg_disjuncion_tripulacion
BEFORE INSERT OR UPDATE ON aeropuerto_esq2.Miembro_tripulacion
FOR EACH ROW
EXECUTE FUNCTION aeropuerto_esq2.check_disjuncion_persona();

-- ==========================================================
-- TRIGGER: DETECCIÓN DE SOLAPAMIENTO DE VUELOS EN BILLETES
-- ==========================================================
-- Detecta si un pasajero intenta reservar un vuelo cuyo intervalo
-- [datetime_salida, datetime_llegada] se solapa con el de otro vuelo
-- que ya tiene reservado. Al usar TIMESTAMP, la comparación es directa
-- sin necesidad de combinar fecha y hora por separado
CREATE OR REPLACE FUNCTION aeropuerto_esq2.check_solapamiento_billete()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.Num_vuelo = OLD.Num_vuelo THEN
        RETURN NEW;
    END IF;

    -- Busca cualquier billete existente del mismo pasajero cuyo vuelo se solape con el nuevo
    IF EXISTS (
        SELECT 1
        FROM aeropuerto_esq2.Billete_emitido b
        JOIN aeropuerto_esq2.Vuelo v1 ON b.Num_vuelo = v1.Num_vuelo     -- vuelo ya reservado
        JOIN aeropuerto_esq2.Vuelo v2 ON v2.Num_vuelo = NEW.Num_vuelo   -- vuelo que se intenta reservar
        WHERE b.Num_pasaporte = NEW.Num_pasaporte
          AND b.Num_vuelo <> NEW.Num_vuelo                              -- descarta la propia fila en UPDATE
          AND v1.Datetime_salida < v2.Datetime_llegada
          AND v2.Datetime_salida < v1.Datetime_llegada
    ) THEN
        RAISE EXCEPTION 'Solapamiento de vuelos para pasajero %', NEW.Num_pasaporte;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Asocia la función anterior a la tabla Billete_emitido; se dispara fila a fila antes de escribir
DROP TRIGGER IF EXISTS trg_solapamiento_billete ON aeropuerto_esq2.Billete_emitido;
CREATE TRIGGER trg_solapamiento_billete
BEFORE INSERT OR UPDATE ON aeropuerto_esq2.Billete_emitido
FOR EACH ROW
EXECUTE FUNCTION aeropuerto_esq2.check_solapamiento_billete();

-- ==========================================================
-- TRIGGER: DETECCIÓN DE SOLAPAMIENTO DE VUELOS EN TRIPULACIÓN
-- ==========================================================
-- Misma lógica que el trigger anterior pero aplicada a la tabla
-- Asignacion_laboral: impide asignar a un miembro de tripulación
-- a dos vuelos cuyas ventanas temporales se solapen
CREATE OR REPLACE FUNCTION aeropuerto_esq2.check_solapamiento_tripulacion()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.Num_vuelo = OLD.Num_vuelo THEN
        RETURN NEW;
    END IF;

    -- Busca cualquier asignación existente del mismo miembro cuyo vuelo se solape con el nuevo
    IF EXISTS (
        SELECT 1
        FROM aeropuerto_esq2.Asignacion_laboral a
        JOIN aeropuerto_esq2.Vuelo v1 ON a.Num_vuelo = v1.Num_vuelo     -- vuelo en el que ya participa
        JOIN aeropuerto_esq2.Vuelo v2 ON v2.Num_vuelo = NEW.Num_vuelo   -- vuelo que se intenta asignar
        WHERE a.Num_pasaporte = NEW.Num_pasaporte
          AND a.Num_vuelo <> NEW.Num_vuelo                              -- descarta la propia fila en UPDATE
          AND v1.Datetime_salida < v2.Datetime_llegada
          AND v2.Datetime_salida < v1.Datetime_llegada
    ) THEN
        RAISE EXCEPTION 'Solapamiento de vuelos para tripulación %', NEW.Num_pasaporte;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Asocia la función anterior a la tabla Asignacion_laboral; se dispara fila a fila antes de escribir
DROP TRIGGER IF EXISTS trg_solapamiento_tripulacion ON aeropuerto_esq2.Asignacion_laboral;
CREATE TRIGGER trg_solapamiento_tripulacion
BEFORE INSERT OR UPDATE ON aeropuerto_esq2.Asignacion_laboral
FOR EACH ROW
EXECUTE FUNCTION aeropuerto_esq2.check_solapamiento_tripulacion();