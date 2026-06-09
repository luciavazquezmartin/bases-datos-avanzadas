package es.unizar.bd2;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.Persistence;
import jakarta.persistence.Query;
import java.util.Date;
import java.util.HashSet;
import java.util.List;

public class Test {
    public static void main(String[] args) {
        System.out.println("Iniciando Hibernate y conectando a la base de datos...");
        EntityManagerFactory emf = null;
        EntityManager em = null;

        try {
            emf = Persistence.createEntityManagerFactory("BanquitoPU");
            em = emf.createEntityManager();

            // =====================================================================
            // BLOQUE 1: POBLAR LA BASE DE DATOS
            // =====================================================================
            em.getTransaction().begin();
            System.out.println("1. Creando datos iniciales (Oficinas, Clientes y Cuentas)...");

            // 1.1 Crear Oficina
            Oficina ofi = new Oficina();
            ofi.setCodigo(1);
            ofi.setDireccion("Cajero Principal Centro");
            ofi.setTelefono(900112233);
            em.persist(ofi);

            // 1.2 Crear Cliente
            Cliente cli = new Cliente();
            cli.setDni("11111111H");
            cli.setNombre("Usuario");
            cli.setApellidos("De Prueba");
            cli.setEdad(30);
            cli.setDireccion("Avenida Principal, 1");
            cli.setEmail("usuario.prueba@banco.com");
            cli.setCuentas(new HashSet<>()); // Inicializamos el Set
            em.persist(cli);

            // 1.3 Crear Cuenta Corriente
            CuentaCorriente cc = new CuentaCorriente();
            cc.setIban("ES9100001111222233334444");
            cc.setNumero(1111);
            cc.setFechacreacion(new Date());
            cc.setSaldoactual(1000.0);
            cc.setOficina(ofi);
            em.persist(cc);

            // 1.4 Crear Cuenta Ahorro (Destino de la transferencia)
            CuentaAhorro ca = new CuentaAhorro();
            ca.setIban("ES9100005555666677778888");
            ca.setNumero(5555);
            ca.setFechacreacion(new Date());
            ca.setSaldoactual(500.0);
            ca.setTipointeres(2.5);
            em.persist(ca);

            // 1.5 Asociar Cliente a Cuentas (N:M ser_titular)
            cli.getCuentas().add(cc);
            cli.getCuentas().add(ca);

            em.getTransaction().commit();
            System.out.println("   -> Datos iniciales guardados correctamente.\n");

            // =====================================================================
            // BLOQUE 2: OPERACIONES BANCARIAS
            // =====================================================================
            em.getTransaction().begin();
            System.out.println("2. Registrando operaciones de Efectivo y Transferencia...");

            // 2.1 Operación Efectivo (Cajero - Retirada de 200€)
            OperacionEfectivo opEfectivo = new OperacionEfectivo();
            opEfectivo.setCodigo(1);
            opEfectivo.setConcepto("Cajero");
            opEfectivo.setFecha(new Date());
            opEfectivo.setCantidad(-200.0);
            opEfectivo.setCuentaorigen(cc);
            opEfectivo.setOficina(ofi);
            em.persist(opEfectivo);

            // Actualizar saldo
            cc.setSaldoactual(cc.getSaldoactual() - 200.0);

            // 2.2 Operación Transferencia (Regalo - 300€)
            OperacionTransferencia opTransf = new OperacionTransferencia();
            opTransf.setCodigo(2);
            opTransf.setConcepto("Regalo");
            opTransf.setFecha(new Date());
            opTransf.setCantidad(300.0);
            opTransf.setCuentaorigen(cc);
            opTransf.setCuentadestino(ca);
            em.persist(opTransf);

            // Actualizar saldos origen y destino
            cc.setSaldoactual(cc.getSaldoactual() - 300.0);
            ca.setSaldoactual(ca.getSaldoactual() + 300.0);

            em.getTransaction().commit();
            System.out.println("   -> Operaciones registradas y saldos actualizados.\n");

            // =====================================================================
            // BLOQUE 3: CONSULTAS JPQL vs SQL NATIVO (Comparativa para la Memoria)
            // =====================================================================
            System.out.println("3. Ejecutando consultas de prueba...\n");

            // --- CONSULTA 1: JOIN N:M (Saldo total por cliente) ---
            System.out.println("--- C1: Saldo total acumulado de cada cliente ---");
            
            // JPQL: Navega por los objetos directamente usando la colección 'cuentas'
            System.out.println(" * Usando JPQL:");
            String jpql1 = "SELECT c.nombre, SUM(cu.saldoactual) FROM Cliente c JOIN c.cuentas cu GROUP BY c.nombre";
            List<Object[]> resJpql1 = em.createQuery(jpql1).getResultList();
            for (Object[] r : resJpql1) System.out.println("   Cliente: " + r[0] + " | Saldo Total: " + r[1] + "€");

            // SQL NATIVO: Requiere hacer los JOIN explícitos con la tabla intermedia (ser_titular)
            System.out.println(" * Usando SQL Nativo:");
            String sql1 = "SELECT c.nombre, SUM(cu.Saldo_actual) FROM Cliente c " +
                          "JOIN ser_titular st ON c.dni = st.refCliente " +
                          "JOIN Cuenta cu ON st.refCuenta = cu.iban GROUP BY c.nombre";
            List<Object[]> resSql1 = em.createNativeQuery(sql1).getResultList();
            for (Object[] r : resSql1) System.out.println("   Cliente: " + r[0] + " | Saldo Total: " + r[1] + "€");
            System.out.println();


            // --- CONSULTA 2: POLIMORFISMO Y HERENCIA (Buscar transferencias) ---
            System.out.println("--- C2: Historial de Transferencias mayores a X importe ---");
            double limite = 100.0;
            
            // JPQL: Consulta directamente a la clase hija 'OperacionTransferencia'. Hibernate deduce el discriminador.
            System.out.println(" * Usando JPQL:");
            String jpql2 = "SELECT o.concepto, o.cantidad, o.cuentaorigen.iban, o.cuentadestino.iban " +
                           "FROM OperacionTransferencia o WHERE o.cantidad > :limite";
            Query qJpql2 = em.createQuery(jpql2);
            qJpql2.setParameter("limite", limite);
            List<Object[]> resJpql2 = qJpql2.getResultList();
            for (Object[] r : resJpql2) System.out.println("   " + r[0] + ": " + r[1] + "€ (De: " + r[2] + " A: " + r[3] + ")");

            // SQL NATIVO: Al usar SINGLE_TABLE, hay que filtrar manualmente por la columna discriminadora.
            System.out.println(" * Usando SQL Nativo:");
            String sql2 = "SELECT concepto, cantidad, refCuentaOrigen, refCuentaDestino " +
                          "FROM Operacion WHERE Tipo_operacion = 'Transferencia' AND cantidad > ?";
            Query qSql2 = em.createNativeQuery(sql2);
            qSql2.setParameter(1, limite);
            List<Object[]> resSql2 = qSql2.getResultList();
            for (Object[] r : resSql2) System.out.println("   " + r[0] + ": " + r[1] + "€ (De: " + r[2] + " A: " + r[3] + ")");
            System.out.println();


            // --- CONSULTA 3: AGRUPACIÓN Y CLASES HIJAS (Saldo medio Cuentas Corrientes por Oficina) ---
            System.out.println("--- C3: Saldo medio de las cuentas corrientes por código de oficina ---");

            // JPQL: Consultamos la clase CuentaCorriente y navegamos a la oficina sin hacer JOINs explícitos
            System.out.println(" * Usando JPQL:");
            String jpql3 = "SELECT c.oficina.codigo, AVG(c.saldoactual) FROM CuentaCorriente c GROUP BY c.oficina.codigo";
            List<Object[]> resJpql3 = em.createQuery(jpql3).getResultList();
            for (Object[] r : resJpql3) System.out.println("   Oficina: " + r[0] + " | Saldo Medio: " + r[1] + "€");

            // SQL NATIVO: Usamos la tabla Cuenta y filtramos por la columna discriminadora 'Es_ahorro' = 0
            System.out.println(" * Usando SQL Nativo:");
            String sql3 = "SELECT refOficina, AVG(Saldo_actual) FROM Cuenta WHERE Es_ahorro = 0 GROUP BY refOficina";
            List<Object[]> resSql3 = em.createNativeQuery(sql3).getResultList();
            for (Object[] r : resSql3) System.out.println("   Oficina: " + r[0] + " | Saldo Medio: " + r[1] + "€");


        } catch (Exception e) {
            System.err.println("Ha ocurrido un error durante la ejecución:");
            e.printStackTrace();
            if (em != null && em.getTransaction().isActive()) {
                em.getTransaction().rollback();
            }
        } finally {
            if (em != null) em.close();
            if (emf != null) emf.close();
            System.out.println("\nEjecución finalizada y conexión cerrada.");
        }
    }
}