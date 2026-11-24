package pe.lumyn.portal.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import pe.lumyn.portal.observer.AuditoriaLogObserver;
import pe.lumyn.portal.observer.NotificacionComercialObserver;
import pe.lumyn.portal.security.PermisosUtil;

import java.io.IOException;

@WebServlet("/notificaciones")
public class NotificacionesServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }

        request.setAttribute("alertasComerciales", NotificacionComercialObserver.obtenerAlertasRecientes());
        request.setAttribute("historialEventos", AuditoriaLogObserver.obtenerHistorialReciente());
        request.setAttribute("rolId", session.getAttribute("rolId"));
        request.setAttribute("nombreUsuario", session.getAttribute("nombreUsuario"));
        request.getRequestDispatcher("/WEB-INF/vistas/notificaciones.jsp").forward(request, response);
    }
}
