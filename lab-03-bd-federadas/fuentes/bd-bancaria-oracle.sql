-- ==========================================================
-- Script: bd-bancaria-oracle.sql
-- SGBD: Oracle
-- Modelo: Relacional
-- Proposito: Creacion del esquema relacional de la base de datos bancaria
-- Requiere: Ninguno
-- Observaciones: El script elimina previamente tablas, secuencia,
-- procedimiento y job scheduler si ya existen.
-- ==========================================================

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE Operacion CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE ser_titular CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE Cliente CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE Cuenta CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE Oficina CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP SEQUENCE seq_operacion';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP PROCEDURE liquidar_intereses';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  DBMS_SCHEDULER.DROP_JOB('JOB_LIQUIDAR_INTERESES', force => TRUE);
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE Cliente
(
   Dni         VARCHAR2(9) PRIMARY KEY,
   Nombre      VARCHAR2(50) NOT NULL,
   Email       VARCHAR2(50) CHECK (Email LIKE '%@%.%'),
   Apellidos   VARCHAR2(50) NOT NULL,
   Edad        NUMBER(3)    NOT NULL CHECK (Edad >= 18),
   Direccion   VARCHAR2(100) NOT NULL,
   Telefono    NUMBER(9)    NOT NULL,
   CHECK (REGEXP_LIKE(Dni, '^[0-9]{8}[a-zA-Z]$'))
);

CREATE TABLE Oficina
(
   Codigo      NUMBER(5) PRIMARY KEY,
   Telefono    NUMBER(9)     NOT NULL,
   Direccion   VARCHAR2(100) NOT NULL
);

CREATE TABLE Cuenta
(
   Iban             VARCHAR2(24) PRIMARY KEY,
   Numero           NUMBER(20) NOT NULL,
   Fecha_creacion   DATE DEFAULT SYSDATE NOT NULL,
   Saldo_actual     NUMBER(10,2) NOT NULL CHECK (Saldo_actual >= 0),
   Es_ahorro        NUMBER(1) NOT NULL CHECK (Es_ahorro IN (0,1)),
   Tipo_interes     NUMBER(5,2),
   Oficina_codigo   NUMBER(5),
   FOREIGN KEY (Oficina_codigo) REFERENCES Oficina(Codigo),
   CHECK (
       (Es_ahorro = 1 AND Tipo_interes IS NOT NULL AND Oficina_codigo IS NULL) 
       OR 
       (Es_ahorro = 0 AND Tipo_interes IS NULL AND Oficina_codigo IS NOT NULL)
   )
);

CREATE TABLE Operacion
(
   Codigo         NUMBER(8),
   Concepto       VARCHAR2(250),
   Fecha          DATE DEFAULT SYSDATE NOT NULL,
   Cantidad       NUMBER(10,2) NOT NULL CHECK (Cantidad > 0),
   Tipo_operacion VARCHAR2(13) NOT NULL CHECK (Tipo_operacion IN ('Ingreso', 'Retirada', 'Transferencia')),
   Cuenta_origen  VARCHAR2(24) NOT NULL,
   Oficina_codigo NUMBER(5),        
   Cuenta_destino VARCHAR2(24),  
   PRIMARY KEY (Codigo, Cuenta_origen),
   FOREIGN KEY (Cuenta_origen) REFERENCES Cuenta(Iban),
   FOREIGN KEY (Oficina_codigo) REFERENCES Oficina(Codigo),
   FOREIGN KEY (Cuenta_destino) REFERENCES Cuenta(Iban),
   CHECK (Cuenta_origen != Cuenta_destino),
   CHECK (
       (Tipo_operacion = 'Transferencia' AND Cuenta_destino IS NOT NULL AND Oficina_codigo IS NULL)
       OR 
       (Tipo_operacion IN ('Ingreso', 'Retirada') AND Oficina_codigo IS NOT NULL AND Cuenta_destino IS NULL)
       OR
       (Tipo_operacion = 'Ingreso' AND Concepto = 'Liquidacion de intereses mensuales' AND Oficina_codigo IS NULL AND Cuenta_destino IS NULL)
   )
);

CREATE TABLE ser_titular
(
   Cliente_dni   VARCHAR2(9),
   Cuenta_iban   VARCHAR2(24),
   PRIMARY KEY (Cliente_dni, Cuenta_iban),
   FOREIGN KEY (Cliente_dni) REFERENCES Cliente(Dni),
   FOREIGN KEY (Cuenta_iban) REFERENCES Cuenta(Iban)
);

CREATE OR REPLACE TRIGGER trg_valida_fecha_operacion
BEFORE INSERT OR UPDATE ON Operacion
FOR EACH ROW
DECLARE
    v_fecha_creacion_origen DATE;
    v_fecha_creacion_destino DATE;
BEGIN
    SELECT Fecha_creacion INTO v_fecha_creacion_origen
    FROM Cuenta WHERE Iban = :NEW.Cuenta_origen;

    IF :NEW.Fecha < v_fecha_creacion_origen THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: La operación es anterior a la creación de la cuenta origen.');
    END IF;

    IF :NEW.Tipo_operacion = 'Transferencia' AND :NEW.Cuenta_destino IS NOT NULL THEN
        SELECT Fecha_creacion INTO v_fecha_creacion_destino
        FROM Cuenta WHERE Iban = :NEW.Cuenta_destino;

        IF :NEW.Fecha < v_fecha_creacion_destino THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error: La operación es anterior a la creación de la cuenta destino.');
        END IF;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_actualiza_saldo
AFTER INSERT ON Operacion
FOR EACH ROW
BEGIN
    IF :NEW.Tipo_operacion = 'Ingreso' THEN
        UPDATE Cuenta SET Saldo_actual = Saldo_actual + :NEW.Cantidad
        WHERE Iban = :NEW.Cuenta_origen;
        
    ELSIF :NEW.Tipo_operacion = 'Retirada' THEN
        UPDATE Cuenta SET Saldo_actual = Saldo_actual - :NEW.Cantidad
        WHERE Iban = :NEW.Cuenta_origen;
        
    ELSIF :NEW.Tipo_operacion = 'Transferencia' THEN
        UPDATE Cuenta SET Saldo_actual = Saldo_actual - :NEW.Cantidad
        WHERE Iban = :NEW.Cuenta_origen;
        UPDATE Cuenta SET Saldo_actual = Saldo_actual + :NEW.Cantidad
        WHERE Iban = :NEW.Cuenta_destino;
    END IF;
END;
/

CREATE SEQUENCE seq_operacion START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE PROCEDURE liquidar_intereses AS
    v_interes_calculado NUMBER(10,2);
BEGIN
    FOR cuenta_rec IN (SELECT Iban, Saldo_actual, Tipo_interes, Oficina_codigo 
                       FROM Cuenta 
                       WHERE Es_ahorro = 1 AND Tipo_interes IS NOT NULL AND Tipo_interes > 0) 
    LOOP
        v_interes_calculado := cuenta_rec.Saldo_actual * (cuenta_rec.Tipo_interes / 100 / 12);
        
        IF v_interes_calculado > 0 THEN
            INSERT INTO Operacion (Codigo, Concepto, Fecha, Cantidad, Tipo_operacion, Cuenta_origen, Oficina_codigo, Cuenta_destino)
            VALUES (seq_operacion.NEXTVAL, 'Liquidacion de intereses mensuales', SYSDATE, v_interes_calculado, 'Ingreso', cuenta_rec.Iban, cuenta_rec.Oficina_codigo, NULL);
        END IF;
    END LOOP;

    COMMIT;
END;
/