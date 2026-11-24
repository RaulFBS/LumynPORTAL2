package pe.lumyn.portal.model;

import java.sql.Timestamp;

public class Entregable {

    private int entregableId;
    private int proyectoId;
    private Integer usuarioId;
    private String titulo;
    private String descripcion;
    private String version;
    private String urlArchivo;
    private String estado;
    private Timestamp fechaRegistro;
    private String nombreProyecto;
    private String nombreResponsable;
    private String ultimaObservacion;

    public int getEntregableId() { return entregableId; }
    public void setEntregableId(int entregableId) { this.entregableId = entregableId; }

    public int getProyectoId() { return proyectoId; }
    public void setProyectoId(int proyectoId) { this.proyectoId = proyectoId; }

    public Integer getUsuarioId() { return usuarioId; }
    public void setUsuarioId(Integer usuarioId) { this.usuarioId = usuarioId; }

    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }

    public String getUrlArchivo() { return urlArchivo; }
    public void setUrlArchivo(String urlArchivo) { this.urlArchivo = urlArchivo; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    public Timestamp getFechaRegistro() { return fechaRegistro; }
    public void setFechaRegistro(Timestamp fechaRegistro) { this.fechaRegistro = fechaRegistro; }

    public String getNombreProyecto() { return nombreProyecto; }
    public void setNombreProyecto(String nombreProyecto) { this.nombreProyecto = nombreProyecto; }

    public String getNombreResponsable() { return nombreResponsable; }
    public void setNombreResponsable(String nombreResponsable) { this.nombreResponsable = nombreResponsable; }

    public String getUltimaObservacion() { return ultimaObservacion; }
    public void setUltimaObservacion(String ultimaObservacion) { this.ultimaObservacion = ultimaObservacion; }
}
