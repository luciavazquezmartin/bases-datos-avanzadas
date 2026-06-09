-- ==========================================================
-- Script: bd-bancaria-or-oracle.sql
-- SGBD: Oracle
-- Modelo: Objeto-relacional
-- Proposito: Creacion del esquema objeto-relacional de la base
-- Requiere: Ninguno
-- Observaciones:
--   - El script elimina previamente tablas, tipos y jobs existentes.
--   - Define tipos objeto (UDT), jerarquias de tipos y colecciones.
--   - Crea tablas tipadas y nested tables.
--   - Implementa triggers de logica de negocio sobre operaciones.
--   - Incluye un procedimiento y un job scheduler para calcular
--     intereses periodicos de las cuentas de ahorro.
-- ==========================================================

-- ==========================================================
-- 1. LIMPIEZA DE ENTORNO (DROP)
-- ==========================================================
BEGIN
    -- 1. Borramos el JOB si ya existía del intento anterior
    BEGIN
        DBMS_SCHEDULER.DROP_JOB('JOB_INTERESES_DIARIOS', force => TRUE);
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    -- 2. Borramos las tablas una a una forzando la caída (Mejor que con un bucle FOR)
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Operacion CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Cuenta CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Cliente CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Oficina CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 3. Borramos los tipos (FORCE para romper dependencias)
    FOR obj IN (SELECT object_name FROM user_objects WHERE object_type = 'TYPE' AND object_name IN 
    ('LISTAREFSCUENTAS','LISTAREFSCLIENTES','LISTAREFSCORRIENTES','LISTAREFSCUENTAS_CORR',
     'LISTAREFSEFECTIVO','OFICINAUDT','CLIENTEUDT','CUENTAUDT','AHORROUDT','CORRIENTEUDT',
     'OPERACIONUDT','TRANSFERENCIAUDT','EFECTIVOUDT')) LOOP
        EXECUTE IMMEDIATE 'DROP TYPE ' || obj.object_name || ' FORCE';
    END LOOP;
END;
/

-- ==========================================================
-- 2. DEFINICIÓN DE TIPOS (UDT) Y COLECCIONES
-- ==========================================================

-- Declaraciones anticipadas para evitar errores de compilación
CREATE OR REPLACE TYPE CuentaUdt;
/
CREATE OR REPLACE TYPE ClienteUdt;
/
CREATE OR REPLACE TYPE OficinaUdt;
/
CREATE OR REPLACE TYPE CorrienteUdt;
/
CREATE OR REPLACE TYPE EfectivoUdt;
/

-- Colecciones para las Nested Tables
CREATE OR REPLACE TYPE ListaRefsCuentas AS TABLE of ref CuentaUdt;
/
CREATE OR REPLACE TYPE ListaRefsClientes AS TABLE of ref ClienteUdt;
/
CREATE OR REPLACE TYPE ListaRefsCorrientes AS TABLE of ref CorrienteUdt;
/
CREATE OR REPLACE TYPE ListaRefsEfectivo AS TABLE of ref EfectivoUdt;
/

-- Tipo Cliente
CREATE OR REPLACE TYPE ClienteUdt AS OBJECT (
    Dni         VARCHAR2(9),
    Nombre      VARCHAR2(50),
    Email       VARCHAR2(50),
    Apellidos   VARCHAR2(50),
    Edad        NUMBER(3),
    Direccion   VARCHAR2(100),
    Telefono    NUMBER(9),
    refCuenta   ListaRefsCuentas
) NOT FINAL;
/

-- Tipo Cuenta y Subtipos
CREATE OR REPLACE TYPE CuentaUdt AS OBJECT (
    Iban           VARCHAR2(24),
    Numero         NUMBER(20),
    Fecha_creacion DATE,
    Saldo_actual   NUMBER(10,2),
    refCliente     ListaRefsClientes
) NOT FINAL;
/

CREATE OR REPLACE TYPE AhorroUdt under CuentaUdt (
    Tipo_interes   NUMBER(10,2)
);
/

CREATE OR REPLACE TYPE CorrienteUdt under CuentaUdt (
    refOficina     REF OficinaUdt
);
/

-- Tipo Oficina (con las colecciones de referencias)
CREATE OR REPLACE TYPE OficinaUdt AS OBJECT (
    Codigo      NUMBER(5), 
    Telefono    NUMBER(9),
    Direccion   VARCHAR2(100),
    refCorriente ListaRefsCorrientes,
    refEfectivo  ListaRefsEfectivo
) NOT FINAL;
/

-- Tipo operación y subtipos
CREATE OR REPLACE TYPE OperacionUdt AS OBJECT (
    Codigo          NUMBER(8),
    Concepto        VARCHAR2(250),
    Fecha           TIMESTAMP,
    Cantidad        NUMBER(10,2),
    refCuentaOrigen REF CuentaUdt
) NOT FINAL;
/

CREATE OR REPLACE TYPE TransferenciaUdt under OperacionUdt (
    refCuentaDestino REF CuentaUdt
);
/

CREATE OR REPLACE TYPE EfectivoUdt under OperacionUdt (
    refOficina      REF OficinaUdt
);
/

-- ==========================================================
-- 3. CREACIÓN DE TABLAS TIPADAS
-- ==========================================================

CREATE TABLE Oficina of OficinaUdt (
    PRIMARY KEY (Codigo)
) NESTED TABLE refCorriente STORE AS tab_ref_corr,
  NESTED TABLE refEfectivo STORE AS tab_ref_efec;

CREATE TABLE Cliente of ClienteUdt (
    PRIMARY KEY (Dni),
    CONSTRAINT cli_edad_val CHECK (Edad >= 18),
    CONSTRAINT cli_email_chk CHECK (Email LIKE '%@%.%'),
    CONSTRAINT cli_dni_chk CHECK (REGEXP_LIKE(Dni, '^[0-9]{8}[a-zA-Z]$'))
) NESTED TABLE refCuenta STORE AS tab_ref_cue_cli;

CREATE TABLE Cuenta of CuentaUdt (
    PRIMARY KEY (Iban),
    CONSTRAINT cue_saldo_chk CHECK (Saldo_actual >= 0)
) NESTED TABLE refCliente STORE AS tab_ref_cli_cue;

CREATE TABLE Operacion of OperacionUdt (
    PRIMARY KEY (Codigo)
);

-- ==========================================================
-- 4. TRIGGERS DE INTEGRIDAD Y LÓGICA DE NEGOCIO
-- ==========================================================

CREATE OR REPLACE TRIGGER TRG_OPERACIONES_COMPUESTO
FOR INSERT ON Operacion
COMPOUND TRIGGER

    -- 1. Declaramos una estructura en memoria para guardar temporalmente las operaciones
    TYPE r_operacion IS RECORD (
        Codigo NUMBER,
        Cantidad NUMBER,
        Fecha TIMESTAMP
    );
    TYPE t_operaciones IS TABLE OF r_operacion;
    v_operaciones t_operaciones := t_operaciones();

-- FASE A: Se ejecuta fila a fila durante la inserción
BEFORE EACH ROW IS
    v_fecha_apertura_orig DATE;
BEGIN
    -- Validar fecha cuenta origen
    SELECT Fecha_creacion INTO v_fecha_apertura_orig 
    FROM Cuenta c WHERE REF(c) = :NEW.refCuentaOrigen;

    IF CAST(:NEW.Fecha AS DATE) < v_fecha_apertura_orig THEN
        RAISE_APPLICATION_ERROR(-20002, 'Fecha operación anterior a apertura cuenta origen.');
    END IF;

    -- Restar saldo en la cuenta origen inmediatamente
    UPDATE Cuenta c SET c.Saldo_actual = c.Saldo_actual - :NEW.Cantidad
    WHERE REF(c) = :NEW.refCuentaOrigen;

    -- Guardamos los datos en memoria para procesar el destino luego
    v_operaciones.EXTEND;
    v_operaciones(v_operaciones.LAST).Codigo := :NEW.Codigo;
    v_operaciones(v_operaciones.LAST).Cantidad := :NEW.Cantidad;
    v_operaciones(v_operaciones.LAST).Fecha := :NEW.Fecha;
END BEFORE EACH ROW;

-- FASE B: Se ejecuta una sola vez al terminar el INSERT (La tabla ya no muta)
AFTER STATEMENT IS
    v_ref_dest REF CuentaUdt;
    v_fecha_apertura_dest DATE;
BEGIN
    FOR i IN 1 .. v_operaciones.COUNT LOOP
        BEGIN
            -- Ahora podemos hacer SELECT en Operacion porque ya ha terminado inserción
            SELECT TREAT(VALUE(o) AS TransferenciaUdt).refCuentaDestino
            INTO v_ref_dest
            FROM Operacion o 
            WHERE o.Codigo = v_operaciones(i).Codigo 
              AND VALUE(o) IS OF (TransferenciaUdt);

            IF v_ref_dest IS NOT NULL THEN
                -- Validar la fecha de la cuenta destino
                SELECT Fecha_creacion INTO v_fecha_apertura_dest 
                FROM Cuenta c WHERE REF(c) = v_ref_dest;

                IF CAST(v_operaciones(i).Fecha AS DATE) < v_fecha_apertura_dest THEN
                    RAISE_APPLICATION_ERROR(-20003, 'Fecha transferencia anterior a apertura cuenta destino.');
                END IF;

                -- Sumar el saldo en la cuenta destino
                UPDATE Cuenta c SET c.Saldo_actual = c.Saldo_actual + v_operaciones(i).Cantidad
                WHERE REF(c) = v_ref_dest;
            END IF;
        EXCEPTION 
            WHEN NO_DATA_FOUND THEN
                NULL; -- Si error, es que era EfectivoUdt (no transferencia), ignoramos.
        END;
    END LOOP;
END AFTER STATEMENT;

END TRG_OPERACIONES_COMPUESTO;
/

-- ==========================================================
-- 5. CÁLCULO DE INTERESES (PROCEDIMIENTO Y JOB 02:00 AM)
-- ==========================================================

-- Procedimiento que recorre las cuentas de ahorro y aplica el interés
CREATE OR REPLACE PROCEDURE PROC_INTERESES_NOCTURNOS IS
BEGIN
    UPDATE Cuenta c
    SET c.Saldo_actual = c.Saldo_actual + (c.Saldo_actual * (TREAT(VALUE(c) AS AhorroUdt).Tipo_interes / 100))
    WHERE VALUE(c) IS OF (AhorroUdt);
    COMMIT;
END;
/

-- Programación del Job para las 2 de la mañana
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'JOB_INTERESES_DIARIOS',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'PROC_INTERESES_NOCTURNOS',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0; BYSECOND=0',
    enabled         => TRUE
  );
END;
/