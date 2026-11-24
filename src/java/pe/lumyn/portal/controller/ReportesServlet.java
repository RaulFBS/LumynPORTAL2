package pe.lumyn.portal.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import pe.lumyn.portal.observer.AuditoriaLogObserver;
import pe.lumyn.portal.observer.NotificacionComercialObserver;
import pe.lumyn.portal.repository.ReportesRepository;
import pe.lumyn.portal.repository.ReportesRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@WebServlet("/reportes")
public class ReportesServlet extends HttpServlet {

    private final ReportesRepository reportesRepository =
            new ReportesRepositoryImpl();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        HttpSession session = request.getSession(false);

        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }

        if (!PermisosUtil.esAdministrador(session)
                && !PermisosUtil.esGestor(session)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permisos para acceder al módulo de reportes."
            );
            return;
        }

        String fechaInicio = request.getParameter("fechaInicio");
        String fechaFin = request.getParameter("fechaFin");

        try {
            Map<String, Object> resumen =
                    reportesRepository.obtenerResumenGeneral();
            List<Map<String, Object>> reporteVentas =
                    reportesRepository.obtenerReporteVentas(fechaInicio, fechaFin);
            List<Map<String, Object>> reporteProyectos =
                    reportesRepository.obtenerReporteProyectos();
            List<Map<String, Object>> reporteClientes =
                    reportesRepository.obtenerReporteClientes();
            List<Map<String, Object>> reporteSolped =
                    reportesRepository.obtenerReporteSolped();
            List<Map<String, Object>> reporteUsuarios =
                    reportesRepository.obtenerReporteUsuarios();

            request.setAttribute("resumen", resumen);
            request.setAttribute("reporteVentas", reporteVentas);
            request.setAttribute("reporteProyectos", reporteProyectos);
            request.setAttribute("reporteClientes", reporteClientes);
            request.setAttribute("reporteSolped", reporteSolped);
            request.setAttribute("reporteUsuarios", reporteUsuarios);
            request.setAttribute("fechaInicio", fechaInicio != null ? fechaInicio : "");
            request.setAttribute("fechaFin", fechaFin != null ? fechaFin : "");
            request.setAttribute("rolId", session.getAttribute("rolId"));
            request.setAttribute("nombreUsuario", session.getAttribute("nombreUsuario"));
            request.setAttribute("alertasComerciales",
                    NotificacionComercialObserver.obtenerAlertasRecientes());
            request.setAttribute("historialEventos",
                    AuditoriaLogObserver.obtenerHistorialReciente());

            request.getRequestDispatcher("/WEB-INF/vistas/reportes.jsp")
                    .forward(request, response);

        } catch (Exception e) {
            throw new ServletException("Error al generar los reportes del portal.", e);
        }
    }
}
