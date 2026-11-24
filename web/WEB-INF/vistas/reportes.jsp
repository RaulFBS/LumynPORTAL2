<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="java.math.BigDecimal"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="pe.lumyn.portal.observer.PortalEvent"%>
<%!
    private String esc(Object val) {
        if (val == null) return "";
        return String.valueOf(val)
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private String escJs(Object val) {
        if (val == null) return "";
        return String.valueOf(val)
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", " ")
                .replace("\r", " ");
    }
%>
<%
    String contexto = request.getContextPath();
    String nombreUsuario = (String) request.getAttribute("nombreUsuario");
    if (nombreUsuario == null || nombreUsuario.isBlank()) {
        nombreUsuario = "Usuario Lumyn";
    }
    Integer rolId = request.getAttribute("rolId") instanceof Number
            ? ((Number) request.getAttribute("rolId")).intValue() : 0;
    String rolNombre;
    switch (rolId) {
        case 1: rolNombre = "Administrador"; break;
        case 2: rolNombre = "Gestor"; break;
        case 3: rolNombre = "Colaborador"; break;
        case 4: rolNombre = "Revisor"; break;
        default: rolNombre = "Usuario"; break;
    }
    String[] partesNombre = nombreUsuario.trim().split("\\s+");
    String iniciales = partesNombre.length >= 2
            ? (partesNombre[0].substring(0, 1) + partesNombre[partesNombre.length - 1].substring(0, 1)).toUpperCase()
            : (!nombreUsuario.trim().isEmpty() ? nombreUsuario.trim().substring(0, 1).toUpperCase() : "UL");

    Map<String, Object> resumen = (Map<String, Object>) request.getAttribute("resumen");
    List<Map<String, Object>> reporteVentas = (List<Map<String, Object>>) request.getAttribute("reporteVentas");
    List<Map<String, Object>> reporteProyectos = (List<Map<String, Object>>) request.getAttribute("reporteProyectos");
    List<Map<String, Object>> reporteClientes = (List<Map<String, Object>>) request.getAttribute("reporteClientes");
    List<Map<String, Object>> reporteSolped = (List<Map<String, Object>>) request.getAttribute("reporteSolped");
    List<Map<String, Object>> reporteUsuarios = (List<Map<String, Object>>) request.getAttribute("reporteUsuarios");
    List<String> alertasComerciales = (List<String>) request.getAttribute("alertasComerciales");
    List<PortalEvent> historialEventos = (List<PortalEvent>) request.getAttribute("historialEventos");

    String fechaInicio = (String) request.getAttribute("fechaInicio");
    String fechaFin = (String) request.getAttribute("fechaFin");
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    SimpleDateFormat sdfFecha = new SimpleDateFormat("dd/MM/yyyy");

    List<Map<String, Object>> proyectosPorEstado = resumen != null
            ? (List<Map<String, Object>>) resumen.get("proyectosPorEstado") : null;
    List<Map<String, Object>> solpedPorEstado = resumen != null
            ? (List<Map<String, Object>>) resumen.get("solpedPorEstado") : null;
    List<Map<String, Object>> ventasPorMes = resumen != null
            ? (List<Map<String, Object>>) resumen.get("ventasPorMes") : null;
    List<Map<String, Object>> topClientes = resumen != null
            ? (List<Map<String, Object>>) resumen.get("topClientes") : null;
    Map<String, Object> clienteMasRecurrente = resumen != null
            ? (Map<String, Object>) resumen.get("clienteMasRecurrente") : null;
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reportes y Analítica | LUMYN</title>
    <link rel="stylesheet" href="<%= contexto %>/css/styles.css">
    <script src="<%= contexto %>/js/pagination.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/jspdf@2.5.1/dist/jspdf.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/jspdf-autotable@3.8.2/dist/jspdf.plugin.autotable.min.js"></script>
    <style>
        .charts-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 18px;
            margin-bottom: 24px;
        }
        @media (max-width: 960px) {
            .charts-grid {
                grid-template-columns: 1fr;
            }
        }
        .chart-card {
            background: #ffffff;
            border: 1px solid #e5e7eb;
            border-radius: 12px;
            padding: 18px;
            min-width: 0;
        }
        .chart-card h3 {
            margin: 0 0 10px;
            font-size: 15px;
            font-weight: 700;
            color: #111827;
        }
        .chart-box {
            width: 100%;
            height: 310px;
        }
        .report-section {
            background: #ffffff;
            border: 1px solid #e5e7eb;
            border-radius: 12px;
            padding: 18px;
            margin-bottom: 20px;
        }
        .report-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 14px;
        }
        .filter-bar {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }
        .table-wrap {
            overflow-x: auto;
        }
        .recurrent-client-card {
            background: linear-gradient(135deg, #171717 0%, #262626 70%, #2e1518 100%);
            color: #ffffff;
            border-radius: 14px;
            padding: 20px 24px;
            margin-bottom: 22px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 18px;
            box-shadow: var(--shadow);
        }
        .recurrent-client-tag {
            display: inline-block;
            font-size: 10px;
            font-weight: 800;
            letter-spacing: 2px;
            text-transform: uppercase;
            color: #ff6b70;
            margin-bottom: 6px;
        }
        .recurrent-client-name {
            margin: 0 0 4px;
            font-size: 20px;
            font-weight: 800;
            letter-spacing: -0.4px;
            color: #ffffff;
        }
        .recurrent-client-meta {
            font-size: 12px;
            color: #cfcfcf;
        }
        .recurrent-client-metrics {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 14px;
        }
        .recurrent-metric {
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 10px;
            padding: 10px 14px;
            min-width: 108px;
        }
        .recurrent-metric span {
            display: block;
            font-size: 10px;
            color: #c7c7c7;
            text-transform: uppercase;
            letter-spacing: 0.8px;
        }
        .recurrent-metric strong {
            display: block;
            font-size: 16px;
            margin-top: 3px;
            color: #ffffff;
        }
        .report-section .table-footer {
            padding: 14px 4px 2px;
            border-top: 1px solid var(--border);
            margin-top: 8px;
        }
    </style>
</head>
<body>
<div class="app-layout">
    <aside class="sidebar">
        <a href="<%= contexto %>/dashboard" class="sidebar-logo">LUM<span>Y</span>N</a>
        <div class="sidebar-label">Principal</div>
        <nav>
            <a href="<%= contexto %>/dashboard" class="nav-link"><span class="nav-icon">▦</span>Panel principal</a>
            <% if (rolId == 1) { %>
            <a href="<%= contexto %>/usuarios" class="nav-link"><span class="nav-icon">♙</span>Usuarios y roles</a>
            <a href="<%= contexto %>/seguridad" class="nav-link"><span class="nav-icon">◇</span>Seguridad</a>
            <% } %>
            <% if (rolId == 1 || rolId == 2) { %>
            <a href="<%= contexto %>/clientes" class="nav-link"><span class="nav-icon">♧</span>Clientes</a>
            <% } %>
            <% if (rolId == 1 || rolId == 2 || rolId == 4) { %>
            <a href="<%= contexto %>/proyectos" class="nav-link"><span class="nav-icon">▣</span>Proyectos</a>
            <% } %>
            <% if (rolId == 1 || rolId == 2) { %>
            <a href="<%= contexto %>/solped" class="nav-link"><span class="nav-icon">▤</span>SOLPED / Cotizaciones</a>
            <a href="<%= contexto %>/ventas" class="nav-link"><span class="nav-icon">S/</span>Ventas</a>
            <% } %>
            <% if (rolId == 1 || rolId == 2 || rolId == 3) { %>
            <a href="<%= contexto %>/tareas" class="nav-link"><span class="nav-icon">☷</span>Tareas</a>
            <% } %>
            <a href="<%= contexto %>/entregables" class="nav-link"><span class="nav-icon">▤</span>Entregables</a>
            <% if (rolId == 1 || rolId == 2) { %>
            <a href="<%= contexto %>/reportes" class="nav-link active"><span class="nav-icon">▥</span>Reportes</a>
            <% } %>
            <a href="<%= contexto %>/notificaciones" class="nav-link"><span class="nav-icon">♧</span>Notificaciones</a>
            <% if (rolId == 1 || rolId == 2 || rolId == 4) { %>
            <a href="<%= contexto %>/observaciones" class="nav-link"><span class="nav-icon">☷</span>Observaciones</a>
            <% } %>
        </nav>
        <div class="sidebar-bottom">
            <div class="user-mini">
                <div class="avatar"><%= esc(iniciales) %></div>
                <div>
                    <strong><%= esc(nombreUsuario) %></strong>
                    <small><%= esc(rolNombre) %></small>
                </div>
            </div>
            <a href="<%= contexto %>/logout" class="nav-link"><span class="nav-icon">↪</span>Cerrar sesión</a>
        </div>
    </aside>

    <main class="main-area">
        <header class="topbar">
            <div class="breadcrumb">LUMYN / <strong>Reportes</strong></div>
        </header>

        <section class="content">
            <div class="page-heading">
                <div>
                    <div class="welcome-tag">Etapa 7 · Analítica</div>
                    <h1>Reportes Operativos y Comerciales</h1>
                    <p>Visualización interactiva con Apache ECharts y exportación a Excel (.xlsx).</p>
                </div>
            </div>

            <!-- Cliente más recurrente -->
            <% if (clienteMasRecurrente != null) { %>
            <div class="recurrent-client-card">
                <div>
                    <div class="recurrent-client-tag">★ Cliente más recurrente</div>
                    <h2 class="recurrent-client-name"><%= esc(clienteMasRecurrente.get("nombre")) %></h2>
                    <div class="recurrent-client-meta">
                        Documento: <strong><%= esc(clienteMasRecurrente.get("documento")) %></strong>
                        <% if (clienteMasRecurrente.get("correo") != null && !String.valueOf(clienteMasRecurrente.get("correo")).isBlank()) { %>
                            · <%= esc(clienteMasRecurrente.get("correo")) %>
                        <% } %>
                    </div>
                </div>
                <div class="recurrent-client-metrics">
                    <div class="recurrent-metric">
                        <span>Ventas</span>
                        <strong><%= clienteMasRecurrente.get("totalVentas") %></strong>
                    </div>
                    <div class="recurrent-metric">
                        <span>Proyectos</span>
                        <strong><%= clienteMasRecurrente.get("totalProyectos") %></strong>
                    </div>
                    <div class="recurrent-metric">
                        <span>SOLPED</span>
                        <strong><%= clienteMasRecurrente.get("totalSolped") %></strong>
                    </div>
                    <div class="recurrent-metric">
                        <span>Facturado</span>
                        <strong>S/ <%= String.format(java.util.Locale.US, "%,.2f", clienteMasRecurrente.get("montoFacturado") != null ? ((BigDecimal) clienteMasRecurrente.get("montoFacturado")).doubleValue() : 0.0) %></strong>
                    </div>
                </div>
            </div>
            <% } %>

            <!-- Gráficos Apache ECharts -->
            <div class="charts-grid">
                <div class="chart-card">
                    <h3>Ventas por mes (S/)</h3>
                    <div id="chartVentasMes" class="chart-box"></div>
                </div>
                <div class="chart-card">
                    <h3>Proyectos por estado</h3>
                    <div id="chartProyectosEstado" class="chart-box"></div>
                </div>
                <div class="chart-card">
                    <h3>Solicitudes SOLPED por estado</h3>
                    <div id="chartSolpedEstado" class="chart-box"></div>
                </div>
                <div class="chart-card">
                    <h3>Top clientes por facturación (S/)</h3>
                    <div id="chartTopClientes" class="chart-box"></div>
                </div>
            </div>

            <!-- Reporte de Ventas con filtro por fechas -->
            <div class="report-section">
                <div class="report-header">
                    <h2>Reporte de Ventas</h2>
                    <div class="filter-bar">
                        <form method="get" action="<%= contexto %>/reportes" class="filter-bar">
                            <label>Desde: <input type="date" name="fechaInicio" value="<%= esc(fechaInicio) %>"></label>
                            <label>Hasta: <input type="date" name="fechaFin" value="<%= esc(fechaFin) %>"></label>
                            <button type="submit" class="btn btn-outline">Filtrar</button>
                        </form>
                        <button type="button" class="btn btn-primary" onclick="exportarExcel('tablaVentas', 'reporte_ventas.xlsx', 'Ventas')">
                            Descargar Excel
                        </button>
                        <button type="button" class="btn btn-outline" onclick="exportarPDF('tablaVentas', 'reporte_ventas.pdf', 'Reporte de Ventas')">
                            Descargar PDF
                        </button>
                        <a class="btn btn-outline" href="<%= contexto %>/reportes/exportar?tipo=ventas&amp;fechaInicio=<%= java.net.URLEncoder.encode(fechaInicio != null ? fechaInicio : "", "UTF-8") %>&amp;fechaFin=<%= java.net.URLEncoder.encode(fechaFin != null ? fechaFin : "", "UTF-8") %>">
                            Descargar CSV
                        </a>
                    </div>
                </div>
                <div class="table-wrap">
                    <table id="tablaVentas" class="data-table">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>SOLPED</th>
                            <th>Cliente</th>
                            <th>Proyecto</th>
                            <th>Fecha</th>
                            <th>Subtotal</th>
                            <th>Impuesto</th>
                            <th>Total</th>
                            <th>Estado</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (reporteVentas != null) {
                            for (Map<String, Object> v : reporteVentas) { %>
                        <tr>
                            <td><%= v.get("ventaId") %></td>
                            <td>#<%= v.get("solpedId") %></td>
                            <td><%= esc(v.get("cliente")) %></td>
                            <td><%= esc(v.get("proyecto")) %></td>
                            <td><%= v.get("fechaVenta") != null ? sdf.format(v.get("fechaVenta")) : "" %></td>
                            <td><%= v.get("subtotal") %></td>
                            <td><%= v.get("impuesto") %></td>
                            <td><%= v.get("total") %></td>
                            <td><%= esc(v.get("estado")) %></td>
                        </tr>
                        <% } } %>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer" id="pagVentas"></div>
            </div>

            <!-- Reporte de Proyectos -->
            <div class="report-section">
                <div class="report-header">
                    <h2>Reporte de Proyectos</h2>
                    <div class="filter-bar">
                        <button type="button" class="btn btn-primary" onclick="exportarExcel('tablaProyectos', 'reporte_proyectos.xlsx', 'Proyectos')">
                            Descargar Excel
                        </button>
                        <button type="button" class="btn btn-outline" onclick="exportarPDF('tablaProyectos', 'reporte_proyectos.pdf', 'Reporte de Proyectos')">
                            Descargar PDF
                        </button>
                        <a class="btn btn-outline" href="<%= contexto %>/reportes/exportar?tipo=proyectos">
                            Descargar CSV
                        </a>
                    </div>
                </div>
                <div class="table-wrap">
                    <table id="tablaProyectos" class="data-table">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Proyecto</th>
                            <th>Cliente</th>
                            <th>Fecha inicio</th>
                            <th>Fecha fin</th>
                            <th>Estado</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (reporteProyectos != null) {
                            for (Map<String, Object> p : reporteProyectos) { %>
                        <tr>
                            <td><%= p.get("proyectoId") %></td>
                            <td><%= esc(p.get("nombre")) %></td>
                            <td><%= esc(p.get("cliente")) %></td>
                            <td><%= p.get("fechaInicio") != null ? sdfFecha.format(p.get("fechaInicio")) : "" %></td>
                            <td><%= p.get("fechaFin") != null ? sdfFecha.format(p.get("fechaFin")) : "" %></td>
                            <td><%= esc(p.get("estado")) %></td>
                        </tr>
                        <% } } %>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer" id="pagProyectos"></div>
            </div>

            <!-- Reporte de Clientes -->
            <div class="report-section">
                <div class="report-header">
                    <h2>Reporte de Clientes</h2>
                    <div class="filter-bar">
                        <button type="button" class="btn btn-primary" onclick="exportarExcel('tablaClientes', 'reporte_clientes.xlsx', 'Clientes')">
                            Descargar Excel
                        </button>
                        <button type="button" class="btn btn-outline" onclick="exportarPDF('tablaClientes', 'reporte_clientes.pdf', 'Reporte de Clientes')">
                            Descargar PDF
                        </button>
                        <a class="btn btn-outline" href="<%= contexto %>/reportes/exportar?tipo=clientes">
                            Descargar CSV
                        </a>
                    </div>
                </div>
                <div class="table-wrap">
                    <table id="tablaClientes" class="data-table">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nombre / Razón social</th>
                            <th>Documento</th>
                            <th>Correo</th>
                            <th>Teléfono</th>
                            <th>Estado</th>
                            <th>Proyectos</th>
                            <th>Total Ventas (S/)</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (reporteClientes != null) {
                            for (Map<String, Object> c : reporteClientes) { %>
                        <tr>
                            <td><%= c.get("clienteId") %></td>
                            <td><%= esc(c.get("nombre")) %></td>
                            <td><%= esc(c.get("documento")) %></td>
                            <td><%= esc(c.get("correo")) %></td>
                            <td><%= esc(c.get("telefono")) %></td>
                            <td><%= esc(c.get("estado")) %></td>
                            <td><%= c.get("totalProyectos") %></td>
                            <td><%= c.get("totalVentas") %></td>
                        </tr>
                        <% } } %>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer" id="pagClientes"></div>
            </div>

            <!-- Reporte de SOLPED -->
            <div class="report-section">
                <div class="report-header">
                    <h2>Reporte de Solicitudes SOLPED</h2>
                    <div class="filter-bar">
                        <button type="button" class="btn btn-primary" onclick="exportarExcel('tablaSolped', 'reporte_solped.xlsx', 'SOLPED')">
                            Descargar Excel
                        </button>
                        <button type="button" class="btn btn-outline" onclick="exportarPDF('tablaSolped', 'reporte_solped.pdf', 'Reporte de Solicitudes SOLPED')">
                            Descargar PDF
                        </button>
                        <a class="btn btn-outline" href="<%= contexto %>/reportes/exportar?tipo=solped">
                            Descargar CSV
                        </a>
                    </div>
                </div>
                <div class="table-wrap">
                    <table id="tablaSolped" class="data-table">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Cliente</th>
                            <th>Proyecto</th>
                            <th>Responsable</th>
                            <th>Fecha solicitud</th>
                            <th>Estado</th>
                            <th>Monto estimado (S/)</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (reporteSolped != null) {
                            for (Map<String, Object> s : reporteSolped) { %>
                        <tr>
                            <td><%= s.get("solpedId") %></td>
                            <td><%= esc(s.get("cliente")) %></td>
                            <td><%= esc(s.get("proyecto")) %></td>
                            <td><%= esc(s.get("responsable")) %></td>
                            <td><%= s.get("fechaSolicitud") != null ? sdf.format(s.get("fechaSolicitud")) : "" %></td>
                            <td><%= esc(s.get("estado")) %></td>
                            <td><%= s.get("montoEstimado") %></td>
                        </tr>
                        <% } } %>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer" id="pagSolped"></div>
            </div>

            <!-- Reporte de Usuarios -->
            <div class="report-section">
                <div class="report-header">
                    <h2>Reporte de Usuarios</h2>
                    <div class="filter-bar">
                        <button type="button" class="btn btn-primary" onclick="exportarExcel('tablaUsuarios', 'reporte_usuarios.xlsx', 'Usuarios')">
                            Descargar Excel
                        </button>
                        <button type="button" class="btn btn-outline" onclick="exportarPDF('tablaUsuarios', 'reporte_usuarios.pdf', 'Reporte de Usuarios')">
                            Descargar PDF
                        </button>
                        <a class="btn btn-outline" href="<%= contexto %>/reportes/exportar?tipo=usuarios">
                            Descargar CSV
                        </a>
                    </div>
                </div>
                <div class="table-wrap">
                    <table id="tablaUsuarios" class="data-table">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nombres</th>
                            <th>Apellidos</th>
                            <th>Correo</th>
                            <th>Rol ID</th>
                            <th>Estado</th>
                            <th>Intentos fallidos</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (reporteUsuarios != null) {
                            for (Map<String, Object> u : reporteUsuarios) { %>
                        <tr>
                            <td><%= u.get("id") %></td>
                            <td><%= esc(u.get("nombres")) %></td>
                            <td><%= esc(u.get("apellidos")) %></td>
                            <td><%= esc(u.get("correo")) %></td>
                            <td><%= u.get("rolId") %></td>
                            <td><%= esc(u.get("estado")) %></td>
                            <td><%= u.get("intentosFallidos") %></td>
                        </tr>
                        <% } } %>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer" id="pagUsuarios"></div>
            </div>

            <!-- Bitácora Observer -->
            <div class="report-section">
                <div class="report-header">
                    <h2>Bitácora de Eventos (Patrón Observer)</h2>
                    <div class="filter-bar">
                        <button type="button" class="btn btn-primary" onclick="exportarExcel('tablaEventos', 'reporte_eventos_observer.xlsx', 'Eventos')">
                            Descargar Excel
                        </button>
                        <button type="button" class="btn btn-outline" onclick="exportarPDF('tablaEventos', 'reporte_eventos_observer.pdf', 'Bitácora de Eventos (Observer)')">
                            Descargar PDF
                        </button>
                    </div>
                </div>
                <div class="table-wrap">
                    <table id="tablaEventos" class="data-table">
                        <thead>
                        <tr>
                            <th>Tipo</th>
                            <th>Entidad ID</th>
                            <th>Usuario ID</th>
                            <th>Detalle</th>
                            <th>Fecha / Hora</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (historialEventos != null && !historialEventos.isEmpty()) {
                            for (PortalEvent ev : historialEventos) { %>
                        <tr>
                            <td><%= esc(ev.getTipo()) %></td>
                            <td><%= ev.getEntidadId() %></td>
                            <td><%= ev.getUsuarioId() != null ? ev.getUsuarioId() : "-" %></td>
                            <td><%= esc(ev.getDetalle()) %></td>
                            <td><%= esc(ev.getFechaHora()) %></td>
                        </tr>
                        <% } } else { %>
                        <tr>
                            <td colspan="5">Sin eventos registrados en esta sesión.</td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer" id="pagEventos"></div>
            </div>
        </section>
    </main>
</div>

<script>
    const reportPagers = {};

    function conTodasLasFilasVisibles(tableId, fn) {
        const table = document.getElementById(tableId);
        const rows = table ? Array.from(table.querySelectorAll('tbody tr')) : [];
        rows.forEach(r => { r.style.display = ''; });
        try {
            fn(table);
        } finally {
            if (reportPagers[tableId]) {
                reportPagers[tableId].render();
            }
        }
    }

    function exportarExcel(tableId, fileName, sheetName) {
        if (typeof XLSX === 'undefined') {
            alert('No se pudo cargar la librería de exportación Excel.');
            return;
        }
        conTodasLasFilasVisibles(tableId, function (table) {
            const workbook = XLSX.utils.table_to_book(table, { sheet: sheetName });
            XLSX.writeFile(workbook, fileName);
        });
    }

    function exportarPDF(tableId, fileName, titulo) {
        if (!window.jspdf || typeof window.jspdf.jsPDF === 'undefined') {
            alert('No se pudo cargar la librería de exportación PDF.');
            return;
        }
        conTodasLasFilasVisibles(tableId, function () {
            const { jsPDF } = window.jspdf;
            const doc = new jsPDF({ orientation: 'landscape', unit: 'pt', format: 'a4' });
            doc.setFontSize(15);
            doc.text('Agencia LUMYN — ' + titulo, 40, 40);
            doc.setFontSize(9);
            doc.setTextColor(100);
            doc.text('Generado: ' + new Date().toLocaleString('es-PE'), 40, 56);
            doc.autoTable({
                html: '#' + tableId,
                startY: 70,
                styles: { fontSize: 8, cellPadding: 4 },
                headStyles: { fillColor: [30, 41, 59] }
            });
            doc.save(fileName);
        });
    }

    (function initReportPagination() {
        if (!window.LumynPagination) return;
        const tablas = [
            { id: 'tablaVentas', footer: '#pagVentas', label: 'ventas' },
            { id: 'tablaProyectos', footer: '#pagProyectos', label: 'proyectos' },
            { id: 'tablaClientes', footer: '#pagClientes', label: 'clientes' },
            { id: 'tablaSolped', footer: '#pagSolped', label: 'solicitudes' },
            { id: 'tablaUsuarios', footer: '#pagUsuarios', label: 'usuarios' },
            { id: 'tablaEventos', footer: '#pagEventos', label: 'eventos' }
        ];
        tablas.forEach(function (cfg) {
            reportPagers[cfg.id] = window.LumynPagination.attachTable({
                tbody: '#' + cfg.id + ' tbody',
                footerEl: cfg.footer,
                label: cfg.label,
                pageSize: 10
            });
        });
    })();

    (function renderCharts() {
        if (typeof echarts === 'undefined') return;

        const ventasMes = [
            <% if (ventasPorMes != null) {
                for (int i = 0; i < ventasPorMes.size(); i++) {
                    Map<String, Object> item = ventasPorMes.get(i);
            %>{ mes: "<%= escJs(item.get("mes")) %>", monto: <%= item.get("monto") != null ? item.get("monto") : 0 %> }<%= i < ventasPorMes.size() - 1 ? "," : "" %>
            <% } } %>
        ];

        const proyectosEstado = [
            <% if (proyectosPorEstado != null) {
                for (int i = 0; i < proyectosPorEstado.size(); i++) {
                    Map<String, Object> item = proyectosPorEstado.get(i);
            %>{ name: "<%= escJs(item.get("etiqueta")) %>", value: <%= item.get("total") != null ? item.get("total") : 0 %> }<%= i < proyectosPorEstado.size() - 1 ? "," : "" %>
            <% } } %>
        ];

        const solpedEstado = [
            <% if (solpedPorEstado != null) {
                for (int i = 0; i < solpedPorEstado.size(); i++) {
                    Map<String, Object> item = solpedPorEstado.get(i);
            %>{ name: "<%= escJs(item.get("etiqueta")) %>", value: <%= item.get("total") != null ? item.get("total") : 0 %> }<%= i < solpedPorEstado.size() - 1 ? "," : "" %>
            <% } } %>
        ];

        const topClientes = [
            <% if (topClientes != null) {
                for (int i = 0; i < topClientes.size(); i++) {
                    Map<String, Object> item = topClientes.get(i);
            %>{ cliente: "<%= escJs(item.get("cliente")) %>", monto: <%= item.get("monto") != null ? item.get("monto") : 0 %> }<%= i < topClientes.size() - 1 ? "," : "" %>
            <% } } %>
        ];

        const formatEstado = (texto) => {
            if (!texto) return '';
            const clean = String(texto).replace(/_/g, ' ');
            return clean.charAt(0).toUpperCase() + clean.slice(1);
        };

        const formatMoneda = (valor) => {
            return 'S/ ' + Number(valor || 0).toLocaleString('es-PE', {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            });
        };

        const c1 = echarts.init(document.getElementById('chartVentasMes'));
        c1.setOption({
            tooltip: {
                trigger: 'axis',
                axisPointer: { type: 'shadow' },
                valueFormatter: (val) => formatMoneda(val)
            },
            grid: { left: 16, right: 20, top: 24, bottom: 16, containLabel: true },
            xAxis: {
                type: 'category',
                data: ventasMes.map(x => x.mes),
                axisLabel: { interval: 0 }
            },
            yAxis: {
                type: 'value',
                axisLabel: {
                    formatter: (val) => 'S/ ' + Number(val).toLocaleString('es-PE')
                }
            },
            series: [{
                name: 'Ventas',
                type: 'bar',
                barMaxWidth: 56,
                data: ventasMes.map(x => x.monto),
                itemStyle: { color: '#2563eb', borderRadius: [6, 6, 0, 0] }
            }]
        });

        const c2 = echarts.init(document.getElementById('chartProyectosEstado'));
        c2.setOption({
            tooltip: {
                trigger: 'item',
                formatter: '{b}: {c} ({d}%)'
            },
            legend: {
                bottom: 0,
                left: 'center',
                type: 'scroll'
            },
            series: [{
                name: 'Proyectos',
                type: 'pie',
                radius: ['38%', '60%'],
                center: ['50%', '43%'],
                avoidLabelOverlap: true,
                itemStyle: {
                    borderRadius: 6,
                    borderColor: '#ffffff',
                    borderWidth: 2
                },
                label: {
                    formatter: '{b}: {c}'
                },
                data: proyectosEstado.map(x => ({
                    name: formatEstado(x.name),
                    value: x.value
                }))
            }]
        });

        const c3 = echarts.init(document.getElementById('chartSolpedEstado'));
        c3.setOption({
            tooltip: {
                trigger: 'axis',
                axisPointer: { type: 'shadow' }
            },
            grid: { left: 16, right: 20, top: 24, bottom: 16, containLabel: true },
            xAxis: {
                type: 'category',
                data: solpedEstado.map(x => formatEstado(x.name)),
                axisLabel: {
                    interval: 0,
                    rotate: solpedEstado.length > 4 ? 15 : 0
                }
            },
            yAxis: {
                type: 'value',
                minInterval: 1
            },
            series: [{
                name: 'SOLPED',
                type: 'bar',
                barMaxWidth: 48,
                data: solpedEstado.map(x => x.value),
                itemStyle: { color: '#0d9488', borderRadius: [6, 6, 0, 0] }
            }]
        });

        const c4 = echarts.init(document.getElementById('chartTopClientes'));
        c4.setOption({
            tooltip: {
                trigger: 'axis',
                axisPointer: { type: 'shadow' },
                valueFormatter: (val) => formatMoneda(val)
            },
            grid: { left: 16, right: 28, top: 20, bottom: 16, containLabel: true },
            xAxis: {
                type: 'value',
                splitNumber: 4,
                axisLabel: {
                    formatter: (val) => 'S/ ' + Number(val).toLocaleString('es-PE')
                }
            },
            yAxis: {
                type: 'category',
                data: topClientes.map(x => x.cliente),
                axisLabel: {
                    width: 160,
                    overflow: 'truncate'
                }
            },
            series: [{
                name: 'Facturación',
                type: 'bar',
                barMaxWidth: 36,
                data: topClientes.map(x => x.monto),
                itemStyle: { color: '#7c3aed', borderRadius: [0, 6, 6, 0] }
            }]
        });

        const charts = [c1, c2, c3, c4];
        window.addEventListener('resize', () => {
            charts.forEach(chart => chart.resize());
        });
    })();
</script>
</body>
</html>
