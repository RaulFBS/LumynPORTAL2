package pe.lumyn.portal.controller;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import pe.lumyn.portal.repository.DashboardRepository;
import pe.lumyn.portal.repository.DashboardRepositoryImpl;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    private DashboardRepository dashboardRepository;
    private ExecutorService queryExecutor;

    @Override
    public void init() throws ServletException {
        dashboardRepository = new DashboardRepositoryImpl();
        queryExecutor = Executors.newFixedThreadPool(4, runnable -> {
            Thread t = new Thread(runnable, "lumyn-dashboard-query");
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

        HttpSession session = request.getSession(false);

        // Comprobar que el usuario haya iniciado sesión.
        if (session == null
                || session.getAttribute("usuarioId") == null) {

            response.sendRedirect(
                    request.getContextPath() + "/login");
            return;
        }

        // Obtener el rol de la sesión.
        Object rolSesion = session.getAttribute("rolId");

        if (rolSesion == null) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        int rolId;

        try {
            rolId = Integer.parseInt(rolSesion.toString());
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        if (rolId < 1 || rolId > 4) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        String nombreUsuario
                = String.valueOf(
                        session.getAttribute("nombreUsuario") != null
                        ? session.getAttribute("nombreUsuario")
                        : "Usuario"
                );

        String nombreRol;

        switch (rolId) {
            case 1:
                nombreRol = "Administrador";
                break;
            case 2:
                nombreRol = "Gestor de proyectos";
                break;
            case 3:
                nombreRol = "Colaborador";
                break;
            case 4:
                nombreRol = "Revisor";
                break;
            default:
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
        }

        try {
            CompletableFuture<List<Map<String, Object>>> fSolped =
                    CompletableFuture.supplyAsync(() -> {
                        try {
                            return dashboardRepository.obtenerSolpedRecientes();
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }, queryExecutor);

            CompletableFuture<List<Map<String, Object>>> fVentas =
                    CompletableFuture.supplyAsync(() -> {
                        try {
                            return dashboardRepository.obtenerVentasRecientes();
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }, queryExecutor);

            CompletableFuture<Map<String, Object>> fStats =
                    CompletableFuture.supplyAsync(() -> {
                        try {
                            return dashboardRepository.obtenerEstadisticas();
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }, queryExecutor);

            CompletableFuture<List<Map<String, Object>>> fProyectos =
                    CompletableFuture.supplyAsync(() -> {
                        try {
                            return dashboardRepository.obtenerProyectosRecientes();
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }, queryExecutor);

            CompletableFuture.allOf(fSolped, fVentas, fStats, fProyectos).join();

            request.setAttribute("solpedRecientes", fSolped.join());
            request.setAttribute("ventasRecientes", fVentas.join());
            request.setAttribute("nombreUsuario", nombreUsuario);
            request.setAttribute("nombreRol", nombreRol);
            request.setAttribute("rolId", rolId);
            request.setAttribute("estadisticas", fStats.join());
            request.setAttribute("proyectos", fProyectos.join());

            request.getRequestDispatcher(
                    "/WEB-INF/vistas/dashboard.jsp"
            ).forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                    "Error al cargar los datos del Dashboard.", e);
        }
    }
}
