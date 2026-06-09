-- ==========================================================
-- Script:      bd-postgresql-esquema2-p3-pruebas.sql
-- SGBD:        PostgreSQL
-- Depende de:  bd-postgresql-esquema2-p3.sql
-- Propósito:   Pruebas de integridad del esquema de gestión
--              aeroportuaria con especialización de persona
-- Contenido:
--   1. Limpieza del entorno
--   2. Inserciones válidas para poblar el entorno de pruebas
--   3. Violaciones de restricciones CHECK
--   4. Violaciones de claves foráneas
--   5. Violaciones de triggers
-- ==========================================================

-- Establece el esquema por defecto para todas las consultas del script,
-- evitando tener que escribir el prefijo aeropuerto_esq2. en cada una.
-- Aunque el script se ejecute conectado a bd_aeropuerto_esq2, el
-- search_path por defecto de PostgreSQL apunta a 'public', por lo que
-- sin esta línea las sentencias no encontrarían las tablas del esquema.
SET search_path TO aeropuerto_esq2;

-- ==========================================================
-- LIMPIEZA DEL ENTORNO
-- ==========================================================

-- Vacía todas las tablas del entorno de pruebas; CASCADE se encarga
-- de propagar el borrado a las tablas dependientes automáticamente
TRUNCATE TABLE Aeropuerto CASCADE;
TRUNCATE TABLE Compania_aerea CASCADE;
TRUNCATE TABLE Persona CASCADE;

-- ==========================================================
-- INSERCIONES VÁLIDAS
-- ==========================================================
-- Pobla el esquema con datos correctos que servirán de base
-- para las pruebas posteriores

DO $$
BEGIN
    INSERT INTO Aeropuerto VALUES ('MAD', 'Adolfo Suárez Madrid-Barajas', 'Madrid', 'España');
    INSERT INTO Aeropuerto VALUES ('BCN', 'Josep Tarradellas Barcelona-El Prat', 'Barcelona', 'España');
    INSERT INTO Aeropuerto VALUES ('JFK', 'John F. Kennedy International', 'Nueva York', 'Estados Unidos');
    RAISE NOTICE 'OK: aeropuertos insertados correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en aeropuertos → %', SQLERRM;
END;
$$;

DO $$
BEGIN
    INSERT INTO Compania_aerea VALUES ('IB', 'Iberia', 'España');
    INSERT INTO Compania_aerea VALUES ('VY', 'Vueling', 'España');
    RAISE NOTICE 'OK: compañías aéreas insertadas correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en compañías aéreas → %', SQLERRM;
END;
$$;

DO $$
BEGIN
    -- Primero se inserta la persona base, luego el subtipo correspondiente
    INSERT INTO Persona VALUES ('P101', 'Sofía Fernández Ruiz',   '600000101');
    INSERT INTO Persona VALUES ('P102', 'Marcos Delgado López',   '600000102');
    INSERT INTO Persona VALUES ('T101', 'Isabel Castro Moreno',   '600000103');
    INSERT INTO Persona VALUES ('T102', 'Andrés Vidal Serrano',   '600000104');
    RAISE NOTICE 'OK: personas base insertadas correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en personas → %', SQLERRM;
END;
$$;

DO $$
BEGIN
    INSERT INTO Pasajero VALUES ('P101', 'Española');
    INSERT INTO Pasajero VALUES ('P102', 'Italiana');
    RAISE NOTICE 'OK: pasajeros insertados correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en pasajeros → %', SQLERRM;
END;
$$;

DO $$
BEGIN
    INSERT INTO Miembro_tripulacion VALUES ('T101', 'Piloto',             8);
    INSERT INTO Miembro_tripulacion VALUES ('T102', 'Auxiliar de vuelo',  3);
    RAISE NOTICE 'OK: miembros de tripulación insertados correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en miembros de tripulación → %', SQLERRM;
END;
$$;

DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB101', '2025-06-01 08:00', '2025-06-01 09:30', 'IB', 'MAD', 'BCN');
    INSERT INTO Vuelo VALUES ('IB102', '2025-06-01 12:00', '2025-06-01 19:00', 'IB', 'MAD', 'JFK');
    INSERT INTO Vuelo VALUES ('VY101', '2025-06-02 10:00', '2025-06-02 11:30', 'VY', 'BCN', 'MAD');
    RAISE NOTICE 'OK: vuelos insertados correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en vuelos → %', SQLERRM;
END;
$$;

DO $$
BEGIN
    INSERT INTO Billete_emitido VALUES ('P101', 'IB101', '14A', 'Turista');
    INSERT INTO Billete_emitido VALUES ('P102', 'IB102', '2B',  'Business');
    RAISE NOTICE 'OK: billetes insertados correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en billetes → %', SQLERRM;
END;
$$;

DO $$
BEGIN
    INSERT INTO Asignacion_laboral VALUES ('T101', 'IB101', 'Comandante');
    INSERT INTO Asignacion_laboral VALUES ('T102', 'IB101', 'Auxiliar de vuelo');
    RAISE NOTICE 'OK: asignaciones laborales insertadas correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en asignaciones laborales → %', SQLERRM;
END;
$$;

-- ==========================================================
-- VIOLACIONES DE RESTRICCIONES CHECK
-- ==========================================================

-- Aeropuerto: código con minúsculas (viola chk_codigo_aeropuerto)
DO $$
BEGIN
    INSERT INTO Aeropuerto VALUES ('mad', 'Adolfo Suárez Madrid-Barajas', 'Madrid', 'España');
    RAISE NOTICE 'ERROR: debería haber fallado (código aeropuerto en minúsculas)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (código aeropuerto en minúsculas) → %', SQLERRM;
END;
$$;

-- Aeropuerto: código con más de 3 letras (viola chk_codigo_aeropuerto)
DO $$
BEGIN
    INSERT INTO Aeropuerto VALUES ('MADR', 'Adolfo Suárez Madrid-Barajas', 'Madrid', 'España');
    RAISE NOTICE 'ERROR: debería haber fallado (código aeropuerto con 4 letras)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (código aeropuerto con 4 letras) → %', SQLERRM;
END;
$$;

-- Compañía aérea: código en minúsculas (viola chk_codigo_oficial)
DO $$
BEGIN
    INSERT INTO Compania_aerea VALUES ('ib', 'Iberia', 'España');
    RAISE NOTICE 'ERROR: debería haber fallado (código compañía en minúsculas)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (código compañía en minúsculas) → %', SQLERRM;
END;
$$;

-- Miembro_tripulacion: puesto con valor no permitido (viola chk_puesto)
DO $$
BEGIN
    INSERT INTO Persona VALUES ('T103', 'Roberto Fuentes', '600000105');
    INSERT INTO Miembro_tripulacion VALUES ('T103', 'Mecánico', 8);
    RAISE NOTICE 'ERROR: debería haber fallado (puesto inválido)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (puesto inválido) → %', SQLERRM;
END;
$$;

-- Miembro_tripulacion: años de experiencia negativos (viola chk_anyos_exp)
DO $$
BEGIN
    INSERT INTO Persona VALUES ('T104', 'Sara Iglesias', '600000106');
    INSERT INTO Miembro_tripulacion VALUES ('T104', 'Piloto', -3);
    RAISE NOTICE 'ERROR: debería haber fallado (experiencia negativa)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (experiencia negativa) → %', SQLERRM;
END;
$$;

-- Vuelo: origen igual al destino (viola chk_origen_destino)
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB199', '2025-06-01 08:00', '2025-06-01 09:00', 'IB', 'MAD', 'MAD');
    RAISE NOTICE 'ERROR: debería haber fallado (origen igual a destino)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (origen igual a destino) → %', SQLERRM;
END;
$$;

-- Vuelo: datetime de llegada anterior a la de salida (viola chk_datetime)
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB198', '2025-06-01 10:00', '2025-06-01 09:00', 'IB', 'MAD', 'BCN');
    RAISE NOTICE 'ERROR: debería haber fallado (llegada anterior a salida)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (llegada anterior a salida) → %', SQLERRM;
END;
$$;

-- Billete_emitido: categoría de viaje con valor no permitido (viola chk_categoria)
DO $$
BEGIN
    INSERT INTO Billete_emitido VALUES ('P101', 'VY101', '10C', 'Premium');
    RAISE NOTICE 'ERROR: debería haber fallado (categoría de viaje inválida)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (categoría de viaje inválida) → %', SQLERRM;
END;
$$;

-- Billete_emitido: dos pasajeros con la misma butaca en el mismo vuelo (viola uq_butaca_vuelo)
DO $$
BEGIN
    INSERT INTO Billete_emitido VALUES ('P102', 'IB101', '14A', 'Turista');
    RAISE NOTICE 'ERROR: debería haber fallado (butaca duplicada en el mismo vuelo)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (butaca duplicada en el mismo vuelo) → %', SQLERRM;
END;
$$;

-- Asignacion_laboral: función con valor no permitido (viola chk_funcion)
DO $$
BEGIN
    INSERT INTO Asignacion_laboral VALUES ('T101', 'VY101', 'Técnico');
    RAISE NOTICE 'ERROR: debería haber fallado (función inválida)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (función inválida) → %', SQLERRM;
END;
$$;

-- ==========================================================
-- VIOLACIONES DE CLAVES FORÁNEAS
-- ==========================================================

-- Vuelo: compañía aérea inexistente
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('XX101', '2025-06-01 08:00', '2025-06-01 10:00', 'XX', 'MAD', 'BCN');
    RAISE NOTICE 'ERROR: debería haber fallado (compañía aérea inexistente)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (compañía aérea inexistente) → %', SQLERRM;
END;
$$;

-- Vuelo: aeropuerto de origen inexistente
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB197', '2025-06-01 08:00', '2025-06-01 10:00', 'IB', 'ZZZ', 'BCN');
    RAISE NOTICE 'ERROR: debería haber fallado (aeropuerto origen inexistente)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (aeropuerto origen inexistente) → %', SQLERRM;
END;
$$;

-- Vuelo: aeropuerto de destino inexistente
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB196', '2025-06-01 08:00', '2025-06-01 10:00', 'IB', 'MAD', 'ZZZ');
    RAISE NOTICE 'ERROR: debería haber fallado (aeropuerto destino inexistente)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (aeropuerto destino inexistente) → %', SQLERRM;
END;
$$;

-- Pasajero: num_pasaporte inexistente en Persona
DO $$
BEGIN
    INSERT INTO Pasajero VALUES ('NOEXISTE', 'Española');
    RAISE NOTICE 'ERROR: debería haber fallado (persona inexistente al insertar pasajero)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (persona inexistente al insertar pasajero) → %', SQLERRM;
END;
$$;

-- Miembro_tripulacion: num_pasaporte inexistente en Persona
DO $$
BEGIN
    INSERT INTO Miembro_tripulacion VALUES ('NOEXISTE', 'Piloto', 5);
    RAISE NOTICE 'ERROR: debería haber fallado (persona inexistente al insertar tripulación)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (persona inexistente al insertar tripulación) → %', SQLERRM;
END;
$$;

-- Billete_emitido: num_pasaporte inexistente en Pasajero
DO $$
BEGIN
    INSERT INTO Billete_emitido VALUES ('NOEXISTE', 'IB101', '5C', 'Turista');
    RAISE NOTICE 'ERROR: debería haber fallado (pasajero inexistente en billete)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (pasajero inexistente en billete) → %', SQLERRM;
END;
$$;

-- Billete_emitido: num_vuelo inexistente en Vuelo
DO $$
BEGIN
    INSERT INTO Billete_emitido VALUES ('P101', 'NOVUELO', '5C', 'Turista');
    RAISE NOTICE 'ERROR: debería haber fallado (vuelo inexistente en billete)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (vuelo inexistente en billete) → %', SQLERRM;
END;
$$;

-- Asignacion_laboral: num_pasaporte inexistente en Miembro_tripulacion
DO $$
BEGIN
    INSERT INTO Asignacion_laboral VALUES ('NOEXISTE', 'IB101', 'Copiloto');
    RAISE NOTICE 'ERROR: debería haber fallado (miembro de tripulación inexistente en asignación)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (miembro de tripulación inexistente en asignación) → %', SQLERRM;
END;
$$;

-- Asignacion_laboral: num_vuelo inexistente en Vuelo
DO $$
BEGIN
    INSERT INTO Asignacion_laboral VALUES ('T101', 'NOVUELO', 'Comandante');
    RAISE NOTICE 'ERROR: debería haber fallado (vuelo inexistente en asignación)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (vuelo inexistente en asignación) → %', SQLERRM;
END;
$$;

-- ==========================================================
-- VIOLACIONES DE TRIGGERS
-- ==========================================================

-- Trigger R11: una persona ya registrada como pasajero intenta registrarse como tripulación
DO $$
BEGIN
    INSERT INTO Miembro_tripulacion VALUES ('P101', 'Piloto', 5);
    RAISE NOTICE 'ERROR: debería haber fallado (pasajero intentando registrarse como tripulación)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (pasajero intentando registrarse como tripulación) → %', SQLERRM;
END;
$$;

-- Trigger R11: una persona ya registrada como tripulación intenta registrarse como pasajero
DO $$
BEGIN
    INSERT INTO Pasajero VALUES ('T101', 'Española');
    RAISE NOTICE 'ERROR: debería haber fallado (tripulación intentando registrarse como pasajero)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (tripulación intentando registrarse como pasajero) → %', SQLERRM;
END;
$$;

-- Trigger solapamiento billetes: pasajero con dos billetes en vuelos solapados en el tiempo
-- P101 ya tiene billete en IB101 (08:00-09:30); IB103 se solapa en ese intervalo
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB103', '2025-06-01 08:30', '2025-06-01 11:00', 'IB', 'MAD', 'JFK');
    INSERT INTO Billete_emitido VALUES ('P101', 'IB103', '1A', 'Primera');
    RAISE NOTICE 'ERROR: debería haber fallado (solapamiento de vuelos en billetes)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (solapamiento de vuelos en billetes) → %', SQLERRM;
END;
$$;

-- Trigger solapamiento tripulación: miembro asignado a dos vuelos solapados en el tiempo
-- T101 ya participa en IB101 (08:00-09:30); IB104 se solapa en ese intervalo
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB104', '2025-06-01 09:00', '2025-06-01 10:30', 'VY', 'BCN', 'MAD');
    INSERT INTO Asignacion_laboral VALUES ('T101', 'IB104', 'Comandante');
    RAISE NOTICE 'ERROR: debería haber fallado (solapamiento de vuelos en asignación laboral)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (solapamiento de vuelos en asignación laboral) → %', SQLERRM;
END;
$$;