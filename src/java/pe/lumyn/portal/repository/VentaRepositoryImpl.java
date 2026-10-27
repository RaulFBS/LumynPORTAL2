
package pe.lumyn.portal.repository;

import pe.lumyn.portal.config.ConexionBD;
import pe.lumyn.portal.model.Venta;
import pe.lumyn.portal.model.VentaDetalle;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class VentaRepositoryImpl implements VentaRepository {

    @Override
    public List<Venta> listarTodas() throws Exception {

        List<Venta> ventas = new ArrayList<>();

        String sql = """
                SELECT venta_id, solped_id, cliente_id, proyecto_id,
                       fecha_venta, subtotal, impuesto, total, estado
                FROM ventas
                ORDER BY venta_id DESC
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                ventas.add(mapearVenta(rs));
            }
        }

        return ventas;
    }

    @Override
    public Venta buscarPorId(int ventaId) throws Exception {

        String sql = """
                SELECT venta_id, solped_id, cliente_id, proyecto_id,
                       fecha_venta, subtotal, impuesto, total, estado
                FROM ventas
                WHERE venta_id = ?
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, ventaId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Venta venta = mapearVenta(rs);
                    venta.setDetalles(listarDetalles(conn, ventaId));
                    return venta;
                }
            }
        }

        return null;
    }

    @Override
    public boolean registrarDesdeSolped(
            int solpedId,
            Integer proyectoId) throws Exception {

        if (solpedId <= 0) {
            throw new IllegalArgumentException(
                    "El identificador de la SOLPED no es válido."
            );
        }

        if (proyectoId != null && proyectoId <= 0) {
            throw new IllegalArgumentException(
                    "El identificador del proyecto no es válido."
            );
        }

        String sqlSolped = """
                SELECT cliente_id, estado
                FROM solped
                WHERE solped_id = ?
                FOR UPDATE
                """;

        String sqlExisteVenta = """
                SELECT venta_id
                FROM ventas
                WHERE solped_id = ?
                """;

        String sqlProyecto = """
                SELECT proyecto_id
                FROM proyectos
                WHERE proyecto_id = ?
                  AND cliente_id = ?
                """;

        String sqlTotales = """
                SELECT COALESCE(SUM(subtotal), 0) AS subtotal
                FROM solped_detalle
                WHERE solped_id = ?
                """;

        String sqlInsertVenta = """
                INSERT INTO ventas
                (solped_id, cliente_id, proyecto_id,
                 subtotal, impuesto, total, estado)
                VALUES (?, ?, ?, ?, ?, ?, 'confirmada')
                """;

        String sqlCopiarDetalles = """
                INSERT INTO venta_detalle
                (venta_id, servicio, descripcion,
                 cantidad, precio_unitario)
                SELECT ?, servicio, descripcion,
                       cantidad, precio_unitario
                FROM solped_detalle
                WHERE solped_id = ?
                """;

        String sqlActualizarSolped = """
                UPDATE solped
                SET estado = 'convertida'
                WHERE solped_id = ?
                  AND estado = 'aprobada'
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar()) {

            conn.setAutoCommit(false);

            try {
                int clienteId;
                String estadoSolped;

                try (PreparedStatement ps =
                             conn.prepareStatement(sqlSolped)) {

                    ps.setInt(1, solpedId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException(
                                    "La SOLPED no existe."
                            );
                        }

                        clienteId = rs.getInt("cliente_id");
                        estadoSolped = rs.getString("estado");
                    }
                }

                if (!"aprobada".equals(estadoSolped)) {
                    throw new IllegalArgumentException(
                            "La SOLPED debe estar aprobada antes "
                            + "de convertirla en venta."
                    );
                }

                try (PreparedStatement ps =
                             conn.prepareStatement(sqlExisteVenta)) {

                    ps.setInt(1, solpedId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            throw new IllegalArgumentException(
                                    "Esta SOLPED ya tiene una venta."
                            );
                        }
                    }
                }

                if (proyectoId != null) {
                    try (PreparedStatement ps =
                                 conn.prepareStatement(sqlProyecto)) {

                        ps.setInt(1, proyectoId);
                        ps.setInt(2, clienteId);

                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) {
                                throw new IllegalArgumentException(
                                        "El proyecto no existe o "
                                        + "no pertenece al cliente."
                                );
                            }
                        }
                    }
                }

                BigDecimal subtotal;

                try (PreparedStatement ps =
                             conn.prepareStatement(sqlTotales)) {

                    ps.setInt(1, solpedId);

                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        subtotal = rs.getBigDecimal("subtotal");
                    }
                }

                if (subtotal == null || subtotal.signum() <= 0) {
                    throw new IllegalArgumentException(
                            "La SOLPED debe tener detalles "
                            + "con un importe mayor que cero."
                    );
                }

                int ventaId;

                try (PreparedStatement ps = conn.prepareStatement(
                        sqlInsertVenta,
                        Statement.RETURN_GENERATED_KEYS)) {

                    ps.setInt(1, solpedId);
                    ps.setInt(2, clienteId);

                    if (proyectoId == null) {
                        ps.setNull(3, java.sql.Types.INTEGER);
                    } else {
                        ps.setInt(3, proyectoId);
                    }

                    ps.setBigDecimal(4, subtotal);
                    ps.setBigDecimal(5, BigDecimal.ZERO);
                    ps.setBigDecimal(6, subtotal);

                    if (ps.executeUpdate() != 1) {
                        throw new Exception(
                                "No se pudo registrar la venta."
                        );
                    }

                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new Exception(
                                    "No se obtuvo el ID de la venta."
                            );
                        }

                        ventaId = rs.getInt(1);
                    }
                }

                try (PreparedStatement ps =
                             conn.prepareStatement(sqlCopiarDetalles)) {

                    ps.setInt(1, ventaId);
                    ps.setInt(2, solpedId);

                    if (ps.executeUpdate() == 0) {
                        throw new Exception(
                                "No se copiaron los detalles de la SOLPED."
                        );
                    }
                }

                try (PreparedStatement ps =
                             conn.prepareStatement(sqlActualizarSolped)) {

                    ps.setInt(1, solpedId);

                    if (ps.executeUpdate() != 1) {
                        throw new Exception(
                                "No se pudo actualizar el estado de la SOLPED."
                        );
                    }
                }

                conn.commit();
                return true;

            } catch (Exception e) {
                try {
                    conn.rollback();
                } catch (Exception rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;

            } finally {
                try {
                    conn.setAutoCommit(true);
                } catch (Exception ignored) {
                    // La conexión se cerrará al terminar el try-with-resources.
                }
            }
        }
    }

    private Venta mapearVenta(ResultSet rs) throws Exception {

        Venta venta = new Venta();

        venta.setVentaId(rs.getInt("venta_id"));
        venta.setSolpedId(rs.getInt("solped_id"));
        venta.setClienteId(rs.getInt("cliente_id"));

        int proyectoId = rs.getInt("proyecto_id");
        venta.setProyectoId(
                rs.wasNull() ? null : proyectoId
        );

        venta.setFechaVenta(rs.getTimestamp("fecha_venta"));
        venta.setSubtotal(rs.getBigDecimal("subtotal"));
        venta.setImpuesto(rs.getBigDecimal("impuesto"));
        venta.setTotal(rs.getBigDecimal("total"));
        venta.setEstado(rs.getString("estado"));

        return venta;
    }

    private List<VentaDetalle> listarDetalles(
            Connection conn,
            int ventaId) throws Exception {

        List<VentaDetalle> detalles = new ArrayList<>();

        String sql = """
                SELECT venta_detalle_id, venta_id, servicio,
                       descripcion, cantidad, precio_unitario, subtotal
                FROM venta_detalle
                WHERE venta_id = ?
                ORDER BY venta_detalle_id
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, ventaId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {

                    VentaDetalle detalle = new VentaDetalle();

                    detalle.setVentaDetalleId(
                            rs.getInt("venta_detalle_id")
                    );
                    detalle.setVentaId(rs.getInt("venta_id"));
                    detalle.setServicio(rs.getString("servicio"));
                    detalle.setDescripcion(
                            rs.getString("descripcion")
                    );
                    detalle.setCantidad(
                            rs.getBigDecimal("cantidad")
                    );
                    detalle.setPrecioUnitario(
                            rs.getBigDecimal("precio_unitario")
                    );
                    detalle.setSubtotal(
                            rs.getBigDecimal("subtotal")
                    );

                    detalles.add(detalle);
                }
            }
        }

        return detalles;
    }
}
