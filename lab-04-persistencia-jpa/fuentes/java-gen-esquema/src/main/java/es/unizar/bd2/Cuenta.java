package es.unizar.bd2;

import jakarta.persistence.*;
import java.util.Date;
import java.util.Set;

@Entity // Le dice a Hibernate que esto será una tabla en la base de datos
@Inheritance(strategy = InheritanceType.SINGLE_TABLE) // Le dice a Hibernate que toda la herencia va en una sola tabla
@DiscriminatorColumn(name = "Es_ahorro", discriminatorType = DiscriminatorType.INTEGER) // Le dice que Es_ahorro es la columna que funcionará como discriminador en los tipos de cuentas
public abstract class Cuenta { // abstract porque nunca se creará una cuenta genérica, sino CuentaCorriente o CuentaAhorro

    @Id // Le dice a Hibernate que el iban es la clave primaria
    private String iban;

    private Integer numero;

    @Column(name = "Fecha_creacion")
    private Date fechacreacion;

    @Column(name = "Saldo_actual")
    private Double saldoactual;

    // Relación N:M con Cliente (Bidireccional)
    // Como en Cliente.java ya está el @ManyToMany, aquí se indica que Cliente es el que manda
    @ManyToMany(mappedBy = "cuentas")
    private Set<Cliente> clientes;

    public Cuenta() {
        // JPA exige que haya un constructor vacío
    }

    // --- GETTERS Y SETTERS ---

    public String getIban() {
        return iban;
    }

    public void setIban(String iban) {
        this.iban = iban;
    }

    public Integer getNumero() {
        return numero;
    }

    public void setNumero(Integer numero) {
        this.numero = numero;
    }

    public Date getFechacreacion() {
        return fechacreacion;
    }

    public void setFechacreacion(Date fechacreacion) {
        this.fechacreacion = fechacreacion;
    }

    public Double getSaldoactual() {
        return saldoactual;
    }

    public void setSaldoactual(Double saldoactual) {
        this.saldoactual = saldoactual;
    }

    public Set<Cliente> getClientes() {
        return clientes;
    }

    public void setClientes(Set<Cliente> clientes) {
        this.clientes = clientes;
    }
}