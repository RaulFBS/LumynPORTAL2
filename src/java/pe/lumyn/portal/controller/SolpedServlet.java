
package pe.lumyn.portal.controller;

import pe.lumyn.portal.model.Cliente;
import pe.lumyn.portal.model.Proyecto;
import pe.lumyn.portal.model.Solped;
import pe.lumyn.portal.model.SolpedDetalle;
import pe.lumyn.portal.repository.ClienteRepository;
import pe.lumyn.portal.repository.ClienteRepositoryImpl;
import pe.lumyn.portal.repository.ProyectoRepository;
import pe.lumyn.portal.repository.ProyectoRepositoryImpl;
import pe.lumyn.portal.repository.SolpedRepository;
import pe.lumyn.portal.repository.SolpedRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/solped")
public class SolpedServlet extends HttpServlet {

    private final SolpedRepository solpedRepository =
            new SolpedRepositoryImpl();

    private final ClienteRepository clienteRepository =
            new ClienteRepositoryImpl();

    private final ProyectoRepository proyectoRepository =
            new ProyectoRepositoryImpl();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(
                    request.getContextPath() + "/login.html"
            );
            return;
        }

        if (!PermisosUtil.puedeGestionarSolped(session)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permisos para acceder a las solicitudes SOLPED."
            );
            return;
        }

        try {
            String accion = request.getParameter("accion");

            if ("nueva".equals(accion)) {
                prepararFormulario(request, response);
                return;
            }

            String idParam = request.getParameter("id");

            if (idParam != null && !idParam.isBlank()) {
                int solpedId = Integer.parseInt(idParam);
                Solped solped =
                        solpedRepository.buscarPorId(solpedId);

                if (solped == null) {
                    response.sendError(
                            HttpServletResponse.SC_NOT_FOUND,
                            "No se encontró la solicitud SOLPED."
                    );
                    return;
                }

                request.setAttribute("solpedSeleccionada", solped);
            }

            List<Solped> solicitudes =
                    solpedRepository.listarTodas();

            request.setAttribute("solpedLista", solicitudes);

            request.getRequestDispatcher(
                    "/WEB-INF/vistas/solped.jsp"
            ).forward(request, response);

        } catch (NumberFormatException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "El identificador proporcionado no es válido."
            );
        } catch (IllegalArgumentException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    e.getMessage()
            );
        } catch (Exception e) {
            throw new ServletException(
                    "Error al consultar las solicitudes SOLPED.", e
            );
        }
    }

    private void prepararFormulario(
            HttpServletRequest request,
            HttpServletResponse response)
            throws Exception {

        List<Cliente> clientes = clienteRepository.listarTodos();
        request.setAttribute("clientes", clientes);

        String proyectoParam = request.getParameter("proyectoId");

        if (proyectoParam != null && !proyectoParam.isBlank()) {
            int proyectoId = Integer.parseInt(proyectoParam);

            if (proyectoId <= 0) {
                throw new IllegalArgumentException(
                        "El proyecto seleccionado no es válido."
                );
            }

            Proyecto proyecto =
                    proyectoRepository.buscarPorId(proyectoId);

            if (proyecto == null) {
                response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "No se encontró el proyecto seleccionado."
                );
                return;
            }

            request.setAttribute("proyectoSeleccionado", proyecto);
            request.setAttribute(
                    "clienteSeleccionadoId",
                    proyecto.getClienteId()
            );
        }

        request.getRequestDispatcher(
                "/WEB-INF/vistas/nueva-solped.jsp"
        ).forward(request, response);
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(
                    request.getContextPath() + "/login.html"
            );
            return;
        }

        if (!PermisosUtil.puedeGestionarSolped(session)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permisos para modificar solicitudes SOLPED."
            );
            return;
        }

        String accion = request.getParameter("accion");

        try {
            if ("crear".equals(accion)) {
                crearSolped(request, response, session);
                return;
            }

            if ("cambiarEstado".equals(accion)) {
                cambiarEstado(request, response);
                return;
            }

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "La acción solicitada no es válida."
            );

        } catch (NumberFormatException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Uno de los identificadores o valores numéricos no es válido."
            );
        } catch (IllegalArgumentException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    e.getMessage()
            );
        } catch (Exception e) {
            throw new ServletException(
                    "Error al procesar la solicitud SOLPED.", e
            );
        }
    }

    private void crearSolped(
            HttpServletRequest request,
            HttpServletResponse response,
            HttpSession session)
            throws Exception {

        String clienteParam = request.getParameter("clienteId");
        String proyectoParam = request.getParameter("proyectoId");
        String descripcion =
                request.getParameter("descripcionRequerimiento");

        if (clienteParam == null || clienteParam.isBlank()) {
            throw new IllegalArgumentException(
                    "Debes seleccionar un cliente."
            );
        }

        int clienteId = Integer.parseInt(clienteParam);

        Solped solped = new Solped();
        solped.setClienteId(clienteId);
        solped.setDescripcionRequerimiento(descripcion);

        Object usuarioSesion = session.getAttribute("usuarioId");

        if (!(usuarioSesion instanceof Number)) {
            response.sendError(
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "No se pudo identificar al usuario de la sesión."
            );
            return;
        }

        solped.setUsuarioId(((Number) usuarioSesion).intValue());

        if (proyectoParam != null && !proyectoParam.isBlank()) {
            int proyectoId = Integer.parseInt(proyectoParam);

            Proyecto proyecto =
                    proyectoRepository.buscarPorId(proyectoId);

            if (proyecto == null) {
                throw new IllegalArgumentException(
                        "El proyecto seleccionado no existe."
                );
            }

            if (proyecto.getClienteId() != clienteId) {
                throw new IllegalArgumentException(
                        "El proyecto no pertenece al cliente seleccionado."
                );
            }

            solped.setProyectoId(proyectoId);
        }

        String[] servicios = request.getParameterValues("servicio[]");
        String[] descripciones =
                request.getParameterValues("detalleDescripcion[]");
        String[] cantidades = request.getParameterValues("cantidad[]");
        String[] precios =
                request.getParameterValues("precioUnitario[]");

        if (servicios == null || cantidades == null || precios == null
                || servicios.length == 0
                || servicios.length != cantidades.length
                || servicios.length != precios.length
                || (descripciones != null
                    && descripciones.length != servicios.length)) {

            throw new IllegalArgumentException(
                    "Los detalles de la cotización están incompletos."
            );
        }

        List<SolpedDetalle> detalles = new ArrayList<>();

        for (int i = 0; i < servicios.length; i++) {
            SolpedDetalle detalle = new SolpedDetalle();

            detalle.setServicio(servicios[i]);
            detalle.setDescripcion(
                    descripciones == null ? null : descripciones[i]
            );

            detalle.setCantidad(
                    new BigDecimal(cantidades[i].trim())
            );

            detalle.setPrecioUnitario(
                    new BigDecimal(precios[i].trim())
            );

            detalles.add(detalle);
        }

        solped.setDetalles(detalles);

        int solpedId = solpedRepository.registrar(solped);

        response.sendRedirect(
                request.getContextPath()
                + "/solped?resultado=creada&id=" + solpedId
        );
    }

    private void cambiarEstado(
            HttpServletRequest request,
            HttpServletResponse response)
            throws Exception {

        String idParam = request.getParameter("solpedId");
        String estado = request.getParameter("estado");

        if (idParam == null || idParam.isBlank() || estado == null) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Faltan los datos para actualizar la SOLPED."
            );
            return;
        }

        int solpedId = Integer.parseInt(idParam);

        boolean actualizado =
                solpedRepository.cambiarEstado(solpedId, estado);

        String resultado = actualizado
                ? estado
                : "sin_cambios";

        response.sendRedirect(
                request.getContextPath()
                + "/solped?resultado=" + resultado
        );
    }
}
