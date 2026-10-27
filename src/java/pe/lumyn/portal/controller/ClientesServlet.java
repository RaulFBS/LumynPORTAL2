
package pe.lumyn.portal.controller;

import pe.lumyn.portal.model.Cliente;
import pe.lumyn.portal.repository.ClienteRepository;
import pe.lumyn.portal.repository.ClienteRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import java.io.IOException;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/clientes")
public class ClientesServlet extends HttpServlet {

    private final ClienteRepository clienteRepository =
            new ClienteRepositoryImpl();

    private boolean tienePermisoGestionarClientes(
            HttpSession session) {

        return PermisosUtil.tieneRol(session, 1)
                || PermisosUtil.tieneRol(session, 2);
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader(
                "Cache-Control",
                "no-cache, no-store, must-revalidate"
        );
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        HttpSession session = request.getSession(false);

        // Verificar que el usuario haya iniciado sesión.
        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(
                    request.getContextPath() + "/login.html"
            );
            return;
        }

        // Solo administrador y gestor pueden gestionar clientes.
        if (!tienePermisoGestionarClientes(session)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permisos para gestionar clientes."
            );
            return;
        }

        try {
            List<Cliente> clientes =
                    clienteRepository.listarTodos();

            request.setAttribute("clientes", clientes);
            request.setAttribute(
                    "totalClientes",
                    clientes.size()
            );

            request.getRequestDispatcher(
                    "/WEB-INF/vistas/clientes.jsp"
            ).forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                    "Error al cargar la gestión de clientes.",
                    e
            );
        }
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

        if (!tienePermisoGestionarClientes(session)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permisos para modificar clientes."
            );
            return;
        }

        String accion = request.getParameter("accion");

        if (accion == null || accion.isBlank()) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Debes indicar una acción."
            );
            return;
        }

        try {
            switch (accion) {

                case "guardar":
                    guardarCliente(request);
                    break;

                case "actualizar":
                    actualizarCliente(request);
                    break;

                case "cambiarEstado":
                    cambiarEstadoCliente(request);
                    break;

                default:
                    response.sendError(
                            HttpServletResponse.SC_BAD_REQUEST,
                            "La acción solicitada no es válida."
                    );
                    return;
            }

            response.sendRedirect(
                    request.getContextPath()
                    + "/clientes?resultado=ok"
            );

        } catch (IllegalArgumentException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    e.getMessage()
            );

        } catch (Exception e) {
            throw new ServletException(
                    "Error al procesar la operación del cliente.",
                    e
            );
        }
    }

    private void guardarCliente(
            HttpServletRequest request) throws Exception {

        Cliente cliente = obtenerDatosCliente(request);

        if (cliente.getNombre().isBlank()) {
            throw new IllegalArgumentException(
                    "El nombre del cliente es obligatorio."
            );
        }

        clienteRepository.guardar(cliente);
    }

    private void actualizarCliente(
            HttpServletRequest request) throws Exception {

        int clienteId = obtenerIdCliente(request);

        Cliente cliente = obtenerDatosCliente(request);
        cliente.setClienteId(clienteId);

        if (cliente.getNombre().isBlank()) {
            throw new IllegalArgumentException(
                    "El nombre del cliente es obligatorio."
            );
        }

        clienteRepository.actualizar(cliente);
    }

    private void cambiarEstadoCliente(
            HttpServletRequest request) throws Exception {

        int clienteId = obtenerIdCliente(request);
        String estado = request.getParameter("estado");

        if (!"activo".equals(estado)
                && !"inactivo".equals(estado)) {
            throw new IllegalArgumentException(
                    "El estado del cliente no es válido."
            );
        }

        clienteRepository.cambiarEstado(
                clienteId,
                estado
        );
    }

    private Cliente obtenerDatosCliente(
            HttpServletRequest request) {

        Cliente cliente = new Cliente();

        cliente.setNombre(
                valorParametro(request, "nombre")
        );
        cliente.setDocumento(
                valorParametro(request, "documento")
        );
        cliente.setCorreo(
                valorParametro(request, "correo")
        );
        cliente.setTelefono(
                valorParametro(request, "telefono")
        );
        cliente.setDireccion(
                valorParametro(request, "direccion")
        );

        return cliente;
    }

    private int obtenerIdCliente(
            HttpServletRequest request) {

        try {
            int id = Integer.parseInt(
                    request.getParameter("clienteId")
            );

            if (id <= 0) {
                throw new NumberFormatException();
            }

            return id;

        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(
                    "El identificador del cliente no es válido."
            );
        }
    }

    private String valorParametro(
            HttpServletRequest request,
            String nombre) {

        String valor = request.getParameter(nombre);

        return valor == null ? "" : valor.trim();
    }
}
