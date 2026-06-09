-- ==========================================================
-- Script: bd-bancaria-or-db2.sql
-- SGBD: IBM DB2
-- Modelo: Objeto-relacional
-- Proposito: Creacion del esquema objeto-relacional en DB2
-- Requiere: Ninguno
-- Observaciones:
--   - El script se ejecuta sobre la base de datos PRACTDB2.
--   - Utiliza terminador de sentencias '@' para permitir
--     bloques BEGIN...END.
--   - Elimina previamente jerarquias de tablas y tipos si existen.
--   - Define tipos estructurados (UDT) y jerarquias de tipos.
--   - Implementa tablas tipadas y jerarquias mediante UNDER.
-- ==========================================================

-- Conexion a la base de datos donde se creara el esquema
CONNECT TO DB2INST1
@

--------------------------------------------------
-- LIMPIEZA
--------------------------------------------------
BEGIN
DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '428O9' BEGIN END; -- Maneja el error si la jerarquía no existe aún

-- Borrado de jerarquías de tablas tipadas (Sintaxis corregida)
EXECUTE IMMEDIATE 'DROP TABLE HIERARCHY Operacion';
EXECUTE IMMEDIATE 'DROP TABLE HIERARCHY Cuenta';
EXECUTE IMMEDIATE 'DROP TABLE Cliente';
EXECUTE IMMEDIATE 'DROP TABLE Oficina';

-- Borrado de tipos
EXECUTE IMMEDIATE 'DROP TYPE EfectivoUdt';
EXECUTE IMMEDIATE 'DROP TYPE TransferenciaUdt';
EXECUTE IMMEDIATE 'DROP TYPE OperacionUdt';
EXECUTE IMMEDIATE 'DROP TYPE CorrienteUdt';
EXECUTE IMMEDIATE 'DROP TYPE AhorroUdt';
EXECUTE IMMEDIATE 'DROP TYPE CuentaUdt';
EXECUTE IMMEDIATE 'DROP TYPE ClienteUdt';
EXECUTE IMMEDIATE 'DROP TYPE OficinaUdt';
END
@

--------------------------------------------------
-- TIPOS OBJETO-RELACIONALES
--------------------------------------------------
CREATE TYPE OficinaUdt AS
(
   Codigo DECIMAL(5,0),
   Telefono DECIMAL(9,0),
   Direccion VARCHAR(100)
)
MODE DB2SQL
INSTANTIABLE NOT FINAL
@

CREATE TYPE ClienteUdt AS
(
   Dni VARCHAR(9),
   Nombre VARCHAR(50),
   Email VARCHAR(50),
   Apellidos VARCHAR(50),
   Edad DECIMAL(3,0),
   Direccion VARCHAR(100),
   Telefono DECIMAL(9,0)
)
MODE DB2SQL
INSTANTIABLE NOT FINAL
@

CREATE TYPE CuentaUdt AS
(
   Iban VARCHAR(24),
   Numero DECIMAL(20,0),
   Fecha_creacion DATE,
   Saldo_actual DECIMAL(10,2)
)
MODE DB2SQL
INSTANTIABLE NOT FINAL
@

CREATE TYPE AhorroUdt UNDER CuentaUdt AS
(
   Tipo_interes DECIMAL(10,2)
)
MODE DB2SQL
INSTANTIABLE NOT FINAL
@

CREATE TYPE CorrienteUdt UNDER CuentaUdt AS
(
   refOficina DECIMAL(5,0)
)
MODE DB2SQL
INSTANTIABLE NOT FINAL
@

CREATE TYPE OperacionUdt AS
(
   Codigo DECIMAL(8,0),
   Concepto VARCHAR(250),
   Fecha TIMESTAMP,
   Cantidad DECIMAL(10,2),
   refCuentaOrigen VARCHAR(24)
)
MODE DB2SQL
INSTANTIABLE NOT FINAL
@

CREATE TYPE TransferenciaUdt UNDER OperacionUdt AS
(
   refCuentaDestino VARCHAR(24)
)
MODE DB2SQL
INSTANTIABLE NOT FINAL
@

CREATE TYPE EfectivoUdt UNDER OperacionUdt AS
(
   refOficina DECIMAL(5,0)
)
MODE DB2SQL
INSTANTIABLE NOT FINAL
@

--------------------------------------------------
-- TABLAS TIPADAS (MODELO OBJETO-RELACIONAL)
--------------------------------------------------

-- Tablas sin jerarquía
CREATE TABLE Oficina OF OficinaUdt
(
   REF IS oid_oficina USER GENERATED,
   Codigo WITH OPTIONS NOT NULL PRIMARY KEY,
   Telefono WITH OPTIONS NOT NULL,
   Direccion WITH OPTIONS NOT NULL
)
@

CREATE TABLE Cliente OF ClienteUdt
(
   REF IS oid_cliente USER GENERATED,
   Dni WITH OPTIONS NOT NULL PRIMARY KEY,
   Nombre WITH OPTIONS NOT NULL,
   Apellidos WITH OPTIONS NOT NULL,
   Edad WITH OPTIONS NOT NULL CHECK (Edad >= 18),
   Direccion WITH OPTIONS NOT NULL,
   Telefono WITH OPTIONS NOT NULL
)
@

-- Jerarquía de Cuentas
CREATE TABLE Cuenta OF CuentaUdt
(
   REF IS oid_cuenta USER GENERATED,
   Iban WITH OPTIONS NOT NULL PRIMARY KEY,
   Numero WITH OPTIONS NOT NULL,
   Fecha_creacion WITH OPTIONS NOT NULL,
   Saldo_actual WITH OPTIONS NOT NULL CHECK (Saldo_actual >= 0)
)
@

CREATE TABLE CuentaAhorro OF AhorroUdt UNDER Cuenta
INHERIT SELECT PRIVILEGES
(
   Tipo_interes WITH OPTIONS NOT NULL CHECK (Tipo_interes > 0)
)
@

CREATE TABLE CuentaCorriente OF CorrienteUdt UNDER Cuenta
INHERIT SELECT PRIVILEGES
(
   refOficina WITH OPTIONS NOT NULL
)
@

-- Jerarquía de Operaciones
CREATE TABLE Operacion OF OperacionUdt
(
   REF IS oid_operacion USER GENERATED,
   Codigo WITH OPTIONS NOT NULL PRIMARY KEY,
   Fecha WITH OPTIONS NOT NULL,
   Cantidad WITH OPTIONS NOT NULL CHECK (Cantidad > 0),
   refCuentaOrigen WITH OPTIONS NOT NULL
)
@

CREATE TABLE Transferencia OF TransferenciaUdt UNDER Operacion
INHERIT SELECT PRIVILEGES
(
   refCuentaDestino WITH OPTIONS NOT NULL
)
@

CREATE TABLE OperacionEfectivo OF EfectivoUdt UNDER Operacion
INHERIT SELECT PRIVILEGES
(
   refOficina WITH OPTIONS NOT NULL
)
@

CONNECT RESET
@