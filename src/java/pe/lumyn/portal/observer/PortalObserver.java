package pe.lumyn.portal.observer;

/**
 * Contrato para los observadores que reaccionan ante eventos del portal LUMYN.
 */
public interface PortalObserver {

    void actualizar(PortalEvent evento);
}
