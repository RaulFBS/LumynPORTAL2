
package pe.lumyn.portal.controller;

import pe.lumyn.portal.config.ConexionBD;
import pe.lumyn.portal.security.PermisosUtil;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/prueba-conexion")
public class PruebaConexionServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }

        if (!PermisosUtil.esAdministrador(session)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Solo el administrador puede ejecutar pruebas de conexión."
            );
            return;
        }

        response.setContentType("text/html;charset=UTF-8");

        try (PrintWriter out = response.getWriter()) {
            try (Connection conexion =
                    ConexionBD.getInstancia().conectar()) {

                out.println("<h2>Conexion correcta</h2>");
                out.println("<p>La aplicacion se conecto a MySQL.</p>");

            } catch (SQLException e) {
                response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
                );

                out.println("<h2>Error de conexion</h2>");
                out.println("<p>Revisa la configuracion de ConexionBD.</p>");

                getServletContext().log(
                    "Error al conectar con MySQL", e
                );
            }
        }
    }
}

