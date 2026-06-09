package es.unizar.bd2;

import jakarta.persistence.*;
import java.util.Set;

@Entity // Le dice a Hibernate que esto será una tabla en la base de datos
public class Cliente {
    @Id // Le dice a Hibernate que el DNI es la clave primaria
    private String dni;

    private String nombre;
    private String apellidos;
    private String email;
    private Integer edad;
    private String direccion;
    private Integer telefono;

    // Relación N:M con Cuenta (tabla ser_titular)
    @ManyToMany
    @JoinTable(
        name = "ser_titular", // Para evitar que le ponga él otro nombre
        joinColumns = @JoinColumn(name = "refCliente"),
        inverseJoinColumns = @JoinColumn(name = "refCuenta")
    )
    private Set<Cuenta> cuentas;

    public Cliente() {
        // JPA exige que haya un constructor vacío
    }

    // --- GETTERS Y SETTERS ---

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

    public String getApellidos() {
        return apellidos;
    }

    public void setApellidos(String apellidos) {
        this.apellidos = apellidos;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
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

    public Integer getTelefono() {
        return telefono;
    }

    public void setTelefono(Integer telefono) {
        this.telefono = telefono;
    }

    public Set<Cuenta> getCuentas() {
        return cuentas;
    }

    public void setCuentas(Set<Cuenta> cuentas) {
        this.cuentas = cuentas;
    }
}
