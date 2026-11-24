package pe.lumyn.portal.repository;

import pe.lumyn.portal.config.ConexionBD;
import pe.lumyn.portal.model.Entregable;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class EntregableRepositoryImpl implements EntregableRepository {

    @Override
    public List<Entregable> listarTodos() throws Exception {
        List<Entregable> lista = new ArrayList<>();
        String sql = """
                SELECT e.entregable_id, e.proyecto_id, e.usuario_id, e.titulo, e.descripcion,
                       e.version, e.url_archivo, e.estado, e.fecha_registro,
                       p.nombre AS nombre_proyecto,
                       COALESCE(CONCAT(u.nombres, ' ', u.apellidos), 'Sin asignar') AS nombre_responsable,
                       (SELECT o.comentario FROM entregable_observaciones o
                        WHERE o.entregable_id = e.entregable_id
                        ORDER BY o.observacion_id DESC LIMIT 1) AS ultima_observacion
                FROM entregables e
                INNER JOIN proyectos p ON e.proyecto_id = p.proyecto_id
                LEFT JOIN usuarios u ON e.usuario_id = u.id
                ORDER BY e.entregable_id DESC
                """;
        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Entregable e = new Entregable();
                e.setEntregableId(rs.getInt("entregable_id"));
                e.setProyectoId(rs.getInt("proyecto_id"));
                int uid = rs.getInt("usuario_id");
                e.setUsuarioId(rs.wasNull() ? null : uid);
                e.setTitulo(rs.getString("titulo"));
                e.setDescripcion(rs.getString("descripcion"));
                e.setVersion(rs.getString("version"));
                e.setUrlArchivo(rs.getString("url_archivo"));
                e.setEstado(rs.getString("estado"));
                e.setFechaRegistro(rs.getTimestamp("fecha_registro"));
                e.setNombreProyecto(rs.getString("nombre_proyecto"));
                e.setNombreResponsable(rs.getString("nombre_responsable"));
                e.setUltimaObservacion(rs.getString("ultima_observacion"));
                lista.add(e);
            }
        }
        return lista;
    }

    @Override
    public boolean registrar(Entregable entregable) throws Exception {
        if (entregable == null || entregable.getTitulo() == null || entregable.getTitulo().isBlank()) {
            throw new IllegalArgumentException("El título del entregable es obligatorio.");
        }
        String sql = """
                INSERT INTO entregables (proyecto_id, usuario_id, titulo, descripcion, version, url_archivo, estado)
                VALUES (?, ?, ?, ?, ?, ?, 'pendiente')
                """;
        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, entregable.getProyectoId());
            if (entregable.getUsuarioId() == null) {
                ps.setNull(2, Types.INTEGER);
            } else {
                ps.setInt(2, entregable.getUsuarioId());
            }
            ps.setString(3, entregable.getTitulo().trim());
            ps.setString(4, entregable.getDescripcion() != null ? entregable.getDescripcion().trim() : null);
            ps.setString(5, entregable.getVersion() != null && !entregable.getVersion().isBlank()
                    ? entregable.getVersion().trim() : "v1.0");
            ps.setString(6, entregable.getUrlArchivo() != null ? entregable.getUrlArchivo().trim() : null);
            return ps.executeUpdate() == 1;
        }
    }

    @Override
    public boolean revisar(int entregableId, int usuarioId, String estado, String observacion) throws Exception {
        if (!"aprobado".equals(estado) && !"observado".equals(estado)) {
            throw new IllegalArgumentException("Estado de revisión no permitido.");
        }
        try (Connection conn = ConexionBD.getInstancia().conectar()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE entregables SET estado = ? WHERE entregable_id = ?")) {
                    ps.setString(1, estado);
                    ps.setInt(2, entregableId);
                    if (ps.executeUpdate() != 1) {
                        conn.rollback();
                        return false;
                    }
                }
                if (observacion != null && !observacion.isBlank()) {
                    try (PreparedStatement psObs = conn.prepareStatement(
                            "INSERT INTO entregable_observaciones (entregable_id, usuario_id, comentario) VALUES (?, ?, ?)")) {
                        psObs.setInt(1, entregableId);
                        psObs.setInt(2, usuarioId);
                        psObs.setString(3, observacion.trim());
                        psObs.executeUpdate();
                    }
                }
                conn.commit();
                return true;
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            }
        }
    }

    @Override
    public List<Map<String, Object>> listarObservaciones() throws Exception {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = """
                SELECT o.observacion_id, e.titulo AS entregable, p.nombre AS proyecto,
                       CONCAT(u.nombres, ' ', u.apellidos) AS revisor,
                       o.comentario, o.fecha_registro, e.estado
                FROM entregable_observaciones o
                INNER JOIN entregables e ON o.entregable_id = e.entregable_id
                INNER JOIN proyectos p ON e.proyecto_id = p.proyecto_id
                LEFT JOIN usuarios u ON o.usuario_id = u.id
                ORDER BY o.observacion_id DESC
                """;
        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> fila = new LinkedHashMap<>();
                fila.put("observacionId", rs.getInt("observacion_id"));
                fila.put("entregable", rs.getString("entregable"));
                fila.put("proyecto", rs.getString("proyecto"));
                fila.put("revisor", rs.getString("revisor"));
                fila.put("comentario", rs.getString("comentario"));
                fila.put("fechaRegistro", rs.getTimestamp("fecha_registro"));
                fila.put("estado", rs.getString("estado"));
                lista.add(fila);
            }
        }
        return lista;
    }
}
