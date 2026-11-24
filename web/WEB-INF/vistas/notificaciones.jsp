<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.time.format.DateTimeFormatter"%>
<%@page import="java.util.List"%>
<%@page import="pe.lumyn.portal.observer.PortalEvent"%>
<%!
    private String esc(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String contexto = request.getContextPath();
    Integer rolId = request.getAttribute("rolId") instanceof Number
            ? ((Number) request.getAttribute("rolId")).intValue() : 0;
    String nombreUsuario = (String) request.getAttribute("nombreUsuario");
    if (nombreUsuario == null || nombreUsuario.isBlank()) {
        nombreUsuario = "Usuario Lumyn";
    }
    String rolNombre = switch (rolId) {
        case 1 -> "Administrador";
        case 2 -> "Gestor";
        case 3 -> "Colaborador";
        case 4 -> "Revisor";
        default -> "Usuario";
    };
    String[] partesNombre = nombreUsuario.trim().split("\\s+");
    String iniciales = partesNombre.length >= 2
            ? (partesNombre[0].substring(0, 1) + partesNombre[partesNombre.length - 1].substring(0, 1)).toUpperCase()
            : (!nombreUsuario.trim().isEmpty() ? nombreUsuario.trim().substring(0, 1).toUpperCase() : "UL");
    List<String> alertas = (List<String>) request.getAttribute("alertasComerciales");
    List<PortalEvent> eventos = (List<PortalEvent>) request.getAttribute("historialEventos");
    DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Notificaciones | LUMYN</title>
    <link rel="stylesheet" href="<%= contexto %>/css/styles.css">
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
            <a href="<%= contexto %>/tareas" class="nav-link"><span class="nav-icon">☷</span><%= rolId == 3 ? "Mis tareas" : "Tareas" %></a>
            <% } %>
            <a href="<%= contexto %>/entregables" class="nav-link"><span class="nav-icon">▤</span>Entregables</a>
            <% if (rolId == 1 || rolId == 2) { %>
            <a href="<%= contexto %>/reportes" class="nav-link"><span class="nav-icon">▥</span>Reportes</a>
            <% } %>
            <a href="<%= contexto %>/notificaciones" class="nav-link active"><span class="nav-icon">♧</span>Notificaciones</a>
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
        <header class="topbar"><div class="breadcrumb">LUMYN / <strong>Notificaciones</strong></div></header>
        <section class="content">
            <div class="page-heading">
                <div>
                    <div class="welcome-tag">Patrón Observer</div>
                    <h1>Centro de Notificaciones</h1>
                    <p>Alertas comerciales y eventos operativos emitidos en tiempo real.</p>
                </div>
                <form method="post" action="<%= contexto %>/notificaciones">
                    <button type="submit" class="btn btn-outline">+ Simular notificación</button>
                </form>
            </div>

            <div class="card" style="margin-bottom:20px;">
                <h3 style="margin-top:0;">Alertas comerciales (SOLPED / Ventas)</h3>
                <% if (alertas != null && !alertas.isEmpty()) {
                    for (String a : alertas) { %>
                <div class="activity-item">
                    <div class="activity-dot"></div>
                    <div><strong style="font-size:13px;"><%= esc(a) %></strong></div>
                </div>
                <% } } else { %>
                <p>No hay alertas comerciales recientes en esta sesión.</p>
                <% } %>
            </div>

            <div class="card">
                <h3 style="margin-top:0;">Actividad reciente del sistema</h3>
                <% if (eventos != null && !eventos.isEmpty()) {
                    for (PortalEvent ev : eventos) {
                        String fechaStr = ev.getFechaHora() != null ? ev.getFechaHora().format(fmt) : ""; %>
                <div class="activity-item">
                    <div class="activity-dot"></div>
                    <div>
                        <strong style="font-size:13px;"><%= esc(ev.getTipo()) %> (#<%= ev.getEntidadId() %>)</strong>
                        <p style="font-size:12px;"><%= esc(ev.getDetalle()) %> — <%= esc(fechaStr) %></p>
                    </div>
                </div>
                <% } } else { %>
                <p>Sin eventos registrados todavía.</p>
                <% } %>
            </div>
        </section>
    </main>
</div>
</body>
</html>
