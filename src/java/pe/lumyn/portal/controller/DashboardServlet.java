package pe.lumyn.portal.controller;

import java.io.IOException;
import java.util.List;
import java.util.Map;

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

    @Override
    public void init() throws ServletException {
        dashboardRepository = new DashboardRepositoryImpl();
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
            List<Map<String, Object>> solpedRecientes
                    = dashboardRepository.obtenerSolpedRecientes();

            List<Map<String, Object>> ventasRecientes
                    = dashboardRepository.obtenerVentasRecientes();
            Map<String, Object> estadisticas
                    = dashboardRepository.obtenerEstadisticas();

            List<Map<String, Object>> proyectos
                    = dashboardRepository.obtenerProyectosRecientes();
            request.setAttribute("solpedRecientes", solpedRecientes);
            request.setAttribute("ventasRecientes", ventasRecientes);
            request.setAttribute("nombreUsuario", nombreUsuario);
            request.setAttribute("nombreRol", nombreRol);
            request.setAttribute("rolId", rolId);
            request.setAttribute("estadisticas", estadisticas);
            request.setAttribute("proyectos", proyectos);

            request.getRequestDispatcher(
                    "/WEB-INF/vistas/dashboard.jsp"
            ).forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                    "Error al cargar los datos del Dashboard.", e);
        }
    }
}
