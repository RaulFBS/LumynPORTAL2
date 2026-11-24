package pe.lumyn.portal.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import pe.lumyn.portal.repository.ReportesRepository;
import pe.lumyn.portal.repository.ReportesRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

/**
 * Servlet encargado de generar y descargar reportes en formato CSV desde el servidor.
 */
@WebServlet("/reportes/exportar")
public class ExportarReporteServlet extends HttpServlet {

    private final ReportesRepository reportesRepository =
            new ReportesRepositoryImpl();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }

        if (!PermisosUtil.esAdministrador(session)
                && !PermisosUtil.esGestor(session)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permisos para exportar reportes."
            );
            return;
        }

        String tipo = request.getParameter("tipo");
        if (tipo == null || tipo.isBlank()) {
            tipo = "ventas";
        }
        tipo = tipo.trim().toLowerCase();

        String fechaInicio = request.getParameter("fechaInicio");
        String fechaFin = request.getParameter("fechaFin");

        try {
            String[] headers;
            String[] keys;
            List<Map<String, Object>> filas;

            switch (tipo) {
                case "ventas" -> {
                    headers = new String[]{"ID", "SOLPED", "Cliente", "Proyecto", "Fecha", "Subtotal", "Impuesto", "Total", "Estado"};
                    keys = new String[]{"ventaId", "solpedId", "cliente", "proyecto", "fechaVenta", "subtotal", "impuesto", "total", "estado"};
                    filas = reportesRepository.obtenerReporteVentas(fechaInicio, fechaFin);
                }
                case "proyectos" -> {
                    headers = new String[]{"ID", "Proyecto", "Cliente", "Fecha Inicio", "Fecha Fin", "Estado"};
                    keys = new String[]{"proyectoId", "nombre", "cliente", "fechaInicio", "fechaFin", "estado"};
                    filas = reportesRepository.obtenerReporteProyectos();
                }
                case "clientes" -> {
                    headers = new String[]{"ID", "Cliente", "Documento", "Correo", "Telefono", "Estado", "Proyectos", "Total Ventas"};
                    keys = new String[]{"clienteId", "nombre", "documento", "correo", "telefono", "estado", "totalProyectos", "totalVentas"};
                    filas = reportesRepository.obtenerReporteClientes();
                }
                case "solped" -> {
                    headers = new String[]{"ID", "Cliente", "Proyecto", "Responsable", "Fecha", "Estado", "Monto Estimado"};
                    keys = new String[]{"solpedId", "cliente", "proyecto", "responsable", "fechaSolicitud", "estado", "montoEstimado"};
                    filas = reportesRepository.obtenerReporteSolped();
                }
                case "usuarios" -> {
                    headers = new String[]{"ID", "Nombres", "Apellidos", "Correo", "Rol ID", "Estado", "Intentos Fallidos"};
                    keys = new String[]{"id", "nombres", "apellidos", "correo", "rolId", "estado", "intentosFallidos"};
                    filas = reportesRepository.obtenerReporteUsuarios();
                }
                default -> {
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Tipo de reporte no soportado.");
                    return;
                }
            }

            response.setCharacterEncoding(StandardCharsets.UTF_8.name());
            response.setContentType("text/csv; charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment; filename=\"reporte_" + tipo + ".csv\"");
            response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

            PrintWriter writer = response.getWriter();
            // BOM UTF-8 para compatibilidad directa al abrir en Microsoft Excel.
            writer.write('\uFEFF');
            escribirFilaCsv(writer, headers);

            for (Map<String, Object> fila : filas) {
                String[] valores = new String[keys.length];
                for (int i = 0; i < keys.length; i++) {
                    Object val = fila.get(keys[i]);
                    valores[i] = val != null ? String.valueOf(val) : "";
                }
                escribirFilaCsv(writer, valores);
            }
            writer.flush();

        } catch (Exception e) {
            throw new ServletException("Error al exportar el reporte CSV.", e);
        }
    }

    private void escribirFilaCsv(PrintWriter writer, String[] columnas) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < columnas.length; i++) {
            if (i > 0) {
                sb.append(',');
            }
            String valor = columnas[i] != null ? columnas[i] : "";
            String escapado = valor.replace("\"", "\"\"");
            sb.append('"').append(escapado).append('"');
        }
        writer.println(sb);
    }
}
