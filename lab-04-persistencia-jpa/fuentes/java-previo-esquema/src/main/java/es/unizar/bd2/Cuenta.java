package es.unizar.bd2;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.Date;
import java.util.LinkedHashSet;
import java.util.Objects;
import java.util.Set;

@Entity
@Table(name = "CUENTA")
public class Cuenta {

   @Id
   @Column(name = "IBAN", length = 24, nullable = false)
   private String iban;

   @Column(name = "NUMERO", precision = 20, scale = 0, nullable = false)
   private BigDecimal numero;

   @Temporal(TemporalType.DATE)
   @Column(name = "FECHA_CREACION", nullable = false)
   private Date fechaCreacion;

   @Column(name = "SALDO_ACTUAL", precision = 10, scale = 2, nullable = false)
   private BigDecimal saldoActual;

   @Column(name = "ES_AHORRO", precision = 1, nullable = false)
   private Integer esAhorro;

   @Column(name = "TIPO_INTERES", precision = 5, scale = 2)
   private BigDecimal tipoInteres;

   @ManyToOne
   @JoinColumn(name = "OFICINA_CODIGO")
   private Oficina oficina;

   @ManyToMany
   @JoinTable(name = "SER_TITULAR", joinColumns = @JoinColumn(name = "CUENTA_IBAN"), inverseJoinColumns = @JoinColumn(name = "CLIENTE_DNI"))
   private Set<Cliente> titulares = new LinkedHashSet<>();

   @OneToMany(mappedBy = "cuentaOrigen")
   private Set<Operacion> operacionesOrigen = new LinkedHashSet<>();

   @OneToMany(mappedBy = "cuentaDestino")
   private Set<Operacion> operacionesDestino = new LinkedHashSet<>();

   public Cuenta() {
   }

   public String getIban() {
      return iban;
   }

   public void setIban(String iban) {
      this.iban = iban;
   }

   public BigDecimal getNumero() {
      return numero;
   }

   public void setNumero(BigDecimal numero) {
      this.numero = numero;
   }

   public Date getFechaCreacion() {
      return fechaCreacion;
   }

   public void setFechaCreacion(Date fechaCreacion) {
      this.fechaCreacion = fechaCreacion;
   }

   public BigDecimal getSaldoActual() {
      return saldoActual;
   }

   public void setSaldoActual(BigDecimal saldoActual) {
      this.saldoActual = saldoActual;
   }

   public Integer getEsAhorro() {
      return esAhorro;
   }

   public void setEsAhorro(Integer esAhorro) {
      this.esAhorro = esAhorro;
   }

   public BigDecimal getTipoInteres() {
      return tipoInteres;
   }

   public void setTipoInteres(BigDecimal tipoInteres) {
      this.tipoInteres = tipoInteres;
   }

   public Oficina getOficina() {
      return oficina;
   }

   public void setOficina(Oficina oficina) {
      this.oficina = oficina;
   }

   public Set<Cliente> getTitulares() {
      return titulares;
   }

   public void setTitulares(Set<Cliente> titulares) {
      this.titulares = titulares;
   }

   public Set<Operacion> getOperacionesOrigen() {
      return operacionesOrigen;
   }

   public void setOperacionesOrigen(Set<Operacion> operacionesOrigen) {
      this.operacionesOrigen = operacionesOrigen;
   }

   public Set<Operacion> getOperacionesDestino() {
      return operacionesDestino;
   }

   public void setOperacionesDestino(Set<Operacion> operacionesDestino) {
      this.operacionesDestino = operacionesDestino;
   }

   public boolean esCuentaAhorro() {
      return esAhorro != null && esAhorro == 1;
   }

   public boolean esCuentaCorriente() {
      return esAhorro != null && esAhorro == 0;
   }

   @Override
   public boolean equals(Object o) {
      if (this == o)
         return true;
      if (!(o instanceof Cuenta cuenta))
         return false;
      return Objects.equals(iban, cuenta.iban);
   }

   @Override
   public int hashCode() {
      return Objects.hash(iban);
   }
}