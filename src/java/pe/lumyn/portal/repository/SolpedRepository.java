

package pe.lumyn.portal.repository;

import pe.lumyn.portal.model.Solped;
import java.util.List;

public interface SolpedRepository {

    List<Solped> listarTodas() throws Exception;

    Solped buscarPorId(int solpedId) throws Exception;

    boolean cambiarEstado(int solpedId, String estado) throws Exception;

    int registrar(Solped solped) throws Exception;
}
