
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.math.BigDecimal"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.text.NumberFormat"%>
<%@page import="java.util.Locale"%>
<%@page import="pe.lumyn.portal.model.Solped"%>
<%@page import="pe.lumyn.portal.model.SolpedDetalle"%>
<%@page import="pe.lumyn.portal.security.PermisosUtil"%>

<%!
    private String escapar(String valor) {
        if (valor == null) return "";

        return valor.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private String nombreEstadoSolped(String estado) {
        if (estado == null) return "Sin estado";

        switch (estado) {
            case "pendiente": return "Pendiente";
            case "en_revision": return "En revisión";
            case "aprobada": return "Aprobada";
            case "rechazada": return "Rechazada";
            case "convertida": return "Convertida";
            default: return estado;
        }
    }

    private String claseEstadoSolped(String estado) {
        if ("aprobada".equals(estado) || "convertida".equals(estado)) {
            return "badge-green";
        }

        if ("pendiente".equals(estado) || "en_revision".equals(estado)) {
            return "badge-yellow";
        }

        if ("rechazada".equals(estado)) {
            return "badge-red";
        }

        return "badge-gray";
    }

    private BigDecimal importeSolped(Solped solicitud) {
        BigDecimal importe = BigDecimal.ZERO;

        if (solicitud != null && solicitud.getDetalles() != null) {
            for (SolpedDetalle detalle : solicitud.getDetalles()) {
                if (detalle.getSubtotal() != null) {
                    importe = importe.add(detalle.getSubtotal());
                }
            }
        }

        return importe;
    }
%>

<%
    List<Solped> solicitudes =
            (List<Solped>) request.getAttribute("solpedLista");

    if (solicitudes == null) {
        solicitudes = new ArrayList<>();
    }

    Solped seleccionada =
            (Solped) request.getAttribute("solpedSeleccionada");

    int total = solicitudes.size();
    int pendientes = 0;
    int revision = 0;
    int aprobadas = 0;
    int rechazadas = 0;

    for (Solped solicitud : solicitudes) {
        String estado = solicitud.getEstado();

        if ("pendiente".equals(estado)) pendientes++;
        if ("en_revision".equals(estado)) revision++;
        if ("aprobada".equals(estado)) aprobadas++;
        if ("rechazada".equals(estado)) rechazadas++;
    }

    SimpleDateFormat formatoFecha =
            new SimpleDateFormat("dd/MM/yyyy HH:mm");

    NumberFormat formatoMoneda =
            NumberFormat.getNumberInstance(new Locale("es", "PE"));

    formatoMoneda.setMinimumFractionDigits(2);
    formatoMoneda.setMaximumFractionDigits(2);

    String ctx = request.getContextPath();

    boolean esAdministrador = PermisosUtil.esAdministrador(session);

    String rolActual = esAdministrador ? "ADMINISTRADOR" : "GESTOR";

    Object nombreSesion = session.getAttribute("nombreUsuario");
    String nombreUsuario = nombreSesion != null
            ? nombreSesion.toString() : "Usuario Lumyn";

    String iniciales = "UL";
    String[] partesNombre = nombreUsuario.trim().split("\\s+");

    if (partesNombre.length >= 2) {
        iniciales = (
                partesNombre[0].substring(0, 1)
                + partesNombre[partesNombre.length - 1].substring(0, 1)
        ).toUpperCase();
    } else if (!nombreUsuario.trim().isEmpty()) {
        iniciales = nombreUsuario.substring(0, 1).toUpperCase();
    }

    String resultado = request.getParameter("resultado");
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>SOLPED | LUMYN</title>

    <base href="<%= ctx %>/">
    <link rel="stylesheet" href="css/styles.css">

    <style>
        .solped-description {
            display: block;
            max-width: 300px;
            white-space: normal;
            color: var(--muted);
            font-size: 10px;
            line-height: 1.6;
            margin-top: 5px;
        }

        .solped-id {
            font-weight: 800;
            color: var(--red);
        }

        .solped-filter {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            padding: 17px 19px;
            border-bottom: 1px solid var(--border);
        }

        .solped-filter .form-control {
            max-width: 300px;
        }

        .solped-toolbar-title {
            font-size: 14px;
            font-weight: 700;
        }

        .solped-toolbar-description {
            color: var(--muted);
            font-size: 10px;
            margin-top: 6px;
        }

        .solped-detail {
            margin-top: 22px;
            margin-bottom: 22px;
        }

        .solped-detail-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 18px;
            margin-bottom: 22px;
        }

        .solped-detail-item {
            padding: 14px;
            background: #FAFAF8;
            border: 1px solid var(--border);
            border-radius: 10px;
            min-width: 0;
        }

        .solped-detail-item small {
            display: block;
            color: var(--muted);
            font-size: 10px;
            margin-bottom: 7px;
        }

        .solped-detail-item strong {
            display: block;
            font-size: 12px;
            overflow-wrap: anywhere;
            white-space: normal;
        }

        .solped-detail-description {
            white-space: pre-wrap;
            overflow-wrap: anywhere;
            line-height: 1.7;
            font-size: 12px;
        }

        .solped-actions {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 8px;
        }

        .solped-actions form {
            display: inline-flex;
            margin: 0;
        }

        .solped-total {
            font-weight: 800;
            white-space: nowrap;
        }

        .solped-state-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 9px;
            margin-top: 22px;
            padding-top: 18px;
            border-top: 1px solid var(--border);
        }

        .solped-state-actions form {
            margin: 0;
        }

        .solped-empty {
            padding: 40px;
            text-align: center;
            color: var(--muted);
            font-size: 12px;
        }

        .solped-alert-space {
            margin-bottom: 20px;
        }

        @media (max-width: 760px) {
            .solped-filter {
                padding: 14px;
            }

            .solped-filter .form-control {
                max-width: none;
            }

            .solped-detail-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>

<body data-nombre-usuario="<%= escapar(nombreUsuario) %>"
      data-rol-usuario="<%= escapar(rolActual) %>">

<div class="app-layout">

    <!-- MENÚ LATERAL -->
    <aside class="sidebar">

        <a href="dashboard" class="sidebar-logo">
            LUM<span>Y</span>N
        </a>

        <div class="sidebar-label">Principal</div>

        <nav id="sidebarNavigation"></nav>

        <div class="sidebar-bottom">

            <div class="user-mini">
                <div class="avatar" id="sidebarAvatar">
                    <%= escapar(iniciales) %>
                </div>

                <div>
                    <strong id="sidebarUserName">
                        <%= escapar(nombreUsuario) %>
                    </strong>
                    <small id="sidebarUserRole">
                        <%= esAdministrador ? "Administrador" : "Gestor" %>
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
                LUMYN / Gestión / <strong>SOLPED</strong>
            </div>

            <div class="topbar-right">
                <span class="date-label" id="pageDate"></span>

                <div class="avatar" id="topbarAvatar">
                    <%= escapar(iniciales) %>
                </div>
            </div>

        </header>

        <section class="content">

            <!-- ENCABEZADO -->
            <div class="page-heading">
                <div>
                    <div class="welcome-tag">Gestión comercial</div>
                    <h1>Solicitudes de pedido</h1>
                    <p>
                        Consulta los requerimientos de tus clientes y administra
                        la revisión y aprobación de solicitudes.
                    </p>
                </div>
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
                    <div class="stat-title">Total de solicitudes</div>
                    <div class="stat-value"><%= total %></div>
                    <div class="stat-foot">Solicitudes registradas</div>
                </div>

                <div class="stat-card">
                    <div class="stat-symbol">◷</div>
                    <div class="stat-title">Pendientes</div>
                    <div class="stat-value"><%= pendientes %></div>
                    <div class="stat-foot">Esperando revisión</div>
                </div>

                <div class="stat-card">
                    <div class="stat-symbol">↗</div>
                    <div class="stat-title">En revisión</div>
                    <div class="stat-value"><%= revision %></div>
                    <div class="stat-foot">Solicitudes en evaluación</div>
                </div>

                <div class="stat-card">
                    <div class="stat-symbol">✓</div>
                    <div class="stat-title">Aprobadas</div>
                    <div class="stat-value"><%= aprobadas %></div>
                    <div class="stat-foot">Listas para continuar</div>
                </div>

            </div>

            <!-- DETALLE DE SOLICITUD -->
            <% if (seleccionada != null) {
                String estadoSeleccionado = seleccionada.getEstado() == null
                        ? "" : seleccionada.getEstado();
            %>

            <section class="card solped-detail">

                <div class="card-heading">
                    <div>
                        <h3>
                            Detalle de SOLPED #<%= seleccionada.getSolpedId() %>
                        </h3>
                        <p class="solped-toolbar-description">
                            Información y servicios incluidos en la solicitud.
                        </p>
                    </div>

                    <a href="solped" class="btn btn-outline">
                        Volver al listado
                    </a>
                </div>

                <div class="solped-detail-grid">

                    <div class="solped-detail-item">
                        <small>Número de solicitud</small>
                        <strong>#<%= seleccionada.getSolpedId() %></strong>
                    </div>

                    <div class="solped-detail-item">
                        <small>Cliente</small>
                        <strong>
                            Cliente #<%= seleccionada.getClienteId() %>
                        </strong>
                    </div>

                    <div class="solped-detail-item">
                        <small>Fecha de solicitud</small>
                        <strong>
                            <%= seleccionada.getFechaSolicitud() == null
                                    ? "Sin fecha"
                                    : formatoFecha.format(seleccionada.getFechaSolicitud()) %>
                        </strong>
                    </div>

                    <div class="solped-detail-item">
                        <small>Estado actual</small>
                        <strong>
                            <span class="badge <%= claseEstadoSolped(estadoSeleccionado) %>">
                                <%= escapar(nombreEstadoSolped(estadoSeleccionado)) %>
                            </span>
                        </strong>
                    </div>

                </div>

                <div class="form-group">
                    <label>Descripción del requerimiento</label>
                    <div class="solped-detail-description"><%= escapar(
                            seleccionada.getDescripcionRequerimiento() == null
                                    ? "Sin descripción"
                                    : seleccionada.getDescripcionRequerimiento()
                    ) %></div>
                </div>

                <div class="card-heading" style="margin-top:24px;">
                    <h3>Servicios solicitados</h3>
                </div>

                <div class="table-scroll">
                    <table>
                        <thead>
                            <tr>
                                <th>Servicio</th>
                                <th>Descripción</th>
                                <th>Cantidad</th>
                                <th>Precio unitario</th>
                                <th>Subtotal</th>
                            </tr>
                        </thead>

                        <tbody>
                            <% if (seleccionada.getDetalles() != null
                                    && !seleccionada.getDetalles().isEmpty()) {
                                for (SolpedDetalle detalle : seleccionada.getDetalles()) {
                            %>
                            <tr>
                                <td><%= escapar(detalle.getServicio()) %></td>
                                <td>
                                    <%= escapar(detalle.getDescripcion() == null
                                            ? "-" : detalle.getDescripcion()) %>
                                </td>
                                <td>
                                    <%= detalle.getCantidad() == null
                                            ? "0" : detalle.getCantidad().toPlainString() %>
                                </td>
                                <td>
                                    S/ <%= formatoMoneda.format(
                                            detalle.getPrecioUnitario() == null
                                                    ? BigDecimal.ZERO
                                                    : detalle.getPrecioUnitario()) %>
                                </td>
                                <td>
                                    S/ <%= formatoMoneda.format(
                                            detalle.getSubtotal() == null
                                                    ? BigDecimal.ZERO
                                                    : detalle.getSubtotal()) %>
                                </td>
                            </tr>
                            <%  }
                            } else { %>
                            <tr>
                                <td colspan="5">
                                    <div class="empty-state">
                                        Esta solicitud no tiene servicios registrados.
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>

                        <tfoot>
                            <tr>
                                <td colspan="4" style="text-align:right;font-weight:800;">
                                    Importe estimado
                                </td>
                                <td class="solped-total">
                                    S/ <%= formatoMoneda.format(importeSolped(seleccionada)) %>
                                </td>
                            </tr>
                        </tfoot>
                    </table>
                </div>

                <% if ("pendiente".equals(estadoSeleccionado)
                        || "en_revision".equals(estadoSeleccionado)) { %>

                <div class="solped-state-actions">

                    <form method="post"
                          action="solped"
                          onsubmit="return confirm('¿Deseas aprobar esta solicitud?');">

                        <input type="hidden" name="accion" value="cambiarEstado">
                        <input type="hidden" name="solpedId"
                               value="<%= seleccionada.getSolpedId() %>">
                        <input type="hidden" name="estado" value="aprobada">

                        <button type="submit" class="btn btn-primary">
                            ✓ Aprobar solicitud
                        </button>
                    </form>

                    <form method="post"
                          action="solped"
                          onsubmit="return confirm('¿Deseas rechazar esta solicitud?');">

                        <input type="hidden" name="accion" value="cambiarEstado">
                        <input type="hidden" name="solpedId"
                               value="<%= seleccionada.getSolpedId() %>">
                        <input type="hidden" name="estado" value="rechazada">

                        <button type="submit" class="btn btn-danger-light">
                            Rechazar solicitud
                        </button>
                    </form>

                </div>

                <% } %>

                <!-- CONVERTIR SOLPED APROBADA EN VENTA -->
                <% if ("aprobada".equals(estadoSeleccionado)) { %>

                <div class="solped-state-actions">

                    <form method="post"
                          action="ventas"
                          onsubmit="return confirm('¿Deseas convertir esta SOLPED en una venta? Esta acción registrará la venta correspondiente.');">

                        <input type="hidden"
                               name="accion"
                               value="convertirSolped">

                        <input type="hidden"
                               name="solpedId"
                               value="<%= seleccionada.getSolpedId() %>">

                        <% if (seleccionada.getProyectoId() != null) { %>
                        <input type="hidden"
                               name="proyectoId"
                               value="<%= seleccionada.getProyectoId() %>">
                        <% } %>

                        <button type="submit" class="btn btn-primary">
                            Convertir en venta
                        </button>

                    </form>

                </div>

                <% } %>

            </section>

            <% } %>

            <!-- LISTADO -->
            <section class="table-card">

                <div class="table-toolbar">
                    <div>
                        <div class="solped-toolbar-title">
                            Directorio de solicitudes
                        </div>
                        <p class="solped-toolbar-description">
                            Busca por número, cliente o requerimiento y filtra por estado.
                        </p>
                    </div>
                </div>

                <div class="solped-filter">

                    <input type="search"
                           class="form-control search-input"
                           id="buscarSolped"
                           placeholder="Buscar solicitud, cliente o descripción..."
                           aria-label="Buscar solicitudes">

                    <select class="form-control"
                            id="filtroEstado"
                            aria-label="Filtrar solicitudes por estado"
                            style="max-width:200px;">

                        <option value="">Todos los estados</option>
                        <option value="pendiente">Pendiente</option>
                        <option value="en_revision">En revisión</option>
                        <option value="aprobada">Aprobada</option>
                        <option value="rechazada">Rechazada</option>
                        <option value="convertida">Convertida</option>

                    </select>

                </div>

                <div class="table-scroll">

                    <table id="tablaSolped">

                        <thead>
                            <tr>
                                <th>N.º SOLPED</th>
                                <th>Cliente</th>
                                <th>Fecha de solicitud</th>
                                <th>Requerimiento</th>
                                <th>Importe estimado</th>
                                <th>Estado</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>

                        <tbody>

                            <% if (solicitudes.isEmpty()) { %>

                            <tr>
                                <td colspan="7">
                                    <div class="empty-state">
                                        Todavía no hay solicitudes registradas.
                                    </div>
                                </td>
                            </tr>

                            <% } else {
                                for (Solped solicitud : solicitudes) {
                                    String estado = solicitud.getEstado() == null
                                            ? "" : solicitud.getEstado();

                                    String descripcion =
                                            solicitud.getDescripcionRequerimiento() == null
                                                    ? "Sin descripción"
                                                    : solicitud.getDescripcionRequerimiento();

                                    String fecha = solicitud.getFechaSolicitud() == null
                                            ? "Sin fecha"
                                            : formatoFecha.format(solicitud.getFechaSolicitud());

                                    String textoBusqueda = (
                                            solicitud.getSolpedId() + " "
                                            + solicitud.getClienteId() + " "
                                            + descripcion + " "
                                            + nombreEstadoSolped(estado)
                                    ).toLowerCase();
                            %>

                            <tr class="solped-row"
                                data-estado="<%= escapar(estado) %>"
                                data-busqueda="<%= escapar(textoBusqueda) %>">

                                <td>
                                    <span class="solped-id">
                                        #<%= solicitud.getSolpedId() %>
                                    </span>
                                </td>

                                <td>
                                    Cliente #<%= solicitud.getClienteId() %>
                                </td>

                                <td><%= escapar(fecha) %></td>

                                <td>
                                    <span class="solped-description">
                                        <%= escapar(descripcion) %>
                                    </span>
                                </td>

                                <td class="solped-total">
                                    S/ <%= formatoMoneda.format(importeSolped(solicitud)) %>
                                </td>

                                <td>
                                    <span class="badge <%= claseEstadoSolped(estado) %>">
                                        <%= escapar(nombreEstadoSolped(estado)) %>
                                    </span>
                                </td>

                                <td>
                                    <div class="table-actions">
                                        <a class="btn btn-outline btn-small"
                                           href="solped?id=<%= solicitud.getSolpedId() %>">
                                            Ver detalle
                                        </a>
                                    </div>
                                </td>

                            </tr>

                            <%  }
                            } %>

                        </tbody>

                    </table>

                </div>

                <div class="table-footer" id="solpedCount">
                    Mostrando <%= total %> solicitudes
                </div>

            </section>

        </section>

    </main>
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
            {label: "SOLPED", icon: "▤", href: "solped"},
            {label: "Ventas", icon: "S/", href: "ventas"},
            {label: "Tareas", icon: "☷", action: "tareas"},
            {label: "Entregables", icon: "▤", action: "entregables"},
            {label: "Reportes", icon: "▥", action: "reportes"}
        ],

        GESTOR: [
            {label: "Panel principal", icon: "▦", href: "dashboard"},
            {label: "Clientes", icon: "♧", href: "clientes"},
            {label: "Proyectos", icon: "▣", href: "proyectos"},
            {label: "SOLPED", icon: "▤", href: "solped"},
            {label: "Ventas", icon: "S/", href: "ventas"},
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

    function mostrarAviso(mensaje) {
        const toast = document.getElementById("mensajeResultado");

        toast.textContent = mensaje;
        toast.style.display = "block";

        window.setTimeout(function () {
            toast.style.display = "none";
        }, 4000);
    }

    function renderSidebar(rol) {
        const nav = document.getElementById("sidebarNavigation");
        const menu = roleMenus[rol];

        if (!menu || !nav) return;

        const rutaActual = window.location.pathname
                .split("/")
                .filter(Boolean)
                .pop();

        nav.innerHTML = menu.map(function (item) {
            const activo = item.href === rutaActual;
            const enlace = item.href || "#";
            const accion = item.action
                    ? ' data-action="' + item.action + '"'
                    : "";

            return '<a class="nav-link ' + (activo ? "active" : "") + '"'
                    + ' href="' + enlace + '"' + accion + '>'
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
                partes[0].charAt(0)
                + partes[partes.length - 1].charAt(0)
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

    // BÚSQUEDA Y FILTRO
    const buscador = document.getElementById("buscarSolped");
    const filtroEstado = document.getElementById("filtroEstado");
    const filas = document.querySelectorAll(".solped-row");
    const contador = document.getElementById("solpedCount");

    function filtrarSolicitudes() {
        const texto = buscador.value.toLowerCase().trim();
        const estado = filtroEstado.value;
        let visibles = 0;

        filas.forEach(function (fila) {
            const textoFila = fila.dataset.busqueda || "";
            const estadoFila = fila.dataset.estado || "";

            const coincideTexto = textoFila.includes(texto);
            const coincideEstado = !estado || estadoFila === estado;
            const mostrar = coincideTexto && coincideEstado;

            fila.style.display = mostrar ? "" : "none";

            if (mostrar) visibles++;
        });

        contador.textContent =
                "Mostrando " + visibles + " de " + filas.length + " solicitudes";
    }

    buscador.addEventListener("input", filtrarSolicitudes);
    filtroEstado.addEventListener("change", filtrarSolicitudes);

    // RESULTADO DE LA OPERACIÓN
    const parametros = new URLSearchParams(window.location.search);
    const resultado = parametros.get("resultado");

    if (resultado === "aprobada") {
        mostrarAviso("La solicitud fue aprobada correctamente.");
    } else if (resultado === "rechazada") {
        mostrarAviso("La solicitud fue rechazada.");
    } else if (resultado === "convertida") {
        mostrarAviso("La SOLPED se convirtió en venta correctamente.");
    } else if (resultado === "sin_cambios") {
        mostrarAviso("No se realizaron cambios. Verifica el estado actual.");
    } else if (resultado === "creada") {
        mostrarAviso("La solicitud se creó correctamente.");
    }

    if (resultado) {
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
