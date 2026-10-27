
package pe.lumyn.portal.repository;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import pe.lumyn.portal.config.ConexionBD;

public class DashboardRepositoryImpl implements DashboardRepository {

    @Override
    public Map<String, Object> obtenerEstadisticas() throws Exception {

        Map<String, Object> estadisticas = new LinkedHashMap<>();

        String sqlClientes =
                "SELECT COUNT(*) AS total FROM clientes";

        String sqlProyectos =
                "SELECT COUNT(*) AS total FROM proyectos";

        String sqlEstados =
                "SELECT estado, COUNT(*) AS total " +
                "FROM proyectos GROUP BY estado";

        String sqlSolped =
                "SELECT estado, COUNT(*) AS total " +
                "FROM solped GROUP BY estado";

        String sqlTotalSolped =
                "SELECT COUNT(*) AS total FROM solped";

        String sqlVentas =
                "SELECT COUNT(*) AS total, " +
                "COALESCE(SUM(total), 0) AS importe " +
                "FROM ventas " +
                "WHERE estado <> 'anulada'";

        try (Connection conexion =
                     ConexionBD.getInstancia().conectar()) {

            try (PreparedStatement ps =
                         conexion.prepareStatement(sqlClientes);
                 ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    estadisticas.put(
                            "totalClientes", rs.getInt("total"));
                }
            }

            try (PreparedStatement ps =
                         conexion.prepareStatement(sqlProyectos);
                 ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    estadisticas.put(
                            "totalProyectos", rs.getInt("total"));
                }
            }

            try (PreparedStatement ps =
                         conexion.prepareStatement(sqlEstados);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    String estado = rs.getString("estado");

                    estadisticas.put(
                            "proyectos_" + estado,
                            rs.getInt("total"));
                }
            }

            try (PreparedStatement ps =
                         conexion.prepareStatement(sqlTotalSolped);
                 ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    estadisticas.put(
                            "totalSolped", rs.getInt("total"));
                }
            }

            try (PreparedStatement ps =
                         conexion.prepareStatement(sqlSolped);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    String estado = rs.getString("estado");

                    estadisticas.put(
                            "solped_" + estado,
                            rs.getInt("total"));
                }
            }

            try (PreparedStatement ps =
                         conexion.prepareStatement(sqlVentas);
                 ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    estadisticas.put(
                            "totalVentas", rs.getInt("total"));

                    estadisticas.put(
                            "importeVentas", rs.getBigDecimal("importe"));
                }
            }
        }

        // Valores por defecto para evitar indicadores vacíos.
        estadisticas.putIfAbsent("totalClientes", 0);
        estadisticas.putIfAbsent("totalProyectos", 0);
        estadisticas.putIfAbsent("totalSolped", 0);
        estadisticas.putIfAbsent("totalVentas", 0);
        estadisticas.putIfAbsent("importeVentas", BigDecimal.ZERO);

        for (String estado : new String[]{
            "planificado", "en_progreso", "completado", "cancelado"
        }) {
            estadisticas.putIfAbsent("proyectos_" + estado, 0);
        }

        for (String estado : new String[]{
            "pendiente", "en_revision", "aprobada",
            "rechazada", "convertida"
        }) {
            estadisticas.putIfAbsent("solped_" + estado, 0);
        }

        return estadisticas;
    }

    @Override
    public List<Map<String, Object>> obtenerProyectosRecientes()
            throws Exception {

        List<Map<String, Object>> proyectos = new ArrayList<>();

        String sql =
                "SELECT p.proyecto_id, p.nombre, p.estado, " +
                "p.fecha_inicio, c.nombre AS nombre_cliente " +
                "FROM proyectos p " +
                "INNER JOIN clientes c " +
                "ON p.cliente_id = c.cliente_id " +
                "ORDER BY p.fecha_registro DESC, p.proyecto_id DESC " +
                "LIMIT 5";

        try (Connection conexion =
                     ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> proyecto = new LinkedHashMap<>();

                proyecto.put("proyectoId", rs.getInt("proyecto_id"));
                proyecto.put("nombre", rs.getString("nombre"));
                proyecto.put("estado", rs.getString("estado"));
                proyecto.put("fechaInicio", rs.getDate("fecha_inicio"));
                proyecto.put("nombreCliente",
                        rs.getString("nombre_cliente"));

                proyectos.add(proyecto);
            }
        }

        return proyectos;
    }

    @Override
    public List<Map<String, Object>> obtenerSolpedRecientes()
            throws Exception {

        List<Map<String, Object>> solicitudes = new ArrayList<>();

        String sql =
                "SELECT s.solped_id, s.descripcion_requerimiento, " +
                "s.fecha_solicitud, s.estado, c.nombre AS nombre_cliente, " +
                "COALESCE(SUM(d.subtotal), 0) AS importe " +
                "FROM solped s " +
                "INNER JOIN clientes c ON s.cliente_id = c.cliente_id " +
                "LEFT JOIN solped_detalle d ON s.solped_id = d.solped_id " +
                "GROUP BY s.solped_id, s.descripcion_requerimiento, " +
                "s.fecha_solicitud, s.estado, c.nombre " +
                "ORDER BY s.fecha_solicitud DESC, s.solped_id DESC " +
                "LIMIT 5";

        try (Connection conexion =
                     ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> solicitud = new LinkedHashMap<>();

                solicitud.put("solpedId", rs.getInt("solped_id"));
                solicitud.put(
                        "descripcion",
                        rs.getString("descripcion_requerimiento"));
                solicitud.put(
                        "fecha", rs.getTimestamp("fecha_solicitud"));
                solicitud.put("estado", rs.getString("estado"));
                solicitud.put(
                        "nombreCliente", rs.getString("nombre_cliente"));
                solicitud.put("importe", rs.getBigDecimal("importe"));

                solicitudes.add(solicitud);
            }
        }

        return solicitudes;
    }

    @Override
    public List<Map<String, Object>> obtenerVentasRecientes()
            throws Exception {

        List<Map<String, Object>> ventas = new ArrayList<>();

        String sql =
                "SELECT v.venta_id, v.fecha_venta, v.estado, " +
                "v.total, c.nombre AS nombre_cliente " +
                "FROM ventas v " +
                "INNER JOIN clientes c ON v.cliente_id = c.cliente_id " +
                "ORDER BY v.fecha_venta DESC, v.venta_id DESC " +
                "LIMIT 5";

        try (Connection conexion =
                     ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conexion.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> venta = new LinkedHashMap<>();

                venta.put("ventaId", rs.getInt("venta_id"));
                venta.put("fecha", rs.getTimestamp("fecha_venta"));
                venta.put("estado", rs.getString("estado"));
                venta.put("total", rs.getBigDecimal("total"));
                venta.put(
                        "nombreCliente", rs.getString("nombre_cliente"));

                ventas.add(venta);
            }
        }

        return ventas;
    }
}
