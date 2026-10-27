
package pe.lumyn.portal.model;

import java.math.BigDecimal;

public class SolpedDetalle {

    private int solpedDetalleId;
    private int solpedId;
    private String servicio;
    private String descripcion;
    private BigDecimal cantidad;
    private BigDecimal precioUnitario;
    private BigDecimal subtotal;

    public int getSolpedDetalleId() {
        return solpedDetalleId;
    }

    public void setSolpedDetalleId(int solpedDetalleId) {
        this.solpedDetalleId = solpedDetalleId;
    }

    public int getSolpedId() {
        return solpedId;
    }

    public void setSolpedId(int solpedId) {
        this.solpedId = solpedId;
    }

    public String getServicio() {
        return servicio;
    }

    public void setServicio(String servicio) {
        this.servicio = servicio;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public BigDecimal getCantidad() {
        return cantidad;
    }

    public void setCantidad(BigDecimal cantidad) {
        this.cantidad = cantidad;
    }

    public BigDecimal getPrecioUnitario() {
        return precioUnitario;
    }

    public void setPrecioUnitario(BigDecimal precioUnitario) {
        this.precioUnitario = precioUnitario;
    }

    public BigDecimal getSubtotal() {
        return subtotal;
    }

    public void setSubtotal(BigDecimal subtotal) {
        this.subtotal = subtotal;
    }
}
