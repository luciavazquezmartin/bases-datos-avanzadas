package es.unizar.bd2;

import java.io.Serializable;
import java.util.Objects;

public class OperacionId implements Serializable { // Reprensenta la clave primaria compuesta de Operacion
    
    private Integer codigo; // Coincide con el nombre del atributo @Id en Operacion
    private String cuentaorigen; // Coincide con el nombre del objeto Cuenta en Operacion, pero guarda su ID (IBAN que es String)

    public OperacionId() {}

    public OperacionId(Integer codigo, String cuentaorigen) {
        this.codigo = codigo;
        this.cuentaorigen = cuentaorigen;
    }

   // --- GETTERS Y SETTERS ---

    public Integer getCodigo() { 
        return codigo; 
    }

    public void setCodigo(Integer codigo) { 
        this.codigo = codigo;
    }

    public String getCuentaorigen() { 
        return cuentaorigen; 
    }
    
    public void setCuentaorigen(String cuentaorigen) { 
        this.cuentaorigen = cuentaorigen; 
    }

    // JPA exige equals y hashCode para comparar claves compuestas
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        OperacionId that = (OperacionId) o;
        return Objects.equals(codigo, that.codigo) && Objects.equals(cuentaorigen, that.cuentaorigen);
    }

    @Override
    public int hashCode() {
        return Objects.hash(codigo, cuentaorigen);
    }
}