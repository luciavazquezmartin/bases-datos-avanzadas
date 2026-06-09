package es.unizar.bd2;

import jakarta.persistence.*;

@Entity
@DiscriminatorValue("Transferencia") // Le dice a Hibernate: Si Tipo_operacion es "Transferencia", entonces es una operación de transferencia
public class OperacionTransferencia extends Operacion {
    
    @ManyToOne 
    @JoinColumn (name = "refCuentaDestino")
    private Cuenta cuentadestino;

    public OperacionTransferencia () {
        // JPA exige que haya un constructor vacío
    }

    // --- GETTERS Y SETTERS ---

    public Cuenta getCuentadestino() {
        return cuentadestino;
    }

    public void setCuentadestino(Cuenta cuentadestino) {
        this.cuentadestino = cuentadestino;
    }
}
