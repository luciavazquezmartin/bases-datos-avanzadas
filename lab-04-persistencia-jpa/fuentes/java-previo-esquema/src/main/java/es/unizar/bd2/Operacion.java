package es.unizar.bd2;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.Date;
import java.util.Objects;

@Entity
@Table(name = "OPERACION")
public class Operacion {

   @EmbeddedId
   private OperacionId id;

   @Column(name = "CONCEPTO", length = 250)
   private String concepto;

   @Temporal(TemporalType.DATE)
   @Column(name = "FECHA", nullable = false)
   private Date fecha;

   @Column(name = "CANTIDAD", precision = 10, scale = 2, nullable = false)
   private BigDecimal cantidad;

   @Column(name = "TIPO_OPERACION", length = 13, nullable = false)
   private String tipoOperacion;

   @MapsId("cuentaOrigen")
   @ManyToOne
   @JoinColumn(name = "CUENTA_ORIGEN", nullable = false)
   private Cuenta cuentaOrigen;

   @ManyToOne
   @JoinColumn(name = "OFICINA_CODIGO")
   private Oficina oficina;

   @ManyToOne
   @JoinColumn(name = "CUENTA_DESTINO")
   private Cuenta cuentaDestino;

   public Operacion() {
   }

   public OperacionId getId() {
      return id;
   }

   public void setId(OperacionId id) {
      this.id = id;
   }

   public String getConcepto() {
      return concepto;
   }

   public void setConcepto(String concepto) {
      this.concepto = concepto;
   }

   public Date getFecha() {
      return fecha;
   }

   public void setFecha(Date fecha) {
      this.fecha = fecha;
   }

   public BigDecimal getCantidad() {
      return cantidad;
   }

   public void setCantidad(BigDecimal cantidad) {
      this.cantidad = cantidad;
   }

   public String getTipoOperacion() {
      return tipoOperacion;
   }

   public void setTipoOperacion(String tipoOperacion) {
      this.tipoOperacion = tipoOperacion;
   }

   public Cuenta getCuentaOrigen() {
      return cuentaOrigen;
   }

   public void setCuentaOrigen(Cuenta cuentaOrigen) {
      this.cuentaOrigen = cuentaOrigen;
   }

   public Oficina getOficina() {
      return oficina;
   }

   public void setOficina(Oficina oficina) {
      this.oficina = oficina;
   }

   public Cuenta getCuentaDestino() {
      return cuentaDestino;
   }

   public void setCuentaDestino(Cuenta cuentaDestino) {
      this.cuentaDestino = cuentaDestino;
   }

   public boolean esTransferencia() {
      return "Transferencia".equalsIgnoreCase(tipoOperacion);
   }

   public boolean esIngreso() {
      return "Ingreso".equalsIgnoreCase(tipoOperacion);
   }

   public boolean esRetirada() {
      return "Retirada".equalsIgnoreCase(tipoOperacion);
   }

   @Override
   public boolean equals(Object o) {
      if (this == o)
         return true;
      if (!(o instanceof Operacion operacion))
         return false;
      return Objects.equals(id, operacion.id);
   }

   @Override
   public int hashCode() {
      return Objects.hash(id);
   }
}