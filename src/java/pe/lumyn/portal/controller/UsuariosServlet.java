
package pe.lumyn.portal.controller;

import pe.lumyn.portal.model.Usuario;
import pe.lumyn.portal.repository.UsuarioRepository;
import pe.lumyn.portal.repository.UsuarioRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import java.io.IOException;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/usuarios")
public class UsuariosServlet extends HttpServlet {

    private final UsuarioRepository usuarioRepository =
            new UsuarioRepositoryImpl();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader(
                "Cache-Control",
                "no-cache, no-store, must-revalidate"
        );
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        HttpSession session = request.getSession(false);

        // Verificar que exista una sesión autenticada.
        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(
                    request.getContextPath() + "/login.html"
            );
            return;
        }

        // Solo el administrador puede gestionar usuarios.
        if (!PermisosUtil.esAdministrador(session)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permisos para gestionar usuarios."
            );
            return;
        }

        try {
            List<Usuario> usuarios =
                    usuarioRepository.listarTodos();

            request.setAttribute("usuarios", usuarios);

            request.setAttribute(
                    "totalUsuarios",
                    usuarioRepository.contarTodos()
            );

            request.setAttribute(
                    "usuariosActivos",
                    usuarioRepository.contarPorEstado("activo")
            );

            request.setAttribute(
                    "usuariosInactivos",
                    usuarioRepository.contarPorEstado("inactivo")
            );

            request.setAttribute(
                    "administradoresActivos",
                    usuarioRepository.contarAdministradoresActivos()
            );

            request.getRequestDispatcher(
                    "/WEB-INF/vistas/usuarios.html"
            ).forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                    "Error al cargar la gestión de usuarios.",
                    e
            );
        }
    }
}
