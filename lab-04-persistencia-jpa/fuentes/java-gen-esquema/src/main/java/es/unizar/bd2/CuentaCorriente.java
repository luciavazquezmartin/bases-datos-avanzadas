package es.unizar.bd2;

import jakarta.persistence.*;

@Entity
@DiscriminatorValue("0") // Le dice a Hibernate: Si Es_ahorro vale '0', entonces es una cuenta corriente
public class CuentaCorriente extends Cuenta {
    
    @ManyToOne 
    @JoinColumn(name = "refOficina") // Nombre de la clave foránea
    private Oficina oficina;

    public CuentaCorriente () {
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
