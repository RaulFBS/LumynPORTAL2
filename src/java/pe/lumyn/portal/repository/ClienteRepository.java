package pe.lumyn.portal.repository;

import pe.lumyn.portal.model.Cliente;

import java.util.List;

public interface ClienteRepository {

    List<Cliente> listarTodos() throws Exception;

    Cliente buscarPorId(int clienteId) throws Exception;

    boolean guardar(Cliente cliente) throws Exception;

    boolean actualizar(Cliente cliente) throws Exception;

    boolean cambiarEstado(int clienteId, String estado) throws Exception;
}