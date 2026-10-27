
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>
<%@page import="pe.lumyn.portal.model.Cliente"%>
<%@page import="pe.lumyn.portal.model.Proyecto"%>
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
%>

<%
    List<Cliente> clientes =
        (List<Cliente>) request.getAttribute("clientes");

    if (clientes == null) {
        clientes = new ArrayList<>();
    }

    Proyecto proyectoSeleccionado =
        (Proyecto) request.getAttribute("proyectoSeleccionado");

    Object clienteAttr =
        request.getAttribute("clienteSeleccionadoId");

    String clienteSeleccionadoId =
        clienteAttr != null ? clienteAttr.toString() : "";

    String ctx = request.getContextPath();

    boolean esAdministrador =
        PermisosUtil.esAdministrador(session);

    Object nombreSesion = session.getAttribute("nombreUsuario");
    String nombreUsuario = nombreSesion != null
        ? nombreSesion.toString() : "Usuario Lumyn";

    String rolActual = esAdministrador
        ? "ADMINISTRADOR" : "GESTOR";

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
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nueva cotización | LUMYN</title>

    <base href="<%= ctx %>/">
    <link rel="stylesheet" href="css/styles.css">

    <style>
        .quote-section {
            margin-top: 22px;
        }

        .quote-intro {
            color: var(--muted);
            font-size: 11px;
            line-height: 1.7;
            margin-top: 7px;
        }

        .quote-context {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 14px;
            margin-bottom: 20px;
        }

        .quote-context-item {
            border: 1px solid var(--border);
            border-radius: 9px;
            padding: 14px;
            min-width: 0;
        }

        .quote-context-label {
            font-size: 10px;
            color: var(--muted);
            margin-bottom: 7px;
        }

        .quote-context-value {
            font-size: 13px;
            font-weight: 700;
            overflow-wrap: anywhere;
        }

        .quote-table-wrap {
            overflow-x: auto;
        }

        .quote-table {
            width: 100%;
            min-width: 700px;
            border-collapse: collapse;
        }

        .quote-table th,
        .quote-table td {
            padding: 10px 8px;
            text-align: left;
            border-bottom: 1px solid var(--border);
            vertical-align: top;
        }

        .quote-table th {
            font-size: 10px;
            color: var(--muted);
        }

        .quote-table .form-control {
            min-width: 90px;
            width: 100%;
        }

        .quote-table .service-input {
            min-width: 150px;
        }

        .quote-table .description-input {
            min-width: 160px;
        }

        .quote-table .quantity-input,
        .quote-table .price-input {
            min-width: 100px;
        }

        .quote-subtotal {
            font-size: 12px;
            font-weight: 700;
            white-space: nowrap;
        }

        .quote-total {
            margin-left: auto;
            margin-top: 18px;
            max-width: 300px;
            padding: 17px;
            background: var(--surface, #f8fafc);
            border: 1px solid var(--border);
            border-radius: 9px;
        }

        .quote-total-line {
            display: flex;
            justify-content: space-between;
            gap: 16px;
            font-size: 12px;
        }

        .quote-total-value {
            font-size: 23px;
            font-weight: 800;
            margin-top: 8px;
        }

        .quote-actions {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-top: 22px;
        }

        .quote-error {
            display: none;
            color: var(--red);
            font-size: 11px;
            margin-top: 12px;
        }

        .quote-error.visible {
            display: block;
        }

        .quote-help {
            color: var(--muted);
            font-size: 10px;
            line-height: 1.6;
            margin-top: 10px;
        }

        @media (max-width: 760px) {
            .quote-context {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>

<body data-nombre-usuario="<%= escapar(nombreUsuario) %>"
      data-rol-usuario="<%= escapar(rolActual) %>">

<div class="app-layout">

    <aside class="sidebar">
        <a href="dashboard" class="sidebar-logo">LUM<span>Y</span>N</a>

        <div class="sidebar-label">Principal</div>
        <nav id="sidebarNavigation"></nav>

        <div class="sidebar-bottom">
            <div class="user-mini">
                <div class="avatar" id="sidebarAvatar">
                    <%= escapar(iniciales) %>
                </div>
                <div>
                    <strong id="sidebarUserName"><%= escapar(nombreUsuario) %></strong>
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

    <main class="main-area">
        <header class="topbar">
            <div class="breadcrumb">
                LUMYN / Gestión / <strong>Nueva cotización</strong>
            </div>

            <div class="topbar-right">
                <span class="date-label" id="pageDate"></span>
                <div class="avatar" id="topbarAvatar">
                    <%= escapar(iniciales) %>
                </div>
            </div>
        </header>

        <section class="content">

            <div class="page-heading">
                <div>
                    <div class="welcome-tag">Gestión comercial</div>
                    <h1>Nueva cotización</h1>
                    <p>
                        Registra el requerimiento del cliente y detalla
                        los servicios que deseas cotizar.
                    </p>
                </div>

                <a href="solped" class="btn btn-outline">
                    Volver a SOLPED
                </a>
            </div>

            <form action="solped" method="post" id="quoteForm">
                <input type="hidden" name="accion" value="crear">

                <input type="hidden"
                       name="proyectoId"
                       id="proyectoId"
                       value="<%= proyectoSeleccionado != null
                           ? proyectoSeleccionado.getProyectoId() : "" %>">

                <section class="card">
                    <div class="card-heading">
                        <div>
                            <h3>Datos de la solicitud</h3>
                            <p class="quote-intro">
                                Selecciona el cliente y describe lo que necesita.
                            </p>
                        </div>
                    </div>

                    <div class="form-grid">

                        <div class="form-group">
                            <label for="clienteId">Cliente *</label>

                            <select class="form-control"
                                    name="clienteId"
                                    id="clienteId"
                                    required
                                    <%= proyectoSeleccionado != null
                                        ? "disabled" : "" %>>
                                <option value="">Selecciona un cliente</option>

                                <% for (Cliente cliente : clientes) { %>
                                    <option
                                        value="<%= cliente.getClienteId() %>"
                                        <%= String.valueOf(cliente.getClienteId())
                                            .equals(clienteSeleccionadoId)
                                            ? "selected" : "" %>>
                                        <%= escapar(cliente.getNombre()) %>
                                    </option>
                                <% } %>
                            </select>

                            <% if (proyectoSeleccionado != null) { %>
                                <input type="hidden"
                                       name="clienteId"
                                       value="<%= proyectoSeleccionado.getClienteId() %>">

                                <div class="quote-help">
                                    El cliente está vinculado al proyecto seleccionado.
                                </div>
                            <% } %>
                        </div>

                        <div class="form-group">
                            <label>Proyecto asociado</label>

                            <input class="form-control"
                                   type="text"
                                   value="<%= proyectoSeleccionado != null
                                       ? escapar(proyectoSeleccionado.getNombre())
                                       : "Sin proyecto asociado" %>"
                                   readonly>

                            <% if (proyectoSeleccionado == null) { %>
                                <div class="quote-help">
                                    Puedes registrar la solicitud sin asociarla a un proyecto.
                                </div>
                            <% } %>
                        </div>

                        <div class="form-group span-2">
                            <label for="descripcionRequerimiento">
                                Descripción del requerimiento *
                            </label>

                            <textarea class="form-control"
                                      id="descripcionRequerimiento"
                                      name="descripcionRequerimiento"
                                      rows="3"
                                      maxlength="2000"
                                      required
                                      placeholder="Describe el objetivo o necesidad del cliente"></textarea>
                        </div>

                    </div>
                </section>

                <section class="card quote-section">
                    <div class="card-heading">
                        <div>
                            <h3>Servicios y precios</h3>
                            <p class="quote-intro">
                                Agrega los servicios, sus cantidades y precios unitarios.
                            </p>
                        </div>

                        <button type="button"
                                class="btn btn-outline"
                                id="addDetailButton">
                            + Agregar servicio
                        </button>
                    </div>

                    <div class="quote-table-wrap">
                        <table class="quote-table">
                            <thead>
                                <tr>
                                    <th>Servicio *</th>
                                    <th>Descripción</th>
                                    <th>Cantidad *</th>
                                    <th>Precio unitario (S/) *</th>
                                    <th>Subtotal (S/)</th>
                                    <th>Acción</th>
                                </tr>
                            </thead>

                            <tbody id="detailsBody">
                                <tr class="detail-row">
                                    <td>
                                        <input class="form-control service-input"
                                               name="servicio[]"
                                               maxlength="150"
                                               required
                                               placeholder="Ej. Desarrollo web">
                                    </td>
                                    <td>
                                        <input class="form-control description-input"
                                               name="detalleDescripcion[]"
                                               maxlength="1000"
                                               placeholder="Detalle del servicio">
                                    </td>
                                    <td>
                                        <input class="form-control quantity-input"
                                               type="number"
                                               name="cantidad[]"
                                               min="0.01"
                                               step="0.01"
                                               value="1"
                                               required>
                                    </td>
                                    <td>
                                        <input class="form-control price-input"
                                               type="number"
                                               name="precioUnitario[]"
                                               min="0"
                                               step="0.01"
                                               value="0.00"
                                               required>
                                    </td>
                                    <td class="quote-subtotal">S/ 0.00</td>
                                    <td>
                                        <button type="button"
                                                class="btn btn-danger-light btn-small remove-detail"
                                                disabled>
                                            Quitar
                                        </button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <div class="quote-help">
                        El total mostrado es una estimación calculada en pantalla.
                        El servidor valida las cantidades y los precios al guardar.
                    </div>

                    <div class="quote-total">
                        <div class="quote-total-line">
                            <span>Total estimado</span>
                            <span>PEN</span>
                        </div>
                        <div class="quote-total-value" id="quoteTotal">S/ 0.00</div>
                    </div>

                    <div id="quoteError"
                         class="quote-error"
                         role="alert"></div>

                    <div class="quote-actions">
                        <button type="submit" class="btn btn-primary">
                            Registrar cotización
                        </button>

                        <a href="solped" class="btn btn-outline">
                            Cancelar
                        </a>
                    </div>
                </section>
            </form>
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
            {label: "SOLPED / Cotizaciones", icon: "▤", href: "solped"},
            {label: "Ventas", icon: "S/", href: "ventas"},
            {label: "Tareas", icon: "☷", action: "tareas"},
            {label: "Entregables", icon: "▤", action: "entregables"},
            {label: "Reportes", icon: "▥", action: "reportes"}
        ],
        GESTOR: [
            {label: "Panel principal", icon: "▦", href: "dashboard"},
            {label: "Clientes", icon: "♧", href: "clientes"},
            {label: "Proyectos", icon: "▣", href: "proyectos"},
            {label: "SOLPED / Cotizaciones", icon: "▤", href: "solped"},
            {label: "Ventas", icon: "S/", href: "ventas"},
            {label: "Tareas", icon: "☷", action: "tareas"},
            {label: "Entregables", icon: "▤", action: "entregables"},
            {label: "Reportes", icon: "▥", action: "reportes"}
        ]
    };

    function renderSidebar(rol) {
        const nav = document.getElementById("sidebarNavigation");
        const menu = roleMenus[rol] || [];
        const rutaActual = window.location.pathname.split("/").pop();

        nav.innerHTML = menu.map(function(item) {
            const activo = item.href === rutaActual;
            return '<a class="nav-link ' + (activo ? "active" : "") +
                '" href="' + (item.href || "#") + '">' +
                '<span class="nav-icon">' + item.icon + '</span>' +
                item.label + '</a>';
        }).join("");
    }

    function cargarPerfil() {
        const nombre =
            document.body.dataset.nombreUsuario || "Usuario Lumyn";
        const rol =
            (document.body.dataset.rolUsuario || "ADMINISTRADOR")
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
        new Intl.DateTimeFormat("es-PE", {dateStyle: "medium"})
            .format(new Date());

    const detailsBody = document.getElementById("detailsBody");
    const totalElement = document.getElementById("quoteTotal");
    const errorElement = document.getElementById("quoteError");

    function formatoMoneda(valor) {
        return new Intl.NumberFormat("es-PE", {
            style: "currency",
            currency: "PEN"
        }).format(valor);
    }

    function actualizarTotales() {
        let total = 0;

        detailsBody.querySelectorAll(".detail-row").forEach(function(row) {
            const cantidad =
                Number(row.querySelector('[name="cantidad[]"]').value);
            const precio =
                Number(row.querySelector('[name="precioUnitario[]"]').value);

            const subtotal =
                Number.isFinite(cantidad) && Number.isFinite(precio)
                    ? Math.max(0, cantidad) * Math.max(0, precio)
                    : 0;

            row.querySelector(".quote-subtotal").textContent =
                formatoMoneda(subtotal);

            total += subtotal;
        });

        totalElement.textContent = formatoMoneda(total);

        const filas = detailsBody.querySelectorAll(".detail-row");
        filas.forEach(function(row) {
            row.querySelector(".remove-detail").disabled = filas.length === 1;
        });
    }

    function crearFilaDetalle() {
        const row = document.createElement("tr");
        row.className = "detail-row";

        row.innerHTML = `
            <td>
                <input class="form-control service-input"
                       name="servicio[]" maxlength="150"
                       required placeholder="Nombre del servicio">
            </td>
            <td>
                <input class="form-control description-input"
                       name="detalleDescripcion[]" maxlength="1000"
                       placeholder="Detalle del servicio">
            </td>
            <td>
                <input class="form-control quantity-input"
                       type="number" name="cantidad[]"
                       min="0.01" step="0.01" value="1" required>
            </td>
            <td>
                <input class="form-control price-input"
                       type="number" name="precioUnitario[]"
                       min="0" step="0.01" value="0.00" required>
            </td>
            <td class="quote-subtotal">S/ 0.00</td>
            <td>
                <button type="button"
                        class="btn btn-danger-light btn-small remove-detail">
                    Quitar
                </button>
            </td>
        `;

        return row;
    }

    document.getElementById("addDetailButton")
        .addEventListener("click", function() {
            detailsBody.appendChild(crearFilaDetalle());
            actualizarTotales();
        });

    detailsBody.addEventListener("input", function(event) {
        if (event.target.matches(
            '[name="cantidad[]"], [name="precioUnitario[]"]'
        )) {
            actualizarTotales();
        }
    });

    detailsBody.addEventListener("click", function(event) {
        const button = event.target.closest(".remove-detail");

        if (button && detailsBody.querySelectorAll(".detail-row").length > 1) {
            button.closest(".detail-row").remove();
            actualizarTotales();
        }
    });

    document.getElementById("quoteForm")
        .addEventListener("submit", function(event) {
            errorElement.textContent = "";
            errorElement.classList.remove("visible");

            if (!this.checkValidity()) {
                return;
            }

            const filas = detailsBody.querySelectorAll(".detail-row");
            let total = 0;

            for (const row of filas) {
                const servicio =
                    row.querySelector('[name="servicio[]"]').value.trim();
                const cantidad =
                    Number(row.querySelector('[name="cantidad[]"]').value);
                const precio =
                    Number(row.querySelector('[name="precioUnitario[]"]').value);

                if (!servicio || !Number.isFinite(cantidad) ||
                    cantidad <= 0 || !Number.isFinite(precio) || precio < 0) {
                    event.preventDefault();
                    errorElement.textContent =
                        "Revisa los servicios, cantidades y precios ingresados.";
                    errorElement.classList.add("visible");
                    return;
                }

                total += cantidad * precio;
            }

            if (total <= 0) {
                event.preventDefault();
                errorElement.textContent =
                    "El total debe ser mayor que cero para registrar la cotización.";
                errorElement.classList.add("visible");
            }
        });

    cargarPerfil();
    actualizarTotales();
</script>

</body>
</html>
