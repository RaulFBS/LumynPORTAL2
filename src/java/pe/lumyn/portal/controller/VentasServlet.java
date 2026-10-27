
package pe.lumyn.portal.controller;

import pe.lumyn.portal.model.Venta;
import pe.lumyn.portal.repository.VentaRepository;
import pe.lumyn.portal.repository.VentaRepositoryImpl;
import pe.lumyn.portal.security.PermisosUtil;

import java.io.IOException;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/ventas")
public class VentasServlet extends HttpServlet {

    private final VentaRepository ventaRepository =
            new VentaRepositoryImpl();

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

        if (!PermisosUtil.tieneSesion(session)) {
            response.sendRedirect(
                    request.getContextPath() + "/login.html"
            );
            return;
        }

        if (!PermisosUtil.puedeGestionarVentas(session)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permisos para gestionar ventas."
            );
            return;
        }

        try {
            List<Venta> ventas = ventaRepository.listarTodas();

            request.setAttribute("ventas", ventas);
            request.setAttribute("totalVentas", ventas.size());

            request.getRequestDispatcher(
                    "/WEB-INF/vistas/ventas.jsp"
            ).forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                    "Error al cargar las ventas.",
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

        if (!PermisosUtil.puedeGestionarVentas(session)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permisos para registrar ventas."
            );
            return;
        }

        String accion = request.getParameter("accion");

        if (!"convertirSolped".equals(accion)) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "La acción solicitada no es válida."
            );
            return;
        }

        try {
            int solpedId = obtenerId(
                    request.getParameter("solpedId"),
                    "El identificador de la SOLPED no es válido."
            );

            String proyectoParametro =
                    request.getParameter("proyectoId");

            Integer proyectoId = null;

            if (proyectoParametro != null
                    && !proyectoParametro.isBlank()) {

                proyectoId = obtenerId(
                        proyectoParametro,
                        "El identificador del proyecto no es válido."
                );
            }

            boolean convertida =
                    ventaRepository.registrarDesdeSolped(
                            solpedId,
                            proyectoId
                    );

            if (!convertida) {
                throw new ServletException(
                        "No se pudo convertir la SOLPED en venta."
                );
            }

            response.sendRedirect(
        request.getContextPath()
        + "/solped?id=" + solpedId
        + "&resultado=convertida"
);

        } catch (IllegalArgumentException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    e.getMessage()
            );

        } catch (Exception e) {
            throw new ServletException(
                    "Error al convertir la SOLPED en venta.",
                    e
            );
        }
    }

    private int obtenerId(
            String parametro,
            String mensaje) {

        try {
            int id = Integer.parseInt(parametro);

            if (id <= 0) {
                throw new NumberFormatException();
            }

            return id;

        } catch (NumberFormatException | NullPointerException e) {
            throw new IllegalArgumentException(mensaje);
        }
    }
}
