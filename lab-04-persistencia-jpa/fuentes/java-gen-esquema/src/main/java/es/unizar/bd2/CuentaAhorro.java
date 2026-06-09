package es.unizar.bd2;

import jakarta.persistence.*;

@Entity
@DiscriminatorValue("1") // Le dice a Hibernate: Si Es_ahorro vale '1', entonces es una cuenta ahorro
public class CuentaAhorro extends Cuenta {
    @Column (name = "Tipo_interes")
    private Double tipointeres;

    public CuentaAhorro () {
        // JPA exige que haya un constructor vacío
    }

    // --- GETTERS Y SETTERS ---

    public Double getTipointeres() {
        return tipointeres;
    }

    public void setTipointeres(Double tipointeres) {
        this.tipointeres = tipointeres;
    }
}
