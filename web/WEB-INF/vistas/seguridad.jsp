<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="pe.lumyn.portal.model.Usuario"%>
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
    String nombreUsuario = (String) request.getAttribute("nombreUsuario");
    List<Usuario> usuarios = (List<Usuario>) request.getAttribute("usuarios");
    List<PortalEvent> historialEventos = (List<PortalEvent>) request.getAttribute("historialEventos");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Seguridad y Auditoría | LUMYN</title>
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
            <a href="<%= contexto %>/usuarios" class="nav-link"><span class="nav-icon">♙</span>Usuarios y roles</a>
            <a href="<%= contexto %>/seguridad" class="nav-link active"><span class="nav-icon">◇</span>Seguridad</a>
            <a href="<%= contexto %>/clientes" class="nav-link"><span class="nav-icon">♧</span>Clientes</a>
            <a href="<%= contexto %>/proyectos" class="nav-link"><span class="nav-icon">▣</span>Proyectos</a>
            <a href="<%= contexto %>/solped" class="nav-link"><span class="nav-icon">▤</span>SOLPED / Cotizaciones</a>
            <a href="<%= contexto %>/ventas" class="nav-link"><span class="nav-icon">S/</span>Ventas</a>
            <a href="<%= contexto %>/tareas" class="nav-link"><span class="nav-icon">☷</span>Tareas</a>
            <a href="<%= contexto %>/entregables" class="nav-link"><span class="nav-icon">▤</span>Entregables</a>
            <a href="<%= contexto %>/reportes" class="nav-link"><span class="nav-icon">▥</span>Reportes</a>
            <a href="<%= contexto %>/notificaciones" class="nav-link"><span class="nav-icon">♧</span>Notificaciones</a>
            <a href="<%= contexto %>/observaciones" class="nav-link"><span class="nav-icon">☷</span>Observaciones</a>
        </nav>
        <div class="sidebar-bottom">
            <div class="user-mini"><div><strong><%= esc(nombreUsuario) %></strong></div></div>
            <a href="<%= contexto %>/logout" class="nav-link"><span class="nav-icon">↪</span>Cerrar sesión</a>
        </div>
    </aside>
    <main class="main-area">
        <header class="topbar"><div class="breadcrumb">LUMYN / <strong>Seguridad</strong></div></header>
        <section class="content">
            <div class="page-heading">
                <div>
                    <div class="welcome-tag">Auditoría y Control</div>
                    <h1>Seguridad de Cuentas y Eventos</h1>
                    <p>Monitoreo de intentos fallidos, desbloqueo de cuentas y traza del patrón Observer.</p>
                </div>
            </div>

            <div class="table-card" style="margin-bottom:20px;">
                <div class="table-toolbar"><strong>Estado de seguridad por usuario</strong></div>
                <div class="table-scroll">
                    <table class="data-table">
                        <thead>
                        <tr><th>ID</th><th>Usuario</th><th>Correo</th><th>Estado</th><th>Intentos fallidos</th><th>Bloqueado hasta</th><th>Acción</th></tr>
                        </thead>
                        <tbody>
                        <% if (usuarios != null) for (Usuario u : usuarios) { %>
                        <tr>
                            <td><%= u.getId() %></td>
                            <td><%= esc(u.getNombres() + " " + u.getApellidos()) %></td>
                            <td><%= esc(u.getCorreo()) %></td>
                            <td><%= esc(u.getEstado()) %></td>
                            <td><%= u.getIntentosFallidos() %></td>
                            <td><%= esc(u.getBloqueadoHasta()) %></td>
                            <td>
                                <% if (u.getIntentosFallidos() > 0 || u.getBloqueadoHasta() != null) { %>
                                <form method="post" action="<%= contexto %>/seguridad">
                                    <input type="hidden" name="accion" value="desbloquear">
                                    <input type="hidden" name="usuarioId" value="<%= u.getId() %>">
                                    <button type="submit" class="btn btn-outline btn-small">Desbloquear</button>
                                </form>
                                <% } else { %>
                                <span class="badge badge-green">Sin alertas</span>
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer" id="seguridadUsuariosPagination"></div>
            </div>

            <div class="table-card">
                <div class="table-toolbar"><strong>Historial reciente de auditoría (Observer)</strong></div>
                <div class="table-scroll">
                    <table class="data-table">
                        <thead><tr><th>Tipo</th><th>Entidad</th><th>Usuario</th><th>Detalle</th><th>Fecha / Hora</th></tr></thead>
                        <tbody id="seguridadEventosBody">
                        <% if (historialEventos != null && !historialEventos.isEmpty()) {
                            for (PortalEvent ev : historialEventos) { %>
                        <tr>
                            <td><%= esc(ev.getTipo()) %></td>
                            <td>#<%= ev.getEntidadId() %></td>
                            <td><%= ev.getUsuarioId() != null ? ev.getUsuarioId() : "-" %></td>
                            <td><%= esc(ev.getDetalle()) %></td>
                            <td><%= esc(ev.getFechaHora()) %></td>
                        </tr>
                        <% } } else { %>
                        <tr><td colspan="5">No hay eventos registrados aún en esta sesión.</td></tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer" id="seguridadEventosPagination"></div>
            </div>
        </section>
    </main>
</div>
<script>
    if (window.LumynPagination) {
        const tablas = document.querySelectorAll(".data-table tbody");
        if (tablas[0]) {
            window.LumynPagination.attachTable({
                tbody: tablas[0],
                footerEl: "#seguridadUsuariosPagination",
                label: "usuarios",
                pageSize: 10
            });
        }
        window.LumynPagination.attachTable({
            tbody: "#seguridadEventosBody",
            footerEl: "#seguridadEventosPagination",
            label: "eventos",
            pageSize: 10
        });
    }
</script>
</body>
</html>
