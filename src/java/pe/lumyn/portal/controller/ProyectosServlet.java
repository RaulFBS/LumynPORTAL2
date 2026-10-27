
package pe.lumyn.portal.controller;

import java.io.IOException;
import java.sql.Date;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import pe.lumyn.portal.model.Proyecto;
import pe.lumyn.portal.model.Cliente;
import pe.lumyn.portal.repository.ProyectoRepository;
import pe.lumyn.portal.repository.ProyectoRepositoryImpl;
import pe.lumyn.portal.repository.ClienteRepository;
import pe.lumyn.portal.repository.ClienteRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

@WebServlet("/proyectos")
public class ProyectosServlet extends HttpServlet {

    private final ProyectoRepository proyectoRepository =
            new ProyectoRepositoryImpl();

    private final ClienteRepository clienteRepository =
            new ClienteRepositoryImpl();

    private boolean tienePermiso(HttpSession session) {
        return PermisosUtil.tieneRol(session, 1)
                || PermisosUtil.tieneRol(session, 2);
    }

    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control",
                "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        HttpSession session = request.getSession(false);

        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(
                    request.getContextPath() + "/login.html");
            return;
        }

        if (!tienePermiso(session)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permiso para gestionar proyectos.");
            return;
        }

        try {
            List<Proyecto> proyectos =
                    proyectoRepository.listarTodos();

            List<Cliente> clientes =
                    clienteRepository.listarTodos();

            request.setAttribute("proyectos", proyectos);
            request.setAttribute("clientes", clientes);
            request.setAttribute("totalProyectos", proyectos.size());

            request.getRequestDispatcher(
                    "/WEB-INF/vistas/proyectos.jsp")
                    .forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                    "Error al cargar los proyectos.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(
                    request.getContextPath() + "/login.html");
            return;
        }

        if (!tienePermiso(session)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permiso para gestionar proyectos.");
            return;
        }

        String accion = request.getParameter("accion");

        try {
            if ("guardar".equals(accion)) {
                guardarProyecto(request);

            } else if ("actualizar".equals(accion)) {
                actualizarProyecto(request);

            } else if ("cambiarEstado".equals(accion)) {
                cambiarEstado(request);

            } else {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "Acción no válida.");
                return;
            }

            response.sendRedirect(
                    request.getContextPath()
                    + "/proyectos?resultado=ok");

        } catch (IllegalArgumentException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    e.getMessage());

        } catch (Exception e) {
            throw new ServletException(
                    "Error al procesar el proyecto.", e);
        }
    }

    private void guardarProyecto(HttpServletRequest request)
            throws Exception {

        Proyecto proyecto = obtenerProyectoDesdeFormulario(request);

        proyectoRepository.guardar(proyecto);
    }

    private void actualizarProyecto(HttpServletRequest request)
            throws Exception {

        int proyectoId = Integer.parseInt(
                request.getParameter("proyectoId"));

        Proyecto proyecto = obtenerProyectoDesdeFormulario(request);
        proyecto.setProyectoId(proyectoId);

        if (proyectoRepository.buscarPorId(proyectoId) == null) {
            throw new IllegalArgumentException(
                    "El proyecto indicado no existe.");
        }

        proyectoRepository.actualizar(proyecto);
    }

    private void cambiarEstado(HttpServletRequest request)
            throws Exception {

        int proyectoId = Integer.parseInt(
                request.getParameter("proyectoId"));

        String estado = request.getParameter("estado");

        validarEstado(estado);

        if (proyectoRepository.buscarPorId(proyectoId) == null) {
            throw new IllegalArgumentException(
                    "El proyecto indicado no existe.");
        }

        proyectoRepository.cambiarEstado(proyectoId, estado);
    }

    private Proyecto obtenerProyectoDesdeFormulario(
            HttpServletRequest request) {

        String clienteTexto = request.getParameter("clienteId");
        String nombre = request.getParameter("nombre");
        String descripcion = request.getParameter("descripcion");
        String inicioTexto = request.getParameter("fechaInicio");
        String finTexto = request.getParameter("fechaFin");
        String estado = request.getParameter("estado");

        if (clienteTexto == null || clienteTexto.isBlank()
                || nombre == null || nombre.isBlank()
                || inicioTexto == null || inicioTexto.isBlank()) {
            throw new IllegalArgumentException(
                    "Completa el cliente, el nombre y la fecha de inicio.");
        }

        try {
            int clienteId = Integer.parseInt(clienteTexto.trim());

            Date fechaInicio = Date.valueOf(inicioTexto);
            Date fechaFin = (finTexto == null || finTexto.isBlank())
                    ? null : Date.valueOf(finTexto);

            if (fechaFin != null && fechaFin.before(fechaInicio)) {
                throw new IllegalArgumentException(
                        "La fecha de fin no puede ser anterior "
                        + "a la fecha de inicio.");
            }

            if (nombre.trim().length() > 150) {
                throw new IllegalArgumentException(
                        "El nombre no puede superar los 150 caracteres.");
            }

            validarEstado(estado);

            Proyecto proyecto = new Proyecto();
            proyecto.setClienteId(clienteId);
            proyecto.setNombre(nombre.trim());
            proyecto.setDescripcion(
                    descripcion == null || descripcion.isBlank()
                    ? null : descripcion.trim());
            proyecto.setFechaInicio(fechaInicio);
            proyecto.setFechaFin(fechaFin);
            proyecto.setEstado(estado);

            return proyecto;

        } catch (IllegalArgumentException e) {
            if (e.getMessage() != null
                    && (e.getMessage().startsWith("Completa")
                    || e.getMessage().startsWith("La fecha")
                    || e.getMessage().startsWith("El nombre")
                    || e.getMessage().startsWith("Estado"))) {
                throw e;
            }

            throw new IllegalArgumentException(
                    "Revisa el cliente y el formato de las fechas.");
        }
    }

    private void validarEstado(String estado) {
        if (estado == null
                || !(estado.equals("planificado")
                || estado.equals("en_progreso")
                || estado.equals("completado")
                || estado.equals("cancelado"))) {

            throw new IllegalArgumentException(
                    "Estado no válido.");
        }
    }
}
