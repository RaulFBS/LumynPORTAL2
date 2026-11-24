package pe.lumyn.portal.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import pe.lumyn.portal.model.Entregable;
import pe.lumyn.portal.observer.PortalEvent;
import pe.lumyn.portal.observer.PortalEventManager;
import pe.lumyn.portal.repository.EntregableRepository;
import pe.lumyn.portal.repository.EntregableRepositoryImpl;
import pe.lumyn.portal.repository.ProyectoRepository;
import pe.lumyn.portal.repository.ProyectoRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import java.io.IOException;

@WebServlet("/entregables")
public class EntregablesServlet extends HttpServlet {

    private final EntregableRepository entregableRepository = new EntregableRepositoryImpl();
    private final ProyectoRepository proyectoRepository = new ProyectoRepositoryImpl();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }

        try {
            request.setAttribute("entregables", entregableRepository.listarTodos());
            request.setAttribute("proyectos", proyectoRepository.listarTodos());
            request.setAttribute("rolId", session.getAttribute("rolId"));
            request.setAttribute("nombreUsuario", session.getAttribute("nombreUsuario"));
            request.getRequestDispatcher("/WEB-INF/vistas/entregables.jsp").forward(request, response);
        } catch (Exception e) {
            throw new ServletException("Error al cargar los entregables.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession(false);
        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }

        int usuarioId = ((Number) session.getAttribute("usuarioId")).intValue();
        String accion = request.getParameter("accion");

        try {
            if ("crear".equals(accion)) {
                Entregable ent = new Entregable();
                ent.setProyectoId(Integer.parseInt(request.getParameter("proyectoId")));
                ent.setUsuarioId(usuarioId);
                ent.setTitulo(request.getParameter("titulo"));
                ent.setDescripcion(request.getParameter("descripcion"));
                ent.setVersion(request.getParameter("version"));
                ent.setUrlArchivo(request.getParameter("urlArchivo"));
                entregableRepository.registrar(ent);

                PortalEventManager.getInstancia().notificar(new PortalEvent(
                        "ENTREGABLE_CREADO", ent.getProyectoId(), usuarioId,
                        "Entregable registrado: " + ent.getTitulo()
                ));
                response.sendRedirect(request.getContextPath() + "/entregables?resultado=creado");
                return;
            }

            if ("revisar".equals(accion)) {
                if (!PermisosUtil.esAdministrador(session)
                        && !PermisosUtil.esGestor(session)
                        && !PermisosUtil.esRevisor(session)) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "No tienes permisos para revisar entregables.");
                    return;
                }
                int entregableId = Integer.parseInt(request.getParameter("entregableId"));
                String estado = request.getParameter("estado");
                String observacion = request.getParameter("observacion");
                entregableRepository.revisar(entregableId, usuarioId, estado, observacion);

                PortalEventManager.getInstancia().notificar(new PortalEvent(
                        "ENTREGABLE_" + estado.toUpperCase(), entregableId, usuarioId,
                        "Revisión de entregable: " + estado
                ));
                response.sendRedirect(request.getContextPath() + "/entregables?resultado=" + estado);
                return;
            }

            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Acción no válida.");
        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (Exception e) {
            throw new ServletException("Error al procesar el entregable.", e);
        }
    }
}
