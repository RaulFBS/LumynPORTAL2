
package pe.lumyn.portal.model;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class Solped {

    private int solpedId;
    private int clienteId;
    private Integer usuarioId;
    private Timestamp fechaSolicitud;
    private String descripcionRequerimiento;
    private String estado;
    private List<SolpedDetalle> detalles = new ArrayList<>();
    private Integer proyectoId;
    public Integer getProyectoId() {
    return proyectoId;
}

public void setProyectoId(Integer proyectoId) {
    this.proyectoId = proyectoId;
}

    public int getSolpedId() {
        return solpedId;
    }

    public void setSolpedId(int solpedId) {
        this.solpedId = solpedId;
    }

    public int getClienteId() {
        return clienteId;
    }

    public void setClienteId(int clienteId) {
        this.clienteId = clienteId;
    }

    public Integer getUsuarioId() {
        return usuarioId;
    }

    public void setUsuarioId(Integer usuarioId) {
        this.usuarioId = usuarioId;
    }

    public Timestamp getFechaSolicitud() {
        return fechaSolicitud;
    }

    public void setFechaSolicitud(Timestamp fechaSolicitud) {
        this.fechaSolicitud = fechaSolicitud;
    }

    public String getDescripcionRequerimiento() {
        return descripcionRequerimiento;
    }

    public void setDescripcionRequerimiento(
            String descripcionRequerimiento) {
        this.descripcionRequerimiento = descripcionRequerimiento;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public List<SolpedDetalle> getDetalles() {
        return detalles;
    }

    public void setDetalles(List<SolpedDetalle> detalles) {
        this.detalles = detalles;
    }
}
