
package pe.lumyn.portal.model;

public class Usuario {

    private int id;
    private String nombres;
    private String apellidos;
    private String correo;
    private String passwordHash;
    private int rolId;
    private String estado;
    private int intentosFallidos;
    private String bloqueadoHasta;

    public Usuario() {
    }

    public Usuario(int id, String nombres, String apellidos,
                   String correo, String passwordHash,
                   int rolId, String estado,
                   int intentosFallidos, String bloqueadoHasta) {
        this.id = id;
        this.nombres = nombres;
        this.apellidos = apellidos;
        this.correo = correo;
        this.passwordHash = passwordHash;
        this.rolId = rolId;
        this.estado = estado;
        this.intentosFallidos = intentosFallidos;
        this.bloqueadoHasta = bloqueadoHasta;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getNombres() {
        return nombres;
    }

    public void setNombres(String nombres) {
        this.nombres = nombres;
    }

    public String getApellidos() {
        return apellidos;
    }

    public void setApellidos(String apellidos) {
        this.apellidos = apellidos;
    }

    public String getCorreo() {
        return correo;
    }

    public void setCorreo(String correo) {
        this.correo = correo;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public int getRolId() {
        return rolId;
    }

    public void setRolId(int rolId) {
        this.rolId = rolId;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public int getIntentosFallidos() {
        return intentosFallidos;
    }

    public void setIntentosFallidos(int intentosFallidos) {
        this.intentosFallidos = intentosFallidos;
    }

    public String getBloqueadoHasta() {
        return bloqueadoHasta;
    }

    public void setBloqueadoHasta(String bloqueadoHasta) {
        this.bloqueadoHasta = bloqueadoHasta;
    }
}
