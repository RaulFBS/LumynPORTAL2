<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Locale"%>
<%@page import="java.text.NumberFormat"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="pe.lumyn.portal.model.Venta"%>
<%@page import="pe.lumyn.portal.security.PermisosUtil"%>

<%!
    private String escapar(String texto) {
        if (texto == null) return "";
        return texto.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }

    private String nombreEstadoVenta(String estado) {
        if (estado == null) return "Sin estado";

        switch (estado) {
            case "pendiente":
                return "Pendiente";
            case "confirmada":
                return "Confirmada";
            case "en_proceso":
                return "En proceso";
            case "completada":
                return "Completada";
            case "anulada":
                return "Anulada";
            default:
                return estado;
        }
    }

    private String claseEstadoVenta(String estado) {
        if ("confirmada".equals(estado)
                || "completada".equals(estado)) {
            return "badge-green";
        }

        if ("pendiente".equals(estado)
                || "en_proceso".equals(estado)) {
            return "badge-yellow";
        }

        if ("anulada".equals(estado)) {
            return "badge-red";
        }

        return "badge-gray";
    }
%>

<%
    List<Venta> ventas =
            (List<Venta>) request.getAttribute("ventas");

    if (ventas == null) {
        ventas = java.util.Collections.emptyList();
    }

    NumberFormat moneda = NumberFormat.getNumberInstance(
            new Locale("es", "PE")
    );
    moneda.setMinimumFractionDigits(2);
    moneda.setMaximumFractionDigits(2);

    SimpleDateFormat formatoFecha =
            new SimpleDateFormat("dd/MM/yyyy HH:mm");

    int totalVentas = ventas.size();
    int confirmadas = 0;
    int pendientes = 0;
    int completadas = 0;
    double totalFacturado = 0;

    for (Venta venta : ventas) {
        String estado = venta.getEstado();

        if ("confirmada".equals(estado)) confirmadas++;
        if ("pendiente".equals(estado)) pendientes++;
        if ("completada".equals(estado)) completadas++;

        if (!"anulada".equals(estado)
                && venta.getTotal() != null) {
            totalFacturado += venta.getTotal().doubleValue();
        }
    }

    String ctx = request.getContextPath();

    boolean esAdministrador =
            PermisosUtil.esAdministrador(session);

    String rolActual = esAdministrador
            ? "ADMINISTRADOR" : "GESTOR";

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

    <title>Ventas | LUMYN</title>

    <base href="<%= ctx %>/">
    <link rel="stylesheet" href="css/styles.css">

    <style>
        .sale-description {
            color: var(--muted);
            font-size: 10px;
            line-height: 1.6;
            margin-top: 5px;
        }

        .sale-filter {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            padding: 17px 19px;
            border-bottom: 1px solid var(--border);
        }

        .sale-filter .form-control {
            max-width: 300px;
        }

        .sale-toolbar-title {
            font-size: 14px;
            font-weight: 700;
        }

        .sale-toolbar-description {
            color: var(--muted);
            font-size: 10px;
            margin-top: 6px;
        }

        .sale-total {
            font-weight: 700;
            white-space: nowrap;
        }

        .sale-row td {
            vertical-align: middle;
        }

        .sale-id {
            font-weight: 700;
        }

        @media (max-width: 760px) {
            .sale-filter {
                padding: 14px;
            }

            .sale-filter .form-control {
                max-width: none;
                width: 100%;
            }
        }
    </style>
</head>

<body data-nombre-usuario="<%= escapar(nombreUsuario) %>"
      data-rol-usuario="<%= escapar(rolActual) %>">

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
                    LUMYN / Gestión / <strong>Ventas</strong>
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
                        <h1>Ventas</h1>
                        <p>
                            Consulta las ventas registradas, los importes
                            y su relación con las SOLPED y los proyectos.
                        </p>
                    </div>
                </div>

                <!-- MENSAJE DE RESULTADO -->
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
                        <div class="stat-title">Total de ventas</div>
                        <div class="stat-value"><%= totalVentas %></div>
                        <div class="stat-foot">Ventas registradas</div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-symbol">✓</div>
                        <div class="stat-title">Confirmadas</div>
                        <div class="stat-value"><%= confirmadas %></div>
                        <div class="stat-foot">Ventas confirmadas</div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-symbol">◷</div>
                        <div class="stat-title">Pendientes</div>
                        <div class="stat-value"><%= pendientes %></div>
                        <div class="stat-foot">Ventas por atender</div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-symbol">S/</div>
                        <div class="stat-title">Importe no anulado</div>
                        <div class="stat-value">
                            S/ <%= moneda.format(totalFacturado) %>
                        </div>
                        <div class="stat-foot">Excluye ventas anuladas</div>
                    </div>

                </div>

                <div style="height:22px"></div>

                <!-- TABLA DE VENTAS -->
                <section class="table-card">

                    <div class="table-toolbar">
                        <div>
                            <div class="sale-toolbar-title">
                                Directorio de ventas
                            </div>
                            <p class="sale-toolbar-description">
                                Consulta los importes y estados de las ventas de LUMYN.
                            </p>
                        </div>
                    </div>

                    <!-- BÚSQUEDA Y FILTRO -->
                    <div class="sale-filter">

                        <input type="search"
                               class="form-control search-input"
                               id="searchSales"
                               placeholder="Buscar venta, SOLPED, cliente o proyecto..."
                               aria-label="Buscar ventas">

                        <select class="form-control"
                                id="filterSaleStatus"
                                aria-label="Filtrar por estado"
                                style="max-width:200px">

                            <option value="">Todos los estados</option>
                            <option value="pendiente">Pendiente</option>
                            <option value="confirmada">Confirmada</option>
                            <option value="en_proceso">En proceso</option>
                            <option value="completada">Completada</option>
                            <option value="anulada">Anulada</option>

                        </select>

                    </div>

                    <div class="table-scroll">

                        <table id="salesTable">

                            <thead>
                                <tr>
                                    <th>Venta</th>
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

                            <tbody id="salesTableBody">

                                <% if (ventas.isEmpty()) { %>

                                <tr>
                                    <td colspan="9">
                                        <div class="empty-state">
                                            Todavía no hay ventas registradas.
                                        </div>
                                    </td>
                                </tr>

                                <% } else { %>

                                    <% for (Venta venta : ventas) {
                                        String estado = venta.getEstado() == null
                                                ? "" : venta.getEstado();

                                        String fecha = venta.getFechaVenta() == null
                                                ? "-"
                                                : formatoFecha.format(venta.getFechaVenta());

                                        String proyecto = venta.getProyectoId() == null
                                                ? "Sin proyecto"
                                                : "#" + venta.getProyectoId();

                                        String textoBusqueda =
                                                ("#" + venta.getVentaId() + " "
                                                + "#" + venta.getSolpedId() + " "
                                                + "#" + venta.getClienteId() + " "
                                                + proyecto + " " + estado).toLowerCase();
                                    %>

                                    <tr class="sale-row"
                                        data-search="<%= escapar(textoBusqueda) %>"
                                        data-status="<%= escapar(estado) %>">

                                        <td class="sale-id">
                                            #<%= venta.getVentaId() %>
                                        </td>

                                        <td>
                                            #<%= venta.getSolpedId() %>
                                        </td>

                                        <td>
                                            #<%= venta.getClienteId() %>
                                        </td>

                                        <td>
                                            <%= escapar(proyecto) %>
                                        </td>

                                        <td>
                                            <%= escapar(fecha) %>
                                        </td>

                                        <td>
                                            S/ <%= moneda.format(venta.getSubtotal()) %>
                                        </td>

                                        <td>
                                            S/ <%= moneda.format(venta.getImpuesto()) %>
                                        </td>

                                        <td class="sale-total">
                                            S/ <%= moneda.format(venta.getTotal()) %>
                                        </td>

                                        <td>
                                            <span class="badge <%= claseEstadoVenta(estado) %>">
                                                <%= escapar(nombreEstadoVenta(estado)) %>
                                            </span>
                                        </td>

                                    </tr>

                                    <% } %>

                                <% } %>

                            </tbody>

                        </table>

                    </div>

                    <div class="table-footer" id="salesCount">
                        Mostrando <%= totalVentas %> ventas
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

            if (!menu) return;

            const rutaActual = window.location.pathname
                    .split("/")
                    .filter(Boolean)
                    .pop();

            nav.innerHTML = menu.map(function (item) {
                const activo = item.href === rutaActual;
                const enlace = item.href || "#";
                const atributoAccion = item.action
                        ? 'data-action="' + item.action + '"'
                        : "";

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

        function filtrarVentas() {
            const busqueda = document.getElementById("searchSales")
                    .value.toLowerCase().trim();

            const estadoSeleccionado =
                    document.getElementById("filterSaleStatus").value;

            const filas = document.querySelectorAll(".sale-row");
            let visibles = 0;

            filas.forEach(function (fila) {
                const texto = fila.dataset.search || "";
                const estado = fila.dataset.status || "";

                const coincideTexto = texto.includes(busqueda);
                const coincideEstado = !estadoSeleccionado
                        || estado === estadoSeleccionado;

                const mostrar = coincideTexto && coincideEstado;
                fila.style.display = mostrar ? "" : "none";

                if (mostrar) visibles++;
            });

            document.getElementById("salesCount").textContent =
                    "Mostrando " + visibles + " de " + filas.length + " ventas";
        }

        document.getElementById("searchSales")
                .addEventListener("input", filtrarVentas);

        document.getElementById("filterSaleStatus")
                .addEventListener("change", filtrarVentas);

        function mostrarAviso(mensaje) {
            const toast = document.createElement("div");
            toast.className = "toast";
            toast.textContent = mensaje;
            document.body.appendChild(toast);

            setTimeout(function () {
                toast.remove();
            }, 3000);
        }

        const parametros = new URLSearchParams(window.location.search);
        const resultado = parametros.get("resultado");

        if (resultado === "convertida") {
            mostrarAviso("La SOLPED se convirtió en venta correctamente.");

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