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
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@WebServlet("/reportes")
public class ReportesServlet extends HttpServlet {

    private final ReportesRepository reportesRepository =
            new ReportesRepositoryImpl();

    private ExecutorService queryExecutor;

    @Override
    public void init() throws ServletException {
        queryExecutor = Executors.newFixedThreadPool(6, runnable -> {
            Thread t = new Thread(runnable, "lumyn-reportes-query");
            t.setDaemon(true);
            return t;
        });
    }

    @Override
    public void destroy() {
        if (queryExecutor != null) {
            queryExecutor.shutdownNow();
        }
    }

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
            CompletableFuture<Map<String, Object>> fResumen =
                    CompletableFuture.supplyAsync(() -> {
                        try {
                            return reportesRepository.obtenerResumenGeneral();
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }, queryExecutor);

            CompletableFuture<List<Map<String, Object>>> fVentas =
                    CompletableFuture.supplyAsync(() -> {
                        try {
                            return reportesRepository.obtenerReporteVentas(fechaInicio, fechaFin);
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }, queryExecutor);

            CompletableFuture<List<Map<String, Object>>> fProyectos =
                    CompletableFuture.supplyAsync(() -> {
                        try {
                            return reportesRepository.obtenerReporteProyectos();
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }, queryExecutor);

            CompletableFuture<List<Map<String, Object>>> fClientes =
                    CompletableFuture.supplyAsync(() -> {
                        try {
                            return reportesRepository.obtenerReporteClientes();
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }, queryExecutor);

            CompletableFuture<List<Map<String, Object>>> fSolped =
                    CompletableFuture.supplyAsync(() -> {
                        try {
                            return reportesRepository.obtenerReporteSolped();
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }, queryExecutor);

            CompletableFuture<List<Map<String, Object>>> fUsuarios =
                    CompletableFuture.supplyAsync(() -> {
                        try {
                            return reportesRepository.obtenerReporteUsuarios();
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }, queryExecutor);

            CompletableFuture.allOf(fResumen, fVentas, fProyectos, fClientes, fSolped, fUsuarios).join();

            request.setAttribute("resumen", fResumen.join());
            request.setAttribute("reporteVentas", fVentas.join());
            request.setAttribute("reporteProyectos", fProyectos.join());
            request.setAttribute("reporteClientes", fClientes.join());
            request.setAttribute("reporteSolped", fSolped.join());
            request.setAttribute("reporteUsuarios", fUsuarios.join());
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
