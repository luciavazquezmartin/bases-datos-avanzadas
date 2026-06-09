-- ==========================================================
-- Script: bd-bancaria-pruebas-oracle.sql
-- SGBD: Oracle
-- Modelo: Relacional
-- Proposito: Insercion de datos y pruebas funcionales del modelo
-- Requiere: bd-bancaria-oracle.sql
-- Observaciones:
--   - Inserta datos base para clientes, cuentas y oficinas.
--   - Ejecuta pruebas de restricciones (algunos ORA- son esperados).
--   - Verifica triggers de operaciones y actualizacion de saldo.
--   - Comprueba el funcionamiento del procedimiento de liquidacion
--     de intereses.
-- ==========================================================

-- Configuracion de formato para mejorar la visualizacion en SQL*Plus
SET LINESIZE 150;
SET PAGESIZE 50;
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

PROMPT ==========================================================;
PROMPT 0. LIMPIEZA DE DATOS PREVIOS;
PROMPT ==========================================================;

-- Borramos en orden para respetar las claves foraneas (hijos primero, luego padres)
DELETE FROM ser_titular;
DELETE FROM Operacion;
DELETE FROM Cuenta;
DELETE FROM Cliente;
DELETE FROM Oficina;
COMMIT;
PROMPT Datos anteriores eliminados correctamente.

PROMPT ==========================================================;
PROMPT 1. INSERCION DE DATOS BASE (DEBEN FUNCIONAR CORRECTAMENTE);
PROMPT ==========================================================;

-- Insertar Oficinas
INSERT INTO Oficina (Codigo, Telefono, Direccion) VALUES (1, 976111222, 'Paseo Independencia, Zaragoza');
INSERT INTO Oficina (Codigo, Telefono, Direccion) VALUES (2, 911222333, 'Gran Vía, Madrid');

-- Insertar Clientes
INSERT INTO Cliente (Dni, Nombre, Apellidos, Email, Edad, Direccion, Telefono) 
VALUES ('12345678A', 'Ana', 'García', 'ana@email.com', 25, 'Calle Mayor 1', 600111222);
INSERT INTO Cliente (Dni, Nombre, Apellidos, Email, Edad, Direccion, Telefono) 
VALUES ('87654321B', 'Luis', 'Pérez', 'luis@email.com', 40, 'Calle Menor 2', 600333444);

-- Insertar Cuentas (Nacen con Saldo_actual a 0)
-- Cuenta Corriente para Ana
INSERT INTO Cuenta (Iban, Numero, Es_ahorro, Tipo_interes, Oficina_codigo, Saldo_actual) 
VALUES ('ES9100001111222233334444', 1111222233334444, 0, NULL, 1, 0);

-- Cuenta de Ahorro para Luis
INSERT INTO Cuenta (Iban, Numero, Es_ahorro, Tipo_interes, Oficina_codigo, Saldo_actual) 
VALUES ('ES9100005555666677778888', 5555666677778888, 1, 2.5, NULL, 0);

-- Asignar titulares
INSERT INTO ser_titular (Cliente_dni, Cuenta_iban) VALUES ('12345678A', 'ES9100001111222233334444');
INSERT INTO ser_titular (Cliente_dni, Cuenta_iban) VALUES ('87654321B', 'ES9100005555666677778888');

COMMIT;
PROMPT Datos base insertados.

PROMPT ==========================================================;
PROMPT 2. PRUEBAS DE RESTRICCIONES (AQUI DEBEN SALIR ERRORES ORA-);
PROMPT ==========================================================;

PROMPT > Prueba 2.1: Intentar insertar un DNI falso (Falla por Regex)
INSERT INTO Cliente (Dni, Nombre, Apellidos, Email, Edad, Direccion, Telefono) 
VALUES ('123A45678', 'Falso', 'Dni', 'falso@email.com', 30, 'Dir', 600000000);

PROMPT > Prueba 2.2: Intentar insertar un menor de edad (Falla por CHECK)
INSERT INTO Cliente (Dni, Nombre, Apellidos, Email, Edad, Direccion, Telefono) 
VALUES ('11111111C', 'Joven', 'Menor', 'joven@email.com', 16, 'Dir', 600000000);

PROMPT > Prueba 2.3: Cuenta de Ahorro sin tipo de interes (Falla por CHECK de jerarquia)
INSERT INTO Cuenta (Iban, Numero, Es_ahorro, Tipo_interes, Oficina_codigo, Saldo_actual) 
VALUES ('ES9100009999000011112222', 9999000011112222, 1, NULL, NULL, 0);

PROMPT > Prueba 2.4: Transferencia sin Cuenta Destino (Falla por CHECK de operacion)
INSERT INTO Operacion (Codigo, Concepto, Cantidad, Tipo_operacion, Cuenta_origen, Oficina_codigo, Cuenta_destino)
VALUES (seq_operacion.NEXTVAL, 'Transf fallida', 100, 'Transferencia', 'ES9100001111222233334444', NULL, NULL);

PROMPT ==========================================================;
PROMPT 3. PRUEBAS DE TRIGGERS Y OPERACIONES (DEBEN FUNCIONAR);
PROMPT ==========================================================;

PROMPT > Hacemos un Ingreso de 1000 euros en la cuenta de Ana
INSERT INTO Operacion (Codigo, Concepto, Cantidad, Tipo_operacion, Cuenta_origen, Oficina_codigo, Cuenta_destino)
VALUES (seq_operacion.NEXTVAL, 'Nomina', 1000, 'Ingreso', 'ES9100001111222233334444', 1, NULL);

PROMPT > Hacemos una Retirada de 200 euros en la cuenta de Ana
INSERT INTO Operacion (Codigo, Concepto, Cantidad, Tipo_operacion, Cuenta_origen, Oficina_codigo, Cuenta_destino)
VALUES (seq_operacion.NEXTVAL, 'Cajero', 200, 'Retirada', 'ES9100001111222233334444', 1, NULL);

PROMPT > Ana hace una transferencia de 300 euros a Luis
INSERT INTO Operacion (Codigo, Concepto, Cantidad, Tipo_operacion, Cuenta_origen, Oficina_codigo, Cuenta_destino)
VALUES (seq_operacion.NEXTVAL, 'Regalo', 300, 'Transferencia', 'ES9100001111222233334444', NULL, 'ES9100005555666677778888');

PROMPT > ESTADO DE SALDOS ESPERADO:
PROMPT > Ana empezo con 0 + 1000 - 200 - 300 = 500 euros.
PROMPT > Luis empezo con 0 + 300 transferidos = 300 euros.
SELECT Iban, Saldo_actual FROM Cuenta;

PROMPT ==========================================================;
PROMPT 4. PRUEBA DE DISPARADOR EN CADENA (FONDOS INSUFICIENTES);
PROMPT ==========================================================;

PROMPT > Ana intenta sacar 600 euros pero solo tiene 500. 
PROMPT > El trigger restara el saldo y Oracle parara la insercion por el CHECK de saldo >= 0.
INSERT INTO Operacion (Codigo, Concepto, Cantidad, Tipo_operacion, Cuenta_origen, Oficina_codigo, Cuenta_destino)
VALUES (seq_operacion.NEXTVAL, 'Compra TV', 600, 'Retirada', 'ES9100001111222233334444', 1, NULL);

PROMPT > Comprobamos que el saldo de Ana sigue intacto en 500 euros
SELECT Iban, Saldo_actual FROM Cuenta WHERE Iban = 'ES9100001111222233334444';

PROMPT ==========================================================;
PROMPT 5. PRUEBA DEL PROCEDIMIENTO DE INTERESES;
PROMPT ==========================================================;

PROMPT > Ejecutamos el pago de intereses manual (Liquidacion de la cuenta de ahorro de Luis)
EXEC liquidar_intereses;

PROMPT > Comprobamos las operaciones. Deberia aparecer un nuevo Ingreso automatico para Luis
COLUMN Concepto FORMAT A35;
SELECT Codigo, Concepto, Cantidad, Tipo_operacion FROM Operacion ORDER BY Codigo;

PROMPT > Comprobamos que el saldo de Luis ha subido (Tenia 300, y se le ha sumado su interes)
SELECT Iban, Saldo_actual FROM Cuenta WHERE Iban = 'ES9100005555666677778888';

COMMIT;
PROMPT PRUEBAS FINALIZADAS.