package es.unizar.bd2;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.Persistence;
import jakarta.persistence.Query;

import java.math.BigDecimal;
import java.util.Date;
import java.util.HashSet;
import java.util.List;

public class Test {

   public static void main(String[] args) {
      System.out.println("Iniciando Hibernate y conectando a la base de datos...");
      EntityManagerFactory emf = null;
      EntityManager em = null;

      try {
         emf = Persistence.createEntityManagerFactory("banquito-previo");
         em = emf.createEntityManager();

         // =====================================================================
         // BLOQUE 1: POBLADO CONTROLADO DE DATOS DE EJEMPLO
         // =====================================================================
         System.out.println("==========================================================");
         System.out.println("1. POBLADO CONTROLADO DE DATOS DE EJEMPLO");
         System.out.println("==========================================================");

         em.getTransaction().begin();

         // 1.1 Crear o recuperar Oficina
         Oficina ofi = em.find(Oficina.class, 99);
         if (ofi == null) {
            ofi = new Oficina();
            ofi.setCodigo(99);
            ofi.setDireccion("Oficina de Pruebas JPA");
            ofi.setTelefono(900112233L);
            em.persist(ofi);
            System.out.println("   -> Oficina creada.");
         } else {
            System.out.println("   -> Oficina ya existente.");
         }

         // 1.2 Crear o recuperar Cliente
         Cliente cli = em.find(Cliente.class, "11111111H");
         if (cli == null) {
            cli = new Cliente();
            cli.setDni("11111111H");
            cli.setNombre("Usuario");
            cli.setApellidos("De Prueba");
            cli.setEdad(30);
            cli.setDireccion("Avenida Principal, 1");
            cli.setEmail("usuario.prueba@banco.com");
            cli.setTelefono(600123123L);
            cli.setCuentas(new HashSet<>());
            em.persist(cli);
            System.out.println("   -> Cliente creado.");
         } else {
            System.out.println("   -> Cliente ya existente.");
         }

         // 1.3 Crear o recuperar Cuenta Corriente
         Cuenta cc = em.find(Cuenta.class, "ES9199001111222233334444");
         if (cc == null) {
            cc = new Cuenta();
            cc.setIban("ES9199001111222233334444");
            cc.setNumero(new BigDecimal("1111222233334444"));
            cc.setFechaCreacion(new Date());
            cc.setSaldoActual(new BigDecimal("0.00"));
            cc.setEsAhorro(0);
            cc.setTipoInteres(null);
            cc.setOficina(ofi);
            cc.setTitulares(new HashSet<>());
            em.persist(cc);
            System.out.println("   -> Cuenta corriente creada.");
         } else {
            System.out.println("   -> Cuenta corriente ya existente.");
         }

         // 1.4 Crear o recuperar Cuenta Ahorro
         Cuenta ca = em.find(Cuenta.class, "ES9199005555666677778888");
         if (ca == null) {
            ca = new Cuenta();
            ca.setIban("ES9199005555666677778888");
            ca.setNumero(new BigDecimal("5555666677778888"));
            ca.setFechaCreacion(new Date());
            ca.setSaldoActual(new BigDecimal("0.00"));
            ca.setEsAhorro(1);
            ca.setTipoInteres(new BigDecimal("2.50"));
            ca.setOficina(null);
            ca.setTitulares(new HashSet<>());
            em.persist(ca);
            System.out.println("   -> Cuenta ahorro creada.");
         } else {
            System.out.println("   -> Cuenta ahorro ya existente.");
         }

         // 1.5 Asociar Cliente a Cuentas (N:M ser_titular)
         if (!cc.getTitulares().contains(cli)) {
            cc.getTitulares().add(cli);
         }
         if (!ca.getTitulares().contains(cli)) {
            ca.getTitulares().add(cli);
         }
         if (!cli.getCuentas().contains(cc)) {
            cli.getCuentas().add(cc);
         }
         if (!cli.getCuentas().contains(ca)) {
            cli.getCuentas().add(ca);
         }

         em.getTransaction().commit();
         System.out.println("   -> Datos de ejemplo verificados/preparados correctamente.\n");

         // =====================================================================
         // BLOQUE 2: REGISTRO DE OPERACIONES BANCARIAS
         // =====================================================================
         System.out.println("==========================================================");
         System.out.println("2. REGISTRO DE OPERACIONES BANCARIAS");
         System.out.println("==========================================================");

         em.getTransaction().begin();

         // 2.1 Ingreso de 1000 euros
         OperacionId idIngreso = new OperacionId(1001, cc.getIban());
         Operacion opIngreso = em.find(Operacion.class, idIngreso);
         if (opIngreso == null) {
            opIngreso = new Operacion();
            opIngreso.setId(idIngreso);
            opIngreso.setConcepto("Nomina JPA");
            opIngreso.setFecha(new Date());
            opIngreso.setCantidad(new BigDecimal("1000.00"));
            opIngreso.setTipoOperacion("Ingreso");
            opIngreso.setCuentaOrigen(cc);
            opIngreso.setOficina(ofi);
            opIngreso.setCuentaDestino(null);
            em.persist(opIngreso);
            System.out.println("   -> Ingreso registrado.");
         } else {
            System.out.println("   -> Ingreso ya existente.");
         }

         // 2.2 Retirada de 200 euros
         OperacionId idRetirada = new OperacionId(1002, cc.getIban());
         Operacion opRetirada = em.find(Operacion.class, idRetirada);
         if (opRetirada == null) {
            opRetirada = new Operacion();
            opRetirada.setId(idRetirada);
            opRetirada.setConcepto("Cajero JPA");
            opRetirada.setFecha(new Date());
            opRetirada.setCantidad(new BigDecimal("200.00"));
            opRetirada.setTipoOperacion("Retirada");
            opRetirada.setCuentaOrigen(cc);
            opRetirada.setOficina(ofi);
            opRetirada.setCuentaDestino(null);
            em.persist(opRetirada);
            System.out.println("   -> Retirada registrada.");
         } else {
            System.out.println("   -> Retirada ya existente.");
         }

         // 2.3 Transferencia de 300 euros a la cuenta de ahorro
         OperacionId idTransferencia = new OperacionId(1003, cc.getIban());
         Operacion opTransferencia = em.find(Operacion.class, idTransferencia);
         if (opTransferencia == null) {
            opTransferencia = new Operacion();
            opTransferencia.setId(idTransferencia);
            opTransferencia.setConcepto("Transferencia JPA");
            opTransferencia.setFecha(new Date());
            opTransferencia.setCantidad(new BigDecimal("300.00"));
            opTransferencia.setTipoOperacion("Transferencia");
            opTransferencia.setCuentaOrigen(cc);
            opTransferencia.setOficina(null);
            opTransferencia.setCuentaDestino(ca);
            em.persist(opTransferencia);
            System.out.println("   -> Transferencia registrada.");
         } else {
            System.out.println("   -> Transferencia ya existente.");
         }

         em.getTransaction().commit();
         System.out.println("   -> Operaciones bancarias registradas correctamente.\n");

         // Se limpia el contexto para releer el estado real actualizado desde BD
         em.clear();

         // =====================================================================
         // BLOQUE 3: CONSULTAS DE EJEMPLO
         // =====================================================================
         System.out.println("==========================================================");
         System.out.println("3. CONSULTAS DE EJEMPLO");
         System.out.println("==========================================================\n");

         // ---------------------------------------------------------------------
         // C1. SALDO TOTAL ACUMULADO DE CADA CLIENTE
         // ---------------------------------------------------------------------
         System.out.println("----------------------------------------------------------");
         System.out.println("C1. SALDO TOTAL ACUMULADO DE CADA CLIENTE");
         System.out.println("----------------------------------------------------------");

         // JPQL
         System.out.println(" * Usando JPQL:");
         String jpql1 = "SELECT c.nombre, SUM(cu.saldoActual) " +
               "FROM Cliente c JOIN c.cuentas cu " +
               "GROUP BY c.nombre";
         List<Object[]> resJpql1 = em.createQuery(jpql1).getResultList();
         for (Object[] r : resJpql1) {
            System.out.println("   Cliente: " + r[0] + " | Saldo Total: " + r[1] + " euros");
         }

         // SQL NATIVO
         System.out.println(" * Usando SQL Nativo:");
         String sql1 = "SELECT c.NOMBRE, SUM(cu.SALDO_ACTUAL) " +
               "FROM CLIENTE c " +
               "JOIN SER_TITULAR st ON c.DNI = st.CLIENTE_DNI " +
               "JOIN CUENTA cu ON st.CUENTA_IBAN = cu.IBAN " +
               "GROUP BY c.NOMBRE";
         List<Object[]> resSql1 = em.createNativeQuery(sql1).getResultList();
         for (Object[] r : resSql1) {
            System.out.println("   Cliente: " + r[0] + " | Saldo Total: " + r[1] + " euros");
         }
         System.out.println();

         // ---------------------------------------------------------------------
         // C2. HISTORIAL DE TRANSFERENCIAS MAYORES A UN IMPORTE DADO
         // ---------------------------------------------------------------------
         System.out.println("----------------------------------------------------------");
         System.out.println("C2. HISTORIAL DE TRANSFERENCIAS MAYORES A UN IMPORTE DADO");
         System.out.println("----------------------------------------------------------");

         BigDecimal limite = new BigDecimal("100.00");

         // JPQL
         System.out.println(" * Usando JPQL:");
         String jpql2 = "SELECT o.concepto, o.cantidad, o.cuentaOrigen.iban, o.cuentaDestino.iban " +
               "FROM Operacion o " +
               "WHERE o.tipoOperacion = :tipo AND o.cantidad > :limite";
         Query qJpql2 = em.createQuery(jpql2);
         qJpql2.setParameter("tipo", "Transferencia");
         qJpql2.setParameter("limite", limite);
         List<Object[]> resJpql2 = qJpql2.getResultList();
         for (Object[] r : resJpql2) {
            System.out.println("   " + r[0] + ": " + r[1] + " euros (De: " + r[2] + " A: " + r[3] + ")");
         }

         // SQL NATIVO
         System.out.println(" * Usando SQL Nativo:");
         String sql2 = "SELECT CONCEPTO, CANTIDAD, CUENTA_ORIGEN, CUENTA_DESTINO " +
               "FROM OPERACION " +
               "WHERE TIPO_OPERACION = 'Transferencia' AND CANTIDAD > ?";
         Query qSql2 = em.createNativeQuery(sql2);
         qSql2.setParameter(1, limite);
         List<Object[]> resSql2 = qSql2.getResultList();
         for (Object[] r : resSql2) {
            System.out.println("   " + r[0] + ": " + r[1] + " euros (De: " + r[2] + " A: " + r[3] + ")");
         }
         System.out.println();

         // ---------------------------------------------------------------------
         // C3. SALDO MEDIO DE LAS CUENTAS CORRIENTES POR OFICINA
         // ---------------------------------------------------------------------
         System.out.println("----------------------------------------------------------");
         System.out.println("C3. SALDO MEDIO DE LAS CUENTAS CORRIENTES POR OFICINA");
         System.out.println("----------------------------------------------------------");

         // JPQL
         System.out.println(" * Usando JPQL:");
         String jpql3 = "SELECT c.oficina.codigo, AVG(c.saldoActual) " +
               "FROM Cuenta c " +
               "WHERE c.esAhorro = 0 " +
               "GROUP BY c.oficina.codigo";
         List<Object[]> resJpql3 = em.createQuery(jpql3).getResultList();
         for (Object[] r : resJpql3) {
            System.out.println("   Oficina: " + r[0] + " | Saldo Medio: " + r[1] + " euros");
         }

         // SQL NATIVO
         System.out.println(" * Usando SQL Nativo:");
         String sql3 = "SELECT OFICINA_CODIGO, AVG(SALDO_ACTUAL) " +
               "FROM CUENTA " +
               "WHERE ES_AHORRO = 0 " +
               "GROUP BY OFICINA_CODIGO";
         List<Object[]> resSql3 = em.createNativeQuery(sql3).getResultList();
         for (Object[] r : resSql3) {
            System.out.println("   Oficina: " + r[0] + " | Saldo Medio: " + r[1] + " euros");
         }
         System.out.println();

         // =====================================================================
         // BLOQUE 4: COMPROBACION DE SALDOS FINALES
         // =====================================================================
         System.out.println("==========================================================");
         System.out.println("4. COMPROBACION DE SALDOS FINALES");
         System.out.println("==========================================================");

         Cuenta cuentaCorrienteFinal = em.find(Cuenta.class, "ES9199001111222233334444");
         Cuenta cuentaAhorroFinal = em.find(Cuenta.class, "ES9199005555666677778888");

         System.out.println("   Cuenta corriente: " + cuentaCorrienteFinal.getIban() +
               " | Saldo: " + cuentaCorrienteFinal.getSaldoActual() + " euros");
         System.out.println("   Cuenta ahorro: " + cuentaAhorroFinal.getIban() +
               " | Saldo: " + cuentaAhorroFinal.getSaldoActual() + " euros");

      } catch (Exception e) {
         System.err.println("Ha ocurrido un error durante la ejecución:");
         e.printStackTrace();
         if (em != null && em.getTransaction().isActive()) {
            em.getTransaction().rollback();
         }
      } finally {
         if (em != null)
            em.close();
         if (emf != null)
            emf.close();
         System.out.println("\nEjecución finalizada y conexión cerrada.");
      }
   }
}