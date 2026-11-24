package pe.lumyn.portal.observer;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Deque;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedDeque;
import java.util.logging.Logger;

/**
 * Observador encargado de registrar una traza de auditoría por cada evento emitido.
 */
public class AuditoriaLogObserver implements PortalObserver {

    private static final Logger LOGGER =
            Logger.getLogger(AuditoriaLogObserver.class.getName());
    private static final int MAX_HISTORIAL = 100;
    private static final Deque<PortalEvent> HISTORIAL = new ConcurrentLinkedDeque<>();

    @Override
    public void actualizar(PortalEvent evento) {
        HISTORIAL.addFirst(evento);
        while (HISTORIAL.size() > MAX_HISTORIAL) {
            HISTORIAL.removeLast();
        }
        LOGGER.info(String.format(
                "[AUDITORIA] tipo=%s entidadId=%d usuarioId=%s detalle=%s",
                evento.getTipo(),
                evento.getEntidadId(),
                evento.getUsuarioId(),
                evento.getDetalle()
        ));
    }

    public static List<PortalEvent> obtenerHistorialReciente() {
        return Collections.unmodifiableList(new ArrayList<>(HISTORIAL));
    }
}
