
package pe.lumyn.portal.repository;

import pe.lumyn.portal.model.Usuario;
import java.util.List;

public interface UsuarioRepository {

    // Consultas
    Usuario buscarPorCorreo(String correo) throws Exception;

    List<Usuario> listarTodos() throws Exception;

    int contarTodos() throws Exception;

    int contarPorEstado(String estado) throws Exception;

    int contarAdministradoresActivos() throws Exception;

    boolean existeCorreo(String correo, int idExcluir) throws Exception;

    // Registro y actualización
    boolean registrar(Usuario usuario, String password) throws Exception;

    boolean actualizar(Usuario usuario) throws Exception;

    boolean cambiarEstado(int idUsuario, String estado) throws Exception;

    // Seguridad del inicio de sesión
    boolean registrarIntentoFallido(int idUsuario) throws Exception;

    boolean reiniciarIntentos(int idUsuario) throws Exception;
    boolean desactivarAdministradorSiHayOtroActivo(int idUsuario)
        throws Exception;
}
