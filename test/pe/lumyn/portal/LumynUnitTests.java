package pe.lumyn.portal;

import pe.lumyn.portal.config.ConexionBD;
import pe.lumyn.portal.observer.AuditoriaLogObserver;
import pe.lumyn.portal.observer.NotificacionComercialObserver;
import pe.lumyn.portal.observer.PortalEvent;
import pe.lumyn.portal.observer.PortalEventManager;
import pe.lumyn.portal.observer.PortalObserver;
import pe.lumyn.portal.security.PasswordUtil;

import java.util.concurrent.atomic.AtomicInteger;

/**
 * Suite de pruebas unitarias de verificación para seguridad, Singleton y Observer.
 * Ejecutable directamente con `java` sin dependencias externas de testing.
 */
public class LumynUnitTests {

    private static int pruebasEjecutadas = 0;
    private static int pruebasExitosas = 0;

    public static void main(String[] args) {
        ejecutar("testSingletonConexionBD", LumynUnitTests::testSingletonConexionBD);
        ejecutar("testPasswordUtilHashYVerificacion", LumynUnitTests::testPasswordUtilHashYVerificacion);
        ejecutar("testObserverNotificacionYSuscripcion", LumynUnitTests::testObserverNotificacionYSuscripcion);

        System.out.printf("Resumen: %d/%d pruebas unitarias exitosas.%n",
                pruebasExitosas, pruebasEjecutadas);

        if (pruebasExitosas != pruebasEjecutadas) {
            System.exit(1);
        }
    }

    private static void ejecutar(String nombre, Runnable prueba) {
        pruebasEjecutadas++;
        try {
            prueba.run();
            pruebasExitosas++;
            System.out.println("[PASS] " + nombre);
        } catch (Throwable t) {
            System.err.println("[FAIL] " + nombre + ": " + t.getMessage());
        }
    }

    private static void assertTrue(boolean condicion, String mensaje) {
        if (!condicion) {
            throw new AssertionError(mensaje);
        }
    }

    public static void testSingletonConexionBD() {
        ConexionBD instancia1 = ConexionBD.getInstancia();
        ConexionBD instancia2 = ConexionBD.getInstancia();
        assertTrue(instancia1 != null, "La instancia de ConexionBD no debe ser nula.");
        assertTrue(instancia1 == instancia2, "ConexionBD debe retornar siempre la misma instancia Singleton.");
    }

    public static void testPasswordUtilHashYVerificacion() {
        String clavePlano = "LumynSegura2026!";
        String hash = PasswordUtil.encriptar(clavePlano);

        assertTrue(hash != null && !hash.equals(clavePlano), "La contraseña debe almacenarse encriptada.");
        assertTrue(PasswordUtil.verificar(clavePlano, hash), "La contraseña correcta debe validarse.");
        assertTrue(!PasswordUtil.verificar("Incorrecta123", hash), "Una contraseña incorrecta debe rechazarse.");
        assertTrue(!PasswordUtil.verificar(null, hash), "Una contraseña nula debe rechazarse.");
    }

    public static void testObserverNotificacionYSuscripcion() {
        PortalEventManager manager = PortalEventManager.getInstancia();
        AtomicInteger contador = new AtomicInteger(0);
        PortalObserver customObserver = evento -> {
            if ("SOLPED_APROBADA".equals(evento.getTipo()) && evento.getEntidadId() == 999) {
                contador.incrementAndGet();
            }
        };

        manager.suscribir(customObserver);
        try {
            manager.notificar(new PortalEvent("SOLPED_APROBADA", 999, 1, "Prueba unitaria Observer"));
            assertTrue(contador.get() == 1, "El observador suscrito debe recibir exactamente 1 notificación.");
            assertTrue(!AuditoriaLogObserver.obtenerHistorialReciente().isEmpty(),
                    "AuditoriaLogObserver debe registrar el evento.");
            assertTrue(!NotificacionComercialObserver.obtenerAlertasRecientes().isEmpty(),
                    "NotificacionComercialObserver debe registrar la alerta comercial.");
        } finally {
            manager.desuscribir(customObserver);
        }
    }
}
