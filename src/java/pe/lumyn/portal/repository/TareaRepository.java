package pe.lumyn.portal.repository;

import pe.lumyn.portal.model.Tarea;
import java.util.List;

public interface TareaRepository {

    List<Tarea> listarTodas() throws Exception;

    List<Tarea> listarPorUsuario(int usuarioId) throws Exception;

    boolean registrar(Tarea tarea) throws Exception;

    boolean actualizarAvance(int tareaId, int avance, String estado) throws Exception;
}
