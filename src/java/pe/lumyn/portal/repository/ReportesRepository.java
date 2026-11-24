package pe.lumyn.portal.repository;

import java.util.List;
import java.util.Map;

public interface ReportesRepository {

    Map<String, Object> obtenerResumenGeneral() throws Exception;

    List<Map<String, Object>> obtenerReporteVentas(
            String fechaInicio,
            String fechaFin) throws Exception;

    List<Map<String, Object>> obtenerReporteProyectos() throws Exception;

    List<Map<String, Object>> obtenerReporteClientes() throws Exception;

    List<Map<String, Object>> obtenerReporteSolped() throws Exception;

    List<Map<String, Object>> obtenerReporteUsuarios() throws Exception;
}
