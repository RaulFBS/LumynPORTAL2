<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="pe.lumyn.portal.model.Entregable"%>
<%@page import="pe.lumyn.portal.model.Proyecto"%>
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
    List<Entregable> entregables = (List<Entregable>) request.getAttribute("entregables");
    List<Proyecto> proyectos = (List<Proyecto>) request.getAttribute("proyectos");
    boolean puedeRevisar = (rolId == 1 || rolId == 2 || rolId == 4);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Entregables | LUMYN</title>
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
            <a href="<%= contexto %>/entregables" class="nav-link active"><span class="nav-icon">▤</span>Entregables</a>
            <% if (rolId == 1 || rolId == 2) { %>
            <a href="<%= contexto %>/reportes" class="nav-link"><span class="nav-icon">▥</span>Reportes</a>
            <% } %>
            <a href="<%= contexto %>/notificaciones" class="nav-link"><span class="nav-icon">♧</span>Notificaciones</a>
            <% if (rolId == 1 || rolId == 2 || rolId == 4) { %>
            <a href="<%= contexto %>/observaciones" class="nav-link"><span class="nav-icon">☷</span>Observaciones</a>
            <% } %>
        </nav>
        <div class="sidebar-bottom">
            <div class="user-mini"><div><strong><%= esc(nombreUsuario) %></strong></div></div>
            <a href="<%= contexto %>/logout" class="nav-link"><span class="nav-icon">↪</span>Cerrar sesión</a>
        </div>
    </aside>
    <main class="main-area">
        <header class="topbar"><div class="breadcrumb">LUMYN / <strong>Entregables</strong></div></header>
        <section class="content">
            <div class="page-heading">
                <div>
                    <div class="welcome-tag">Control de Calidad</div>
                    <h1>Entregables de Proyectos</h1>
                    <p>Registro de versiones, enlace al entregable y flujo de aprobación u observación.</p>
                </div>
            </div>

            <div class="card" style="margin-bottom:20px;">
                <h3 style="margin-top:0;">Registrar entregable</h3>
                <form method="post" action="<%= contexto %>/entregables" class="form-grid">
                    <input type="hidden" name="accion" value="crear">
                    <div class="form-group">
                        <label>Proyecto</label>
                        <select name="proyectoId" required>
                            <% if (proyectos != null) for (Proyecto p : proyectos) { %>
                            <option value="<%= p.getProyectoId() %>"><%= esc(p.getNombre()) %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Título</label>
                        <input type="text" name="titulo" required placeholder="Ej. Prototipo v1.0">
                    </div>
                    <div class="form-group">
                        <label>Versión</label>
                        <input type="text" name="version" value="v1.0">
                    </div>
                    <div class="form-group">
                        <label>Enlace / Archivo</label>
                        <input type="text" name="urlArchivo" placeholder="https://...">
                    </div>
                    <div class="form-group span-2">
                        <label>Descripción</label>
                        <input type="text" name="descripcion" placeholder="Resumen del entregable">
                    </div>
                    <div class="span-2">
                        <button type="submit" class="btn btn-primary">Guardar entregable</button>
                    </div>
                </form>
            </div>

            <div class="table-card">
                <div class="table-scroll">
                    <table class="data-table">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Proyecto</th>
                            <th>Entregable</th>
                            <th>Versión</th>
                            <th>Responsable</th>
                            <th>Estado</th>
                            <th>Última observación</th>
                            <% if (puedeRevisar) { %><th>Revisión</th><% } %>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (entregables != null && !entregables.isEmpty()) {
                            for (Entregable e : entregables) { %>
                        <tr>
                            <td>#<%= e.getEntregableId() %></td>
                            <td><%= esc(e.getNombreProyecto()) %></td>
                            <td>
                                <strong><%= esc(e.getTitulo()) %></strong>
                                <% if (e.getUrlArchivo() != null && !e.getUrlArchivo().isBlank()) { %>
                                <br><a href="<%= esc(e.getUrlArchivo()) %>" target="_blank" rel="noopener">Ver recurso</a>
                                <% } %>
                            </td>
                            <td><%= esc(e.getVersion()) %></td>
                            <td><%= esc(e.getNombreResponsable()) %></td>
                            <td><span class="badge <%= "aprobado".equals(e.getEstado()) ? "badge-green" : ("observado".equals(e.getEstado()) ? "badge-red" : "badge-yellow") %>"><%= esc(e.getEstado()) %></span></td>
                            <td><%= esc(e.getUltimaObservacion()) %></td>
                            <% if (puedeRevisar) { %>
                            <td>
                                <form method="post" action="<%= contexto %>/entregables" style="display:flex;gap:6px;align-items:center;">
                                    <input type="hidden" name="accion" value="revisar">
                                    <input type="hidden" name="entregableId" value="<%= e.getEntregableId() %>">
                                    <input type="text" name="observacion" placeholder="Comentario" style="width:140px;">
                                    <select name="estado" style="width:110px;">
                                        <option value="aprobado">Aprobar</option>
                                        <option value="observado">Observar</option>
                                    </select>
                                    <button type="submit" class="btn btn-outline btn-small">Aplicar</button>
                                </form>
                            </td>
                            <% } %>
                        </tr>
                        <% } } else { %>
                        <tr><td colspan="8">No hay entregables registrados.</td></tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </section>
    </main>
</div>
</body>
</html>
