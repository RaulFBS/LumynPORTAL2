
package pe.lumyn.portal.repository;

import pe.lumyn.portal.config.ConexionBD;
import pe.lumyn.portal.model.Solped;
import pe.lumyn.portal.model.SolpedDetalle;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class SolpedRepositoryImpl implements SolpedRepository {

    @Override
    public List<Solped> listarTodas() throws Exception {
        List<Solped> solicitudes = new ArrayList<>();

        String sql = """
            SELECT solped_id, cliente_id, proyecto_id, usuario_id,
                   fecha_solicitud, descripcion_requerimiento, estado
            FROM solped
            ORDER BY fecha_solicitud DESC, solped_id DESC
            """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Solped solped = mapearSolped(rs);
                solped.setDetalles(
                    listarDetalles(conn, solped.getSolpedId())
                );
                solicitudes.add(solped);
            }
        }

        return solicitudes;
    }

    @Override
    public Solped buscarPorId(int solpedId) throws Exception {
        if (solpedId <= 0) {
            throw new IllegalArgumentException(
                "El identificador de la SOLPED no es válido."
            );
        }

        String sql = """
            SELECT solped_id, cliente_id, proyecto_id, usuario_id,
                   fecha_solicitud, descripcion_requerimiento, estado
            FROM solped
            WHERE solped_id = ?
            """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, solpedId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                Solped solped = mapearSolped(rs);
                solped.setDetalles(listarDetalles(conn, solpedId));
                return solped;
            }
        }
    }

    @Override
    public boolean cambiarEstado(int solpedId, String estado)
            throws Exception {

        if (solpedId <= 0) {
            throw new IllegalArgumentException(
                "El identificador de la SOLPED no es válido."
            );
        }

        if (!"aprobada".equals(estado)
                && !"rechazada".equals(estado)) {
            throw new IllegalArgumentException(
                "El estado solicitado no está permitido."
            );
        }

        String sql = """
            UPDATE solped
            SET estado = ?
            WHERE solped_id = ?
              AND estado IN ('pendiente', 'en_revision')
            """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, estado);
            ps.setInt(2, solpedId);

            return ps.executeUpdate() == 1;
        }
    }

    @Override
    public int registrar(Solped solped) throws Exception {
        validarSolped(solped);

        try (Connection conn =
                 ConexionBD.getInstancia().conectar()) {

            boolean autocommitOriginal = conn.getAutoCommit();

            try {
                conn.setAutoCommit(false);

                validarCliente(conn, solped.getClienteId());

                if (solped.getProyectoId() != null) {
                    validarProyecto(
                        conn,
                        solped.getProyectoId(),
                        solped.getClienteId()
                    );
                }

                String sqlSolped = """
                    INSERT INTO solped
                        (cliente_id, proyecto_id, usuario_id,
                         descripcion_requerimiento, estado)
                    VALUES (?, ?, ?, ?, 'pendiente')
                    """;

                int solpedId;

                try (PreparedStatement ps = conn.prepareStatement(
                        sqlSolped, Statement.RETURN_GENERATED_KEYS)) {

                    ps.setInt(1, solped.getClienteId());

                    if (solped.getProyectoId() == null) {
                        ps.setNull(2, java.sql.Types.INTEGER);
                    } else {
                        ps.setInt(2, solped.getProyectoId());
                    }

                    if (solped.getUsuarioId() == null) {
                        ps.setNull(3, java.sql.Types.INTEGER);
                    } else {
                        ps.setInt(3, solped.getUsuarioId());
                    }

                    ps.setString(
                        4,
                        solped.getDescripcionRequerimiento().trim()
                    );

                    ps.executeUpdate();

                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new SQLException(
                                "No se pudo obtener el ID de la SOLPED."
                            );
                        }
                        solpedId = rs.getInt(1);
                    }
                }

                String sqlDetalle = """
                    INSERT INTO solped_detalle
                        (solped_id, servicio, descripcion,
                         cantidad, precio_unitario)
                    VALUES (?, ?, ?, ?, ?)
                    """;

                try (PreparedStatement ps =
                         conn.prepareStatement(sqlDetalle)) {

                    for (SolpedDetalle detalle : solped.getDetalles()) {
                        validarDetalle(detalle);

                        ps.setInt(1, solpedId);
                        ps.setString(2, detalle.getServicio().trim());

                        String descripcion = detalle.getDescripcion();
                        if (descripcion == null
                                || descripcion.isBlank()) {
                            ps.setNull(3, java.sql.Types.VARCHAR);
                        } else {
                            ps.setString(3, descripcion.trim());
                        }

                        ps.setBigDecimal(4, detalle.getCantidad());
                        ps.setBigDecimal(
                            5, detalle.getPrecioUnitario()
                        );

                        ps.addBatch();
                    }

                    ps.executeBatch();
                }

                conn.commit();

                solped.setSolpedId(solpedId);
                solped.setEstado("pendiente");

                return solpedId;

            } catch (Exception e) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackError) {
                    e.addSuppressed(rollbackError);
                }
                throw e;

            } finally {
                try {
                    conn.setAutoCommit(autocommitOriginal);
                } catch (SQLException ignored) {
                    // La conexión se cerrará al salir del try.
                }
            }
        }
    }

    private void validarSolped(Solped solped) {
        if (solped == null) {
            throw new IllegalArgumentException(
                "La solicitud no puede estar vacía."
            );
        }

        if (solped.getClienteId() <= 0) {
            throw new IllegalArgumentException(
                "Debes seleccionar un cliente válido."
            );
        }

        if (solped.getProyectoId() != null
                && solped.getProyectoId() <= 0) {
            throw new IllegalArgumentException(
                "El proyecto seleccionado no es válido."
            );
        }

        String descripcion = solped.getDescripcionRequerimiento();

        if (descripcion == null || descripcion.isBlank()) {
            throw new IllegalArgumentException(
                "Debes describir el requerimiento."
            );
        }

        if (solped.getDetalles() == null
                || solped.getDetalles().isEmpty()) {
            throw new IllegalArgumentException(
                "Debes agregar al menos un detalle."
            );
        }
    }

    private void validarDetalle(SolpedDetalle detalle) {
        if (detalle == null
                || detalle.getServicio() == null
                || detalle.getServicio().isBlank()) {
            throw new IllegalArgumentException(
                "Cada detalle debe tener un servicio."
            );
        }

        BigDecimal cantidad = detalle.getCantidad();
        BigDecimal precio = detalle.getPrecioUnitario();

        if (cantidad == null
                || cantidad.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException(
                "La cantidad debe ser mayor que cero."
            );
        }

        if (precio == null
                || precio.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException(
                "El precio unitario no puede ser negativo."
            );
        }
    }

    private void validarCliente(Connection conn, int clienteId)
            throws SQLException {

        String sql = """
            SELECT cliente_id
            FROM clientes
            WHERE cliente_id = ?
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, clienteId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException(
                        "El cliente seleccionado no existe."
                    );
                }
            }
        }
    }

    private void validarProyecto(
            Connection conn, int proyectoId, int clienteId)
            throws SQLException {

        String sql = """
            SELECT proyecto_id
            FROM proyectos
            WHERE proyecto_id = ?
              AND cliente_id = ?
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, proyectoId);
            ps.setInt(2, clienteId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException(
                        "El proyecto no existe o no pertenece al cliente."
                    );
                }
            }
        }
    }

    private Solped mapearSolped(ResultSet rs) throws SQLException {
        Solped solped = new Solped();

        solped.setSolpedId(rs.getInt("solped_id"));
        solped.setClienteId(rs.getInt("cliente_id"));

        int proyectoId = rs.getInt("proyecto_id");
        solped.setProyectoId(
            rs.wasNull() ? null : proyectoId
        );

        int usuarioId = rs.getInt("usuario_id");
        solped.setUsuarioId(
            rs.wasNull() ? null : usuarioId
        );

        solped.setFechaSolicitud(
            rs.getTimestamp("fecha_solicitud")
        );
        solped.setDescripcionRequerimiento(
            rs.getString("descripcion_requerimiento")
        );
        solped.setEstado(rs.getString("estado"));

        return solped;
    }

    private List<SolpedDetalle> listarDetalles(
            Connection conn, int solpedId) throws SQLException {

        List<SolpedDetalle> detalles = new ArrayList<>();

        String sql = """
            SELECT solped_detalle_id, solped_id, servicio,
                   descripcion, cantidad, precio_unitario, subtotal
            FROM solped_detalle
            WHERE solped_id = ?
            ORDER BY solped_detalle_id
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, solpedId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    SolpedDetalle detalle = new SolpedDetalle();

                    detalle.setSolpedDetalleId(
                        rs.getInt("solped_detalle_id")
                    );
                    detalle.setSolpedId(rs.getInt("solped_id"));
                    detalle.setServicio(rs.getString("servicio"));
                    detalle.setDescripcion(rs.getString("descripcion"));
                    detalle.setCantidad(rs.getBigDecimal("cantidad"));
                    detalle.setPrecioUnitario(
                        rs.getBigDecimal("precio_unitario")
                    );
                    detalle.setSubtotal(rs.getBigDecimal("subtotal"));

                    detalles.add(detalle);
                }
            }
        }

        return detalles;
    }
}
