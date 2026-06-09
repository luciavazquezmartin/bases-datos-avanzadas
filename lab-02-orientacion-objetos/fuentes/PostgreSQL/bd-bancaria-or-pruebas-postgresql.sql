-- ==========================================================
-- Script: bd-bancaria-or-pruebas-postgresql.sql
-- SGBD: PostgreSQL
-- Modelo: Objeto-relacional
-- Proposito: Insercion de datos y pruebas funcionales del
--            modelo objeto-relacional en PostgreSQL
-- Requiere: bd-bancaria-or-postgresql.sql
-- Observaciones:
--   - Inserta datos base en oficinas, clientes y cuentas.
--   - Utiliza arrays para representar referencias entre objetos.
--   - Ejecuta pruebas negativas de restricciones y triggers
--     (algunos errores SQL son esperados).
--   - Verifica el funcionamiento de los triggers de operaciones
--     y del procedimiento de calculo de intereses.
-- ==========================================================

\echo '=========================================================='
\echo '0. LIMPIEZA DE DATOS PREVIOS'
\echo '=========================================================='

-- TRUNCATE CASCADE vacía las tablas y todas las que heredan de ellas automáticamente
TRUNCATE TABLE Operacion CASCADE;
TRUNCATE TABLE Cuenta CASCADE;
TRUNCATE TABLE Cliente CASCADE;
TRUNCATE TABLE Oficina CASCADE;

\echo 'Datos anteriores eliminados correctamente.'

\echo '=========================================================='
\echo '1. INSERCION DE DATOS BASE (DEBEN FUNCIONAR CORRECTAMENTE)'
\echo '=========================================================='

-- Insertar Oficinas (Inicializando arrays vacíos)
INSERT INTO Oficina (Codigo, Telefono, Direccion, refCorriente, refEfectivo) 
VALUES (1, 976111222, 'Paseo Independencia, Zaragoza', '{}', '{}');

INSERT INTO Oficina (Codigo, Telefono, Direccion, refCorriente, refEfectivo) 
VALUES (2, 911222333, 'Gran Vía, Madrid', '{}', '{}');

-- Insertar Clientes
INSERT INTO Cliente (Dni, Nombre, Apellidos, Email, Edad, Direccion, Telefono, refCuenta) 
VALUES ('12345678A', 'Ana', 'García', 'ana@email.com', 25, 'Calle Mayor 1', 600111222, '{}');

INSERT INTO Cliente (Dni, Nombre, Apellidos, Email, Edad, Direccion, Telefono, refCuenta) 
VALUES ('87654321B', 'Luis', 'Pérez', 'luis@email.com', 40, 'Calle Menor 2', 600333444, '{}');

-- Insertar Cuentas directamente en las TABLAS HIJAS (Gracias a INHERITS)
-- Cuenta Corriente para Ana
INSERT INTO CuentaCorriente (Iban, Numero, Fecha_creacion, Saldo_actual, refCliente, refOficina) 
VALUES ('ES9100001111222233334444', 1111222233334444, NOW(), 0, ARRAY['12345678A'], 1);

-- Cuenta de Ahorro para Luis (con 2.5% de interés)
INSERT INTO CuentaAhorro (Iban, Numero, Fecha_creacion, Saldo_actual, refCliente, Tipo_interes) 
VALUES ('ES9100005555666677778888', 5555666677778888, NOW(), 0, ARRAY['87654321B'], 2.5);

-- Actualizar la relación bidireccional (Añadir cuentas al array de los clientes)
UPDATE Cliente SET refCuenta = array_append(refCuenta, 'ES9100001111222233334444') WHERE Dni = '12345678A';
UPDATE Cliente SET refCuenta = array_append(refCuenta, 'ES9100005555666677778888') WHERE Dni = '87654321B';

\echo 'Datos base insertados correctamente.'

\echo '=========================================================='
\echo '2. PRUEBAS DE RESTRICCIONES DE INTEGRIDAD (ERRORES ESPERADOS)'
\echo '=========================================================='

\echo '> Prueba 2.1: Email con formato erróneo (Falla por CHECK de la tabla)'
INSERT INTO Cliente (Dni, Nombre, Apellidos, Email, Edad, Direccion, Telefono, refCuenta) 
VALUES ('123A45678', 'Falso', 'Dni', 'falsoemail.com', 30, 'Dir', 600000000, '{}');

\echo '> Prueba 2.2: Cliente menor de edad (Falla por CHECK de la tabla)'
INSERT INTO Cliente (Dni, Nombre, Apellidos, Email, Edad, Direccion, Telefono, refCuenta) 
VALUES ('11111111C', 'Joven', 'Menor', 'joven@email.com', 16, 'Dir', 600000000, '{}');

\echo '> Prueba 2.3: Operación con fecha anterior a creación de cuenta (Falla por Trigger PL/pgSQL)'
INSERT INTO OperacionEfectivo (Codigo, Concepto, Fecha, Cantidad, refCuentaOrigen, refOficina)
VALUES (999, 'Retirada en pasado', NOW() - INTERVAL '10 days', 50, 'ES9100001111222233334444', 1);

\echo '=========================================================='
\echo '3. PRUEBAS DE OPERACIONES Y TRIGGERS DE SALDO'
\echo '=========================================================='

\echo '> 3.1: Inicializamos el saldo de Ana a 1000 euros para pruebas'
UPDATE CuentaCorriente SET Saldo_actual = 1000 WHERE Iban = 'ES9100001111222233334444';

\echo '> 3.2: Hacemos una Retirada de 200 euros en la cuenta de Ana (OperacionEfectivo)'
INSERT INTO OperacionEfectivo (Codigo, Concepto, Fecha, Cantidad, refCuentaOrigen, refOficina)
VALUES (1, 'Cajero', NOW(), 200, 'ES9100001111222233334444', 1);

\echo '> 3.3: Ana hace una transferencia de 300 euros a Luis (Transferencia)'
INSERT INTO Transferencia (Codigo, Concepto, Fecha, Cantidad, refCuentaOrigen, refCuentaDestino)
VALUES (2, 'Regalo', NOW(), 300, 'ES9100001111222233334444', 'ES9100005555666677778888');

\echo '> ESTADO DE SALDOS ESPERADO:'
\echo '> Ana: 1000 - 200 - 300 = 500 euros.'
\echo '> Luis: 0 + 300 transferidos = 300 euros.'
-- Nota: Hacemos SELECT sobre "Cuenta" (tabla padre) y gracias a INHERITS mostrará los saldos de Corriente y Ahorro
SELECT Iban, Saldo_actual FROM Cuenta;

\echo '=========================================================='
\echo '4. PRUEBA DE DISPARADOR DE FONDOS INSUFICIENTES (CHECK SALDO)'
\echo '=========================================================='

\echo '> Ana intenta sacar 600 euros pero solo tiene 500. El CHECK (Saldo_actual >= 0) lo impedirá.'
INSERT INTO OperacionEfectivo (Codigo, Concepto, Fecha, Cantidad, refCuentaOrigen, refOficina)
VALUES (3, 'Compra TV', NOW(), 600, 'ES9100001111222233334444', 1);

\echo '> Comprobamos que el saldo de Ana sigue intacto en 500 euros'
SELECT Iban, Saldo_actual FROM Cuenta WHERE Iban = 'ES9100001111222233334444';

\echo '=========================================================='
\echo '5. PRUEBA DEL PROCEDIMIENTO DE INTERESES NOCTURNOS'
\echo '=========================================================='

\echo '> Ejecutamos el pago de intereses (Liquidación de la cuenta de ahorro de Luis al 2.5%)'
CALL proc_intereses_nocturnos();

\echo '> Comprobamos que el saldo de Luis ha subido (Tenía 300, se le suma el 2.5% = 307.50)'
SELECT Iban, Saldo_actual FROM Cuenta WHERE Iban = 'ES9100005555666677778888';

\echo 'PRUEBAS FINALIZADAS.