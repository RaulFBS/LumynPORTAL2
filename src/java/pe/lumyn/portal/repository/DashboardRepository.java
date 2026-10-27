
package pe.lumyn.portal.repository;

import java.util.List;
import java.util.Map;

public interface DashboardRepository {

    Map<String, Object> obtenerEstadisticas() throws Exception;

    List<Map<String, Object>> obtenerProyectosRecientes()
            throws Exception;

    List<Map<String, Object>> obtenerSolpedRecientes()
            throws Exception;

    List<Map<String, Object>> obtenerVentasRecientes()
            throws Exception;
}
