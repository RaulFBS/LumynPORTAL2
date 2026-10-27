
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="pe.lumyn.portal.model.Proyecto"%>
<%@page import="pe.lumyn.portal.model.Cliente"%>
<%@page import="pe.lumyn.portal.security.PermisosUtil"%>

<%!
    private String escapar(String valor) {
        if (valor == null) {
            return "";
        }
        return valor.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private String nombreEstado(String estado) {
        if (estado == null) {
            return "Planificado";
        }

        switch (estado) {
            case "planificado":
                return "Planificado";
            case "en_progreso":
                return "En progreso";
            case "completado":
                return "Completado";
            case "cancelado":
                return "Cancelado";
            default:
                return estado;
        }
    }

    private String claseEstado(String estado) {
        if ("completado".equals(estado)) {
            return "badge-green";
        }
        if ("en_progreso".equals(estado)) {
            return "badge-yellow";
        }
        if ("cancelado".equals(estado)) {
            return "badge-red";
        }
        return "badge-gray";
    }
%>

<%
    List<Proyecto> proyectos
            = (List<Proyecto>) request.getAttribute("proyectos");

    List<Cliente> clientes
            = (List<Cliente>) request.getAttribute("clientes");

    if (proyectos == null) {
        proyectos = new java.util.ArrayList<>();
    }

    if (clientes == null) {
        clientes = new java.util.ArrayList<>();
    }

    int totalProyectos = proyectos.size();
    int planificados = 0;
    int enProgreso = 0;
    int completados = 0;
    int cancelados = 0;

    for (Proyecto proyecto : proyectos) {
        String estado = proyecto.getEstado();

        if ("planificado".equals(estado)) {
            planificados++;
        }
        if ("en_progreso".equals(estado)) {
            enProgreso++;
        }
        if ("completado".equals(estado)) {
            completados++;
        }
        if ("cancelado".equals(estado)) {
            cancelados++;
        }
    }

    String ctx = request.getContextPath();

    boolean esAdministrador
            = PermisosUtil.esAdministrador(session);

    String rolActual = esAdministrador
            ? "ADMINISTRADOR" : "GESTOR";

    Object nombreSesion = session.getAttribute("nombreUsuario");
    String nombreUsuario = nombreSesion != null
            ? nombreSesion.toString() : "Usuario Lumyn";

    String iniciales = "UL";
    String[] partesNombre = nombreUsuario.trim().split("\\s+");

    if (partesNombre.length >= 2) {
        iniciales = (partesNombre[0].substring(0, 1)
                + partesNombre[partesNombre.length - 1].substring(0, 1)).toUpperCase();
    } else if (!nombreUsuario.trim().isEmpty()) {
        iniciales = nombreUsuario.substring(0, 1).toUpperCase();
    }
%>

<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">

        <title>Proyectos | LUMYN</title>

        <base href="<%= ctx%>/">
        <link rel="stylesheet" href="css/styles.css">

        <style>
            #projectModal[hidden],
            #projectModal .modal[hidden] {
                display: none !important;
            }

            #projectModal:not([hidden]) {
                display: flex;
            }

            #projectModal .modal {
                display: block;
            }

            .project-description {
                display: block;
                max-width: 260px;
                white-space: normal;
                color: var(--muted);
                font-size: 10px;
                line-height: 1.6;
                margin-top: 5px;
            }

            .project-name {
                font-weight: 700;
                font-size: 11px;
            }

            .project-filter {
                display: flex;
                gap: 10px;
                flex-wrap: wrap;
                padding: 17px 19px;
                border-bottom: 1px solid var(--border);
            }

            .project-filter .form-control {
                max-width: 300px;
            }

            .form-section-title {
                font-size: 13px;
                font-weight: 700;
                margin-bottom: 17px;
            }

            .form-hint {
                font-size: 10px;
                line-height: 1.6;
                color: var(--muted);
                margin-top: 6px;
            }

            .empty-state a {
                display: inline-flex;
                margin-top: 12px;
            }

            .form-error {
                display: none;
                color: var(--red);
                font-size: 11px;
                margin-top: 10px;
            }

            .form-error.visible {
                display: block;
            }

            .table-actions form {
                display: inline-flex;
                margin: 0;
            }

            .table-actions {
                align-items: center;
            }

            .project-toolbar-title {
                font-size: 14px;
                font-weight: 700;
            }

            .project-toolbar-description {
                color: var(--muted);
                font-size: 10px;
                margin-top: 6px;
            }

            @media (max-width: 760px) {
                .project-filter {
                    padding: 14px;
                }

                .project-filter .form-control {
                    max-width: none;
                }
            }
        </style>
    </head>

    <body data-nombre-usuario="<%= escapar(nombreUsuario)%>"
          data-rol-usuario="<%= escapar(rolActual)%>">

        <div class="app-layout">

            <!-- BARRA LATERAL -->
            <aside class="sidebar">

                <a href="dashboard" class="sidebar-logo">
                    LUM<span>Y</span>N
                </a>

                <div class="sidebar-label">Principal</div>

                <nav id="sidebarNavigation"></nav>

                <div class="sidebar-bottom">

                    <div class="user-mini">
                        <div class="avatar" id="sidebarAvatar">
                            <%= escapar(iniciales)%>
                        </div>

                        <div>
                            <strong id="sidebarUserName">
                                <%= escapar(nombreUsuario)%>
                            </strong>
                            <small id="sidebarUserRole">
                                <%= esAdministrador ? "Administrador" : "Gestor"%>
                            </small>
                        </div>
                    </div>

                    <a href="logout" class="nav-link">
                        <span class="nav-icon">↪</span>
                        Cerrar sesión
                    </a>

                </div>
            </aside>

            <!-- CONTENIDO PRINCIPAL -->
            <main class="main-area">

                <header class="topbar">

                    <div class="breadcrumb">
                        LUMYN / Gestión / <strong>Proyectos</strong>
                    </div>

                    <div class="topbar-right">
                        <span class="date-label" id="pageDate"></span>
                        <div class="avatar" id="topbarAvatar">
                            <%= escapar(iniciales)%>
                        </div>
                    </div>

                </header>

                <section class="content">

                    <!-- ENCABEZADO -->
                    <div class="page-heading">
                        <div>
                            <div class="welcome-tag">Gestión de proyectos</div>
                            <h1>Proyectos</h1>
                            <p>
                                Organiza los proyectos de tus clientes y consulta
                                su estado, fechas y datos principales.
                            </p>
                        </div>

                        <button type="button"
                                class="btn btn-primary"
                                onclick="abrirCrearProyecto()">
                            + Registrar proyecto
                        </button>
                    </div>

                    <!-- MENSAJES -->
                    <div id="mensajeResultado"
                         class="toast"
                         role="status"
                         aria-live="polite"
                         style="display:none; bottom:auto; top:90px;">
                    </div>

                    <!-- ESTADÍSTICAS -->
                    <div class="grid-stats">

                        <div class="stat-card">
                            <div class="stat-symbol">▣</div>
                            <div class="stat-title">Total de proyectos</div>
                            <div class="stat-value"><%= totalProyectos%></div>
                            <div class="stat-foot">Proyectos registrados</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-symbol">◷</div>
                            <div class="stat-title">Planificados</div>
                            <div class="stat-value"><%= planificados%></div>
                            <div class="stat-foot">Pendientes de iniciar</div>
                        </div>

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

                    </div>

                    <div style="height:22px"></div>

                    <!-- FORMULARIO DE REGISTRO -->
                    <section class="card" id="formularioProyecto">

                        <div class="card-heading">
                            <div>
                                <h3>Registrar nuevo proyecto</h3>
                            </div>
                        </div>

                        <% if (clientes.isEmpty()) { %>

                        <div class="empty-state">
                            <p>
                                Para registrar un proyecto primero necesitas
                                tener al menos un cliente.
                            </p>

                            <a href="clientes" class="btn btn-primary">
                                Ir al módulo de clientes
                            </a>
                        </div>

                        <% } else { %>

                        <form action="proyectos"
                              method="post"
                              id="createProjectForm">

                            <input type="hidden"
                                   name="accion"
                                   value="guardar">

                            <div class="form-grid">

                                <div class="form-group">
                                    <label for="clienteId">Cliente *</label>

                                    <select class="form-control"
                                            id="clienteId"
                                            name="clienteId"
                                            required>

                                        <option value="">
                                            Selecciona un cliente
                                        </option>

                                        <% for (Cliente cliente : clientes) { %>
                                        <% if ("activo".equalsIgnoreCase(
                                                    cliente.getEstado())) {%>

                                        <option value="<%= cliente.getClienteId()%>">
                                            <%= escapar(cliente.getNombre())%>
                                        </option>

                                        <% } %>
                                        <% } %>

                                    </select>
                                </div>

                                <div class="form-group">
                                    <label for="nombre">Nombre del proyecto *</label>

                                    <input class="form-control"
                                           type="text"
                                           id="nombre"
                                           name="nombre"
                                           maxlength="150"
                                           required
                                           placeholder="Ej. Página web corporativa">
                                </div>

                                <div class="form-group span-2">
                                    <label for="descripcion">Descripción</label>

                                    <textarea class="form-control"
                                              id="descripcion"
                                              name="descripcion"
                                              rows="3"
                                              style="resize:vertical"
                                              placeholder="Describe el objetivo y alcance del proyecto"></textarea>
                                </div>

                                <div class="form-group">
                                    <label for="fechaInicio">Fecha de inicio *</label>

                                    <input class="form-control"
                                           type="date"
                                           id="fechaInicio"
                                           name="fechaInicio"
                                           required>
                                </div>

                                <div class="form-group">
                                    <label for="fechaFin">Fecha de fin</label>

                                    <input class="form-control"
                                           type="date"
                                           id="fechaFin"
                                           name="fechaFin">
                                    <div class="form-hint">
                                        Puedes dejarla vacía si todavía no está definida.
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label for="estado">Estado</label>

                                    <select class="form-control"
                                            id="estado"
                                            name="estado">

                                        <option value="planificado">Planificado</option>
                                        <option value="en_progreso">En progreso</option>
                                        <option value="completado">Completado</option>
                                        <option value="cancelado">Cancelado</option>

                                    </select>
                                </div>

                            </div>

                            <div id="createError" class="form-error"></div>

                            <div style="display:flex;gap:9px;margin-top:20px;flex-wrap:wrap">

                                <button type="submit" class="btn btn-primary">
                                    Guardar proyecto
                                </button>

                                <button type="reset" class="btn btn-outline">
                                    Limpiar formulario
                                </button>

                            </div>

                        </form>

                        <% } %>

                    </section>

                    <div style="height:22px"></div>

                    <!-- TABLA DE PROYECTOS -->
                    <section class="table-card">

                        <div class="table-toolbar">

                            <div>
                                <div class="project-toolbar-title">
                                    Directorio de proyectos
                                </div>

                                <p class="project-toolbar-description">
                                    Consulta y administra los proyectos registrados en LUMYN.
                                </p>
                            </div>

                        </div>

                        <div class="project-filter">

                            <input type="search"
                                   class="form-control search-input"
                                   id="searchProjects"
                                   placeholder="Buscar proyecto o cliente..."
                                   aria-label="Buscar proyectos">

                            <select class="form-control"
                                    id="filterStatus"
                                    aria-label="Filtrar por estado"
                                    style="max-width:200px">

                                <option value="">Todos los estados</option>
                                <option value="planificado">Planificado</option>
                                <option value="en_progreso">En progreso</option>
                                <option value="completado">Completado</option>
                                <option value="cancelado">Cancelado</option>

                            </select>

                        </div>

                        <div class="table-scroll">

                            <table id="projectsTable">

                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Proyecto</th>
                                        <th>Cliente</th>
                                        <th>Fecha de inicio</th>
                                        <th>Fecha de fin</th>
                                        <th>Estado</th>
                                        <th>Acciones</th>
                                    </tr>
                                </thead>

                                <tbody id="projectsTableBody">

                                    <% if (proyectos.isEmpty()) { %>

                                    <tr>
                                        <td colspan="7">
                                            <div class="empty-state">
                                                Todavía no hay proyectos registrados.
                                                Registra el primero usando el formulario.
                                            </div>
                                        </td>
                                    </tr>

                                    <% } else { %>

                                    <% for (Proyecto proyecto : proyectos) { %>

                                    <%
                                        String nombreCliente = "Cliente #"
                                                + proyecto.getClienteId();

                                        for (Cliente cliente : clientes) {
                                            if (cliente.getClienteId()
                                                    == proyecto.getClienteId()) {
                                                nombreCliente = cliente.getNombre();
                                                break;
                                            }
                                        }

                                        String estado = proyecto.getEstado() == null
                                                ? "planificado" : proyecto.getEstado();

                                        String inicio = proyecto.getFechaInicio() == null
                                                ? "" : proyecto.getFechaInicio().toString();

                                        String fin = proyecto.getFechaFin() == null
                                                ? "" : proyecto.getFechaFin().toString();
                                    %>

                                    <tr class="project-row"
                                        data-search="<%= escapar(
                                                (proyecto.getNombre() + " " + nombreCliente)
                                                        .toLowerCase()
                                        )%>"
                                        data-status="<%= escapar(estado)%>">

                                        <td>#<%= proyecto.getProyectoId()%></td>

                                        <td>
                                            <span class="project-name">
                                                <%= escapar(proyecto.getNombre())%>
                                            </span>

                                            <% if (proyecto.getDescripcion() != null
                                                        && !proyecto.getDescripcion().isBlank()) {%>

                                            <span class="project-description">
                                                <%= escapar(proyecto.getDescripcion())%>
                                            </span>

                                            <% }%>
                                        </td>

                                        <td><%= escapar(nombreCliente)%></td>

                                        <td><%= escapar(inicio)%></td>

                                        <td>
                                            <%= fin.isEmpty()
                                                    ? "Sin definir"
                                                    : escapar(fin)%>
                                        </td>

                                        <td>
                                            <span class="badge <%= claseEstado(estado)%>">
                                                <%= nombreEstado(estado)%>
                                            </span>
                                        </td>

                                        <td>
                                            <div class="table-actions">
                                                <a href="solped?accion=nueva&proyectoId=<%= proyecto.getProyectoId()%>"
                                                   class="btn btn-primary btn-small">
                                                    Crear cotización
                                                </a>

                                                <button type="button"
                                                        class="btn btn-outline btn-small"
                                                        onclick="editarProyecto(this)"
                                                        data-id="<%= proyecto.getProyectoId()%>"
                                                        data-cliente="<%= proyecto.getClienteId()%>"
                                                        data-nombre="<%= escapar(proyecto.getNombre())%>"
                                                        data-descripcion="<%= escapar(proyecto.getDescripcion())%>"
                                                        data-inicio="<%= escapar(inicio)%>"
                                                        data-fin="<%= escapar(fin)%>"
                                                        data-estado="<%= escapar(estado)%>">

                                                    Editar

                                                </button>

                                                <% if (!"cancelado".equals(estado)) {%>

                                                <form action="proyectos"
                                                      method="post"
                                                      onsubmit="return confirm('¿Deseas cancelar este proyecto?')">

                                                    <input type="hidden"
                                                           name="accion"
                                                           value="cambiarEstado">

                                                    <input type="hidden"
                                                           name="proyectoId"
                                                           value="<%= proyecto.getProyectoId()%>">

                                                    <input type="hidden"
                                                           name="estado"
                                                           value="cancelado">

                                                    <button type="submit"
                                                            class="btn btn-danger-light btn-small">
                                                        Cancelar
                                                    </button>

                                                </form>

                                                <% } else {%>

                                                <form action="proyectos"
                                                      method="post"
                                                      onsubmit="return confirm('¿Deseas reactivar este proyecto?')">

                                                    <input type="hidden"
                                                           name="accion"
                                                           value="cambiarEstado">

                                                    <input type="hidden"
                                                           name="proyectoId"
                                                           value="<%= proyecto.getProyectoId()%>">

                                                    <input type="hidden"
                                                           name="estado"
                                                           value="planificado">

                                                    <button type="submit"
                                                            class="btn btn-dark btn-small">
                                                        Reactivar
                                                    </button>

                                                </form>

                                                <% } %>

                                            </div>
                                        </td>

                                    </tr>

                                    <% } %>

                                    <% }%>

                                </tbody>

                            </table>

                        </div>

                        <div class="table-footer" id="projectsCount">
                            Mostrando <%= totalProyectos%> proyectos
                        </div>

                    </section>

                </section>

            </main>
        </div>

        <!-- MODAL PARA EDITAR PROYECTO -->
        <div class="modal-backdrop"
             id="projectModal"
             hidden>

            <form class="modal"
                  id="editProjectForm"
                  action="proyectos"
                  method="post">

                <div class="modal-header">

                    <h2 id="modalTitle">Editar proyecto</h2>

                    <button type="button"
                            class="modal-close"
                            onclick="cerrarModal()"
                            aria-label="Cerrar">
                        ✕
                    </button>

                </div>

                <div class="modal-body">

                    <input type="hidden"
                           name="accion"
                           value="actualizar">

                    <input type="hidden"
                           name="proyectoId"
                           id="editProyectoId">

                    <div class="form-grid">

                        <div class="form-group">
                            <label for="editClienteId">Cliente *</label>

                            <select class="form-control"
                                    name="clienteId"
                                    id="editClienteId"
                                    required>

                                <% for (Cliente cliente : clientes) {%>

                                <option value="<%= cliente.getClienteId()%>">
                                    <%= escapar(cliente.getNombre())%>
                                </option>

                                <% }%>

                            </select>
                        </div>

                        <div class="form-group">
                            <label for="editNombre">Nombre del proyecto *</label>

                            <input class="form-control"
                                   type="text"
                                   name="nombre"
                                   id="editNombre"
                                   maxlength="150"
                                   required>
                        </div>

                        <div class="form-group span-2">
                            <label for="editDescripcion">Descripción</label>

                            <textarea class="form-control"
                                      name="descripcion"
                                      id="editDescripcion"
                                      rows="3"
                                      style="resize:vertical"></textarea>
                        </div>

                        <div class="form-group">
                            <label for="editFechaInicio">Fecha de inicio *</label>

                            <input class="form-control"
                                   type="date"
                                   name="fechaInicio"
                                   id="editFechaInicio"
                                   required>
                        </div>

                        <div class="form-group">
                            <label for="editFechaFin">Fecha de fin</label>

                            <input class="form-control"
                                   type="date"
                                   name="fechaFin"
                                   id="editFechaFin">
                        </div>

                        <div class="form-group span-2">
                            <label for="editEstado">Estado</label>

                            <select class="form-control"
                                    name="estado"
                                    id="editEstado">

                                <option value="planificado">Planificado</option>
                                <option value="en_progreso">En progreso</option>
                                <option value="completado">Completado</option>
                                <option value="cancelado">Cancelado</option>

                            </select>
                        </div>

                    </div>

                    <div id="editError" class="form-error"></div>

                </div>

                <div class="modal-footer">

                    <button type="button"
                            class="btn btn-outline"
                            onclick="cerrarModal()">
                        Cancelar
                    </button>

                    <button type="submit"
                            class="btn btn-primary">
                        Guardar cambios
                    </button>

                </div>

            </form>
        </div>

        <script>
            "use strict";

            const roleMenus = {
                ADMINISTRADOR: [
                    {label: "Panel principal", icon: "▦", href: "dashboard"},
                    {label: "Usuarios y roles", icon: "♙", href: "usuarios"},
                    {label: "Seguridad", icon: "◇", action: "seguridad"},
                    {label: "Clientes", icon: "♧", href: "clientes"},
                    {label: "Proyectos", icon: "▣", href: "proyectos"},
                    {label: "Tareas", icon: "☷", action: "tareas"},
                    {label: "Entregables", icon: "▤", action: "entregables"},
                    {label: "Reportes", icon: "▥", action: "reportes"}
                ],

                GESTOR: [
                    {label: "Panel principal", icon: "▦", href: "dashboard"},
                    {label: "Clientes", icon: "♧", href: "clientes"},
                    {label: "Proyectos", icon: "▣", href: "proyectos"},
                    {label: "Tareas", icon: "☷", action: "tareas"},
                    {label: "Entregables", icon: "▤", action: "entregables"},
                    {label: "Reportes", icon: "▥", action: "reportes"}
                ],

                COLABORADOR: [
                    {label: "Panel principal", icon: "▦", href: "dashboard"},
                    {label: "Mis tareas", icon: "☷", action: "tareas"},
                    {label: "Entregables", icon: "▤", action: "entregables"},
                    {label: "Notificaciones", icon: "♧", action: "notificaciones"}
                ],

                REVISOR: [
                    {label: "Panel principal", icon: "▦", href: "dashboard"},
                    {label: "Proyectos", icon: "▣", action: "proyectos"},
                    {label: "Revisión de entregables", icon: "▤", action: "entregables"},
                    {label: "Observaciones", icon: "☷", action: "observaciones"}
                ]
            };


            function renderSidebar(rol) {
                const nav = document.getElementById("sidebarNavigation");
                const menu = roleMenus[rol];

                if (!menu)
                    return;

                const rutaActual = window.location.pathname
                        .split("/")
                        .filter(Boolean)
                        .pop();

                nav.innerHTML = menu.map(function (item) {
                    const activo = item.href === rutaActual;

                    let enlace = item.href || "#";
                    let atributoAccion = "";

                    if (item.action) {
                        atributoAccion = 'data-action="' + item.action + '"';
                    }

                    return '<a class="nav-link ' + (activo ? "active" : "") + '"'
                            + ' href="' + enlace + '" '
                            + atributoAccion + '>'
                            + '<span class="nav-icon">' + item.icon + '</span>'
                            + item.label
                            + '</a>';
                }).join("");

                nav.querySelectorAll("[data-action]").forEach(function (link) {
                    link.addEventListener("click", function (event) {
                        event.preventDefault();

                        mostrarAviso(
                                "El módulo de " + this.textContent.trim()
                                + " todavía está en desarrollo."
                                );
                    });
                });
            }


            function cargarPerfil() {
                const nombre = document.body.dataset.nombreUsuario || "Usuario Lumyn";
                const rol = (document.body.dataset.rolUsuario || "ADMINISTRADOR")
                        .trim().toUpperCase();

                document.getElementById("sidebarUserName").textContent = nombre;
                document.getElementById("sidebarUserRole").textContent =
                        rol.charAt(0) + rol.slice(1).toLowerCase();

                let iniciales = "UL";
                const partes = nombre.trim().split(/\s+/).filter(Boolean);

                if (partes.length >= 2) {
                    iniciales = (
                            partes[0].charAt(0) +
                            partes[partes.length - 1].charAt(0)
                            ).toUpperCase();
                } else if (partes.length === 1) {
                    iniciales = partes[0].substring(0, 2).toUpperCase();
                }

                document.getElementById("sidebarAvatar").textContent = iniciales;
                document.getElementById("topbarAvatar").textContent = iniciales;

                renderSidebar(rol);
            }

            document.getElementById("pageDate").textContent =
                    new Intl.DateTimeFormat("es-PE", {
                        dateStyle: "medium"
                    }).format(new Date());

            const projectModal = document.getElementById("projectModal");

            function abrirCrearProyecto() {
                document.getElementById("formularioProyecto")
                        .scrollIntoView({behavior: "smooth", block: "start"});

                const campoNombre = document.getElementById("nombre");

                if (campoNombre) {
                    setTimeout(() => campoNombre.focus(), 300);
                }
            }

            function editarProyecto(boton) {
                document.getElementById("editProyectoId").value =
                        boton.dataset.id;

                document.getElementById("editClienteId").value =
                        boton.dataset.cliente;

                document.getElementById("editNombre").value =
                        boton.dataset.nombre;

                document.getElementById("editDescripcion").value =
                        boton.dataset.descripcion || "";

                document.getElementById("editFechaInicio").value =
                        boton.dataset.inicio;

                document.getElementById("editFechaFin").value =
                        boton.dataset.fin || "";

                document.getElementById("editEstado").value =
                        boton.dataset.estado;

                document.getElementById("editError").classList.remove("visible");

                projectModal.hidden = false;
            }

            function cerrarModal() {
                projectModal.hidden = true;
            }

            projectModal.addEventListener("click", function (event) {
                if (event.target === projectModal) {
                    cerrarModal();
                }
            });

            document.addEventListener("keydown", function (event) {
                if (event.key === "Escape") {
                    cerrarModal();
                }
            });

            function validarFormularioProyecto(form, errorId) {
                const inicio = form.querySelector('[name="fechaInicio"]').value;
                const fin = form.querySelector('[name="fechaFin"]').value;
                const nombre = form.querySelector('[name="nombre"]').value.trim();
                const error = document.getElementById(errorId);

                error.textContent = "";
                error.classList.remove("visible");

                if (!nombre) {
                    error.textContent = "Ingresa el nombre del proyecto.";
                    error.classList.add("visible");
                    return false;
                }

                if (fin && inicio && fin < inicio) {
                    error.textContent =
                            "La fecha de fin no puede ser anterior a la fecha de inicio.";
                    error.classList.add("visible");
                    return false;
                }

                return true;
            }

            const createForm = document.getElementById("createProjectForm");

            if (createForm) {
                createForm.addEventListener("submit", function (event) {
                    if (!validarFormularioProyecto(this, "createError")) {
                        event.preventDefault();
                    }
                });

                createForm.addEventListener("reset", function () {
                    const error = document.getElementById("createError");
                    error.textContent = "";
                    error.classList.remove("visible");
                });
            }

            document.getElementById("editProjectForm")
                    .addEventListener("submit", function (event) {
                        if (!validarFormularioProyecto(this, "editError")) {
                            event.preventDefault();
                        }
                    });

            // BÚSQUEDA Y FILTRO
            function filtrarProyectos() {
                const busqueda = document.getElementById("searchProjects")
                        .value.toLowerCase().trim();

                const estadoSeleccionado =
                        document.getElementById("filterStatus").value;

                const filas = document.querySelectorAll(".project-row");
                let visibles = 0;

                filas.forEach(fila => {
                    const texto = fila.dataset.search || "";
                    const estado = fila.dataset.status || "";

                    const coincideTexto = texto.includes(busqueda);
                    const coincideEstado = !estadoSeleccionado
                            || estado === estadoSeleccionado;

                    const mostrar = coincideTexto && coincideEstado;

                    fila.style.display = mostrar ? "" : "none";

                    if (mostrar)
                        visibles++;
                });

                document.getElementById("projectsCount").textContent =
                        "Mostrando " + visibles + " de " + filas.length + " proyectos";
            }

            document.getElementById("searchProjects")
                    .addEventListener("input", filtrarProyectos);

            document.getElementById("filterStatus")
                    .addEventListener("change", filtrarProyectos);

            function mostrarAviso(mensaje) {
                const toast = document.createElement("div");
                toast.className = "toast";
                toast.textContent = mensaje;

                document.body.appendChild(toast);

                setTimeout(() => toast.remove(), 3000);
            }

            // RESULTADO DE LA OPERACIÓN
            const parametros = new URLSearchParams(window.location.search);
            const resultado = parametros.get("resultado");

            if (resultado === "ok") {
                mostrarAviso("La operación se procesó correctamente.");

                window.history.replaceState(
                        {},
                        document.title,
                        window.location.pathname
                        );
            }

            cargarPerfil();
        </script>

    </body>
</html>
