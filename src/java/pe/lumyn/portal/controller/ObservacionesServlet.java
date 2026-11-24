package pe.lumyn.portal.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import pe.lumyn.portal.repository.EntregableRepository;
import pe.lumyn.portal.repository.EntregableRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import java.io.IOException;

@WebServlet("/observaciones")
public class ObservacionesServlet extends HttpServlet {

    private final EntregableRepository entregableRepository = new EntregableRepositoryImpl();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }
        if (!PermisosUtil.esAdministrador(session)
                && !PermisosUtil.esGestor(session)
                && !PermisosUtil.esRevisor(session)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "No tienes permisos para ver observaciones.");
            return;
        }

        try {
            request.setAttribute("observaciones", entregableRepository.listarObservaciones());
            request.setAttribute("rolId", session.getAttribute("rolId"));
            request.setAttribute("nombreUsuario", session.getAttribute("nombreUsuario"));
            request.getRequestDispatcher("/WEB-INF/vistas/observaciones.jsp").forward(request, response);
        } catch (Exception e) {
            throw new ServletException("Error al cargar observaciones.", e);
        }
    }
}
