package es.unizar.bd2;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class OperacionId implements Serializable {

   @Column(name = "CODIGO", precision = 8, nullable = false)
   private Integer codigo;

   @Column(name = "CUENTA_ORIGEN", length = 24, nullable = false)
   private String cuentaOrigen;

   public OperacionId() {
   }

   public OperacionId(Integer codigo, String cuentaOrigen) {
      this.codigo = codigo;
      this.cuentaOrigen = cuentaOrigen;
   }

   public Integer getCodigo() {
      return codigo;
   }

   public void setCodigo(Integer codigo) {
      this.codigo = codigo;
   }

   public String getCuentaOrigen() {
      return cuentaOrigen;
   }

   public void setCuentaOrigen(String cuentaOrigen) {
      this.cuentaOrigen = cuentaOrigen;
   }

   @Override
   public boolean equals(Object o) {
      if (this == o)
         return true;
      if (!(o instanceof OperacionId that))
         return false;
      return Objects.equals(codigo, that.codigo)
            && Objects.equals(cuentaOrigen, that.cuentaOrigen);
   }

   @Override
   public int hashCode() {
      return Objects.hash(codigo, cuentaOrigen);
   }
}