
package pe.lumyn.portal.controller;

import pe.lumyn.portal.model.Usuario;
import pe.lumyn.portal.repository.UsuarioRepository;
import pe.lumyn.portal.repository.UsuarioRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Locale;

@WebServlet("/api/usuarios")
public class UsuariosApiServlet extends HttpServlet {

    private final UsuarioRepository usuarioRepository =
            new UsuarioRepositoryImpl();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws IOException {

        if (!esAdministrador(request, response)) {
            return;
        }

        prepararRespuesta(response);

        try {
            List<Usuario> usuarios =
                    usuarioRepository.listarTodos();

            int total = usuarioRepository.contarTodos();
            int activos = usuarioRepository.contarPorEstado("activo");
            int inactivos = usuarioRepository.contarPorEstado("inactivo");
            int administradores =
                    usuarioRepository.contarAdministradoresActivos();

            StringBuilder json = new StringBuilder();

            json.append("{")
                .append("\"ok\":true,")
                .append("\"totalUsuarios\":").append(total).append(",")
                .append("\"usuariosActivos\":").append(activos).append(",")
                .append("\"usuariosInactivos\":").append(inactivos).append(",")
                .append("\"administradoresActivos\":")
                .append(administradores).append(",")
                .append("\"usuarios\":[");

            for (int i = 0; i < usuarios.size(); i++) {
                Usuario usuario = usuarios.get(i);

                if (i > 0) {
                    json.append(",");
                }

                json.append("{")
                    .append("\"id\":").append(usuario.getId()).append(",")
                    .append("\"nombres\":\"")
                    .append(escapar(usuario.getNombres())).append("\",")
                    .append("\"apellidos\":\"")
                    .append(escapar(usuario.getApellidos())).append("\",")
                    .append("\"correo\":\"")
                    .append(escapar(usuario.getCorreo())).append("\",")
                    .append("\"rolId\":").append(usuario.getRolId()).append(",")
                    .append("\"estado\":\"")
                    .append(escapar(normalizarEstado(usuario.getEstado())))
                    .append("\",")
                    .append("\"creadoEn\":\"—\"")
                    .append("}");
            }

            json.append("]}");

            response.setStatus(HttpServletResponse.SC_OK);
            response.getWriter().write(json.toString());

        } catch (Exception e) {
            getServletContext().log("Error al listar usuarios", e);

            enviarError(
                    response,
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "No se pudo obtener la lista de usuarios."
            );
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws IOException {

        request.setCharacterEncoding(StandardCharsets.UTF_8.name());

        if (!esAdministrador(request, response)) {
            return;
        }

        prepararRespuesta(response);

        String accion = request.getParameter("accion");

        if (accion == null || accion.isBlank()) {
            enviarError(response, 400, "Debes especificar una acción.");
            return;
        }

        try {
            switch (accion) {
                case "crear":
                    crearUsuario(request, response);
                    break;

                case "actualizar":
                    actualizarUsuario(request, response);
                    break;

                case "cambiarEstado":
                    cambiarEstado(request, response);
                    break;

                default:
                    enviarError(response, 400,
                            "La acción solicitada no es válida.");
            }
        } catch (Exception e) {
            getServletContext().log(
                    "Error en la operación de usuarios", e);

            enviarError(response, 500,
                    "No se pudo completar la operación.");
        }
    }

    private void crearUsuario(HttpServletRequest request,
                              HttpServletResponse response)
            throws Exception, IOException {

        String nombres = limpiar(request.getParameter("nombres"));
        String apellidos = limpiar(request.getParameter("apellidos"));
        String correo = limpiar(request.getParameter("correo"))
                .toLowerCase(Locale.ROOT);
        String password = request.getParameter("password");
        String rolTexto = limpiar(request.getParameter("rolId"));

        if (nombres.isEmpty() || apellidos.isEmpty()
                || correo.isEmpty() || password == null
                || rolTexto.isEmpty()) {
            enviarError(response, 400,
                    "Completa todos los campos obligatorios.");
            return;
        }

        if (!correoValido(correo)) {
            enviarError(response, 400,
                    "El correo electrónico no tiene un formato válido.");
            return;
        }

        if (password.length() < 12 || password.length() > 72) {
            enviarError(response, 400,
                    "La contraseña debe tener entre 12 y 72 caracteres.");
            return;
        }

        int rolId = obtenerRolValido(rolTexto);

        if (rolId == -1) {
            enviarError(response, 400,
                    "El rol seleccionado no es válido.");
            return;
        }

        if (usuarioRepository.existeCorreo(correo, 0)) {
            enviarError(response, 409,
                    "Ya existe un usuario con ese correo.");
            return;
        }

        Usuario usuario = new Usuario();
        usuario.setNombres(nombres);
        usuario.setApellidos(apellidos);
        usuario.setCorreo(correo);
        usuario.setRolId(rolId);
        usuario.setEstado("activo");
        usuario.setIntentosFallidos(0);

        if (!usuarioRepository.registrar(usuario, password)) {
            enviarError(response, 500,
                    "No se pudo registrar el usuario.");
            return;
        }

        enviarExito(response, "Usuario registrado correctamente.");
    }

    private void actualizarUsuario(HttpServletRequest request,
                                   HttpServletResponse response)
            throws Exception, IOException {

        int id = obtenerId(request, response);
        if (id <= 0) {
            return;
        }

        String nombres = limpiar(request.getParameter("nombres"));
        String apellidos = limpiar(request.getParameter("apellidos"));
        String correo = limpiar(request.getParameter("correo"))
                .toLowerCase(Locale.ROOT);
        String rolTexto = limpiar(request.getParameter("rolId"));

        if (nombres.isEmpty() || apellidos.isEmpty()
                || correo.isEmpty() || rolTexto.isEmpty()) {
            enviarError(response, 400,
                    "Completa todos los campos obligatorios.");
            return;
        }

        if (!correoValido(correo)) {
            enviarError(response, 400,
                    "El correo electrónico no tiene un formato válido.");
            return;
        }

        int rolId = obtenerRolValido(rolTexto);

        if (rolId == -1) {
            enviarError(response, 400,
                    "El rol seleccionado no es válido.");
            return;
        }

        if (usuarioRepository.existeCorreo(correo, id)) {
            enviarError(response, 409,
                    "Otro usuario ya utiliza ese correo.");
            return;
        }

        Usuario usuario = new Usuario();
        usuario.setId(id);
        usuario.setNombres(nombres);
        usuario.setApellidos(apellidos);
        usuario.setCorreo(correo);
        usuario.setRolId(rolId);

        if (!usuarioRepository.actualizar(usuario)) {
            enviarError(response, 404,
                    "No se encontró el usuario o no se pudo actualizar.");
            return;
        }

        enviarExito(response, "Usuario actualizado correctamente.");
    }

    private void cambiarEstado(HttpServletRequest request,
                               HttpServletResponse response)
            throws Exception, IOException {

        int id = obtenerId(request, response);
        if (id <= 0) {
            return;
        }

        String estado = limpiar(request.getParameter("estado"))
                .toLowerCase(Locale.ROOT);

        if (!estado.equals("activo") && !estado.equals("inactivo")) {
            enviarError(response, 400,
                    "El estado indicado no es válido.");
            return;
        }

        HttpSession session = request.getSession(false);
        Object idSesionObjeto = session.getAttribute("usuarioId");

        if (!(idSesionObjeto instanceof Number)) {
            enviarError(response, 401,
                    "La sesión del usuario no es válida.");
            return;
        }

        int idSesion = ((Number) idSesionObjeto).intValue();

        if (id == idSesion && estado.equals("inactivo")) {
            enviarError(response, 400,
                    "No puedes desactivar tu propia cuenta.");
            return;
        }

        if (estado.equals("inactivo")) {
            List<Usuario> usuarios = usuarioRepository.listarTodos();
            Usuario objetivo = null;

            for (Usuario usuario : usuarios) {
                if (usuario.getId() == id) {
                    objetivo = usuario;
                    break;
                }
            }

            if (objetivo == null) {
                enviarError(response, 404,
                        "El usuario que intentas modificar no existe.");
                return;
            }

            boolean administradorActivo =
                    objetivo.getRolId() == 1
                    && "activo".equalsIgnoreCase(objetivo.getEstado());

            if (administradorActivo) {
                boolean cambiado = usuarioRepository
                        .desactivarAdministradorSiHayOtroActivo(id);

                if (!cambiado) {
                    enviarError(response, 409,
                            "No se puede desactivar al último administrador activo.");
                    return;
                }

                enviarExito(response, "Estado actualizado correctamente.");
                return;
            }
        }

        if (!usuarioRepository.cambiarEstado(id, estado)) {
            enviarError(response, 404,
                    "No se encontró el usuario o no se pudo cambiar su estado.");
            return;
        }

        enviarExito(response, "Estado actualizado correctamente.");
    }

    private boolean esAdministrador(HttpServletRequest request,
                                    HttpServletResponse response)
            throws IOException {

        prepararRespuesta(response);

        HttpSession session = request.getSession(false);

        if (!PermisosUtil.tieneSesion(session)) {
            enviarError(response, 401,
                    "Tu sesión ha expirado. Inicia sesión nuevamente.");
            return false;
        }

        if (!PermisosUtil.esAdministrador(session)) {
            enviarError(response, 403,
                    "No tienes permiso para realizar esta operación.");
            return false;
        }

        return true;
    }

    private int obtenerId(HttpServletRequest request,
                          HttpServletResponse response)
            throws IOException {

        try {
            int id = Integer.parseInt(request.getParameter("id"));

            if (id <= 0) {
                throw new NumberFormatException();
            }

            return id;
        } catch (NumberFormatException | NullPointerException e) {
            enviarError(response, 400,
                    "El identificador del usuario no es válido.");
            return -1;
        }
    }

    private int obtenerRolValido(String rolTexto) {
        try {
            int rolId = Integer.parseInt(rolTexto);
            return rolId >= 1 && rolId <= 4 ? rolId : -1;
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    private boolean correoValido(String correo) {
        return correo.matches(
                "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        );
    }

    private String normalizarEstado(String estado) {
        return estado == null ? "" : estado.toLowerCase(Locale.ROOT);
    }

    private String limpiar(String valor) {
        return valor == null ? "" : valor.trim();
    }

    private void prepararRespuesta(HttpServletResponse response) {
        response.setContentType("application/json");
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
        response.setHeader("X-Content-Type-Options", "nosniff");
    }

    private void enviarExito(HttpServletResponse response,
                             String mensaje) throws IOException {
        response.setStatus(HttpServletResponse.SC_OK);

        response.getWriter().write(
                "{\"ok\":true,\"mensaje\":\"" + escapar(mensaje) + "\"}"
        );
    }

    private void enviarError(HttpServletResponse response,
                             int codigo,
                             String mensaje) throws IOException {
        prepararRespuesta(response);
        response.setStatus(codigo);

        response.getWriter().write(
                "{\"ok\":false,\"mensaje\":\"" + escapar(mensaje) + "\"}"
        );
    }

    private String escapar(String texto) {
        if (texto == null) {
            return "";
        }

        StringBuilder resultado = new StringBuilder();

        for (char c : texto.toCharArray()) {
            switch (c) {
                case '"':
                    resultado.append("\\\"");
                    break;
                case '\\':
                    resultado.append("\\\\");
                    break;
                case '\b':
                    resultado.append("\\b");
                    break;
                case '\f':
                    resultado.append("\\f");
                    break;
                case '\n':
                    resultado.append("\\n");
                    break;
                case '\r':
                    resultado.append("\\r");
                    break;
                case '\t':
                    resultado.append("\\t");
                    break;
                default:
                    if (c < 0x20) {
                        resultado.append(String.format("\\u%04x", (int) c));
                    } else {
                        resultado.append(c);
                    }
            }
        }

        return resultado.toString();
    }
}
