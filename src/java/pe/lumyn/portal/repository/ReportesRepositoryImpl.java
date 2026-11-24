package pe.lumyn.portal.repository;

import pe.lumyn.portal.config.ConexionBD;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ReportesRepositoryImpl implements ReportesRepository {

    @Override
    public Map<String, Object> obtenerResumenGeneral() throws Exception {
        Map<String, Object> resumen = new LinkedHashMap<>();

        try (Connection conn = ConexionBD.getInstancia().conectar()) {
            resumen.put("proyectosPorEstado", consultarAgrupado(
                    conn,
                    "SELECT estado AS etiqueta, COUNT(*) AS total "
                    + "FROM proyectos GROUP BY estado ORDER BY total DESC"
            ));

            resumen.put("solpedPorEstado", consultarAgrupado(
                    conn,
                    "SELECT estado AS etiqueta, COUNT(*) AS total "
                    + "FROM solped GROUP BY estado ORDER BY total DESC"
            ));

            resumen.put("usuariosPorEstado", consultarAgrupado(
                    conn,
                    "SELECT estado AS etiqueta, COUNT(*) AS total "
                    + "FROM usuarios GROUP BY estado"
            ));

            resumen.put("ventasPorMes", consultarVentasPorMes(conn));
            resumen.put("topClientes", consultarTopClientes(conn));
            resumen.put("clienteMasRecurrente", consultarClienteMasRecurrente(conn));
        }

        return resumen;
    }

    @Override
    public List<Map<String, Object>> obtenerReporteVentas(
            String fechaInicio,
            String fechaFin) throws Exception {

        List<Map<String, Object>> lista = new ArrayList<>();
        StringBuilder sql = new StringBuilder("""
                SELECT v.venta_id, v.solped_id, c.nombre AS cliente,
                       COALESCE(p.nombre, 'Sin proyecto') AS proyecto,
                       v.fecha_venta, v.subtotal, v.impuesto, v.total, v.estado
                FROM ventas v
                INNER JOIN clientes c ON v.cliente_id = c.cliente_id
                LEFT JOIN proyectos p ON v.proyecto_id = p.proyecto_id
                WHERE 1=1
                """);

        boolean tieneInicio = fechaInicio != null && !fechaInicio.isBlank();
        boolean tieneFin = fechaFin != null && !fechaFin.isBlank();

        if (tieneInicio) {
            sql.append(" AND DATE(v.fecha_venta) >= ?");
        }
        if (tieneFin) {
            sql.append(" AND DATE(v.fecha_venta) <= ?");
        }
        sql.append(" ORDER BY v.fecha_venta DESC, v.venta_id DESC");

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            int idx = 1;
            if (tieneInicio) {
                ps.setString(idx++, fechaInicio.trim());
            }
            if (tieneFin) {
                ps.setString(idx, fechaFin.trim());
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> fila = new LinkedHashMap<>();
                    fila.put("ventaId", rs.getInt("venta_id"));
                    fila.put("solpedId", rs.getInt("solped_id"));
                    fila.put("cliente", rs.getString("cliente"));
                    fila.put("proyecto", rs.getString("proyecto"));
                    fila.put("fechaVenta", rs.getTimestamp("fecha_venta"));
                    fila.put("subtotal", rs.getBigDecimal("subtotal"));
                    fila.put("impuesto", rs.getBigDecimal("impuesto"));
                    fila.put("total", rs.getBigDecimal("total"));
                    fila.put("estado", rs.getString("estado"));
                    lista.add(fila);
                }
            }
        }
        return lista;
    }

    @Override
    public List<Map<String, Object>> obtenerReporteProyectos() throws Exception {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = """
                SELECT p.proyecto_id, p.nombre, c.nombre AS cliente,
                       p.fecha_inicio, p.fecha_fin, p.estado
                FROM proyectos p
                INNER JOIN clientes c ON p.cliente_id = c.cliente_id
                ORDER BY p.proyecto_id DESC
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> fila = new LinkedHashMap<>();
                fila.put("proyectoId", rs.getInt("proyecto_id"));
                fila.put("nombre", rs.getString("nombre"));
                fila.put("cliente", rs.getString("cliente"));
                fila.put("fechaInicio", rs.getDate("fecha_inicio"));
                fila.put("fechaFin", rs.getDate("fecha_fin"));
                fila.put("estado", rs.getString("estado"));
                lista.add(fila);
            }
        }
        return lista;
    }

    @Override
    public List<Map<String, Object>> obtenerReporteClientes() throws Exception {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = """
                SELECT c.cliente_id, c.nombre, c.documento, c.correo,
                       c.telefono, c.estado,
                       COUNT(DISTINCT p.proyecto_id) AS total_proyectos,
                       COALESCE(SUM(CASE WHEN v.estado <> 'anulada' THEN v.total ELSE 0 END), 0) AS total_ventas
                FROM clientes c
                LEFT JOIN proyectos p ON c.cliente_id = p.cliente_id
                LEFT JOIN ventas v ON c.cliente_id = v.cliente_id
                GROUP BY c.cliente_id, c.nombre, c.documento, c.correo, c.telefono, c.estado
                ORDER BY total_ventas DESC, c.cliente_id DESC
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> fila = new LinkedHashMap<>();
                fila.put("clienteId", rs.getInt("cliente_id"));
                fila.put("nombre", rs.getString("nombre"));
                fila.put("documento", rs.getString("documento"));
                fila.put("correo", rs.getString("correo"));
                fila.put("telefono", rs.getString("telefono"));
                fila.put("estado", rs.getString("estado"));
                fila.put("totalProyectos", rs.getInt("total_proyectos"));
                fila.put("totalVentas", rs.getBigDecimal("total_ventas"));
                lista.add(fila);
            }
        }
        return lista;
    }

    @Override
    public List<Map<String, Object>> obtenerReporteSolped() throws Exception {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = """
                SELECT s.solped_id, c.nombre AS cliente,
                       COALESCE(p.nombre, 'Sin proyecto') AS proyecto,
                       CONCAT(u.nombres, ' ', u.apellidos) AS responsable,
                       s.fecha_solicitud, s.estado,
                       COALESCE(SUM(d.subtotal), 0) AS monto_estimado
                FROM solped s
                INNER JOIN clientes c ON s.cliente_id = c.cliente_id
                LEFT JOIN proyectos p ON s.proyecto_id = p.proyecto_id
                INNER JOIN usuarios u ON s.usuario_id = u.id
                LEFT JOIN solped_detalle d ON s.solped_id = d.solped_id
                GROUP BY s.solped_id, c.nombre, proyecto, responsable, s.fecha_solicitud, s.estado
                ORDER BY s.fecha_solicitud DESC, s.solped_id DESC
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> fila = new LinkedHashMap<>();
                fila.put("solpedId", rs.getInt("solped_id"));
                fila.put("cliente", rs.getString("cliente"));
                fila.put("proyecto", rs.getString("proyecto"));
                fila.put("responsable", rs.getString("responsable"));
                fila.put("fechaSolicitud", rs.getTimestamp("fecha_solicitud"));
                fila.put("estado", rs.getString("estado"));
                fila.put("montoEstimado", rs.getBigDecimal("monto_estimado"));
                lista.add(fila);
            }
        }
        return lista;
    }

    @Override
    public List<Map<String, Object>> obtenerReporteUsuarios() throws Exception {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = """
                SELECT id, nombres, apellidos, correo, rol_id, estado, intentos_fallidos
                FROM usuarios
                ORDER BY id DESC
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> fila = new LinkedHashMap<>();
                fila.put("id", rs.getInt("id"));
                fila.put("nombres", rs.getString("nombres"));
                fila.put("apellidos", rs.getString("apellidos"));
                fila.put("correo", rs.getString("correo"));
                fila.put("rolId", rs.getInt("rol_id"));
                fila.put("estado", rs.getString("estado"));
                fila.put("intentosFallidos", rs.getInt("intentos_fallidos"));
                lista.add(fila);
            }
        }
        return lista;
    }

    private List<Map<String, Object>> consultarAgrupado(
            Connection conn,
            String sql) throws SQLException {

        List<Map<String, Object>> resultado = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("etiqueta", rs.getString("etiqueta"));
                item.put("total", rs.getInt("total"));
                resultado.add(item);
            }
        }
        return resultado;
    }

    private List<Map<String, Object>> consultarVentasPorMes(
            Connection conn) throws SQLException {

        List<Map<String, Object>> resultado = new ArrayList<>();
        String sql = """
                SELECT DATE_FORMAT(fecha_venta, '%Y-%m') AS mes,
                       COUNT(*) AS cantidad,
                       COALESCE(SUM(total), 0) AS monto
                FROM ventas
                WHERE estado <> 'anulada'
                GROUP BY DATE_FORMAT(fecha_venta, '%Y-%m')
                ORDER BY mes ASC
                LIMIT 12
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("mes", rs.getString("mes"));
                item.put("cantidad", rs.getInt("cantidad"));
                BigDecimal monto = rs.getBigDecimal("monto");
                item.put("monto", monto != null ? monto : BigDecimal.ZERO);
                resultado.add(item);
            }
        }
        return resultado;
    }

    private List<Map<String, Object>> consultarTopClientes(
            Connection conn) throws SQLException {

        List<Map<String, Object>> resultado = new ArrayList<>();
        String sql = """
                SELECT c.nombre AS cliente,
                       COALESCE(SUM(v.total), 0) AS monto
                FROM ventas v
                INNER JOIN clientes c ON v.cliente_id = c.cliente_id
                WHERE v.estado <> 'anulada'
                GROUP BY c.cliente_id, c.nombre
                ORDER BY monto DESC
                LIMIT 6
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("cliente", rs.getString("cliente"));
                BigDecimal monto = rs.getBigDecimal("monto");
                item.put("monto", monto != null ? monto : BigDecimal.ZERO);
                resultado.add(item);
            }
        }
        return resultado;
    }

    private Map<String, Object> consultarClienteMasRecurrente(
            Connection conn) throws SQLException {

        String sql = """
                SELECT c.cliente_id,
                       c.nombre,
                       c.documento,
                       c.correo,
                       COUNT(DISTINCT v.venta_id) AS total_ventas,
                       COUNT(DISTINCT p.proyecto_id) AS total_proyectos,
                       COUNT(DISTINCT s.solped_id) AS total_solped,
                       COALESCE((
                           SELECT SUM(v2.total)
                           FROM ventas v2
                           WHERE v2.cliente_id = c.cliente_id
                             AND v2.estado <> 'anulada'
                       ), 0) AS monto_facturado
                FROM clientes c
                LEFT JOIN ventas v
                       ON c.cliente_id = v.cliente_id
                      AND v.estado <> 'anulada'
                LEFT JOIN proyectos p
                       ON c.cliente_id = p.cliente_id
                LEFT JOIN solped s
                       ON c.cliente_id = s.cliente_id
                GROUP BY c.cliente_id, c.nombre, c.documento, c.correo
                HAVING (COUNT(DISTINCT v.venta_id)
                      + COUNT(DISTINCT p.proyecto_id)
                      + COUNT(DISTINCT s.solped_id)) > 0
                ORDER BY total_ventas DESC,
                         total_proyectos DESC,
                         total_solped DESC,
                         monto_facturado DESC
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                Map<String, Object> cliente = new LinkedHashMap<>();
                cliente.put("clienteId", rs.getInt("cliente_id"));
                cliente.put("nombre", rs.getString("nombre"));
                cliente.put("documento", rs.getString("documento"));
                cliente.put("correo", rs.getString("correo"));
                cliente.put("totalVentas", rs.getInt("total_ventas"));
                cliente.put("totalProyectos", rs.getInt("total_proyectos"));
                cliente.put("totalSolped", rs.getInt("total_solped"));
                BigDecimal monto = rs.getBigDecimal("monto_facturado");
                cliente.put("montoFacturado", monto != null ? monto : BigDecimal.ZERO);
                return cliente;
            }
        }
        return null;
    }
}
