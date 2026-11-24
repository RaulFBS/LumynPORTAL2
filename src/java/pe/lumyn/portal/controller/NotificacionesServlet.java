package pe.lumyn.portal.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import pe.lumyn.portal.observer.AuditoriaLogObserver;
import pe.lumyn.portal.observer.NotificacionComercialObserver;
import pe.lumyn.portal.observer.PortalEvent;
import pe.lumyn.portal.observer.PortalEventManager;
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

        PortalEventManager.getInstancia();
        request.setAttribute("alertasComerciales", NotificacionComercialObserver.obtenerAlertasRecientes());
        request.setAttribute("historialEventos", AuditoriaLogObserver.obtenerHistorialReciente());
        request.setAttribute("rolId", session.getAttribute("rolId"));
        request.setAttribute("nombreUsuario", session.getAttribute("nombreUsuario"));
        request.getRequestDispatcher("/WEB-INF/vistas/notificaciones.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }

        Integer usuarioId = session.getAttribute("usuarioId") instanceof Number
                ? ((Number) session.getAttribute("usuarioId")).intValue() : null;
        PortalEventManager.getInstancia().notificar(new PortalEvent(
                "SOLPED_ACTUALIZADA",
                15,
                usuarioId,
                "Notificación de prueba emitida desde el Centro de Notificaciones."
        ));
        response.sendRedirect(request.getContextPath() + "/notificaciones");
    }
}
