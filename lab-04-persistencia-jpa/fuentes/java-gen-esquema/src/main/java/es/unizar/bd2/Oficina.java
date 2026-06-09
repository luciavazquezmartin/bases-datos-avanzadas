package es.unizar.bd2;

import jakarta.persistence.*;

@Entity // Le dice a Hibernate que esto será una tabla en la base de datos
public class Oficina {
    @Id // Le dice a Hibernate que el codigo es la clave primaria
    private Integer codigo;

    private Integer telefono;
    private String direccion;

    public Oficina () {
        // JPA exige que haya un constructor vacío
    }

    // --- GETTERS Y SETTERS ---

    public Integer getCodigo() {
        return codigo;
    }

    public void setCodigo(Integer codigo) {
        this.codigo = codigo;
    }

    public Integer getTelefono() {
        return telefono;
    }

    public void setTelefono(Integer telefono) {
        this.telefono = telefono;
    }

    public String getDireccion() {
        return direccion;
    }

    public void setDireccion(String direccion) {
        this.direccion = direccion;
    }
}
