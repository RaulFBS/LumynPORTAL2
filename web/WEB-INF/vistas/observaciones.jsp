<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
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
    List<Map<String, Object>> observaciones = (List<Map<String, Object>>) request.getAttribute("observaciones");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Observaciones | LUMYN</title>
    <link rel="stylesheet" href="<%= contexto %>/css/styles.css">
    <script src="<%= contexto %>/js/pagination.js"></script>
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
            <a href="<%= contexto %>/reportes" class="nav-link"><span class="nav-icon">▥</span>Reportes</a>
            <% } %>
            <a href="<%= contexto %>/notificaciones" class="nav-link"><span class="nav-icon">♧</span>Notificaciones</a>
            <a href="<%= contexto %>/observaciones" class="nav-link active"><span class="nav-icon">☷</span>Observaciones</a>
        </nav>
        <div class="sidebar-bottom">
            <div class="user-mini"><div><strong><%= esc(nombreUsuario) %></strong></div></div>
            <a href="<%= contexto %>/logout" class="nav-link"><span class="nav-icon">↪</span>Cerrar sesión</a>
        </div>
    </aside>
    <main class="main-area">
        <header class="topbar"><div class="breadcrumb">LUMYN / <strong>Observaciones</strong></div></header>
        <section class="content">
            <div class="page-heading">
                <div>
                    <div class="welcome-tag">Control de Calidad</div>
                    <h1>Historial de Observaciones</h1>
                    <p>Registro completo de revisiones y comentarios sobre entregables.</p>
                </div>
            </div>
            <div class="table-card">
                <div class="table-scroll">
                    <table class="data-table">
                        <thead>
                        <tr><th>ID</th><th>Proyecto</th><th>Entregable</th><th>Revisor</th><th>Estado</th><th>Comentario</th><th>Fecha</th></tr>
                        </thead>
                        <tbody>
                        <% if (observaciones != null && !observaciones.isEmpty()) {
                            for (Map<String, Object> o : observaciones) { %>
                        <tr>
                            <td>#<%= o.get("observacionId") %></td>
                            <td><%= esc(o.get("proyecto")) %></td>
                            <td><%= esc(o.get("entregable")) %></td>
                            <td><%= esc(o.get("revisor")) %></td>
                            <td><%= esc(o.get("estado")) %></td>
                            <td><%= esc(o.get("comentario")) %></td>
                            <td><%= esc(o.get("fechaRegistro")) %></td>
                        </tr>
                        <% } } else { %>
                        <tr><td colspan="7">No hay observaciones registradas todavía.</td></tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer" id="observacionesPagination"></div>
            </div>
        </section>
    </main>
</div>
<script>
    if (window.LumynPagination) {
        window.LumynPagination.attachTable({
            tbody: ".data-table tbody",
            footerEl: "#observacionesPagination",
            label: "observaciones",
            pageSize: 10
        });
    }
</script>
</body>
</html>
