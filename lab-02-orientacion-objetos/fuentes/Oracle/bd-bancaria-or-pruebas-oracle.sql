-- ==========================================================
-- Script: bd-bancaria-or-pruebas-oracle.sql
-- SGBD: Oracle
-- Modelo: Objeto-relacional
-- Proposito: Insercion de datos y pruebas funcionales del
--            modelo objeto-relacional
-- Requiere: bd-bancaria-or-oracle.sql
-- Observaciones:
--   - Inserta datos base utilizando constructores de tipos objeto.
--   - Actualiza relaciones mediante colecciones y referencias (REF).
--   - Ejecuta pruebas negativas de restricciones y triggers
--     (algunos errores ORA- son esperados).
--   - Verifica el funcionamiento de los triggers de operaciones
--     y del procedimiento de calculo de intereses.
-- ==========================================================

-- Configuracion de formato para mejorar la visualizacion en SQL*Plus
SET LINESIZE 150;
SET PAGESIZE 50;
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';
PROMPT ==========================================================;
PROMPT 0. LIMPIEZA DE DATOS PREVIOS;
PROMPT ==========================================================;

-- Borramos en orden para respetar las referencias
DELETE FROM Operacion;
DELETE FROM Cuenta;
DELETE FROM Cliente;
DELETE FROM Oficina;
COMMIT;
PROMPT Datos anteriores eliminados correctamente.

PROMPT ==========================================================;
PROMPT 1. INSERCION DE DATOS BASE (DEBEN FUNCIONAR CORRECTAMENTE);
PROMPT ==========================================================;

-- Insertar Oficinas (Inicializando sus listas de referencias vacías)
INSERT INTO Oficina (Codigo, Telefono, Direccion, refCorriente, refEfectivo) 
VALUES (1, 976111222, 'Paseo Independencia, Zaragoza', ListaRefsCorrientes(), ListaRefsEfectivo());

INSERT INTO Oficina (Codigo, Telefono, Direccion, refCorriente, refEfectivo) 
VALUES (2, 911222333, 'Gran Vía, Madrid', ListaRefsCorrientes(), ListaRefsEfectivo());

-- Insertar Clientes (Cumplen regex DNI, edad >= 18 y email)
INSERT INTO Cliente (Dni, Nombre, Apellidos, Email, Edad, Direccion, Telefono, refCuenta) 
VALUES ('12345678A', 'Ana', 'García', 'ana@email.com', 25, 'Calle Mayor 1', 600111222, ListaRefsCuentas());

INSERT INTO Cliente (Dni, Nombre, Apellidos, Email, Edad, Direccion, Telefono, refCuenta) 
VALUES ('87654321B', 'Luis', 'Pérez', 'luis@email.com', 40, 'Calle Menor 2', 600333444, ListaRefsCuentas());

-- Insertar Cuentas usando constructores tipados
-- Cuenta Corriente para Ana (apuntando a la oficina 1)
INSERT INTO Cuenta VALUES (
    CorrienteUdt('ES9100001111222233334444', 1111222233334444, SYSDATE, 0, ListaRefsClientes(),
        (SELECT REF(o) FROM Oficina o WHERE o.Codigo = 1)
    )
);

-- Cuenta de Ahorro para Luis (con 2.5% de interés)
INSERT INTO Cuenta VALUES (
    AhorroUdt('ES9100005555666677778888', 5555666677778888, SYSDATE, 0, ListaRefsClientes(), 2.5)
);

-- Actualizar la relación bidireccional (Añadir clientes a cuentas y cuentas a clientes)
UPDATE Cuenta c
SET c.refCliente = c.refCliente MULTISET UNION ListaRefsClientes((SELECT REF(cl) FROM Cliente cl WHERE cl.Dni = '12345678A'))
WHERE c.Iban = 'ES9100001111222233334444';

UPDATE Cliente cl
SET cl.refCuenta = cl.refCuenta MULTISET UNION ListaRefsCuentas((SELECT REF(c) FROM Cuenta c WHERE c.Iban = 'ES9100001111222233334444'))
WHERE cl.Dni = '12345678A';

COMMIT;
PROMPT Datos base insertados correctamente.

PROMPT ==========================================================;
PROMPT 2. PRUEBAS DE RESTRICCIONES DE INTEGRIDAD (ERRORES ORA-);
PROMPT ==========================================================;

PROMPT > Prueba 2.1: DNI con formato erroneo (Falla por CHECK cli_dni_chk)
INSERT INTO Cliente (Dni, Nombre, Email, Apellidos, Edad, Direccion, Telefono, refCuenta) 
VALUES ('123A45678', 'Falso', 'falso@email.com', 'Dni', 30, 'Dir', 600000000, ListaRefsCuentas());

PROMPT > Prueba 2.2: Cliente menor de edad (Falla por CHECK cli_edad_val)
INSERT INTO Cliente (Dni, Nombre, Email, Apellidos, Edad, Direccion, Telefono, refCuenta) 
VALUES ('11111111C', 'Joven', 'joven@email.com', 'Menor', 16, 'Dir', 600000000, ListaRefsCuentas());

PROMPT > Prueba 2.3: Operacion con fecha anterior a creacion de la cuenta (Falla por Trigger TRG_VAL_FECHAS_OP)
INSERT INTO Operacion VALUES (
    EfectivoUdt(999, 'Retirada en pasado', SYSDATE - 10, 50, 
        (SELECT REF(c) FROM Cuenta c WHERE c.Iban = 'ES9100001111222233334444'),
        (SELECT REF(o) FROM Oficina o WHERE o.Codigo = 1)
    )
);

PROMPT ==========================================================;
PROMPT 3. PRUEBAS DE OPERACIONES Y TRIGGERS DE SALDO (DEBEN FUNCIONAR);
PROMPT ==========================================================;

PROMPT > 3.1: Hacemos un Ingreso de 1000 euros en la cuenta de Ana (Operacion en Efectivo)
-- *Nota: En diseño objeto, un ingreso suma (como un pago negativo o un trigger adaptado)
-- Asumimos que el trigger de actualizacion lo maneja como resta del origen. Para simular ingreso:
UPDATE Cuenta c SET c.Saldo_actual = 1000 WHERE Iban = 'ES9100001111222233334444'; 
PROMPT Ingreso manual inicializado para pruebas de extraccion.

PROMPT > 3.2: Hacemos una Retirada de 200 euros en la cuenta de Ana (Operacion en Efectivo)
INSERT INTO Operacion VALUES (
    EfectivoUdt(1, 'Cajero', SYSDATE, 200, 
        (SELECT REF(c) FROM Cuenta c WHERE c.Iban = 'ES9100001111222233334444'),
        (SELECT REF(o) FROM Oficina o WHERE o.Codigo = 1)
    )
);

PROMPT > 3.3: Ana hace una transferencia de 300 euros a Luis
INSERT INTO Operacion VALUES (
    TransferenciaUdt(2, 'Regalo', SYSDATE, 300, 
        (SELECT REF(c) FROM Cuenta c WHERE c.Iban = 'ES9100001111222233334444'),
        (SELECT REF(c) FROM Cuenta c WHERE c.Iban = 'ES9100005555666677778888')
    )
);

PROMPT > ESTADO DE SALDOS ESPERADO:
PROMPT > Ana empezo con 1000 - 200 - 300 = 500 euros.
PROMPT > Luis empezo con 0 + 300 transferidos = 300 euros.
SELECT Iban, Saldo_actual FROM Cuenta;

PROMPT ==========================================================;
PROMPT 4. PRUEBA DE DISPARADOR DE FONDOS INSUFICIENTES (CHECK SALDO);
PROMPT ==========================================================;

PROMPT > Ana intenta sacar 600 euros pero solo tiene 500. 
PROMPT > El trigger intentara restar el saldo y el CHECK (Saldo_actual >= 0) de la tabla Cuenta lo impedira.
INSERT INTO Operacion VALUES (
    EfectivoUdt(3, 'Compra TV', SYSDATE, 600, 
        (SELECT REF(c) FROM Cuenta c WHERE c.Iban = 'ES9100001111222233334444'),
        (SELECT REF(o) FROM Oficina o WHERE o.Codigo = 1)
    )
);

PROMPT > Comprobamos que el saldo de Ana sigue intacto en 500 euros
SELECT Iban, Saldo_actual FROM Cuenta WHERE Iban = 'ES9100001111222233334444';

PROMPT ==========================================================;
PROMPT 5. PRUEBA DEL PROCEDIMIENTO DE INTERESES NOCTURNOS;
PROMPT ==========================================================;

PROMPT > Ejecutamos el pago de intereses manual (Liquidacion de la cuenta de ahorro de Luis al 2.5%)
EXEC PROC_INTERESES_NOCTURNOS;

PROMPT > Comprobamos que el saldo de Luis ha subido (Tenia 300, y se le ha sumado su interes)
SELECT Iban, Saldo_actual FROM Cuenta WHERE Iban = 'ES9100005555666677778888';

COMMIT;
PROMPT PRUEBAS FINALIZADAS.