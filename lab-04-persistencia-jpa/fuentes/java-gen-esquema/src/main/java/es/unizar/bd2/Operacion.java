package es.unizar.bd2;

import jakarta.persistence.*;
import java.util.Date;

@Entity // Le dice a Hibernate que esto será una tabla en la base de datos
@IdClass(OperacionId.class) // Le dice a JPA que mire esta clase para formar la clave compuesta
@Inheritance(strategy = InheritanceType.SINGLE_TABLE) // Le dice a Hibernate que toda la herencia va en una sola tabla
@DiscriminatorColumn(name = "Tipo_operacion", discriminatorType = DiscriminatorType.STRING) // Le dice que Tipo_operacion es la columna que funcionará como discriminador en los tipos de operaciones
public abstract class Operacion {
    @Id // Le dice a Hibernate que el codigo es la clave primaria
    private Integer codigo;

    @Id
    @ManyToOne
    @JoinColumn(name = "refCuentaOrigen") // Nombre de la clave foránea
    private Cuenta cuentaorigen;

    private String concepto;

    @Temporal(TemporalType.TIMESTAMP) // Guarda fecha y hora
    private Date fecha;
    private Double cantidad;
    
    public Operacion () {
        // JPA exige que haya un constructor vacío
    }

    // --- GETTERS Y SETTERS ---

    public Integer getCodigo() {
        return codigo;
    }

    public void setCodigo(Integer codigo) {
        this.codigo = codigo;
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

    public Double getCantidad() {
        return cantidad;
    }

    public void setCantidad(Double cantidad) {
        this.cantidad = cantidad;
    }

    public Cuenta getCuentaorigen() {
        return cuentaorigen;
    }

    public void setCuentaorigen(Cuenta cuentaorigen) {
        this.cuentaorigen = cuentaorigen;
    } 
}
