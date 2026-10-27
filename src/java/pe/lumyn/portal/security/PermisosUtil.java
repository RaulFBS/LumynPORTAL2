
package pe.lumyn.portal.security;

import jakarta.servlet.http.HttpSession;

public class PermisosUtil {

    private PermisosUtil() {
        // Evita crear instancias de esta clase.
    }

    public static boolean tieneSesion(HttpSession session) {
        return session != null
                && session.getAttribute("usuarioId") != null;
    }

    public static boolean tieneRol(
            HttpSession session,
            int rolRequerido) {

        if (!tieneSesion(session)) {
            return false;
        }

        Object rol = session.getAttribute("rolId");

        if (rol == null) {
            return false;
        }

        try {
            return Integer.parseInt(rol.toString())
                    == rolRequerido;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    public static boolean esAdministrador(HttpSession session) {
        return tieneRol(session, 1);
    }

    public static boolean esGestor(HttpSession session) {
        return tieneRol(session, 2);
    }

    public static boolean esColaborador(HttpSession session) {
        return tieneRol(session, 3);
    }

    public static boolean esRevisor(HttpSession session) {
        return tieneRol(session, 4);
    }

    public static boolean puedeGestionarClientes(
            HttpSession session) {
        return esAdministrador(session)
                || esGestor(session);
    }

    public static boolean puedeGestionarVentas(
            HttpSession session) {
        return esAdministrador(session)
                || esGestor(session);
    }

    public static boolean puedeGestionarSolped(
            HttpSession session) {
        return esAdministrador(session)
                || esGestor(session);
    }
}

