
package pe.lumyn.portal.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConexionBD {

    private static ConexionBD instancia;

    private ConexionBD() {
    }

    public static synchronized ConexionBD getInstancia() {
        if (instancia == null) {
            instancia = new ConexionBD();
        }
        return instancia;
    }

    public Connection conectar() throws SQLException {
        String url = System.getenv("DB_URL");
        String usuario = System.getenv("DB_USER");
        String password = System.getenv("DB_PASSWORD");

        // Valores locales para desarrollo.
        if (url == null || url.isBlank()) {
            url = "jdbc:mysql://localhost:3306/lumyn_portal"
                    + "?useSSL=false&serverTimezone=UTC";
        }

        if (usuario == null || usuario.isBlank()) {
            usuario = "root";
        }

        if (password == null) {
            password = "";
        }

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException(
                    "No se encontro el controlador JDBC de MySQL.", e
            );
        }

        return DriverManager.getConnection(url, usuario, password);
    }
}
