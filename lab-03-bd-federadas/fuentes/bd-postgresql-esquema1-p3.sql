-- ==========================================================
-- Script:      bd-postgresql-esquema1-p3.sql
-- SGBD:        PostgreSQL
-- Depende de:  ninguno (script autónomo)
-- Propósito:   Modelo relacional de gestión aeroportuaria con
--              restricciones de integridad y triggers asociados
-- Contenido:
--   1. Eliminación de tablas previas (idempotente)
--   2. Creación de tablas: Aeropuerto, Aerolinea, Persona,
--      Vuelo, Reserva y Participa_en
--   3. Restricciones de integridad mediante CHECK y UNIQUE
--   4. Claves foráneas con eliminación en cascada
--   5. Triggers para validar tipo de persona, tipo de
--      tripulación y solapamiento de vuelos
-- ==========================================================

-- Establece el esquema por defecto para todas las sentencias del script.
-- Sin esta línea PostgreSQL crearía las tablas en 'public' en lugar de
-- en aeropuerto_esq1, ya que ese es el search_path por defecto.
SET search_path TO aeropuerto_esq1;

-- ==========================================================
-- LIMPIEZA DEL ENTORNO
-- ==========================================================

-- Se añade CASCADE para forzar la eliminación automática de cualquier 
-- objeto que dependa de la tabla (como vistas o claves foráneas),
-- garantizando un borrado limpio aunque cambie el orden
DROP TABLE IF EXISTS Participa_en CASCADE;
DROP TABLE IF EXISTS Reserva CASCADE;
DROP TABLE IF EXISTS Vuelo CASCADE;
DROP TABLE IF EXISTS Persona CASCADE;
DROP TABLE IF EXISTS Aerolinea CASCADE;
DROP TABLE IF EXISTS Aeropuerto CASCADE;

-- ==========================================================
-- TABLAS BASE (sin dependencias)
-- ==========================================================

CREATE TABLE Aeropuerto (
    Iata_aeropuerto VARCHAR(3) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Ciudad VARCHAR(100) NOT NULL,
    Pais VARCHAR(100) NOT NULL,

    -- Rechaza cualquier código que no sean exactamente 3 letras mayúsculas
    CONSTRAINT chk_iata_aeropuerto
        CHECK (Iata_aeropuerto ~ '^[A-Z]{3}$')
);

CREATE TABLE Aerolinea (
    Iata_aerolinea VARCHAR(2) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Pais VARCHAR(100) NOT NULL,

    -- Rechaza cualquier código que no sean exactamente 2 caracteres alfanuméricos en mayúsculas
    CONSTRAINT chk_iata_aerolinea
        CHECK (Iata_aerolinea ~ '^[A-Z0-9]{2}$')
);

-- Almacena tanto pasajeros como tripulación en una única tabla.
-- El campo tipo_persona actúa como discriminador y determina qué atributos
-- son obligatorios y cuáles deben quedar a NULL en cada caso
CREATE TABLE Persona (
    Pasaporte VARCHAR(20) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Apellidos VARCHAR(150) NOT NULL,
    Telefono VARCHAR(20) NOT NULL,
    Tipo_persona VARCHAR(20) NOT NULL,  -- 'Pasajero' o 'Tripulacion'
    Nacionalidad VARCHAR(50),           -- solo para pasajeros
    Puesto VARCHAR(50),                 -- solo para tripulación: 'Piloto' o 'Auxiliar de vuelo'
    Anyos_experiencia INTEGER,          -- solo para tripulación; debe ser >= 0

    -- Solo admite los dos valores posibles para el discriminador
    CONSTRAINT chk_tipo_persona
        CHECK (Tipo_persona IN ('Pasajero', 'Tripulacion')),

    -- Si se informa el puesto, solo puede ser uno de estos dos valores
    CONSTRAINT chk_puesto
        CHECK (Puesto IS NULL OR Puesto IN ('Piloto', 'Auxiliar de vuelo')),

    -- Los años de experiencia, si se informan, no pueden ser negativos
    CONSTRAINT chk_anyos_exp
        CHECK (Anyos_experiencia IS NULL OR Anyos_experiencia >= 0),

    -- Garantiza que cada fila sea coherente con su tipo_persona;
    -- impide, por ejemplo, un pasajero con puesto o una tripulación sin experiencia
    CONSTRAINT chk_persona_tipo
        CHECK (
            (Tipo_persona = 'Pasajero' AND Nacionalidad IS NOT NULL AND Puesto IS NULL AND Anyos_experiencia IS NULL)
            OR
            (Tipo_persona = 'Tripulacion' AND Nacionalidad IS NULL AND Puesto IS NOT NULL AND Anyos_experiencia IS NOT NULL)
        )
);

-- ==========================================================
-- TABLAS DEPENDIENTES
-- ==========================================================

CREATE TABLE Vuelo (
    Codigo_vuelo VARCHAR(20) PRIMARY KEY,
    Fecha_salida DATE NOT NULL,
    Hora_salida TIME NOT NULL,
    Fecha_llegada DATE NOT NULL,
    Hora_llegada TIME NOT NULL,
    Iata_aerolinea VARCHAR(2) NOT NULL,  -- aerolínea que opera el vuelo
    Iata_origen VARCHAR(3) NOT NULL,     -- aeropuerto de salida
    Iata_destino VARCHAR(3) NOT NULL,    -- aeropuerto de llegada

    -- Asegura que la aerolínea referenciada existe en la tabla Aerolinea
    CONSTRAINT fk_vuelo_aerolinea
        FOREIGN KEY (Iata_aerolinea)
        REFERENCES Aerolinea(Iata_aerolinea),

    -- Asegura que el aeropuerto de origen existe en la tabla Aeropuerto
    CONSTRAINT fk_vuelo_origen
        FOREIGN KEY (Iata_origen)
        REFERENCES Aeropuerto(Iata_aeropuerto),

    -- Asegura que el aeropuerto de destino existe en la tabla Aeropuerto
    CONSTRAINT fk_vuelo_destino
        FOREIGN KEY (Iata_destino)
        REFERENCES Aeropuerto(Iata_aeropuerto),

    -- Un vuelo no puede tener el mismo aeropuerto como origen y destino
    CONSTRAINT chk_origen_destino
        CHECK (Iata_origen <> Iata_destino),

    -- La llegada debe ser estrictamente posterior a la salida;
    -- la comparación de tuplas (fecha, hora) evalúa primero la fecha y,
    -- si coincide, desempata con la hora
    CONSTRAINT chk_fechas
        CHECK (
            (Fecha_llegada > Fecha_salida)
            OR
            (Fecha_llegada = Fecha_salida AND Hora_llegada > Hora_salida)
        )
);

CREATE TABLE Reserva (
    Pasaporte VARCHAR(20) NOT NULL,
    Codigo_vuelo VARCHAR(20) NOT NULL,
    Asiento VARCHAR(10) NOT NULL,
    Clase VARCHAR(20) NOT NULL,

    PRIMARY KEY (Pasaporte, Codigo_vuelo),

    -- Si se elimina una persona, sus reservas se eliminan en cascada
    CONSTRAINT fk_reserva_persona
        FOREIGN KEY (Pasaporte)
        REFERENCES Persona(Pasaporte)
        ON DELETE CASCADE,

    -- Si se elimina un vuelo, sus reservas se eliminan en cascada
    CONSTRAINT fk_reserva_vuelo
        FOREIGN KEY (Codigo_vuelo)
        REFERENCES Vuelo(Codigo_vuelo)
        ON DELETE CASCADE,

    -- Solo se admiten estas tres categorías de clase
    CONSTRAINT chk_clase
        CHECK (Clase IN ('Turista', 'Business', 'Primera')),

    -- Dos pasajeros distintos no pueden ocupar el mismo asiento en el mismo vuelo
    CONSTRAINT uq_asiento_vuelo UNIQUE (Codigo_vuelo, Asiento)
);

CREATE TABLE Participa_en (
    Pasaporte VARCHAR(20) NOT NULL,
    Codigo_vuelo VARCHAR(20) NOT NULL,
    Rol VARCHAR(50) NOT NULL,  -- función desempeñada en el vuelo

    PRIMARY KEY (Pasaporte, Codigo_vuelo),

    -- Si se elimina una persona, sus participaciones se eliminan en cascada
    CONSTRAINT fk_participa_persona
        FOREIGN KEY (Pasaporte)
        REFERENCES Persona(Pasaporte)
        ON DELETE CASCADE,

    -- Si se elimina un vuelo, sus participaciones se eliminan en cascada
    CONSTRAINT fk_participa_vuelo
        FOREIGN KEY (Codigo_vuelo)
        REFERENCES Vuelo(Codigo_vuelo)
        ON DELETE CASCADE,

    -- Solo se admiten estos tres roles operativos
    CONSTRAINT chk_rol
        CHECK (Rol IN ('Comandante', 'Copiloto', 'Auxiliar de vuelo'))
);

-- ==========================================================
-- TRIGGER: SOLO PASAJEROS PUEDEN REALIZAR RESERVAS
-- ==========================================================
-- Función ejecutada antes de cada INSERT o UPDATE en Reserva.
-- Consulta la tabla Persona y lanza un error si la persona no es de tipo 'Pasajero',
-- impidiendo que un miembro de tripulación figure como pasajero reservado
CREATE OR REPLACE FUNCTION aeropuerto_esq1.check_reserva_pasajero()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM aeropuerto_esq1.Persona
        WHERE Pasaporte = NEW.Pasaporte
          AND tipo_persona = 'Pasajero'
    ) THEN
        RAISE EXCEPTION 'La persona con pasaporte % no es un pasajero.', NEW.Pasaporte;
    END IF;

    RETURN NEW;  -- permite continuar con la operación si la validación pasa
END;
$$ LANGUAGE plpgsql;

-- Asocia la función anterior a la tabla Reserva; se dispara fila a fila antes de escribir
DROP TRIGGER IF EXISTS trg_reserva_pasajero ON aeropuerto_esq1.Reserva;
CREATE TRIGGER trg_reserva_pasajero
BEFORE INSERT OR UPDATE ON aeropuerto_esq1.Reserva
FOR EACH ROW
EXECUTE FUNCTION aeropuerto_esq1.check_reserva_pasajero();

-- ==========================================================
-- TRIGGER: SOLO TRIPULACIÓN PUEDE PARTICIPAR EN VUELOS
-- ==========================================================
-- Función ejecutada antes de cada INSERT o UPDATE en Participa_en.
-- Consulta la tabla Persona y lanza un error si la persona no es de tipo 'Tripulacion',
-- impidiendo que un pasajero figure como miembro de la tripulación de un vuelo
CREATE OR REPLACE FUNCTION aeropuerto_esq1.check_tripulacion_participa()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM aeropuerto_esq1.Persona
        WHERE Pasaporte = NEW.Pasaporte
          AND tipo_persona = 'Tripulacion'
    ) THEN
        RAISE EXCEPTION 'La persona con pasaporte % no pertenece a la tripulación.', NEW.Pasaporte;
    END IF;

    RETURN NEW;  -- permite continuar con la operación si la validación pasa
END;
$$ LANGUAGE plpgsql;

-- Asocia la función anterior a la tabla Participa_en; se dispara fila a fila antes de escribir
DROP TRIGGER IF EXISTS trg_participa_tripulacion ON aeropuerto_esq1.Participa_en;
CREATE TRIGGER trg_participa_tripulacion
BEFORE INSERT OR UPDATE ON aeropuerto_esq1.Participa_en
FOR EACH ROW
EXECUTE FUNCTION aeropuerto_esq1.check_tripulacion_participa();

-- ==========================================================
-- TRIGGER: DETECCIÓN DE SOLAPAMIENTO DE VUELOS
-- ==========================================================
-- Función compartida que detecta solapamientos temporales entre vuelos
-- para una misma persona. Dado que pasajeros y tripulación son tipos excluyentes,
-- la comprobación se hace de forma independiente en cada tabla usando TG_TABLE_NAME
-- para saber desde cuál se disparó el trigger.
-- Hay solapamiento cuando los intervalos [salida, llegada] de dos vuelos distintos se cruzan,
-- es decir: inicio_A < fin_B Y inicio_B < fin_A
CREATE OR REPLACE FUNCTION aeropuerto_esq1.check_solapamiento_vuelos()
RETURNS TRIGGER AS $$
BEGIN
    -- En un UPDATE donde el vuelo no cambia, no puede haber solapamiento nuevo; se omite la comprobación
    IF TG_OP = 'UPDATE' AND NEW.Codigo_vuelo = OLD.Codigo_vuelo THEN
        RETURN NEW;
    END IF;

    -- Comprobación de solapamiento para pasajeros (disparado desde Reserva)
    IF TG_TABLE_NAME = 'reserva' THEN

        -- Busca cualquier reserva existente del mismo pasajero cuyo vuelo se solape con el nuevo
        IF EXISTS (
            SELECT 1
            FROM aeropuerto_esq1.Reserva r
            JOIN aeropuerto_esq1.Vuelo v1 ON r.Codigo_vuelo = v1.Codigo_vuelo   -- vuelo ya reservado
            JOIN aeropuerto_esq1.Vuelo v2 ON v2.Codigo_vuelo = NEW.Codigo_vuelo -- vuelo que se intenta reservar
            WHERE r.Pasaporte = NEW.Pasaporte
              AND r.Codigo_vuelo <> NEW.Codigo_vuelo            -- descarta la propia fila en UPDATE
              AND (v1.Fecha_salida, v1.Hora_salida) < (v2.Fecha_llegada, v2.Hora_llegada)
              AND (v2.Fecha_salida, v2.Hora_salida) < (v1.Fecha_llegada, v1.Hora_llegada)
        ) THEN
            RAISE EXCEPTION 'Solapamiento de vuelos en reservas para el pasaporte %.', NEW.Pasaporte;
        END IF;

    -- Comprobación de solapamiento para tripulación (disparado desde Participa_en)
    ELSE

        -- Busca cualquier participación existente del mismo miembro cuyo vuelo se solape con el nuevo
        IF EXISTS (
            SELECT 1
            FROM aeropuerto_esq1.Participa_en p
            JOIN aeropuerto_esq1.Vuelo v1 ON p.Codigo_vuelo = v1.Codigo_vuelo   -- vuelo en el que ya participa
            JOIN aeropuerto_esq1.Vuelo v2 ON v2.Codigo_vuelo = NEW.Codigo_vuelo -- vuelo que se intenta asignar
            WHERE p.Pasaporte = NEW.Pasaporte
              AND p.Codigo_vuelo <> NEW.Codigo_vuelo            -- descarta la propia fila en UPDATE
              AND (v1.Fecha_salida, v1.Hora_salida) < (v2.Fecha_llegada, v2.Hora_llegada)
              AND (v2.Fecha_salida, v2.Hora_salida) < (v1.Fecha_llegada, v1.Hora_llegada)
        ) THEN
            RAISE EXCEPTION 'Solapamiento de vuelos en tripulación para el pasaporte %.', NEW.Pasaporte;
        END IF;

    END IF;

    RETURN NEW;  -- permite continuar con la operación si no hay solapamiento
END;
$$ LANGUAGE plpgsql;

-- Registra el trigger de solapamiento en Reserva (para pasajeros)
DROP TRIGGER IF EXISTS trg_solapamiento_reserva ON aeropuerto_esq1.Reserva;
CREATE TRIGGER trg_solapamiento_reserva
BEFORE INSERT OR UPDATE ON aeropuerto_esq1.Reserva
FOR EACH ROW
EXECUTE FUNCTION aeropuerto_esq1.check_solapamiento_vuelos();

-- Registra el mismo trigger en Participa_en (para tripulación);
-- TG_TABLE_NAME dentro de la función distinguirá cuál de los dos lo disparó
DROP TRIGGER IF EXISTS trg_solapamiento_participa ON aeropuerto_esq1.Participa_en;
CREATE TRIGGER trg_solapamiento_participa
BEFORE INSERT OR UPDATE ON aeropuerto_esq1.Participa_en
FOR EACH ROW
EXECUTE FUNCTION aeropuerto_esq1.check_solapamiento_vuelos();