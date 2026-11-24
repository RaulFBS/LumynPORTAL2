package pe.lumyn.portal.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import pe.lumyn.portal.observer.AuditoriaLogObserver;
import pe.lumyn.portal.observer.PortalEvent;
import pe.lumyn.portal.observer.PortalEventManager;
import pe.lumyn.portal.repository.UsuarioRepository;
import pe.lumyn.portal.repository.UsuarioRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import java.io.IOException;

@WebServlet("/seguridad")
public class SeguridadServlet extends HttpServlet {

    private final UsuarioRepository usuarioRepository = new UsuarioRepositoryImpl();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }
        if (!PermisosUtil.esAdministrador(session)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Solo el administrador puede ver seguridad.");
            return;
        }

        try {
            request.setAttribute("usuarios", usuarioRepository.listarTodos());
            request.setAttribute("historialEventos", AuditoriaLogObserver.obtenerHistorialReciente());
            request.setAttribute("rolId", session.getAttribute("rolId"));
            request.setAttribute("nombreUsuario", session.getAttribute("nombreUsuario"));
            request.getRequestDispatcher("/WEB-INF/vistas/seguridad.jsp").forward(request, response);
        } catch (Exception e) {
            throw new ServletException("Error al cargar el módulo de seguridad.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (!PermisosUtil.tieneSesion(session) || !PermisosUtil.esAdministrador(session)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Acceso denegado.");
            return;
        }

        try {
            if ("desbloquear".equals(request.getParameter("accion"))) {
                int idObjetivo = Integer.parseInt(request.getParameter("usuarioId"));
                int adminId = ((Number) session.getAttribute("usuarioId")).intValue();
                usuarioRepository.reiniciarIntentos(idObjetivo);
                PortalEventManager.getInstancia().notificar(new PortalEvent(
                        "SEGURIDAD_DESBLOQUEO", idObjetivo, adminId,
                        "Cuenta desbloqueada manualmente por administrador"
                ));
                response.sendRedirect(request.getContextPath() + "/seguridad?resultado=desbloqueado");
                return;
            }
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Acción no válida.");
        } catch (Exception e) {
            throw new ServletException("Error al procesar acción de seguridad.", e);
        }
    }
}
