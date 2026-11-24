package pe.lumyn.portal.observer;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Sujeto central (Subject) del patrón Observer para eventos operativos y comerciales.
 */
public class PortalEventManager {

    private static PortalEventManager instancia;
    private final List<PortalObserver> observadores = new CopyOnWriteArrayList<>();

    private PortalEventManager() {
        observadores.add(new AuditoriaLogObserver());
        observadores.add(new NotificacionComercialObserver());
    }

    public static synchronized PortalEventManager getInstancia() {
        if (instancia == null) {
            instancia = new PortalEventManager();
        }
        return instancia;
    }

    public void suscribir(PortalObserver observador) {
        if (observador != null && !observadores.contains(observador)) {
            observadores.add(observador);
        }
    }

    public void desuscribir(PortalObserver observador) {
        observadores.remove(observador);
    }

    public void notificar(PortalEvent evento) {
        if (evento == null) {
            return;
        }
        for (PortalObserver observador : observadores) {
            observador.actualizar(evento);
        }
    }

    public int cantidadObservadores() {
        return observadores.size();
    }
}
