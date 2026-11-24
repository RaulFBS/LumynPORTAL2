package pe.lumyn.portal.repository;

import pe.lumyn.portal.config.ConexionBD;
import pe.lumyn.portal.model.Tarea;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class TareaRepositoryImpl implements TareaRepository {

    private static final String SELECT_BASE = """
            SELECT t.tarea_id, t.proyecto_id, t.usuario_id, t.titulo, t.descripcion,
                   t.prioridad, t.avance, t.fecha_limite, t.estado, t.fecha_registro,
                   p.nombre AS nombre_proyecto,
                   COALESCE(CONCAT(u.nombres, ' ', u.apellidos), 'Sin asignar') AS nombre_responsable
            FROM tareas t
            INNER JOIN proyectos p ON t.proyecto_id = p.proyecto_id
            LEFT JOIN usuarios u ON t.usuario_id = u.id
            """;

    @Override
    public List<Tarea> listarTodas() throws Exception {
        return consultarLista(SELECT_BASE + " ORDER BY t.tarea_id DESC", null);
    }

    @Override
    public List<Tarea> listarPorUsuario(int usuarioId) throws Exception {
        return consultarLista(
                SELECT_BASE + " WHERE t.usuario_id = ? ORDER BY t.tarea_id DESC",
                usuarioId
        );
    }

    @Override
    public boolean registrar(Tarea tarea) throws Exception {
        if (tarea == null || tarea.getTitulo() == null || tarea.getTitulo().isBlank()) {
            throw new IllegalArgumentException("El título de la tarea es obligatorio.");
        }
        String sql = """
                INSERT INTO tareas (proyecto_id, usuario_id, titulo, descripcion, prioridad, avance, fecha_limite, estado)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """;
        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, tarea.getProyectoId());
            if (tarea.getUsuarioId() == null) {
                ps.setNull(2, Types.INTEGER);
            } else {
                ps.setInt(2, tarea.getUsuarioId());
            }
            ps.setString(3, tarea.getTitulo().trim());
            ps.setString(4, tarea.getDescripcion() != null ? tarea.getDescripcion().trim() : null);
            ps.setString(5, tarea.getPrioridad() != null ? tarea.getPrioridad() : "media");
            ps.setInt(6, Math.max(0, Math.min(100, tarea.getAvance())));
            if (tarea.getFechaLimite() == null) {
                ps.setNull(7, Types.DATE);
            } else {
                ps.setDate(7, tarea.getFechaLimite());
            }
            ps.setString(8, tarea.getEstado() != null ? tarea.getEstado() : "pendiente");
            return ps.executeUpdate() == 1;
        }
    }

    @Override
    public boolean actualizarAvance(int tareaId, int avance, String estado) throws Exception {
        if (avance < 0 || avance > 100) {
            throw new IllegalArgumentException("El avance debe estar entre 0 y 100.");
        }
        String estadoFinal = avance == 100 ? "completada" : estado;
        String sql = "UPDATE tareas SET avance = ?, estado = ? WHERE tarea_id = ?";
        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, avance);
            ps.setString(2, estadoFinal);
            ps.setInt(3, tareaId);
            return ps.executeUpdate() == 1;
        }
    }

    private List<Tarea> consultarLista(String sql, Integer usuarioId) throws Exception {
        List<Tarea> lista = new ArrayList<>();
        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (usuarioId != null) {
                ps.setInt(1, usuarioId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Tarea t = new Tarea();
                    t.setTareaId(rs.getInt("tarea_id"));
                    t.setProyectoId(rs.getInt("proyecto_id"));
                    int uid = rs.getInt("usuario_id");
                    t.setUsuarioId(rs.wasNull() ? null : uid);
                    t.setTitulo(rs.getString("titulo"));
                    t.setDescripcion(rs.getString("descripcion"));
                    t.setPrioridad(rs.getString("prioridad"));
                    t.setAvance(rs.getInt("avance"));
                    t.setFechaLimite(rs.getDate("fecha_limite"));
                    t.setEstado(rs.getString("estado"));
                    t.setFechaRegistro(rs.getTimestamp("fecha_registro"));
                    t.setNombreProyecto(rs.getString("nombre_proyecto"));
                    t.setNombreResponsable(rs.getString("nombre_responsable"));
                    lista.add(t);
                }
            }
        }
        return lista;
    }
}
