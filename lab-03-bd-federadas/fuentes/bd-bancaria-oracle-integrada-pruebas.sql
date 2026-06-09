-- =========================================================================
-- ARCHIVO: bd-bancaria-oracle-integrada-pruebas.sql
-- DESCRIPCIÓN: Batería de pruebas de robustez local y validación del esquema global
-- =========================================================================

SET LINESIZE 200;
SET PAGESIZE 100;

PROMPT =====================================================================
PROMPT 1. PRUEBAS DE ROBUSTEZ DEL ESQUEMA FISICO LOCAL (BANQUITO)
PROMPT =====================================================================

PROMPT >> PRUEBA 1.1: Intentamos insertar dos cuentas con el mismo identificador
PROMPT >> Paso A: Insertamos una cuenta corriente nueva (EXITO ESPERADO)
INSERT INTO Cuenta (Iban, Numero, Es_ahorro, Tipo_interes, Oficina_codigo, Saldo_actual) 
VALUES ('ES9100003333444455556666', 3333444455556666, 0, NULL, 2, 500);

PROMPT >> Paso B: Intentamos insertar una cuenta de ahorro usando ese MISMO IBAN 
PROMPT >> (FALLO ESPERADO: ORA-02290 / ORA-00001 - Violacion de exclusividad)
INSERT INTO Cuenta (Iban, Numero, Es_ahorro, Tipo_interes, Oficina_codigo, Saldo_actual) 
VALUES ('ES9100003333444455556666', 3333444455556666, 1, 3.5, 2, 500);

PROMPT >> PRUEBA 1.2: Intentamos crear una cuenta sin tipo definido
PROMPT >> (FALLO ESPERADO: ORA-01400 - Insercion NULL en ES_AHORRO)
INSERT INTO Cuenta (Iban, Numero, Es_ahorro, Tipo_interes, Oficina_codigo, Saldo_actual) 
VALUES ('ES9100007777888899990000', 7777888899990000, NULL, NULL, 2, 1000);

PROMPT >> PRUEBA 1.3: Intentamos registrar dos operaciones con el mismo identificador
PROMPT >> Paso A: Registramos una operacion de Ingreso forzando el codigo 999 (EXITO ESPERADO)
INSERT INTO Operacion (Codigo, Concepto, Fecha, Cantidad, Tipo_operacion, Cuenta_origen, Oficina_codigo, Cuenta_destino) 
VALUES (999, 'Ingreso extra', SYSDATE, 50, 'Ingreso', 'ES9100001111222233334444', 1, NULL);

PROMPT >> Paso B: Intentamos registrar una Transferencia usando el mismo codigo 999 en la misma cuenta 
PROMPT >> (FALLO ESPERADO: ORA-00001 - Violacion de exclusividad)
INSERT INTO Operacion (Codigo, Concepto, Fecha, Cantidad, Tipo_operacion, Cuenta_origen, Oficina_codigo, Cuenta_destino) 
VALUES (999, 'Pago piso', SYSDATE, 50, 'Transferencia', 'ES9100001111222233334444', NULL, 'ES9100005555666677778888');

PROMPT >> PRUEBA 1.4: Intentamos registrar una operacion sin tipo
PROMPT >> (FALLO ESPERADO: ORA-01400 - Insercion NULL en TIPO_OPERACION)
INSERT INTO Operacion (Codigo, Concepto, Fecha, Cantidad, Tipo_operacion, Cuenta_origen, Oficina_codigo, Cuenta_destino) 
VALUES (1000, 'Operacion fantasma', SYSDATE, 100, NULL, 'ES9100001111222233334444', 1, NULL);


PROMPT =====================================================================
PROMPT 2. CONSULTAS DE VALIDACION SOBRE EL ESQUEMA GLOBAL INTEGRADO
PROMPT =====================================================================

PROMPT >> PRUEBA 2.1: Consultando Titular_global
PROMPT >> Objetivo: Verificacion de data cleansing de apellidos y formateo de direcciones.
SELECT * FROM Titular_global;

PROMPT >> PRUEBA 2.2: Consultando Cuenta_global
PROMPT >> Objetivo: Verificacion de unificacion de identificadores (IBAN) y resolucion de jerarquias.
SELECT * FROM Cuenta_global;

PROMPT >> PRUEBA 2.3: Consultando Operacion_global
PROMPT >> Objetivo: Verificacion de homogeneizacion semantica de los tipos de operacion.
SELECT Numop, Iban, Tipo_operacion, Cantidad, Fechaop 
FROM Operacion_global 
ORDER BY Fechaop DESC;


-- =========================================================================
-- LIMPIEZA: Deshacemos las inserciones de prueba locales para mantener la BD intacta
-- =========================================================================
PROMPT =====================================================================
PROMPT >> Ejecutando ROLLBACK para limpiar los datos locales de prueba...
ROLLBACK;
PROMPT >> Pruebas finalizadas con exito. La base de datos ha vuelto a su estado original.
PROMPT =====================================================================