package pe.lumyn.portal.observer;

import java.time.LocalDateTime;

/**
 * Evento de dominio emitido por el sistema para notificar a los observadores suscritos.
 */
public class PortalEvent {

    private final String tipo;
    private final int entidadId;
    private final Integer usuarioId;
    private final String detalle;
    private final LocalDateTime fechaHora;

    public PortalEvent(String tipo, int entidadId, Integer usuarioId, String detalle) {
        this.tipo = tipo;
        this.entidadId = entidadId;
        this.usuarioId = usuarioId;
        this.detalle = detalle;
        this.fechaHora = LocalDateTime.now();
    }

    public String getTipo() {
        return tipo;
    }

    public int getEntidadId() {
        return entidadId;
    }

    public Integer getUsuarioId() {
        return usuarioId;
    }

    public String getDetalle() {
        return detalle;
    }

    public LocalDateTime getFechaHora() {
        return fechaHora;
    }
}
