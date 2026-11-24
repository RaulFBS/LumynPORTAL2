package pe.lumyn.portal.config;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Gestor Singleton de conexiones JDBC con pool ligero integrado.
 * Reutiliza conexiones físicas hacia MySQL/Aiven para evitar el overhead
 * de handshakes TCP/TLS en cada petición HTTP sin requerir dependencias externas.
 */
public class ConexionBD {

    private static final int DEFAULT_MAX_POOL_SIZE = 8;
    private static final long ACQUIRE_TIMEOUT_SECONDS = 10L;
    private static final long VALIDATION_INTERVAL_MS = 30_000L;
    private static final long MAX_IDLE_MS = 4 * 60_000L;
    private static final long MAX_LIFETIME_MS = 20 * 60_000L;

    private static ConexionBD instancia;

    private final int maxPoolSize;
    private final BlockingQueue<PooledConnection> pool;
    private final Semaphore permisos;
    private volatile boolean driverCargado = false;

    private static final class PooledConnection {
        final Connection raw;
        final long createdAt;
        volatile long lastUsedAt;

        PooledConnection(Connection raw) {
            this.raw = raw;
            long now = System.currentTimeMillis();
            this.createdAt = now;
            this.lastUsedAt = now;
        }
    }

    private ConexionBD() {
        this.maxPoolSize = resolverMaxPoolSize();
        this.pool = new LinkedBlockingQueue<>(this.maxPoolSize);
        this.permisos = new Semaphore(this.maxPoolSize, true);

        Runtime.getRuntime().addShutdownHook(
                new Thread(this::cerrarPool, "lumyn-db-pool-shutdown")
        );
    }

    public static synchronized ConexionBD getInstancia() {
        if (instancia == null) {
            instancia = new ConexionBD();
        }
        return instancia;
    }

    public Connection conectar() throws SQLException {
        asegurarDriverCargado();

        boolean adquirido;
        try {
            adquirido = permisos.tryAcquire(
                    ACQUIRE_TIMEOUT_SECONDS, TimeUnit.SECONDS
            );
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new SQLException(
                    "Interrupción al esperar una conexión disponible del pool.", e
            );
        }

        if (!adquirido) {
            throw new SQLException(
                    "Tiempo de espera agotado al obtener una conexión del pool (máx="
                            + maxPoolSize + ")."
            );
        }

        try {
            PooledConnection entry = obtenerConexionValidaDelPool();
            if (entry == null) {
                entry = new PooledConnection(crearConexionFisica());
            }
            return envolverComoProxy(entry);
        } catch (SQLException | RuntimeException e) {
            permisos.release();
            throw e;
        }
    }

    /**
     * Cierra todas las conexiones inactivas almacenadas en el pool.
     */
    public void cerrarPool() {
        PooledConnection entry;
        while ((entry = pool.poll()) != null) {
            cerrarFisicamente(entry.raw);
        }
    }

    private PooledConnection obtenerConexionValidaDelPool() {
        long ahora = System.currentTimeMillis();
        PooledConnection entry;

        while ((entry = pool.poll()) != null) {
            boolean expirada = (ahora - entry.createdAt) > MAX_LIFETIME_MS
                    || (ahora - entry.lastUsedAt) > MAX_IDLE_MS;

            if (expirada) {
                cerrarFisicamente(entry.raw);
                continue;
            }

            if (estaSaludable(entry, ahora)) {
                return entry;
            }

            cerrarFisicamente(entry.raw);
        }

        return null;
    }

    private boolean estaSaludable(PooledConnection entry, long ahora) {
        try {
            if (entry.raw.isClosed()) {
                return false;
            }
            if ((ahora - entry.lastUsedAt) >= VALIDATION_INTERVAL_MS) {
                return entry.raw.isValid(2);
            }
            return true;
        } catch (SQLException e) {
            return false;
        }
    }

    private Connection envolverComoProxy(PooledConnection entry) {
        InvocationHandler handler = new PooledConnectionHandler(entry);
        return (Connection) Proxy.newProxyInstance(
                Connection.class.getClassLoader(),
                new Class<?>[]{Connection.class},
                handler
        );
    }

    private void devolverAlPool(PooledConnection entry) {
        boolean devuelta = false;
        try {
            if (entry.raw != null && !entry.raw.isClosed()) {
                if (!entry.raw.getAutoCommit()) {
                    try {
                        entry.raw.rollback();
                    } catch (SQLException ignored) {
                        // Si falla rollback, se cerrará la conexión física.
                    }
                    entry.raw.setAutoCommit(true);
                }
                entry.lastUsedAt = System.currentTimeMillis();
                devuelta = pool.offer(entry);
            }
        } catch (SQLException e) {
            devuelta = false;
        } finally {
            if (!devuelta) {
                cerrarFisicamente(entry.raw);
            }
            permisos.release();
        }
    }

    private void cerrarFisicamente(Connection raw) {
        if (raw == null) {
            return;
        }
        try {
            if (!raw.isClosed()) {
                raw.close();
            }
        } catch (SQLException ignored) {
            // Cierre defensivo de conexión descartada.
        }
    }

    private void asegurarDriverCargado() throws SQLException {
        if (driverCargado) {
            return;
        }
        synchronized (this) {
            if (driverCargado) {
                return;
            }
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                DriverManager.setLoginTimeout(10);
                driverCargado = true;
            } catch (ClassNotFoundException e) {
                throw new SQLException(
                        "No se encontro el controlador JDBC de MySQL.", e
                );
            }
        }
    }

    private Connection crearConexionFisica() throws SQLException {
        String url = System.getenv("DB_URL");
        String usuario = System.getenv("DB_USER");
        String password = System.getenv("DB_PASSWORD");

        // Valores locales para desarrollo.
        if (url == null || url.isBlank()) {
            url = "jdbc:mysql://localhost:3306/lumyn_portal"
                    + "?useSSL=false&serverTimezone=UTC";
        }

        if (usuario == null || usuario.isBlank()) {
            usuario = "root";
        }

        if (password == null) {
            password = "";
        }

        return DriverManager.getConnection(url, usuario, password);
    }

    private static int resolverMaxPoolSize() {
        String env = System.getenv("DB_POOL_MAX");
        if (env != null && !env.isBlank()) {
            try {
                int parsed = Integer.parseInt(env.trim());
                if (parsed >= 1 && parsed <= 30) {
                    return parsed;
                }
            } catch (NumberFormatException ignored) {
                // Usar valor por defecto.
            }
        }
        return DEFAULT_MAX_POOL_SIZE;
    }

    private final class PooledConnectionHandler implements InvocationHandler {
        private final PooledConnection entry;
        private final AtomicBoolean cerrada = new AtomicBoolean(false);

        PooledConnectionHandler(PooledConnection entry) {
            this.entry = entry;
        }

        @Override
        public Object invoke(Object proxy, Method method, Object[] args)
                throws Throwable {
            String nombre = method.getName();

            if ("close".equals(nombre)) {
                if (cerrada.compareAndSet(false, true)) {
                    devolverAlPool(entry);
                }
                return null;
            }

            if ("isClosed".equals(nombre)) {
                return cerrada.get() || entry.raw.isClosed();
            }

            if ("equals".equals(nombre)) {
                return proxy == args[0];
            }

            if ("hashCode".equals(nombre)) {
                return System.identityHashCode(proxy);
            }

            if ("toString".equals(nombre)) {
                return "PooledConnectionProxy[" + entry.raw + "]";
            }

            if (cerrada.get()) {
                throw new SQLException("La conexión ya fue devuelta al pool.");
            }

            try {
                return method.invoke(entry.raw, args);
            } catch (InvocationTargetException e) {
                throw e.getTargetException();
            }
        }
    }
}
