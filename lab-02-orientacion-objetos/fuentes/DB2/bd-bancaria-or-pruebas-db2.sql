-- ==========================================================
-- Script: bd-bancaria-or-pruebas-db2.sql
-- SGBD: IBM DB2
-- Modelo: Objeto-relacional
-- Proposito: Insercion de datos y pruebas funcionales del
--            modelo objeto-relacional en DB2
-- Requiere: bd-bancaria-or-db2.sql
-- Observaciones:
--   - El script se ejecuta sobre la base de datos PRACTDB2.
--   - Utiliza el terminador '@' para las sentencias SQL.
--   - Inserta datos base en oficinas, clientes y cuentas.
--   - Incluye pruebas negativas de restricciones
--     (algunos errores SQL0545N son esperados).
--   - Simula operaciones bancarias y verifica los saldos finales.
-- ==========================================================

-- Conexion a la base de datos donde se ejecutaran las pruebas
CONNECT TO DB2INST1
@

-- ==========================================================
-- 0. LIMPIEZA DE DATOS (Borrando desde la raíz de la jerarquía)
-- ==========================================================

DELETE FROM Operacion
@

DELETE FROM Cuenta
@

DELETE FROM Cliente
@

DELETE FROM Oficina
@

COMMIT
@

-- ==========================================================
-- 1. INSERCION DE DATOS BASE
-- ==========================================================

INSERT INTO Oficina (oid_oficina, Codigo, Telefono, Direccion)
VALUES (OficinaUdt('1'), 1, 976111222, 'Paseo Independencia, Zaragoza')
@

INSERT INTO Oficina (oid_oficina, Codigo, Telefono, Direccion)
VALUES (OficinaUdt('2'), 2, 911222333, 'Gran Vía, Madrid')
@

INSERT INTO Cliente (oid_cliente, Dni, Nombre, Email, Apellidos, Edad, Direccion, Telefono)
VALUES (ClienteUdt('1'), '12345678A', 'Ana', 'ana@email.com', 'García', 25, 'Calle Mayor 1', 600111222)
@

INSERT INTO Cliente (oid_cliente, Dni, Nombre, Email, Apellidos, Edad, Direccion, Telefono)
VALUES (ClienteUdt('2'), '87654321B', 'Luis', 'luis@email.com', 'Pérez', 40, 'Calle Menor 2', 600333444)
@

INSERT INTO CuentaCorriente (oid_cuenta, Iban, Numero, Fecha_creacion, Saldo_actual, refOficina)
VALUES (CorrienteUdt('1'), 'ES9100001111222233334444', 1111222233334444, CURRENT DATE, 0, 1)
@

INSERT INTO CuentaAhorro (oid_cuenta, Iban, Numero, Fecha_creacion, Saldo_actual, Tipo_interes)
VALUES (AhorroUdt('2'), 'ES9100005555666677778888', 5555666677778888, CURRENT DATE, 0, 2.5)
@

COMMIT
@

-- ==========================================================
-- 2. PRUEBAS DE RESTRICCIONES
-- ==========================================================

-- Cliente menor de edad (debe fallar)
INSERT INTO Cliente (oid_cliente, Dni, Nombre, Apellidos, Email, Edad, Direccion, Telefono)
VALUES (ClienteUdt('3'), '11111111C','Joven','Menor','joven@email.com',16,'Dir',600000000)
@

-- Saldo negativo (debe fallar)
INSERT INTO Cuenta (oid_cuenta, Iban, Numero, Fecha_creacion, Saldo_actual)
VALUES (CuentaUdt('3'), 'ES0000000000000000000000', 1111, CURRENT DATE, -100)
@

-- ==========================================================
-- 3. OPERACIONES
-- ==========================================================

UPDATE Cuenta
SET Saldo_actual = 1000
WHERE Iban = 'ES9100001111222233334444'
@

INSERT INTO OperacionEfectivo (oid_operacion, Codigo, Concepto, Fecha, Cantidad, refCuentaOrigen, refOficina)
VALUES (EfectivoUdt('1'), 1, 'Cajero', CURRENT TIMESTAMP, 200, 'ES9100001111222233334444', 1)
@

INSERT INTO Transferencia (oid_operacion, Codigo, Concepto, Fecha, Cantidad, refCuentaOrigen, refCuentaDestino)
VALUES (TransferenciaUdt('2'), 2, 'Regalo', CURRENT TIMESTAMP, 300, 'ES9100001111222233334444', 'ES9100005555666677778888')
@

UPDATE Cuenta
SET Saldo_actual = Saldo_actual - 200 - 300
WHERE Iban = 'ES9100001111222233334444'
@

UPDATE Cuenta
SET Saldo_actual = Saldo_actual + 300
WHERE Iban = 'ES9100005555666677778888'
@

-- ==========================================================
-- 4. FONDOS INSUFICIENTES
-- ==========================================================

UPDATE Cuenta
SET Saldo_actual = Saldo_actual - 600
WHERE Iban = 'ES9100001111222233334444'
@

-- ==========================================================
-- 5. ESTADO FINAL
-- ==========================================================

SELECT Iban, Saldo_actual FROM Cuenta
@

CONNECT RESET
@