-- ==============================================================================
-- 1. SUCURSALES (Integración Directa)
-- ==============================================================================
CREATE OR REPLACE VIEW Sucursal_global AS
-- Datos de Banquito local
SELECT 
    Codigo AS Codoficina, 
    Direccion AS Dir, 
    Telefono AS Tfno 
FROM Oficina
UNION ALL
-- Datos de Banquete remoto
SELECT 
    CODOFICINA AS Codoficina, 
    DIR AS Dir, 
    TFNO AS Tfno 
FROM SUCURSAL@SCHEMA2BD2;

-- ==============================================================================
-- 2. TITULARES (Separación de apellidos, cálculo de fechas y JOIN a 3 bandas)
-- ==============================================================================
CREATE OR REPLACE VIEW Titular_global AS
-- Datos de Banquito local
SELECT 
    Dni, 
    Nombre, 
    -- Si hay un espacio, cortamos el primer apellido, si no, lo cogemos entero
    CASE WHEN INSTR(Apellidos, ' ') > 0 THEN SUBSTR(Apellidos, 1, INSTR(Apellidos, ' ') - 1) ELSE Apellidos END AS Apellido1,
    -- Cogemos el resto como segundo apellido
    CASE WHEN INSTR(Apellidos, ' ') > 0 THEN SUBSTR(Apellidos, INSTR(Apellidos, ' ') + 1) ELSE NULL END AS Apellido2,
    Direccion, 
    Email, 
    TO_CHAR(Telefono) AS Telefono, 
    -- Transformamos la edad variable en una fecha de nacimiento estática (1 de enero del año calculado)
    TO_DATE('01/01/' || TO_CHAR(EXTRACT(YEAR FROM SYSDATE) - Edad), 'DD/MM/YYYY') AS Fecha_nacimiento
FROM Cliente
UNION ALL
-- Datos de Banquete remoto
SELECT 
    t.DNI, 
    t.NOMBRE, 
    t.APELLIDO1, 
    t.APELLIDO2, 
    -- Generamos la dirección estructurada a partir de DIRECCION y CODPOSTAL
    d.CALLE || ', N. ' || d.NUMERO || ', Piso ' || NVL(d.PISO, '-') || ', ' || d.CIUDAD || ', CP: ' || cp.CODPOSTAL AS Direccion, 
    CAST(NULL AS VARCHAR2(50)) AS Email, -- Banquete no tiene email
    TO_CHAR(t.TELEFONO) AS Telefono, 
    t.FECHA_NACIMIENTO 
FROM TITULAR@SCHEMA2BD2 t
JOIN DIRECCION@SCHEMA2BD2 d ON t.DIRECCION = d.ID_DIRECCION
JOIN CODPOSTAL@SCHEMA2BD2 cp ON d.CALLE = cp.CALLE AND d.CIUDAD = cp.CIUDAD;

-- ==============================================================================
-- 3. CUENTAS (Aplanamiento de jerarquías y generación de IBAN)
-- ==============================================================================
CREATE OR REPLACE VIEW Cuenta_global AS
-- Datos de Banquito local
SELECT 
    Iban, 
    Oficina_codigo AS Codoficina, 
    Fecha_creacion AS Fechacreacion, 
    Saldo_actual, 
    Es_ahorro, 
    Tipo_interes 
FROM Cuenta
UNION ALL
-- Datos de Banquete remoto (Con filtro anti-anomalías)
SELECT 
    'ES91' || c.CCC AS Iban, 
    -- Si está en Corriente, cogemos la oficina. Si no, nulo.
    CASE WHEN cc.CCC IS NOT NULL THEN cc.SUCURSAL_CODOFICINA ELSE NULL END AS Codoficina, 
    c.FECHACREACION AS Fechacreacion, 
    c.SALDO AS Saldo_actual, 
    -- Si está en Corriente marcamos 0. Si solo está en Ahorro marcamos 1.
    CASE WHEN cc.CCC IS NOT NULL THEN 0 ELSE 1 END AS Es_ahorro, 
    -- Si es Corriente, forzamos que el interés sea nulo (escondiendo la anomalía). Si es Ahorro, cogemos el interés.
    CASE WHEN cc.CCC IS NOT NULL THEN NULL ELSE a.TIPOINTERES END AS Tipo_interes 
FROM CUENTA@SCHEMA2BD2 c
LEFT JOIN CUENTACORRIENTE@SCHEMA2BD2 cc ON c.CCC = cc.CCC
LEFT JOIN CUENTAAHORRO@SCHEMA2BD2 a ON c.CCC = a.CCC;

-- ==============================================================================
-- 4. OPERACIONES (Aplanamiento de jerarquías y correspondencia de tipos)
-- ==============================================================================
CREATE OR REPLACE VIEW Operacion_global AS
SELECT 
    Codigo AS Numop, 
    Cuenta_origen AS Iban, 
    Cuenta_destino AS Ibandestino, 
    Oficina_codigo AS Codoficina, 
    Concepto AS Descripcionop, 
    Fecha AS Fechaop, 
    TO_CHAR(Fecha, 'HH24:MI') AS Horaop, 
    Cantidad, 
    CASE WHEN Tipo_operacion = 'Transferencia' THEN 'TRANSFERENCIA' ELSE 'EFECTIVO' END AS Tipo_operacion 
FROM Operacion
UNION ALL
SELECT 
    o.NUMOP AS Numop, 
    'ES91' || o.CCC AS Iban, 
    CASE WHEN t.CUENTADESTINO IS NOT NULL THEN 'ES91' || t.CUENTADESTINO ELSE NULL END AS Ibandestino, 
    e.SUCURSAL_CODOFICINA AS Codoficina, 
    o.DESCRIPCIONOP AS Descripcionop, 
    o.FECHAOP AS Fechaop, 
    o.HORAOP AS Horaop, 
    o.CANTIDADOP AS Cantidad, 
    CASE WHEN t.NUMOP IS NOT NULL THEN 'TRANSFERENCIA' ELSE 'EFECTIVO' END AS Tipo_operacion 
FROM OPERACION@SCHEMA2BD2 o
LEFT JOIN OPEFECTIVO@SCHEMA2BD2 e ON o.NUMOP = e.NUMOP AND o.CCC = e.CCC
LEFT JOIN OPTRANSFERENCIA@SCHEMA2BD2 t ON o.NUMOP = t.NUMOP AND o.CCC = t.CCC;

-- ==============================================================================
-- 5. RELACIÓN SER_TITULAR (N:M real vs 1:N convertida a N:M)
-- ==============================================================================
CREATE OR REPLACE VIEW ser_titular_global AS
SELECT 
    Cliente_dni AS Dni, 
    Cuenta_iban AS Iban 
FROM ser_titular
UNION ALL
SELECT 
    TITULAR AS Dni, 
    'ES91' || CCC AS Iban 
FROM CUENTA@SCHEMA2BD2;