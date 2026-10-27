package pe.lumyn.portal.repository;

import pe.lumyn.portal.dao.UsuarioDAO;
import pe.lumyn.portal.model.Usuario;
import java.util.List;

public class UsuarioRepositoryImpl implements UsuarioRepository {

    private final UsuarioDAO usuarioDAO;

    public UsuarioRepositoryImpl() {
        this.usuarioDAO = new UsuarioDAO();
    }

    @Override
    public Usuario buscarPorCorreo(String correo) throws Exception {
        return usuarioDAO.buscarPorCorreo(correo);
    }

    @Override
    public List<Usuario> listarTodos() throws Exception {
        return usuarioDAO.listarTodos();
    }

    @Override
    public int contarTodos() throws Exception {
        return usuarioDAO.contarTodos();
    }

    @Override
    public int contarPorEstado(String estado) throws Exception {
        return usuarioDAO.contarPorEstado(estado);
    }

    @Override
    public int contarAdministradoresActivos() throws Exception {
        return usuarioDAO.contarAdministradoresActivos();
    }

    @Override
    public boolean existeCorreo(String correo, int idExcluir)
            throws Exception {
        return usuarioDAO.existeCorreo(correo, idExcluir);
    }

    @Override
    public boolean registrar(Usuario usuario, String password)
            throws Exception {
        return usuarioDAO.registrar(usuario, password);
    }

    @Override
    public boolean actualizar(Usuario usuario) throws Exception {
        return usuarioDAO.actualizar(usuario);
    }

    @Override
    public boolean cambiarEstado(int idUsuario, String estado)
            throws Exception {
        return usuarioDAO.cambiarEstado(idUsuario, estado);
    }

    @Override
    public boolean registrarIntentoFallido(int idUsuario)
            throws Exception {
        usuarioDAO.registrarIntentoFallido(idUsuario);
        return true;
    }

    @Override
    public boolean reiniciarIntentos(int idUsuario)
            throws Exception {
        usuarioDAO.reiniciarIntentos(idUsuario);
        return true;
    }

    @Override
    public boolean desactivarAdministradorSiHayOtroActivo(int idUsuario)
            throws Exception {
        return usuarioDAO.desactivarAdministradorSiHayOtroActivo(idUsuario);
    }
}
