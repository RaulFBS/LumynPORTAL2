package pe.lumyn.portal.repository;

import pe.lumyn.portal.model.Entregable;
import java.util.List;
import java.util.Map;

public interface EntregableRepository {

    List<Entregable> listarTodos() throws Exception;

    boolean registrar(Entregable entregable) throws Exception;

    boolean revisar(int entregableId, int usuarioId, String estado, String observacion) throws Exception;

    List<Map<String, Object>> listarObservaciones() throws Exception;
}
