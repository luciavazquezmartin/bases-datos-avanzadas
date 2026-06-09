package es.unizar.bd2;

import jakarta.persistence.*;
import java.util.LinkedHashSet;
import java.util.Objects;
import java.util.Set;

@Entity
@Table(name = "CLIENTE")
public class Cliente {

   @Id
   @Column(name = "DNI", length = 9, nullable = false)
   private String dni;

   @Column(name = "NOMBRE", length = 50, nullable = false)
   private String nombre;

   @Column(name = "EMAIL", length = 50)
   private String email;

   @Column(name = "APELLIDOS", length = 50, nullable = false)
   private String apellidos;

   @Column(name = "EDAD", precision = 3, nullable = false)
   private Integer edad;

   @Column(name = "DIRECCION", length = 100, nullable = false)
   private String direccion;

   @Column(name = "TELEFONO", precision = 9, nullable = false)
   private Long telefono;

   @ManyToMany(mappedBy = "titulares")
   private Set<Cuenta> cuentas = new LinkedHashSet<>();

   public Cliente() {
   }

   public String getDni() {
      return dni;
   }

   public void setDni(String dni) {
      this.dni = dni;
   }

   public String getNombre() {
      return nombre;
   }

   public void setNombre(String nombre) {
      this.nombre = nombre;
   }

   public String getEmail() {
      return email;
   }

   public void setEmail(String email) {
      this.email = email;
   }

   public String getApellidos() {
      return apellidos;
   }

   public void setApellidos(String apellidos) {
      this.apellidos = apellidos;
   }

   public Integer getEdad() {
      return edad;
   }

   public void setEdad(Integer edad) {
      this.edad = edad;
   }

   public String getDireccion() {
      return direccion;
   }

   public void setDireccion(String direccion) {
      this.direccion = direccion;
   }

   public Long getTelefono() {
      return telefono;
   }

   public void setTelefono(Long telefono) {
      this.telefono = telefono;
   }

   public Set<Cuenta> getCuentas() {
      return cuentas;
   }

   public void setCuentas(Set<Cuenta> cuentas) {
      this.cuentas = cuentas;
   }

   @Override
   public boolean equals(Object o) {
      if (this == o)
         return true;
      if (!(o instanceof Cliente cliente))
         return false;
      return Objects.equals(dni, cliente.dni);
   }

   @Override
   public int hashCode() {
      return Objects.hash(dni);
   }
}