-- ==========================================================
-- Script:      bd-postgresql-esquema1-p3-pruebas.sql
-- SGBD:        PostgreSQL
-- Depende de:  bd-postgresql-esquema1-p3.sql
-- Propósito:   Pruebas de integridad del esquema de gestión
--              aeroportuaria
-- Contenido:
--   1. Limpieza del entorno
--   2. Inserciones válidas para poblar el entorno de pruebas
--   3. Violaciones de restricciones CHECK
--   4. Violaciones de claves foráneas
--   5. Violaciones de triggers
-- ==========================================================

-- Establece el esquema por defecto para todas las consultas del script,
-- evitando tener que escribir el prefijo aeropuerto_esq1. en cada una.
-- Aunque el script se ejecute conectado a bd_aeropuerto_esq1, el
-- search_path por defecto de PostgreSQL apunta a 'public', por lo que
-- sin esta línea las sentencias no encontrarían las tablas del esquema.
SET search_path TO aeropuerto_esq1;

-- ==========================================================
-- LIMPIEZA DEL ENTORNO
-- ==========================================================

-- Vacía todas las tablas del entorno de pruebas; CASCADE se encarga
-- de propagar el borrado a las tablas dependientes automáticamente
TRUNCATE TABLE Aeropuerto CASCADE;
TRUNCATE TABLE Aerolinea CASCADE;
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
    INSERT INTO Aerolinea VALUES ('IB', 'Iberia', 'España');
    INSERT INTO Aerolinea VALUES ('VY', 'Vueling', 'España');
    RAISE NOTICE 'OK: aerolíneas insertadas correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en aerolíneas → %', SQLERRM;
END;
$$;

DO $$
BEGIN
    -- Pasajeros: nacionalidad obligatoria, puesto y experiencia deben ser NULL
    INSERT INTO Persona VALUES ('P001', 'Ana', 'García López', '600000001', 'Pasajero', 'Española', NULL, NULL);
    INSERT INTO Persona VALUES ('P002', 'Luis', 'Martínez Ruiz', '600000002', 'Pasajero', 'Francesa', NULL, NULL);
    -- Tripulación: puesto y experiencia obligatorios, nacionalidad debe ser NULL
    INSERT INTO Persona VALUES ('T001', 'Carlos', 'Sánchez Mora', '600000003', 'Tripulacion', NULL, 'Piloto', 12);
    INSERT INTO Persona VALUES ('T002', 'Elena', 'Romero Gil', '600000004', 'Tripulacion', NULL, 'Auxiliar de vuelo', 5);
    RAISE NOTICE 'OK: personas insertadas correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en personas → %', SQLERRM;
END;
$$;

DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB001', '2025-06-01', '08:00', '2025-06-01', '09:30', 'IB', 'MAD', 'BCN');
    INSERT INTO Vuelo VALUES ('IB002', '2025-06-01', '12:00', '2025-06-01', '19:00', 'IB', 'MAD', 'JFK');
    INSERT INTO Vuelo VALUES ('VY001', '2025-06-02', '10:00', '2025-06-02', '11:30', 'VY', 'BCN', 'MAD');
    RAISE NOTICE 'OK: vuelos insertados correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en vuelos → %', SQLERRM;
END;
$$;

DO $$
BEGIN
    INSERT INTO Reserva VALUES ('P001', 'IB001', '14A', 'Turista');
    INSERT INTO Reserva VALUES ('P002', 'IB002', '2B', 'Business');
    RAISE NOTICE 'OK: reservas insertadas correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en reservas → %', SQLERRM;
END;
$$;

DO $$
BEGIN
    INSERT INTO Participa_en VALUES ('T001', 'IB001', 'Comandante');
    INSERT INTO Participa_en VALUES ('T002', 'IB001', 'Auxiliar de vuelo');
    RAISE NOTICE 'OK: participaciones insertadas correctamente';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'ERROR inesperado en participaciones → %', SQLERRM;
END;
$$;

-- ==========================================================
-- VIOLACIONES DE RESTRICCIONES CHECK
-- ==========================================================

-- Aeropuerto: código IATA con minúsculas (viola chk_iata_aeropuerto)
DO $$
BEGIN
    INSERT INTO Aeropuerto VALUES ('mad', 'Adolfo Suárez Madrid-Barajas', 'Madrid', 'España');
    RAISE NOTICE 'ERROR: debería haber fallado (IATA aeropuerto en minúsculas)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (IATA aeropuerto en minúsculas) → %', SQLERRM;
END;
$$;

-- Aeropuerto: código IATA con más de 3 letras (viola chk_iata_aeropuerto)
DO $$
BEGIN
    INSERT INTO Aeropuerto VALUES ('MADR', 'Adolfo Suárez Madrid-Barajas', 'Madrid', 'España');
    RAISE NOTICE 'ERROR: debería haber fallado (IATA aeropuerto con 4 letras)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (IATA aeropuerto con 4 letras) → %', SQLERRM;
END;
$$;

-- Aerolínea: código IATA en minúsculas (viola chk_iata_aerolinea)
DO $$
BEGIN
    INSERT INTO Aerolinea VALUES ('ib', 'Iberia', 'España');
    RAISE NOTICE 'ERROR: debería haber fallado (IATA aerolínea en minúsculas)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (IATA aerolínea en minúsculas) → %', SQLERRM;
END;
$$;

-- Persona: tipo_persona con valor no permitido (viola chk_tipo_persona)
DO $$
BEGIN
    INSERT INTO Persona VALUES ('X001', 'Pedro', 'López', '600000005', 'Otro', 'Española', NULL, NULL);
    RAISE NOTICE 'ERROR: debería haber fallado (tipo_persona inválido)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (tipo_persona inválido) → %', SQLERRM;
END;
$$;

-- Persona: pasajero con puesto informado (viola chk_persona_tipo)
DO $$
BEGIN
    INSERT INTO Persona VALUES ('X002', 'Marta', 'Díaz', '600000006', 'Pasajero', 'Española', 'Piloto', NULL);
    RAISE NOTICE 'ERROR: debería haber fallado (pasajero con puesto)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (pasajero con puesto) → %', SQLERRM;
END;
$$;

-- Persona: tripulación sin puesto (viola chk_persona_tipo)
DO $$
BEGIN
    INSERT INTO Persona VALUES ('X003', 'Jorge', 'Navarro', '600000007', 'Tripulacion', NULL, NULL, 5);
    RAISE NOTICE 'ERROR: debería haber fallado (tripulación sin puesto)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (tripulación sin puesto) → %', SQLERRM;
END;
$$;

-- Persona: tripulación con años de experiencia negativos (viola chk_anyos_exp)
DO $$
BEGIN
    INSERT INTO Persona VALUES ('X004', 'Sara', 'Iglesias', '600000008', 'Tripulacion', NULL, 'Piloto', -3);
    RAISE NOTICE 'ERROR: debería haber fallado (experiencia negativa)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (experiencia negativa) → %', SQLERRM;
END;
$$;

-- Persona: puesto con valor no permitido (viola chk_puesto)
DO $$
BEGIN
    INSERT INTO Persona VALUES ('X005', 'Raúl', 'Vega', '600000009', 'Tripulacion', NULL, 'Mecánico', 8);
    RAISE NOTICE 'ERROR: debería haber fallado (puesto inválido)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (puesto inválido) → %', SQLERRM;
END;
$$;

-- Vuelo: origen igual al destino (viola chk_origen_destino)
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB999', '2025-06-01', '08:00', '2025-06-01', '09:00', 'IB', 'MAD', 'MAD');
    RAISE NOTICE 'ERROR: debería haber fallado (origen igual a destino)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (origen igual a destino) → %', SQLERRM;
END;
$$;

-- Vuelo: fecha de llegada anterior a la de salida (viola chk_fechas)
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB998', '2025-06-01', '10:00', '2025-06-01', '09:00', 'IB', 'MAD', 'BCN');
    RAISE NOTICE 'ERROR: debería haber fallado (llegada anterior a salida)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (llegada anterior a salida) → %', SQLERRM;
END;
$$;

-- Reserva: clase con valor no permitido (viola chk_clase)
DO $$
BEGIN
    INSERT INTO Reserva VALUES ('P001', 'VY001', '10C', 'Premium');
    RAISE NOTICE 'ERROR: debería haber fallado (clase inválida)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (clase inválida) → %', SQLERRM;
END;
$$;

-- Reserva: dos pasajeros con el mismo asiento en el mismo vuelo (viola uq_asiento_vuelo)
DO $$
BEGIN
    INSERT INTO Reserva VALUES ('P002', 'IB001', '14A', 'Turista');
    RAISE NOTICE 'ERROR: debería haber fallado (asiento duplicado en el mismo vuelo)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (asiento duplicado en el mismo vuelo) → %', SQLERRM;
END;
$$;

-- Participa_en: rol con valor no permitido (viola chk_rol)
DO $$
BEGIN
    INSERT INTO Participa_en VALUES ('T001', 'VY001', 'Técnico');
    RAISE NOTICE 'ERROR: debería haber fallado (rol inválido)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (rol inválido) → %', SQLERRM;
END;
$$;

-- ==========================================================
-- VIOLACIONES DE CLAVES FORÁNEAS
-- ==========================================================

-- Vuelo: aerolínea inexistente
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('XX001', '2025-06-01', '08:00', '2025-06-01', '10:00', 'XX', 'MAD', 'BCN');
    RAISE NOTICE 'ERROR: debería haber fallado (aerolínea inexistente)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (aerolínea inexistente) → %', SQLERRM;
END;
$$;

-- Vuelo: aeropuerto de origen inexistente
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB997', '2025-06-01', '08:00', '2025-06-01', '10:00', 'IB', 'ZZZ', 'BCN');
    RAISE NOTICE 'ERROR: debería haber fallado (aeropuerto origen inexistente)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (aeropuerto origen inexistente) → %', SQLERRM;
END;
$$;

-- Vuelo: aeropuerto de destino inexistente
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB996', '2025-06-01', '08:00', '2025-06-01', '10:00', 'IB', 'MAD', 'ZZZ');
    RAISE NOTICE 'ERROR: debería haber fallado (aeropuerto destino inexistente)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (aeropuerto destino inexistente) → %', SQLERRM;
END;
$$;

-- Reserva: pasaporte inexistente en Persona
DO $$
BEGIN
    INSERT INTO Reserva VALUES ('NOEXISTE', 'IB001', '5C', 'Turista');
    RAISE NOTICE 'ERROR: debería haber fallado (pasaporte inexistente en reserva)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (pasaporte inexistente en reserva) → %', SQLERRM;
END;
$$;

-- Reserva: código de vuelo inexistente
DO $$
BEGIN
    INSERT INTO Reserva VALUES ('P001', 'NOVUELO', '5C', 'Turista');
    RAISE NOTICE 'ERROR: debería haber fallado (vuelo inexistente en reserva)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (vuelo inexistente en reserva) → %', SQLERRM;
END;
$$;

-- Participa_en: pasaporte inexistente en Persona
DO $$
BEGIN
    INSERT INTO Participa_en VALUES ('NOEXISTE', 'IB001', 'Copiloto');
    RAISE NOTICE 'ERROR: debería haber fallado (pasaporte inexistente en participación)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (pasaporte inexistente en participación) → %', SQLERRM;
END;
$$;

-- Participa_en: código de vuelo inexistente
DO $$
BEGIN
    INSERT INTO Participa_en VALUES ('T001', 'NOVUELO', 'Comandante');
    RAISE NOTICE 'ERROR: debería haber fallado (vuelo inexistente en participación)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (vuelo inexistente en participación) → %', SQLERRM;
END;
$$;

-- ==========================================================
-- VIOLACIONES DE TRIGGERS
-- ==========================================================

-- Un miembro de tripulación intenta hacer una reserva
DO $$
BEGIN
    INSERT INTO Reserva VALUES ('T001', 'IB001', '20D', 'Turista');
    RAISE NOTICE 'ERROR: debería haber fallado (tripulación intentando reservar)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (tripulación intentando reservar) → %', SQLERRM;
END;
$$;

-- Un pasajero intenta participar como tripulación
DO $$
BEGIN
    INSERT INTO Participa_en VALUES ('P001', 'IB001', 'Auxiliar de vuelo');
    RAISE NOTICE 'ERROR: debería haber fallado (pasajero intentando participar como tripulación)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (pasajero intentando participar como tripulación) → %', SQLERRM;
END;
$$;

-- Pasajero con dos reservas en vuelos solapados en el tiempo P001 ya
-- tiene reserva en IB001 (08:00-09:30); IB003 se solapa en ese intervalo
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB003', '2025-06-01', '08:30', '2025-06-01', '11:00', 'IB', 'MAD', 'JFK');
    INSERT INTO Reserva VALUES ('P001', 'IB003', '1A', 'Primera');
    RAISE NOTICE 'ERROR: debería haber fallado (solapamiento de vuelos en reservas)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (solapamiento de vuelos en reservas) → %', SQLERRM;
END;
$$;

-- Tripulación asignada a dos vuelos solapados en el tiempo T001 ya
-- participa en IB001 (08:00-09:30); IB004 se solapa en ese intervalo
DO $$
BEGIN
    INSERT INTO Vuelo VALUES ('IB004', '2025-06-01', '09:00', '2025-06-01', '10:30', 'VY', 'BCN', 'MAD');
    INSERT INTO Participa_en VALUES ('T001', 'IB004', 'Comandante');
    RAISE NOTICE 'ERROR: debería haber fallado (solapamiento de vuelos en tripulación)';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'OK: fallo esperado (solapamiento de vuelos en tripulación) → %', SQLERRM;
END;
$$;