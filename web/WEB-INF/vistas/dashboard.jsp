
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.List"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Date"%>
<%@page import="java.math.BigDecimal"%>
<%@page import="java.util.Locale"%>

<%
    Map<String, Object> estadisticas =
            (Map<String, Object>) request.getAttribute("estadisticas");

    List<Map<String, Object>> proyectos =
            (List<Map<String, Object>>) request.getAttribute("proyectos");

    List<Map<String, Object>> solpedRecientes =
            (List<Map<String, Object>>) request.getAttribute("solpedRecientes");

    List<Map<String, Object>> ventasRecientes =
            (List<Map<String, Object>>) request.getAttribute("ventasRecientes");

    String nombreUsuario =
            (String) request.getAttribute("nombreUsuario");

    String nombreRol =
            (String) request.getAttribute("nombreRol");

    Integer rolId =
            (Integer) request.getAttribute("rolId");

    String contexto = request.getContextPath();

    int totalClientes = estadisticas != null
            && estadisticas.get("totalClientes") != null
            ? ((Number) estadisticas.get("totalClientes")).intValue() : 0;

    int totalProyectos = estadisticas != null
            && estadisticas.get("totalProyectos") != null
            ? ((Number) estadisticas.get("totalProyectos")).intValue() : 0;

    int planificados = estadisticas != null
            && estadisticas.get("proyectos_planificado") != null
            ? ((Number) estadisticas.get("proyectos_planificado")).intValue() : 0;

    int enProgreso = estadisticas != null
            && estadisticas.get("proyectos_en_progreso") != null
            ? ((Number) estadisticas.get("proyectos_en_progreso")).intValue() : 0;

    int completados = estadisticas != null
            && estadisticas.get("proyectos_completado") != null
            ? ((Number) estadisticas.get("proyectos_completado")).intValue() : 0;

    int cancelados = estadisticas != null
            && estadisticas.get("proyectos_cancelado") != null
            ? ((Number) estadisticas.get("proyectos_cancelado")).intValue() : 0;

    int totalSolped = estadisticas != null
            && estadisticas.get("totalSolped") != null
            ? ((Number) estadisticas.get("totalSolped")).intValue() : 0;

    int solpedPendientes = estadisticas != null
            && estadisticas.get("solped_pendiente") != null
            ? ((Number) estadisticas.get("solped_pendiente")).intValue() : 0;

    int totalVentas = estadisticas != null
            && estadisticas.get("totalVentas") != null
            ? ((Number) estadisticas.get("totalVentas")).intValue() : 0;

    BigDecimal importeVentas = estadisticas != null
            && estadisticas.get("importeVentas") != null
            ? (BigDecimal) estadisticas.get("importeVentas")
            : BigDecimal.ZERO;

    boolean puedeGestionar = rolId != null && (rolId == 1 || rolId == 2);

    String iniciales = "LU";

    if (nombreUsuario != null && !nombreUsuario.trim().isEmpty()) {
        String[] palabras = nombreUsuario.trim().split("\\s+");
        iniciales = palabras[0].substring(0, 1).toUpperCase();

        if (palabras.length > 1) {
            iniciales += palabras[1].substring(0, 1).toUpperCase();
        }
    }

    String fechaActual = new SimpleDateFormat(
            "d 'de' MMMM 'de' yyyy", new Locale("es", "PE")
    ).format(new Date());

    SimpleDateFormat formatoFecha = new SimpleDateFormat("dd/MM/yyyy");

    java.text.NumberFormat formatoMoneda =
            java.text.NumberFormat.getCurrencyInstance(new Locale("es", "PE"));

    formatoMoneda.setCurrency(java.util.Currency.getInstance("PEN"));

    String simboloMoneda = "S/";
%>

<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Panel principal | LUMYN</title>
        <link rel="stylesheet" href="<%= contexto%>/css/styles.css">
    </head>

    <body>
        <div class="app-layout">

            <aside class="sidebar">
                <a href="<%= contexto%>/dashboard" class="sidebar-logo">
                    LUM<span>Y</span>N
                </a>

                <div class="sidebar-label">Principal</div>

                <nav>
                    <a href="<%= contexto%>/dashboard" class="nav-link active">
                        <span class="nav-icon">▦</span>
                        Panel principal
                    </a>

                    <% if (rolId == 1) {%>
                    <a href="<%= contexto%>/usuarios" class="nav-link">
                        <span class="nav-icon">♙</span>
                        Usuarios y roles
                    </a>

                    <a href="<%= contexto%>/seguridad" class="nav-link">
                        <span class="nav-icon">◇</span>
                        Seguridad
                    </a>
                    <% } %>

                    <% if (rolId == 1 || rolId == 2) {%>
                    <a href="<%= contexto%>/clientes" class="nav-link">
                        <span class="nav-icon">♧</span>
                        Clientes
                    </a>
                    <% } %>

                    <% if (rolId == 1 || rolId == 2 || rolId == 4) {%>
                    <a href="<%= contexto%>/proyectos" class="nav-link">
                        <span class="nav-icon">▣</span>
                        Proyectos
                    </a>
                    <% } %>

                    <% if (rolId == 1 || rolId == 2) {%>
                    <a href="<%= contexto%>/solped" class="nav-link">
                        <span class="nav-icon">▤</span>
                        SOLPED / Cotizaciones
                    </a>

                    <a href="<%= contexto%>/ventas" class="nav-link">
                        <span class="nav-icon">S/</span>
                        Ventas
                    </a>
                    <% } %>

                    <% if (rolId == 1 || rolId == 2 || rolId == 3) {%>
                    <a href="<%= contexto%>/tareas" class="nav-link">
                        <span class="nav-icon">☷</span>
                        <%= rolId == 3 ? "Mis tareas" : "Tareas"%>
                    </a>
                    <% } %>

                    <% if (rolId == 1 || rolId == 2 || rolId == 3 || rolId == 4) {%>
                    <a href="<%= contexto%>/entregables" class="nav-link">
                        <span class="nav-icon">▤</span>
                        <%= rolId == 4 ? "Revisión de entregables" : "Entregables"%>
                    </a>
                    <% } %>

                    <% if (rolId == 1 || rolId == 2) {%>
                    <a href="<%= contexto%>/reportes" class="nav-link">
                        <span class="nav-icon">▥</span>
                        Reportes
                    </a>
                    <% } %>

                    <% if (rolId == 3) {%>
                    <a href="<%= contexto%>/notificaciones" class="nav-link">
                        <span class="nav-icon">♧</span>
                        Notificaciones
                    </a>
                    <% } %>

                    <% if (rolId == 4) {%>
                    <a href="<%= contexto%>/observaciones" class="nav-link">
                        <span class="nav-icon">☷</span>
                        Observaciones
                    </a>
                    <% }%>
                </nav>

                <div class="sidebar-bottom">
                    <div class="user-mini">
                        <div class="avatar"><%= iniciales%></div>
                        <div>
                            <strong><%= nombreUsuario%></strong>
                            <small><%= nombreRol%></small>
                        </div>
                    </div>

                    <a href="<%= contexto%>/logout" class="nav-link">
                        <span class="nav-icon">↪</span>
                        Cerrar sesión
                    </a>
                </div>
            </aside>

            <main class="main-area">
                <header class="topbar">
                    <div class="breadcrumb">
                        LUMYN / <strong>Panel principal</strong>
                    </div>

                    <div class="topbar-right">
                        <span class="date-label"><%= fechaActual%></span>
                        <div class="avatar"><%= iniciales%></div>
                    </div>
                </header>

                <section class="content">

                    <div class="page-heading">
                        <div>
                            <div class="welcome-tag">Espacio de trabajo LUMYN</div>
                            <h1>Hola, <%= nombreUsuario%>.</h1>
                            <p>Resumen general de clientes, proyectos, pedidos y ventas.</p>
                        </div>

                        <% if (puedeGestionar) {%>
                        <div style="display:flex; gap:10px; flex-wrap:wrap;">
                            <a href="<%= contexto%>/proyectos" class="btn btn-outline">
                                Ver proyectos
                            </a>

                            <a href="<%= contexto%>/solped" class="btn btn-outline">
                                Ver SOLPED
                            </a>

                            <a href="<%= contexto%>/ventas" class="btn btn-primary">
                                Ver ventas
                            </a>
                        </div>
                        <% }%>
                    </div>

                    <!-- Indicadores principales -->
                    <div class="grid-stats">

                        <div class="stat-card">
                            <div class="stat-symbol">♧</div>
                            <div class="stat-title">Clientes</div>
                            <div class="stat-value"><%= totalClientes%></div>
                            <div class="stat-foot">Registros en la base de datos</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-symbol">▣</div>
                            <div class="stat-title">Proyectos</div>
                            <div class="stat-value"><%= totalProyectos%></div>
                            <div class="stat-foot">Proyectos registrados</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-symbol">▤</div>
                            <div class="stat-title">Pedidos / SOLPED</div>
                            <div class="stat-value"><%= totalSolped%></div>
                            <div class="stat-foot"><%= solpedPendientes%> pendientes de atención</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-symbol">S/</div>
                            <div class="stat-title">Ventas registradas</div>
                            <div class="stat-value"><%= totalVentas%></div>
                            <div class="stat-foot">
                                Importe: <%= simboloMoneda%>
                                <%= String.format(Locale.US, "%,.2f", importeVentas)%>
                            </div>
                        </div>

                    </div>

                    <!-- Segunda fila: estados de proyectos -->
                    <div class="grid-stats">

                        <div class="stat-card">
                            <div class="stat-symbol">↗</div>
                            <div class="stat-title">En progreso</div>
                            <div class="stat-value"><%= enProgreso%></div>
                            <div class="stat-foot">Proyectos en ejecución</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-symbol">✓</div>
                            <div class="stat-title">Completados</div>
                            <div class="stat-value"><%= completados%></div>
                            <div class="stat-foot">Proyectos finalizados</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-symbol">◷</div>
                            <div class="stat-title">Planificados</div>
                            <div class="stat-value"><%= planificados%></div>
                            <div class="stat-foot">Pendientes de ejecución</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-symbol">×</div>
                            <div class="stat-title">Cancelados</div>
                            <div class="stat-value"><%= cancelados%></div>
                            <div class="stat-foot">Proyectos cancelados</div>
                        </div>

                    </div>

                    <!-- Proyectos y resumen de estados -->
                    <div class="dashboard-grid">

                        <section class="card">
                            <div class="card-heading">
                                <h3>Proyectos recientes</h3>
                                <% if (puedeGestionar) {%>
                                <a href="<%= contexto%>/proyectos">Ver todos →</a>
                                <% } %>
                            </div>

                            <% if (proyectos == null || proyectos.isEmpty()) { %>
                            <div class="empty-state">
                                <p>No hay proyectos registrados todavía.</p>
                            </div>
                            <% } else { %>

                            <% for (Map<String, Object> proyecto : proyectos) {
                                    String estado = String.valueOf(proyecto.get("estado"));
                                    String claseBadge = "badge-gray";

                                    if ("completado".equals(estado)) {
                                        claseBadge = "badge-green";
                                    } else if ("en_progreso".equals(estado)) {
                                        claseBadge = "badge-yellow";
                                    } else if ("cancelado".equals(estado)) {
                                        claseBadge = "badge-red";
                                    }

                                    Object fechaInicio = proyecto.get("fechaInicio");
                            %>

                            <div class="project-item">
                                <div class="project-info">
                                    <div>
                                        <strong><%= proyecto.get("nombre")%></strong>
                                        <p>Cliente: <%= proyecto.get("nombreCliente")%></p>
                                    </div>

                                    <span class="badge <%= claseBadge%>">
                                        <%= estado.replace("_", " ").toUpperCase()%>
                                    </span>
                                </div>

                                <p class="stat-foot">
                                    Inicio: <%= fechaInicio != null ? fechaInicio : "Sin fecha"%>
                                </p>
                            </div>

                            <% } %>
                            <% }%>
                        </section>

                        <section class="card">
                            <div class="card-heading">
                                <h3>Resumen de estados</h3>
                            </div>

                            <div class="project-item">
                                <div class="project-info">
                                    <strong>Planificados</strong>
                                    <span class="badge badge-gray"><%= planificados%></span>
                                </div>
                            </div>

                            <div class="project-item">
                                <div class="project-info">
                                    <strong>En progreso</strong>
                                    <span class="badge badge-yellow"><%= enProgreso%></span>
                                </div>
                            </div>

                            <div class="project-item">
                                <div class="project-info">
                                    <strong>Completados</strong>
                                    <span class="badge badge-green"><%= completados%></span>
                                </div>
                            </div>

                            <div class="project-item">
                                <div class="project-info">
                                    <strong>Cancelados</strong>
                                    <span class="badge badge-red"><%= cancelados%></span>
                                </div>
                            </div>
                        </section>

                    </div>

                    <% if (puedeGestionar) { %>

                    <!-- Pedidos recientes -->
                    <section class="card" style="margin-top:20px;">
                        <div class="card-heading">
                            <h3>Pedidos / SOLPED recientes</h3>
                            <a href="<%= contexto%>/solped">Ver todas →</a>
                        </div>

                        <% if (solpedRecientes == null || solpedRecientes.isEmpty()) { %>
                        <div class="empty-state">
                            <p>No hay pedidos registrados todavía.</p>
                        </div>
                        <% } else { %>

                        <div class="table-scroll">
                            <table>
                                <thead>
                                    <tr>
                                        <th>N.º</th>
                                        <th>Cliente</th>
                                        <th>Requerimiento</th>
                                        <th>Fecha</th>
                                        <th>Importe</th>
                                        <th>Estado</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Map<String, Object> solicitud : solpedRecientes) {
                                            String estado = String.valueOf(solicitud.get("estado"));
                                            String claseBadge = "badge-gray";

                                            if ("aprobada".equals(estado) || "convertida".equals(estado)) {
                                                claseBadge = "badge-green";
                                            } else if ("pendiente".equals(estado) || "en_revision".equals(estado)) {
                                                claseBadge = "badge-yellow";
                                            } else if ("rechazada".equals(estado)) {
                                                claseBadge = "badge-red";
                                            }

                                            Object fecha = solicitud.get("fecha");
                                            BigDecimal importe = solicitud.get("importe") instanceof BigDecimal
                                                    ? (BigDecimal) solicitud.get("importe")
                                                    : BigDecimal.ZERO;
                                    %>
                                    <tr>
                                        <td>#<%= solicitud.get("solpedId")%></td>
                                        <td><%= solicitud.get("nombreCliente")%></td>
                                        <td><%= solicitud.get("descripcion")%></td>
                                        <td><%= fecha != null ? formatoFecha.format(fecha) : "—"%></td>
                                        <td><%= simboloMoneda%> <%= String.format(Locale.US, "%,.2f", importe)%></td>
                                        <td>
                                            <span class="badge <%= claseBadge%>">
                                                <%= estado.replace("_", " ").toUpperCase()%>
                                            </span>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                        <% } %>
                    </section>

                    <!-- Ventas recientes -->
                    <section class="card" style="margin-top:20px;">
                        <div class="card-heading">
                            <h3>Ventas recientes</h3>
                            <a href="<%= contexto%>/ventas">Ver todas →</a>
                        </div>

                        <% if (ventasRecientes == null || ventasRecientes.isEmpty()) { %>
                        <div class="empty-state">
                            <p>No hay ventas registradas todavía.</p>
                        </div>
                        <% } else { %>

                        <div class="table-scroll">
                            <table>
                                <thead>
                                    <tr>
                                        <th>N.º venta</th>
                                        <th>Cliente</th>
                                        <th>Fecha</th>
                                        <th>Total</th>
                                        <th>Estado</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Map<String, Object> venta : ventasRecientes) {
                                            String estado = String.valueOf(venta.get("estado"));
                                            String claseBadge = "badge-gray";

                                            if ("confirmada".equals(estado) || "completada".equals(estado)) {
                                                claseBadge = "badge-green";
                                            } else if ("pendiente".equals(estado) || "en_proceso".equals(estado)) {
                                                claseBadge = "badge-yellow";
                                            } else if ("anulada".equals(estado)) {
                                                claseBadge = "badge-red";
                                            }

                                            Object fecha = venta.get("fecha");
                                            BigDecimal total = venta.get("total") instanceof BigDecimal
                                                    ? (BigDecimal) venta.get("total")
                                                    : BigDecimal.ZERO;
                                    %>
                                    <tr>
                                        <td>#<%= venta.get("ventaId")%></td>
                                        <td><%= venta.get("nombreCliente")%></td>
                                        <td><%= fecha != null ? formatoFecha.format(fecha) : "—"%></td>
                                        <td><%= simboloMoneda%> <%= String.format(Locale.US, "%,.2f", total)%></td>
                                        <td>
                                            <span class="badge <%= claseBadge%>">
                                                <%= estado.replace("_", " ").toUpperCase()%>
                                            </span>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                        <% } %>
                    </section>

                    <% } %>

                </section>
            </main>
        </div>
    </body>
</html>
