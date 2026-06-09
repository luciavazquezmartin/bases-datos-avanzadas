package es.unizar.bd2;

import jakarta.persistence.*;

@Entity
@DiscriminatorValue("Efectivo") // Le dice a Hibernate: Si Tipo_operacion es "Efectivo", entonces es una operación de ingreso o retirada
public class OperacionEfectivo extends Operacion {
    
    @ManyToOne 
    @JoinColumn (name = "refOficina")
    private Oficina oficina;

    public OperacionEfectivo () {
        // JPA exige que haya un constructor vacío
    }

    // --- GETTERS Y SETTERS ---

    public Oficina getOficina() {
        return oficina;
    }

    public void setOficina(Oficina oficina) {
        this.oficina = oficina;
    }
}
