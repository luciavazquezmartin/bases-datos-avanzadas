package es.unizar.bd2;

import jakarta.persistence.*;
import java.util.LinkedHashSet;
import java.util.Objects;
import java.util.Set;

@Entity
@Table(name = "OFICINA")
public class Oficina {

   @Id
   @Column(name = "CODIGO", precision = 5, nullable = false)
   private Integer codigo;

   @Column(name = "TELEFONO", precision = 9, nullable = false)
   private Long telefono;

   @Column(name = "DIRECCION", length = 100, nullable = false)
   private String direccion;

   @OneToMany(mappedBy = "oficina")
   private Set<Cuenta> cuentas = new LinkedHashSet<>();

   @OneToMany(mappedBy = "oficina")
   private Set<Operacion> operaciones = new LinkedHashSet<>();

   public Oficina() {
   }

   public Integer getCodigo() {
      return codigo;
   }

   public void setCodigo(Integer codigo) {
      this.codigo = codigo;
   }

   public Long getTelefono() {
      return telefono;
   }

   public void setTelefono(Long telefono) {
      this.telefono = telefono;
   }

   public String getDireccion() {
      return direccion;
   }

   public void setDireccion(String direccion) {
      this.direccion = direccion;
   }

   public Set<Cuenta> getCuentas() {
      return cuentas;
   }

   public void setCuentas(Set<Cuenta> cuentas) {
      this.cuentas = cuentas;
   }

   public Set<Operacion> getOperaciones() {
      return operaciones;
   }

   public void setOperaciones(Set<Operacion> operaciones) {
      this.operaciones = operaciones;
   }

   @Override
   public boolean equals(Object o) {
      if (this == o)
         return true;
      if (!(o instanceof Oficina oficina))
         return false;
      return Objects.equals(codigo, oficina.codigo);
   }

   @Override
   public int hashCode() {
      return Objects.hash(codigo);
   }
}