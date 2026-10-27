
package pe.lumyn.portal.controller;

import java.io.IOException;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/api/sesion")
public class SesionApiServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");

        HttpSession session = request.getSession(false);

        if (session == null
                || session.getAttribute("usuarioId") == null
                || session.getAttribute("rolId") == null) {

            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write(
                    "{\"autenticado\":false}"
            );
            return;
        }

        Object id = session.getAttribute("usuarioId");
        Object nombre = session.getAttribute("nombreUsuario");
        Object rol = session.getAttribute("rolId");

        response.getWriter().write(
                "{\"autenticado\":true,"
                + "\"usuarioId\":" + id + ","
                + "\"nombreUsuario\":\"" + escapar(
                        nombre == null ? "Usuario" : nombre.toString()
                ) + "\","
                + "\"rolId\":" + rol + "}"
        );
    }

    private String escapar(String texto) {
        return texto.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
