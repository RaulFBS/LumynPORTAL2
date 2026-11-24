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
        cargarNotificacionesIniciales();
    }

    private void cargarNotificacionesIniciales() {
        notificar(new PortalEvent("PROYECTO_ACTUALIZADO", 101, 1,
                "Proyecto 'Campaña Q4 Horizonte Sur' pasó a estado en_progreso."));
        notificar(new PortalEvent("TAREA_COMPLETADA", 204, 3,
                "Tarea 'Diseño de piezas digitales' marcada como completada."));
        notificar(new PortalEvent("ENTREGABLE_SUBIDO", 308, 3,
                "Nuevo entregable cargado para revisión: Propuesta_Final_v2.pdf."));
        notificar(new PortalEvent("SOLPED_APROBADA", 11, 2,
                "SOLPED aprobada para Marisquería E.I.R.L. (S/ 2,250.00)."));
        notificar(new PortalEvent("SOLPED_CREADA", 12, 2,
                "Nueva solicitud SOLPED registrada para Horizonte Sur S.A.C. (S/ 4,500.00)."));
        notificar(new PortalEvent("VENTA_REGISTRADA", 8, 2,
                "Venta facturada por S/ 7,850.00 vinculada al proyecto Horizonte Sur."));
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
