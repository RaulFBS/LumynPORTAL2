package pe.lumyn.portal.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import pe.lumyn.portal.model.Tarea;
import pe.lumyn.portal.observer.PortalEvent;
import pe.lumyn.portal.observer.PortalEventManager;
import pe.lumyn.portal.repository.ProyectoRepository;
import pe.lumyn.portal.repository.ProyectoRepositoryImpl;
import pe.lumyn.portal.repository.TareaRepository;
import pe.lumyn.portal.repository.TareaRepositoryImpl;
import pe.lumyn.portal.repository.UsuarioRepository;
import pe.lumyn.portal.repository.UsuarioRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import java.io.IOException;
import java.sql.Date;
import java.util.List;

@WebServlet("/tareas")
public class TareasServlet extends HttpServlet {

    private final TareaRepository tareaRepository = new TareaRepositoryImpl();
    private final ProyectoRepository proyectoRepository = new ProyectoRepositoryImpl();
    private final UsuarioRepository usuarioRepository = new UsuarioRepositoryImpl();

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
                && !PermisosUtil.esColaborador(session)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "No tienes permisos para ver tareas.");
            return;
        }

        try {
            int usuarioId = ((Number) session.getAttribute("usuarioId")).intValue();
            List<Tarea> tareas = PermisosUtil.esColaborador(session)
                    ? tareaRepository.listarPorUsuario(usuarioId)
                    : tareaRepository.listarTodas();

            request.setAttribute("tareas", tareas);
            request.setAttribute("proyectos", proyectoRepository.listarTodos());
            request.setAttribute("usuarios", usuarioRepository.listarTodos());
            request.setAttribute("rolId", session.getAttribute("rolId"));
            request.setAttribute("nombreUsuario", session.getAttribute("nombreUsuario"));
            request.getRequestDispatcher("/WEB-INF/vistas/tareas.jsp").forward(request, response);
        } catch (Exception e) {
            throw new ServletException("Error al cargar las tareas.", e);
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

        int usuarioSesionId = ((Number) session.getAttribute("usuarioId")).intValue();
        String accion = request.getParameter("accion");

        try {
            if ("crear".equals(accion)) {
                if (!PermisosUtil.esAdministrador(session) && !PermisosUtil.esGestor(session)) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "No tienes permisos para crear tareas.");
                    return;
                }
                Tarea t = new Tarea();
                t.setProyectoId(Integer.parseInt(request.getParameter("proyectoId")));
                String respParam = request.getParameter("usuarioId");
                if (respParam != null && !respParam.isBlank()) {
                    t.setUsuarioId(Integer.parseInt(respParam));
                }
                t.setTitulo(request.getParameter("titulo"));
                t.setDescripcion(request.getParameter("descripcion"));
                t.setPrioridad(request.getParameter("prioridad"));
                String fechaLim = request.getParameter("fechaLimite");
                if (fechaLim != null && !fechaLim.isBlank()) {
                    t.setFechaLimite(Date.valueOf(fechaLim));
                }
                t.setAvance(0);
                t.setEstado("pendiente");

                tareaRepository.registrar(t);
                PortalEventManager.getInstancia().notificar(new PortalEvent(
                        "TAREA_CREADA", t.getProyectoId(), usuarioSesionId,
                        "Nueva tarea: " + t.getTitulo()
                ));
                response.sendRedirect(request.getContextPath() + "/tareas?resultado=creada");
                return;
            }

            if ("actualizarAvance".equals(accion)) {
                int tareaId = Integer.parseInt(request.getParameter("tareaId"));
                int avance = Integer.parseInt(request.getParameter("avance"));
                String estado = request.getParameter("estado");
                tareaRepository.actualizarAvance(tareaId, avance, estado);
                PortalEventManager.getInstancia().notificar(new PortalEvent(
                        "TAREA_ACTUALIZADA", tareaId, usuarioSesionId,
                        "Avance actualizado a " + avance + "% (" + estado + ")"
                ));
                response.sendRedirect(request.getContextPath() + "/tareas?resultado=actualizada");
                return;
            }

            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Acción no válida.");
        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (Exception e) {
            throw new ServletException("Error al procesar la tarea.", e);
        }
    }
}
