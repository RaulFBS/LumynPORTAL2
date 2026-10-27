
package pe.lumyn.portal.repository;

import pe.lumyn.portal.model.Venta;
import java.util.List;

public interface VentaRepository {

    List<Venta> listarTodas() throws Exception;

    Venta buscarPorId(int ventaId) throws Exception;

    boolean registrarDesdeSolped(
            int solpedId,
            Integer proyectoId
    ) throws Exception;
}
