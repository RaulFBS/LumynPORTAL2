
package pe.lumyn.portal.security;

import org.mindrot.jbcrypt.BCrypt;

public class PasswordUtil {

    // Genera un hash BCrypt para almacenar la contraseña.
    public static String encriptar(String password) {
        return BCrypt.hashpw(password, BCrypt.gensalt(12));
    }

    // Comprueba una contraseña contra su hash almacenado.
    public static boolean verificar(
            String password,
            String passwordHash) {

        if (password == null || passwordHash == null) {
            return false;
        }

        try {
            return BCrypt.checkpw(password, passwordHash);
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}
