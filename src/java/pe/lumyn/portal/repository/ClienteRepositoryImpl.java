package pe.lumyn.portal.repository;

import pe.lumyn.portal.config.ConexionBD;
import pe.lumyn.portal.model.Cliente;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class ClienteRepositoryImpl implements ClienteRepository {

    @Override
    public List<Cliente> listarTodos() throws Exception {

        List<Cliente> clientes = new ArrayList<>();

        String sql = """
                SELECT cliente_id, nombre, documento, correo,
                       telefono, direccion, estado, fecha_registro
                FROM clientes
                ORDER BY cliente_id DESC
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Cliente cliente = new Cliente();

                cliente.setClienteId(rs.getInt("cliente_id"));
                cliente.setNombre(rs.getString("nombre"));
                cliente.setDocumento(rs.getString("documento"));
                cliente.setCorreo(rs.getString("correo"));
                cliente.setTelefono(rs.getString("telefono"));
                cliente.setDireccion(rs.getString("direccion"));
                cliente.setEstado(rs.getString("estado"));
                cliente.setFechaRegistro(
                        rs.getTimestamp("fecha_registro")
                );

                clientes.add(cliente);
            }
        }

        return clientes;
    }

    @Override
    public Cliente buscarPorId(int clienteId) throws Exception {

        String sql = """
                SELECT cliente_id, nombre, documento, correo,
                       telefono, direccion, estado, fecha_registro
                FROM clientes
                WHERE cliente_id = ?
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, clienteId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    Cliente cliente = new Cliente();

                    cliente.setClienteId(
                            rs.getInt("cliente_id")
                    );
                    cliente.setNombre(
                            rs.getString("nombre")
                    );
                    cliente.setDocumento(
                            rs.getString("documento")
                    );
                    cliente.setCorreo(
                            rs.getString("correo")
                    );
                    cliente.setTelefono(
                            rs.getString("telefono")
                    );
                    cliente.setDireccion(
                            rs.getString("direccion")
                    );
                    cliente.setEstado(
                            rs.getString("estado")
                    );
                    cliente.setFechaRegistro(
                            rs.getTimestamp("fecha_registro")
                    );

                    return cliente;
                }
            }
        }

        return null;
    }

    @Override
    public boolean guardar(Cliente cliente) throws Exception {
        if (cliente.getEstado() == null
        || cliente.getEstado().isBlank()) {
    cliente.setEstado("activo");
}

        String sql = """
                INSERT INTO clientes
                (nombre, documento, correo, telefono, direccion, estado)
                VALUES (?, ?, ?, ?, ?, ?)
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, cliente.getNombre());
            ps.setString(2, cliente.getDocumento());
            ps.setString(3, cliente.getCorreo());
            ps.setString(4, cliente.getTelefono());
            ps.setString(5, cliente.getDireccion());
            ps.setString(6, cliente.getEstado());

            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean actualizar(Cliente cliente) throws Exception {

        String sql = """
                UPDATE clientes
                SET nombre = ?,
                    documento = ?,
                    correo = ?,
                    telefono = ?,
                    direccion = ?,
                    estado = ?
                WHERE cliente_id = ?
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, cliente.getNombre());
            ps.setString(2, cliente.getDocumento());
            ps.setString(3, cliente.getCorreo());
            ps.setString(4, cliente.getTelefono());
            ps.setString(5, cliente.getDireccion());
            ps.setString(6, cliente.getEstado());
            ps.setInt(7, cliente.getClienteId());

            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean cambiarEstado(int clienteId, String estado)
            throws Exception {

        String sql = """
                UPDATE clientes
                SET estado = ?
                WHERE cliente_id = ?
                """;

        try (Connection conn = ConexionBD.getInstancia().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, estado);
            ps.setInt(2, clienteId);

            return ps.executeUpdate() > 0;
        }
    }
}