
package pe.lumyn.portal.repository;

import java.util.List;
import pe.lumyn.portal.model.Proyecto;

public interface ProyectoRepository {

    List<Proyecto> listarTodos() throws Exception;

    Proyecto buscarPorId(int proyectoId) throws Exception;

    boolean guardar(Proyecto proyecto) throws Exception;

    boolean actualizar(Proyecto proyecto) throws Exception;

    boolean cambiarEstado(int proyectoId, String estado)
            throws Exception;
}
