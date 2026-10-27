
package pe.lumyn.portal.repository;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import pe.lumyn.portal.config.ConexionBD;
import pe.lumyn.portal.model.Proyecto;

public class ProyectoRepositoryImpl implements ProyectoRepository {

    @Override
    public List<Proyecto> listarTodos() throws Exception {
        List<Proyecto> proyectos = new ArrayList<>();

        String sql = """
            SELECT proyecto_id, cliente_id, nombre, descripcion,
                   fecha_inicio, fecha_fin, estado, fecha_registro
            FROM proyectos
            ORDER BY proyecto_id DESC
        """;

        try (Connection con = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                proyectos.add(mapearProyecto(rs));
            }
        }

        return proyectos;
    }

    @Override
    public Proyecto buscarPorId(int proyectoId) throws Exception {
        String sql = """
            SELECT proyecto_id, cliente_id, nombre, descripcion,
                   fecha_inicio, fecha_fin, estado, fecha_registro
            FROM proyectos
            WHERE proyecto_id = ?
        """;

        try (Connection con = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, proyectoId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapearProyecto(rs);
                }
            }
        }

        return null;
    }

    @Override
    public boolean guardar(Proyecto proyecto) throws Exception {
        String sql = """
            INSERT INTO proyectos
                (cliente_id, nombre, descripcion, fecha_inicio,
                 fecha_fin, estado)
            VALUES (?, ?, ?, ?, ?, ?)
        """;

        try (Connection con = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, proyecto.getClienteId());
            ps.setString(2, proyecto.getNombre());
            ps.setString(3, proyecto.getDescripcion());
            ps.setDate(4, proyecto.getFechaInicio());
            ps.setDate(5, proyecto.getFechaFin());
            ps.setString(6, normalizarEstado(proyecto.getEstado()));

            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean actualizar(Proyecto proyecto) throws Exception {
        String sql = """
            UPDATE proyectos
            SET cliente_id = ?, nombre = ?, descripcion = ?,
                fecha_inicio = ?, fecha_fin = ?, estado = ?
            WHERE proyecto_id = ?
        """;

        try (Connection con = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, proyecto.getClienteId());
            ps.setString(2, proyecto.getNombre());
            ps.setString(3, proyecto.getDescripcion());
            ps.setDate(4, proyecto.getFechaInicio());
            ps.setDate(5, proyecto.getFechaFin());
            ps.setString(6, normalizarEstado(proyecto.getEstado()));
            ps.setInt(7, proyecto.getProyectoId());

            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean cambiarEstado(int proyectoId, String estado)
            throws Exception {

        String sql = """
            UPDATE proyectos
            SET estado = ?
            WHERE proyecto_id = ?
        """;

        try (Connection con = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, normalizarEstado(estado));
            ps.setInt(2, proyectoId);

            return ps.executeUpdate() > 0;
        }
    }

    private Proyecto mapearProyecto(ResultSet rs) throws Exception {
        Proyecto proyecto = new Proyecto();

        proyecto.setProyectoId(rs.getInt("proyecto_id"));
        proyecto.setClienteId(rs.getInt("cliente_id"));
        proyecto.setNombre(rs.getString("nombre"));
        proyecto.setDescripcion(rs.getString("descripcion"));
        proyecto.setFechaInicio(rs.getDate("fecha_inicio"));
        proyecto.setFechaFin(rs.getDate("fecha_fin"));
        proyecto.setEstado(rs.getString("estado"));
        proyecto.setFechaRegistro(rs.getTimestamp("fecha_registro"));

        return proyecto;
    }

    private String normalizarEstado(String estado) {
        if (estado == null || estado.isBlank()) {
            return "planificado";
        }

        return estado;
    }
}
