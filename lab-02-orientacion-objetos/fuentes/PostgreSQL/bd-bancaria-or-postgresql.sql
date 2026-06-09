-- ==========================================================
-- Script: bd-bancaria-or-postgresql.sql
-- SGBD: PostgreSQL
-- Modelo: Objeto-relacional
-- Proposito: Creacion del esquema objeto-relacional en PostgreSQL
-- Requiere: Ninguno
-- Observaciones:
--   - El script elimina previamente todas las tablas mediante DROP CASCADE.
--   - Implementa jerarquias de tablas utilizando INHERITS.
--   - Sustituye las Nested Tables de Oracle por arrays nativos de PostgreSQL.
--   - Define funciones y triggers en PL/pgSQL para implementar la logica
--     de negocio de las operaciones bancarias.
--   - Incluye un procedimiento para calcular los intereses de las
--     cuentas de ahorro.
-- ==========================================================

-- ==========================================================
-- 1. LIMPIEZA DE ENTORNO
-- ==========================================================
-- En PostgreSQL el CASCADE lo limpia todo (tablas y funciones relacionadas)
DROP TABLE IF EXISTS OperacionEfectivo CASCADE;
DROP TABLE IF EXISTS Transferencia CASCADE;
DROP TABLE IF EXISTS Operacion CASCADE;
DROP TABLE IF EXISTS CuentaCorriente CASCADE;
DROP TABLE IF EXISTS CuentaAhorro CASCADE;
DROP TABLE IF EXISTS Cuenta CASCADE;
DROP TABLE IF EXISTS Cliente CASCADE;
DROP TABLE IF EXISTS Oficina CASCADE;

-- ==========================================================
-- 2. CREACIÓN DE TABLAS (CON ARRAYS E INHERITS)
-- ==========================================================

CREATE TABLE Oficina (
    Codigo INT PRIMARY KEY,
    Telefono INT NOT NULL,
    Direccion VARCHAR(100) NOT NULL,
    -- En PostgreSQL usamos arrays nativos en lugar de Nested Tables
    refCorriente VARCHAR(24)[], 
    refEfectivo INT[]          
);

CREATE TABLE Cliente (
    Dni VARCHAR(9) PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL,
    Email VARCHAR(50) CHECK (Email LIKE '%@%.%'),
    Apellidos VARCHAR(50) NOT NULL,
    Edad INT CHECK (Edad >= 18),
    Direccion VARCHAR(100) NOT NULL,
    Telefono INT NOT NULL,
    refCuenta VARCHAR(24)[] -- Array de IBANs
);

-- Tabla Padre (Cuenta)
CREATE TABLE Cuenta (
    Iban VARCHAR(24) PRIMARY KEY,
    Numero NUMERIC(20) NOT NULL,
    Fecha_creacion TIMESTAMP NOT NULL,
    Saldo_actual DECIMAL(10,2) CHECK (Saldo_actual >= 0),
    refCliente VARCHAR(9)[] -- Array de DNIs
);

-- Tablas Hijas de Cuenta (Usan INHERITS)
CREATE TABLE CuentaAhorro (
    Tipo_interes DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (Iban) -- En PostgreSQL hay que reiterar la PK en las hijas
) INHERITS (Cuenta);

CREATE TABLE CuentaCorriente (
    refOficina INT NOT NULL,
    PRIMARY KEY (Iban)
) INHERITS (Cuenta);

-- Tabla Padre (Operacion)
CREATE TABLE Operacion (
    Codigo INT PRIMARY KEY,
    Concepto VARCHAR(250),
    Fecha TIMESTAMP NOT NULL,
    Cantidad DECIMAL(10,2) NOT NULL,
    refCuentaOrigen VARCHAR(24) NOT NULL
);

-- Tablas hijas de Operacion
CREATE TABLE Transferencia (
    refCuentaDestino VARCHAR(24) NOT NULL,
    PRIMARY KEY (Codigo)
) INHERITS (Operacion);

CREATE TABLE OperacionEfectivo (
    refOficina INT NOT NULL,
    PRIMARY KEY (Codigo)
) INHERITS (Operacion);

-- ===============================
-- 3. TRIGGERS Y LÓGICA DE NEGOCIO
-- ===============================

-- 3.1. Función para Transferencias (Resta origen, Suma destino, Valida fechas)
CREATE OR REPLACE FUNCTION func_logica_transferencia()
RETURNS TRIGGER AS $$
DECLARE
    v_fecha_orig TIMESTAMP;
    v_fecha_dest TIMESTAMP;
BEGIN
    -- Validar fecha origen
    SELECT Fecha_creacion INTO v_fecha_orig FROM Cuenta WHERE Iban = NEW.refCuentaOrigen;
    IF NEW.Fecha < v_fecha_orig THEN
        RAISE EXCEPTION 'Fecha operación anterior a apertura cuenta origen.';
    END IF;

    -- Validar fecha destino
    SELECT Fecha_creacion INTO v_fecha_dest FROM Cuenta WHERE Iban = NEW.refCuentaDestino;
    IF NEW.Fecha < v_fecha_dest THEN
        RAISE EXCEPTION 'Fecha transferencia anterior a apertura cuenta destino.';
    END IF;

    -- Actualizar saldos (por INHERITS al buscar en Cuenta buscará en Ahorro y Corriente)
    UPDATE Cuenta SET Saldo_actual = Saldo_actual - NEW.Cantidad WHERE Iban = NEW.refCuentaOrigen;
    UPDATE Cuenta SET Saldo_actual = Saldo_actual + NEW.Cantidad WHERE Iban = NEW.refCuentaDestino;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_transferencia
BEFORE INSERT ON Transferencia
FOR EACH ROW EXECUTE FUNCTION func_logica_transferencia();

-- 3.2. Función para Operaciones en Efectivo (Resta origen, Valida fecha)
CREATE OR REPLACE FUNCTION func_logica_efectivo()
RETURNS TRIGGER AS $$
DECLARE
    v_fecha_orig TIMESTAMP;
BEGIN
    -- Validar fecha origen
    SELECT Fecha_creacion INTO v_fecha_orig FROM Cuenta WHERE Iban = NEW.refCuentaOrigen;
    IF NEW.Fecha < v_fecha_orig THEN
        RAISE EXCEPTION 'Fecha operación anterior a apertura cuenta origen.';
    END IF;

    -- Actualizar saldo origen
    UPDATE Cuenta SET Saldo_actual = Saldo_actual - NEW.Cantidad WHERE Iban = NEW.refCuentaOrigen;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_efectivo
BEFORE INSERT ON OperacionEfectivo
FOR EACH ROW EXECUTE FUNCTION func_logica_efectivo();

-- ==========================================================
-- 4. CÁLCULO DE INTERESES (Procedimiento)
-- ==========================================================
-- PostgreSQL actualiza solo la tabla CuentaAhorro sin tocar el resto.
CREATE OR REPLACE PROCEDURE proc_intereses_nocturnos()
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE CuentaAhorro
    SET Saldo_actual = Saldo_actual + (Saldo_actual * (Tipo_interes / 100));
END;
$$;