
package pe.lumyn.portal.dao;

import pe.lumyn.portal.config.ConexionBD;
import pe.lumyn.portal.model.Usuario;
import pe.lumyn.portal.security.PasswordUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class UsuarioDAO {

    // =========================================
    // AUTENTICACION: METODOS EXISTENTES
    // =========================================

    public Usuario buscarPorCorreo(String correo) throws SQLException {

        String sql = """
            SELECT id, nombres, apellidos, correo, password_hash,
                   rol_id, estado, intentos_fallidos, bloqueado_hasta
            FROM usuarios
            WHERE correo = ?
            LIMIT 1
            """;

        try (Connection conexion = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setString(1, correo);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Usuario usuario = new Usuario();

                    usuario.setId(rs.getInt("id"));
                    usuario.setNombres(rs.getString("nombres"));
                    usuario.setApellidos(rs.getString("apellidos"));
                    usuario.setCorreo(rs.getString("correo"));
                    usuario.setPasswordHash(rs.getString("password_hash"));
                    usuario.setRolId(rs.getInt("rol_id"));
                    usuario.setEstado(rs.getString("estado"));
                    usuario.setIntentosFallidos(
                            rs.getInt("intentos_fallidos"));

                    Timestamp bloqueo = rs.getTimestamp("bloqueado_hasta");
                    usuario.setBloqueadoHasta(
                            bloqueo != null ? bloqueo.toString() : null);

                    return usuario;
                }
            }
        }

        return null;
    }

    public void registrarIntentoFallido(int idUsuario)
            throws SQLException {

        String sql = """
            UPDATE usuarios
            SET intentos_fallidos = intentos_fallidos + 1,
                bloqueado_hasta = CASE
                    WHEN intentos_fallidos + 1 >= 3
                    THEN DATE_ADD(NOW(), INTERVAL 15 MINUTE)
                    ELSE bloqueado_hasta
                END
            WHERE id = ?
            """;

        try (Connection conexion = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setInt(1, idUsuario);
            ps.executeUpdate();
        }
    }

    public void reiniciarIntentos(int idUsuario) throws SQLException {

        String sql = """
            UPDATE usuarios
            SET intentos_fallidos = 0,
                bloqueado_hasta = NULL
            WHERE id = ?
            """;

        try (Connection conexion = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setInt(1, idUsuario);
            ps.executeUpdate();
        }
    }

    // =========================================
    // CRUD: LISTAR USUARIOS
    // =========================================

    public List<Usuario> listarTodos() throws SQLException {

        List<Usuario> usuarios = new ArrayList<>();

        String sql = """
            SELECT id, nombres, apellidos, correo, password_hash,
                   rol_id, estado, intentos_fallidos, bloqueado_hasta
            FROM usuarios
            ORDER BY id DESC
            """;

        try (Connection conexion = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Usuario usuario = new Usuario();

                usuario.setId(rs.getInt("id"));
                usuario.setNombres(rs.getString("nombres"));
                usuario.setApellidos(rs.getString("apellidos"));
                usuario.setCorreo(rs.getString("correo"));

                // No se envía la contraseña a la vista.
                usuario.setPasswordHash(null);

                usuario.setRolId(rs.getInt("rol_id"));
                usuario.setEstado(rs.getString("estado"));
                usuario.setIntentosFallidos(
                        rs.getInt("intentos_fallidos"));

                Timestamp bloqueo = rs.getTimestamp("bloqueado_hasta");
                usuario.setBloqueadoHasta(
                        bloqueo != null ? bloqueo.toString() : null);

                usuarios.add(usuario);
            }
        }

        return usuarios;
    }

    // =========================================
    // CRUD: REGISTRAR USUARIO
    // =========================================

    public boolean registrar(Usuario usuario, String password)
            throws SQLException {

        String sql = """
            INSERT INTO usuarios
                (nombres, apellidos, correo, password_hash,
                 rol_id, estado, intentos_fallidos)
            VALUES (?, ?, ?, ?, ?, 'activo', 0)
            """;

        String hash = PasswordUtil.encriptar(password);

        try (Connection conexion = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setString(1, usuario.getNombres().trim());
            ps.setString(2, usuario.getApellidos().trim());
            ps.setString(3, usuario.getCorreo().trim().toLowerCase());
            ps.setString(4, hash);
            ps.setInt(5, usuario.getRolId());

            return ps.executeUpdate() == 1;
        }
    }

    // =========================================
    // CRUD: ACTUALIZAR DATOS
    // =========================================

    public boolean actualizar(Usuario usuario) throws SQLException {

        String sql = """
            UPDATE usuarios
            SET nombres = ?,
                apellidos = ?,
                correo = ?,
                rol_id = ?
            WHERE id = ?
            """;

        try (Connection conexion = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setString(1, usuario.getNombres().trim());
            ps.setString(2, usuario.getApellidos().trim());
            ps.setString(3, usuario.getCorreo().trim().toLowerCase());
            ps.setInt(4, usuario.getRolId());
            ps.setInt(5, usuario.getId());

            return ps.executeUpdate() == 1;
        }
    }

    // =========================================
    // CRUD: ACTIVAR / DESACTIVAR
    // =========================================

    public boolean cambiarEstado(int idUsuario, String estado)
            throws SQLException {

        if (!"activo".equalsIgnoreCase(estado)
                && !"inactivo".equalsIgnoreCase(estado)) {
            throw new IllegalArgumentException("Estado no válido.");
        }

        String sql = """
            UPDATE usuarios
            SET estado = ?
            WHERE id = ?
            """;

        try (Connection conexion = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setString(1, estado.toLowerCase());
            ps.setInt(2, idUsuario);

            return ps.executeUpdate() == 1;
        }
    }

    // =========================================
    // CONSULTAR CORREO DUPLICADO
    // =========================================

    public boolean existeCorreo(String correo, int idExcluir)
            throws SQLException {

        String sql = """
            SELECT COUNT(*)
            FROM usuarios
            WHERE correo = ?
              AND id <> ?
            """;

        try (Connection conexion = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setString(1, correo.trim().toLowerCase());
            ps.setInt(2, idExcluir);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    // =========================================
    // ESTADISTICAS
    // =========================================

    public int contarPorEstado(String estado) throws SQLException {

        String sql = """
            SELECT COUNT(*)
            FROM usuarios
            WHERE estado = ?
            """;

        try (Connection conexion = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setString(1, estado.toLowerCase());

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public int contarTodos() throws SQLException {

        String sql = "SELECT COUNT(*) FROM usuarios";

        try (Connection conexion = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    public int contarAdministradoresActivos() throws SQLException {

        String sql = """
            SELECT COUNT(*)
            FROM usuarios
            WHERE rol_id = 1
              AND estado = 'activo'
            """;

        try (Connection conexion = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            return rs.next() ? rs.getInt(1) : 0;
        }
    }

public boolean desactivarAdministradorSiHayOtroActivo(int idUsuario)
        throws SQLException {

    String sql = """
        UPDATE usuarios
        SET estado = 'inactivo'
        WHERE id = ?
          AND rol_id = 1
          AND estado = 'activo'
          AND (
              SELECT cantidad
              FROM (
                  SELECT COUNT(*) AS cantidad
                  FROM usuarios
                  WHERE rol_id = 1
                    AND estado = 'activo'
                    AND id <> ?
              ) AS administradores
          ) > 0
        """;

    try (Connection conexion = ConexionBD.getInstancia().conectar();
         PreparedStatement ps = conexion.prepareStatement(sql)) {

        ps.setInt(1, idUsuario);
        ps.setInt(2, idUsuario);

        return ps.executeUpdate() == 1;
    }
}

}
