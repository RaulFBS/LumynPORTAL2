
package pe.lumyn.portal.controller;

import pe.lumyn.portal.model.Cliente;
import pe.lumyn.portal.repository.ClienteRepository;
import pe.lumyn.portal.repository.ClienteRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/clientes")
public class ClientesServlet extends HttpServlet {

    private static final int TAMANO_PAGINA_DEFECTO = 10;

    private final ClienteRepository clienteRepository =
            new ClienteRepositoryImpl();

    private int parsearTamanoPagina(String valor) {
        if (valor == null || valor.isBlank()) {
            return TAMANO_PAGINA_DEFECTO;
        }
        try {
            int parsed = Integer.parseInt(valor.trim());
            if (parsed == 5 || parsed == 10 || parsed == 20 || parsed == 50) {
                return parsed;
            }
        } catch (NumberFormatException ignored) {
            // Usar valor por defecto si el parámetro no es válido.
        }
        return TAMANO_PAGINA_DEFECTO;
    }

    private int parsearPagina(String valor) {
        if (valor == null || valor.isBlank()) {
            return 1;
        }
        try {
            int parsed = Integer.parseInt(valor.trim());
            return Math.max(parsed, 1);
        } catch (NumberFormatException ignored) {
            return 1;
        }
    }

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
            String busqueda = valorParametro(request, "q");
            int tamanoPagina = parsearTamanoPagina(request.getParameter("size"));
            int paginaSolicitada = parsearPagina(request.getParameter("page"));

            int[] resumen = clienteRepository.obtenerResumenEstadisticas();
            int totalClientes = resumen[0];
            int clientesActivos = resumen[1];
            int clientesConCorreo = resumen[2];

            int totalFiltrados = busqueda.isBlank()
                    ? totalClientes
                    : clienteRepository.contarFiltrados(busqueda);

            int totalPaginas = Math.max(
                    1,
                    (int) Math.ceil((double) totalFiltrados / tamanoPagina)
            );
            int paginaActual = Math.min(paginaSolicitada, totalPaginas);
            int desplazamiento = (paginaActual - 1) * tamanoPagina;

            List<Cliente> clientes = clienteRepository.listarPaginado(
                    busqueda,
                    tamanoPagina,
                    desplazamiento
            );

            request.setAttribute("clientes", clientes);
            request.setAttribute("totalClientes", totalClientes);
            request.setAttribute("clientesActivos", clientesActivos);
            request.setAttribute("clientesConCorreo", clientesConCorreo);
            request.setAttribute("totalFiltrados", totalFiltrados);
            request.setAttribute("paginaActual", paginaActual);
            request.setAttribute("tamanoPagina", tamanoPagina);
            request.setAttribute("totalPaginas", totalPaginas);
            request.setAttribute("busqueda", busqueda);

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

            StringBuilder redirectUrl = new StringBuilder(request.getContextPath())
                    .append("/clientes?resultado=ok");

            String pageParam = valorParametro(request, "page");
            String sizeParam = valorParametro(request, "size");
            String qParam = valorParametro(request, "q");

            if (!"guardar".equals(accion) && !pageParam.isBlank()) {
                redirectUrl.append("&page=").append(parsearPagina(pageParam));
            }
            if (!sizeParam.isBlank()) {
                redirectUrl.append("&size=").append(parsearTamanoPagina(sizeParam));
            }
            if (!qParam.isBlank()) {
                redirectUrl.append("&q=").append(
                        URLEncoder.encode(qParam, StandardCharsets.UTF_8)
                );
            }

            response.sendRedirect(redirectUrl.toString());

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
