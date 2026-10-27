
package pe.lumyn.portal.controller;

import pe.lumyn.portal.model.Usuario;
import pe.lumyn.portal.repository.UsuarioRepository;
import pe.lumyn.portal.repository.UsuarioRepositoryImpl;
import pe.lumyn.portal.security.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Timestamp;
import java.time.LocalDateTime;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private final UsuarioRepository usuarioRepository =
            new UsuarioRepositoryImpl();

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String correo = request.getParameter("correo");
        String password = request.getParameter("password");

        if (correo == null || password == null
                || correo.trim().isEmpty()
                || password.isEmpty()) {

            response.sendRedirect(
                    request.getContextPath() + "/login.html?error=campos"
            );
            return;
        }

        correo = correo.trim().toLowerCase();

        try {
            // Buscar al usuario mediante Repository.
            Usuario usuario =
                    usuarioRepository.buscarPorCorreo(correo);

            if (usuario == null) {
                response.sendRedirect(
                        request.getContextPath()
                        + "/login.html?error=credenciales"
                );
                return;
            }

            // Comprobar si la cuenta está bloqueada.
            String bloqueadoHasta = usuario.getBloqueadoHasta();

            if (bloqueadoHasta != null
                    && !bloqueadoHasta.trim().isEmpty()) {

                LocalDateTime fechaBloqueo =
                        convertirFecha(bloqueadoHasta);

                if (fechaBloqueo != null
                        && fechaBloqueo.isAfter(LocalDateTime.now())) {

                    response.sendRedirect(
                            request.getContextPath()
                            + "/login.html?error=bloqueado"
                    );
                    return;
                }
            }

            // Comprobar que la cuenta esté activa.
            if (usuario.getEstado() == null
                    || !usuario.getEstado().equalsIgnoreCase("activo")) {

                response.sendRedirect(
                        request.getContextPath()
                        + "/login.html?error=inactivo"
                );
                return;
            }

            // Verificar la contraseña mediante BCrypt.
            boolean passwordCorrecta =
                    PasswordUtil.verificar(
                            password,
                            usuario.getPasswordHash()
                    );

            if (!passwordCorrecta) {

                usuarioRepository.registrarIntentoFallido(
                        usuario.getId()
                );

                response.sendRedirect(
                        request.getContextPath()
                        + "/login.html?error=credenciales"
                );
                return;
            }

            // Reiniciar los intentos después de un acceso correcto.
            usuarioRepository.reiniciarIntentos(usuario.getId());

            // Evitar reutilizar una sesión anterior.
            HttpSession sesionAnterior = request.getSession(false);

            if (sesionAnterior != null) {
                sesionAnterior.invalidate();
            }

            HttpSession session = request.getSession(true);

            session.setAttribute("usuarioId", usuario.getId());
            session.setAttribute(
                    "nombreUsuario",
                    usuario.getNombres()
            );
            session.setAttribute("rolId", usuario.getRolId());

            // Tiempo máximo de inactividad: 20 minutos.
            session.setMaxInactiveInterval(20 * 60);

            response.sendRedirect(
                    request.getContextPath() + "/dashboard"
            );

        } catch (Exception e) {
            getServletContext().log(
                    "Error durante el inicio de sesión.", e
            );

            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "No se pudo procesar el inicio de sesión. "
                    + "Inténtalo nuevamente."
            );
        }
    }

    private LocalDateTime convertirFecha(String fecha) {
        try {
            return Timestamp.valueOf(fecha).toLocalDateTime();
        } catch (IllegalArgumentException e) {
            try {
                return LocalDateTime.parse(fecha.replace(" ", "T"));
            } catch (RuntimeException ex) {
                return null;
            }
        }
    }
}
