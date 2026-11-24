<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="pe.lumyn.portal.model.Tarea"%>
<%@page import="pe.lumyn.portal.model.Proyecto"%>
<%@page import="pe.lumyn.portal.model.Usuario"%>
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
    List<Tarea> tareas = (List<Tarea>) request.getAttribute("tareas");
    List<Proyecto> proyectos = (List<Proyecto>) request.getAttribute("proyectos");
    List<Usuario> usuarios = (List<Usuario>) request.getAttribute("usuarios");
    boolean puedeCrear = (rolId == 1 || rolId == 2);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tareas | LUMYN</title>
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
            <a href="<%= contexto %>/tareas" class="nav-link active"><span class="nav-icon">☷</span><%= rolId == 3 ? "Mis tareas" : "Tareas" %></a>
            <a href="<%= contexto %>/entregables" class="nav-link"><span class="nav-icon">▤</span>Entregables</a>
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
        <header class="topbar"><div class="breadcrumb">LUMYN / <strong>Tareas</strong></div></header>
        <section class="content">
            <div class="page-heading">
                <div>
                    <div class="welcome-tag">Control Operativo</div>
                    <h1>Gestión de Tareas</h1>
                    <p>Asignación de responsables, prioridad, fechas límite y seguimiento de avance.</p>
                </div>
            </div>

            <% if (puedeCrear) { %>
            <div class="card" style="margin-bottom:20px;">
                <h3 style="margin-top:0;">Nueva tarea</h3>
                <form method="post" action="<%= contexto %>/tareas" class="form-grid">
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
                        <label>Responsable</label>
                        <select name="usuarioId">
                            <option value="">-- Sin asignar --</option>
                            <% if (usuarios != null) for (Usuario u : usuarios) { %>
                            <option value="<%= u.getId() %>"><%= esc(u.getNombres() + " " + u.getApellidos()) %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Título</label>
                        <input type="text" name="titulo" required placeholder="Ej. Configurar formulario de contacto">
                    </div>
                    <div class="form-group">
                        <label>Prioridad</label>
                        <select name="prioridad">
                            <option value="baja">Baja</option>
                            <option value="media" selected>Media</option>
                            <option value="alta">Alta</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Fecha límite</label>
                        <input type="date" name="fechaLimite">
                    </div>
                    <div class="form-group">
                        <label>Descripción</label>
                        <input type="text" name="descripcion" placeholder="Detalle breve de la tarea">
                    </div>
                    <div class="span-2">
                        <button type="submit" class="btn btn-primary">Registrar tarea</button>
                    </div>
                </form>
            </div>
            <% } %>

            <div class="table-card">
                <div class="table-scroll">
                    <table class="data-table">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Proyecto</th>
                            <th>Título</th>
                            <th>Responsable</th>
                            <th>Prioridad</th>
                            <th>Fecha límite</th>
                            <th>Avance</th>
                            <th>Estado</th>
                            <th>Actualizar</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (tareas != null && !tareas.isEmpty()) {
                            for (Tarea t : tareas) { %>
                        <tr>
                            <td>#<%= t.getTareaId() %></td>
                            <td><%= esc(t.getNombreProyecto()) %></td>
                            <td><strong><%= esc(t.getTitulo()) %></strong><br><small><%= esc(t.getDescripcion()) %></small></td>
                            <td><%= esc(t.getNombreResponsable()) %></td>
                            <td><%= esc(t.getPrioridad()) %></td>
                            <td><%= t.getFechaLimite() != null ? t.getFechaLimite() : "-" %></td>
                            <td><%= t.getAvance() %>%</td>
                            <td><span class="badge <%= "completada".equals(t.getEstado()) ? "badge-green" : "badge-yellow" %>"><%= esc(t.getEstado()) %></span></td>
                            <td>
                                <form method="post" action="<%= contexto %>/tareas" style="display:flex;gap:6px;align-items:center;">
                                    <input type="hidden" name="accion" value="actualizarAvance">
                                    <input type="hidden" name="tareaId" value="<%= t.getTareaId() %>">
                                    <input type="number" name="avance" min="0" max="100" value="<%= t.getAvance() %>" style="width:65px;">
                                    <select name="estado" style="width:120px;">
                                        <option value="pendiente" <%= "pendiente".equals(t.getEstado()) ? "selected" : "" %>>pendiente</option>
                                        <option value="en_progreso" <%= "en_progreso".equals(t.getEstado()) ? "selected" : "" %>>en_progreso</option>
                                        <option value="completada" <%= "completada".equals(t.getEstado()) ? "selected" : "" %>>completada</option>
                                    </select>
                                    <button type="submit" class="btn btn-outline btn-small">Guardar</button>
                                </form>
                            </td>
                        </tr>
                        <% } } else { %>
                        <tr><td colspan="9">No hay tareas registradas.</td></tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <div class="table-footer" id="tareasPagination"></div>
            </div>
        </section>
    </main>
</div>
<script>
    if (window.LumynPagination) {
        window.LumynPagination.attachTable({
            tbody: ".data-table tbody",
            footerEl: "#tareasPagination",
            label: "tareas",
            pageSize: 10
        });
    }
</script>
</body>
</html>
