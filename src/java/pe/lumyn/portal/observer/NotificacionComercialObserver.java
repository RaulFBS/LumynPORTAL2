package pe.lumyn.portal.observer;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Deque;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedDeque;
import java.util.logging.Logger;

/**
 * Observador que genera alertas internas ante eventos del flujo comercial (SOLPED y Ventas).
 */
public class NotificacionComercialObserver implements PortalObserver {

    private static final Logger LOGGER =
            Logger.getLogger(NotificacionComercialObserver.class.getName());
    private static final int MAX_ALERTAS = 50;
    private static final Deque<String> ALERTAS = new ConcurrentLinkedDeque<>();

    @Override
    public void actualizar(PortalEvent evento) {
        String tipo = evento.getTipo();
        if (tipo == null || (!tipo.startsWith("SOLPED_") && !tipo.startsWith("VENTA_"))) {
            return;
        }

        String mensaje = String.format(
                "[%s] #%d - %s",
                tipo,
                evento.getEntidadId(),
                evento.getDetalle()
        );

        ALERTAS.addFirst(mensaje);
        while (ALERTAS.size() > MAX_ALERTAS) {
            ALERTAS.removeLast();
        }
        LOGGER.info("[NOTIFICACION_COMERCIAL] " + mensaje);
    }

    public static List<String> obtenerAlertasRecientes() {
        return Collections.unmodifiableList(new ArrayList<>(ALERTAS));
    }
}
