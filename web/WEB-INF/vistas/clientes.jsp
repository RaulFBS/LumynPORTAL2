
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="pe.lumyn.portal.model.Cliente" %>
<%@ page import="pe.lumyn.portal.security.PermisosUtil" %>

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
    // Verificación de sesión
    if (!PermisosUtil.tieneSesion(session)) {
        response.sendRedirect(request.getContextPath() + "/login.html");
        return;
    }

    boolean esAdministrador = PermisosUtil.esAdministrador(session);
    boolean esGestor = PermisosUtil.tieneRol(session, 2);
    boolean puedeGestionar = esAdministrador || esGestor;

    // Solo administrador y gestor pueden acceder a Clientes.
    if (!puedeGestionar) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN);
        return;
    }

    List<Cliente> clientes =
        (List<Cliente>) request.getAttribute("clientes");

    if (clientes == null) {
        clientes = java.util.Collections.emptyList();
    }

    SimpleDateFormat formatoFecha =
        new SimpleDateFormat("dd/MM/yyyy");

    String contexto = request.getContextPath();
    String resultado = request.getParameter("resultado");

    Object rolSesion = session.getAttribute("rolId");
    int rolId = 0;

    try {
        if (rolSesion != null) {
            rolId = Integer.parseInt(rolSesion.toString());
        }
    } catch (NumberFormatException e) {
        rolId = 0;
    }

    Object nombreSesion = session.getAttribute("nombreUsuario");

    String nombreUsuario = nombreSesion != null
        ? nombreSesion.toString()
        : "Usuario Lumyn";

    String rolNombre;

    switch (rolId) {
        case 1:
            rolNombre = "Administrador";
            break;
        case 2:
            rolNombre = "Gestor";
            break;
        case 3:
            rolNombre = "Colaborador";
            break;
        case 4:
            rolNombre = "Revisor";
            break;
        default:
            rolNombre = "Usuario";
            break;
    }

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

    int activos = 0;
    int conCorreo = 0;

    for (Cliente c : clientes) {
        if ("activo".equalsIgnoreCase(c.getEstado())) {
            activos++;
        }

        if (c.getCorreo() != null && !c.getCorreo().isBlank()) {
            conCorreo++;
        }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Clientes | LUMYN</title>

    <link rel="stylesheet"
          href="<%= contexto %>/css/styles.css">

    <style>
        #clientModal[hidden] {
            display: none !important;
        }

        #clientModal:not([hidden]) {
            display: flex;
        }

        .client-email {
            color: var(--muted);
            font-size: 11px;
        }

        .client-message {
            margin-bottom: 18px;
            padding: 12px 16px;
            border-radius: 8px;
            background: #e8f7ed;
            color: #176b37;
        }

        .client-message.error {
            background: #fff0ef;
            color: #a52a2a;
        }

        .client-empty {
            text-align: center;
            padding: 28px;
            color: var(--muted);
        }

        .client-modal-form {
            width: 100%;
        }

        .client-modal-form .modal-body {
            max-height: 70vh;
            overflow-y: auto;
        }

        .client-modal-form textarea {
            resize: vertical;
            min-height: 80px;
        }

        .client-address {
            display: block;
            color: var(--muted);
            font-size: 11px;
            margin-top: 4px;
        }

        .client-toolbar-description {
            font-size: 10px;
            color: var(--muted);
            margin: 6px 0 0;
        }

        .client-filter {
            padding: 15px 19px;
            border-bottom: 1px solid var(--border);
        }

        .client-filter .form-control {
            max-width: 360px;
        }

        .client-modal-form .form-grid {
            gap: 16px;
        }

        @media (max-width: 760px) {
            .client-filter {
                padding: 14px;
            }

            .client-filter .form-control {
                max-width: none;
                width: 100%;
            }
        }
    </style>
</head>

<body data-nombre-usuario="<%= escapar(nombreUsuario) %>"
      data-rol-usuario="<%= escapar(rolNombre) %>">

<div class="app-layout">

    <!-- MENÚ LATERAL -->
    <aside class="sidebar">

        <a href="<%= contexto %>/dashboard" class="sidebar-logo">
            LUM<span>Y</span>N
        </a>

        <div class="sidebar-label">Principal</div>

        <a href="<%= contexto %>/dashboard" class="nav-link">
            <span class="nav-icon">▦</span>
            Panel principal
        </a>

        <% if (esAdministrador) { %>

            <a href="<%= contexto %>/usuarios" class="nav-link">
                <span class="nav-icon">♙</span>
                Usuarios y roles
            </a>

            <a href="#"
               class="nav-link"
               onclick="showModuleNotice(event, 'Seguridad')">
                <span class="nav-icon">◇</span>
                Seguridad
            </a>

        <% } %>

        <% if (puedeGestionar) { %>

            <a href="<%= contexto %>/clientes"
               class="nav-link active">
                <span class="nav-icon">♧</span>
                Clientes
            </a>

            <a href="<%= contexto %>/proyectos"
               class="nav-link">
                <span class="nav-icon">▣</span>
                Proyectos
            </a>

        <% } %>

        <% if (rolId == 1 || rolId == 2 || rolId == 3) { %>

            <a href="#"
               class="nav-link"
               onclick="showModuleNotice(event, 'Tareas')">
                <span class="nav-icon">☷</span>
                Tareas
            </a>

        <% } %>

        <% if (rolId >= 1 && rolId <= 4) { %>

            <a href="#"
               class="nav-link"
               onclick="showModuleNotice(event, 'Entregables')">
                <span class="nav-icon">▤</span>
                Entregables
            </a>

        <% } %>

        <% if (rolId == 1 || rolId == 2) { %>

            <a href="#"
               class="nav-link"
               onclick="showModuleNotice(event, 'Reportes')">
                <span class="nav-icon">▥</span>
                Reportes
            </a>

        <% } %>

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
                        <%= escapar(rolNombre) %>
                    </small>
                </div>

            </div>

            <a href="<%= contexto %>/logout" class="nav-link">
                <span class="nav-icon">↪</span>
                Cerrar sesión
            </a>

        </div>

    </aside>

    <!-- CONTENIDO PRINCIPAL -->
    <main class="main-area">

        <header class="topbar">

            <div class="breadcrumb">
                LUMYN / Administración / <strong>Clientes</strong>
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
                    <div class="welcome-tag">Administración</div>

                    <h1>Clientes</h1>

                    <p>
                        Registra y administra los clientes de los proyectos
                        de desarrollo web de LUMYN.
                    </p>
                </div>

                <button type="button"
                        class="btn btn-primary"
                        onclick="openCreateModal()">
                    + Registrar cliente
                </button>

            </div>

            <!-- MENSAJE DE RESULTADO -->
            <% if ("ok".equals(resultado)) { %>

                <div class="client-message">
                    La operación se procesó correctamente.
                </div>

            <% } else if ("error".equals(resultado)) { %>

                <div class="client-message error">
                    No se pudo completar la operación. Verifica los datos e inténtalo nuevamente.
                </div>

            <% } %>

            <!-- ESTADÍSTICAS -->
            <div class="grid-stats">

                <div class="stat-card">
                    <div class="stat-symbol">♧</div>
                    <div class="stat-title">Total de clientes</div>
                    <div class="stat-value"><%= clientes.size() %></div>
                    <div class="stat-foot">Clientes registrados</div>
                </div>

                <div class="stat-card">
                    <div class="stat-symbol">✓</div>
                    <div class="stat-title">Clientes activos</div>
                    <div class="stat-value"><%= activos %></div>
                    <div class="stat-foot">Clientes habilitados</div>
                </div>

                <div class="stat-card">
                    <div class="stat-symbol">✉</div>
                    <div class="stat-title">Con correo</div>
                    <div class="stat-value"><%= conCorreo %></div>
                    <div class="stat-foot">Con correo registrado</div>
                </div>

                <div class="stat-card">
                    <div class="stat-symbol">⊘</div>
                    <div class="stat-title">Inactivos</div>
                    <div class="stat-value"><%= clientes.size() - activos %></div>
                    <div class="stat-foot">Clientes desactivados</div>
                </div>

            </div>

            <div style="height:22px"></div>

            <!-- DIRECTORIO DE CLIENTES -->
            <section class="table-card">

                <div class="table-toolbar">

                    <div>
                        <strong style="font-size:14px">
                            Directorio de clientes
                        </strong>

                        <p class="client-toolbar-description">
                            Consulta y administra los datos de tus clientes.
                        </p>
                    </div>

                    <button type="button"
                            class="btn btn-primary"
                            onclick="openCreateModal()">
                        + Nuevo
                    </button>

                </div>

                <div class="client-filter">

                    <input
                        type="search"
                        class="form-control search-input"
                        id="searchClients"
                        placeholder="Buscar por nombre, documento o correo..."
                        aria-label="Buscar clientes"
                    >

                </div>

                <div class="table-scroll">

                    <table>

                        <thead>
                            <tr>
                                <th>Cliente</th>
                                <th>Documento</th>
                                <th>Teléfono</th>
                                <th>Estado</th>
                                <th>Registro</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>

                        <tbody id="clientsTable">

                            <% if (clientes.isEmpty()) { %>

                                <tr id="emptyClientsRow">
                                    <td colspan="6">
                                        <div class="client-empty">
                                            Todavía no hay clientes registrados.
                                        </div>
                                    </td>
                                </tr>

                            <% } else { %>

                                <% for (Cliente c : clientes) { %>

                                    <%
                                        String nombreCliente = c.getNombre() == null
                                            ? "" : c.getNombre();

                                        String estadoCliente = c.getEstado() == null
                                            ? "inactivo" : c.getEstado();

                                        String documentoCliente = c.getDocumento() == null
                                            ? "" : c.getDocumento();

                                        String correoCliente = c.getCorreo() == null
                                            ? "" : c.getCorreo();

                                        String telefonoCliente = c.getTelefono() == null
                                            ? "" : c.getTelefono();

                                        String direccionCliente = c.getDireccion() == null
                                            ? "" : c.getDireccion();

                                        String inicialCliente =
                                            nombreCliente.trim().isEmpty()
                                            ? "C"
                                            : nombreCliente.trim()
                                                .substring(0, 1).toUpperCase();
                                    %>

                                    <tr class="client-row"
                                        data-nombre="<%= escapar(nombreCliente) %>"
                                        data-documento="<%= escapar(documentoCliente) %>"
                                        data-correo="<%= escapar(correoCliente) %>"
                                        data-telefono="<%= escapar(telefonoCliente) %>"
                                        data-direccion="<%= escapar(direccionCliente) %>">

                                        <td>
                                            <div class="person-cell">

                                                <div class="avatar">
                                                    <%= escapar(inicialCliente) %>
                                                </div>

                                                <div>
                                                    <strong>
                                                        <%= escapar(nombreCliente) %>
                                                    </strong>

                                                    <% if (!correoCliente.isBlank()) { %>
                                                        <small class="client-email">
                                                            <%= escapar(correoCliente) %>
                                                        </small>
                                                    <% } %>

                                                    <% if (!direccionCliente.isBlank()) { %>
                                                        <small class="client-address">
                                                            <%= escapar(direccionCliente) %>
                                                        </small>
                                                    <% } %>
                                                </div>

                                            </div>
                                        </td>

                                        <td>
                                            <%= escapar(documentoCliente) %>
                                        </td>

                                        <td>
                                            <%= escapar(telefonoCliente) %>
                                        </td>

                                        <td>

                                            <span class="badge <%= 
                                                "activo".equalsIgnoreCase(estadoCliente)
                                                ? "badge-green" : "badge-gray"
                                            %>">

                                                <%= "activo".equalsIgnoreCase(estadoCliente)
                                                    ? "Activo" : "Inactivo" %>

                                            </span>

                                        </td>

                                        <td>
                                            <%= c.getFechaRegistro() == null
                                                ? "—"
                                                : formatoFecha.format(c.getFechaRegistro()) %>
                                        </td>

                                        <td>

                                            <div class="table-actions">

                                                <button
                                                    type="button"
                                                    class="btn btn-outline btn-small"
                                                    onclick="editClient(this)"
                                                    data-id="<%= c.getClienteId() %>">
                                                    Editar
                                                </button>

                                                <form method="post"
                                                      action="<%= contexto %>/clientes"
                                                      onsubmit="return confirm('¿Deseas cambiar el estado de este cliente?');">

                                                    <input type="hidden"
                                                           name="accion"
                                                           value="cambiarEstado">

                                                    <input type="hidden"
                                                           name="clienteId"
                                                           value="<%= c.getClienteId() %>">

                                                    <input type="hidden"
                                                           name="estado"
                                                           value="<%= "activo".equalsIgnoreCase(estadoCliente)
                                                               ? "inactivo" : "activo" %>">

                                                    <button type="submit"
                                                            class="btn btn-small <%= 
                                                                "activo".equalsIgnoreCase(estadoCliente)
                                                                ? "btn-danger-light" : "btn-dark"
                                                            %>">

                                                        <%= "activo".equalsIgnoreCase(estadoCliente)
                                                            ? "Desactivar" : "Activar" %>

                                                    </button>

                                                </form>

                                            </div>

                                        </td>

                                    </tr>

                                <% } %>

                            <% } %>

                        </tbody>

                    </table>

                </div>

                <div class="table-footer" id="tableCount">
                    Mostrando <%= clientes.size() %> clientes
                </div>

            </section>

        </section>
    </main>
</div>

<!-- MODAL DE REGISTRO Y EDICIÓN -->
<div class="modal-backdrop"
     id="clientModal"
     hidden>

    <form class="modal client-modal-form"
          id="clientForm"
          method="post"
          action="<%= contexto %>/clientes">

        <div class="modal-header">

            <h2 id="modalTitle">Registrar cliente</h2>

            <button type="button"
                    class="modal-close"
                    onclick="closeModal()"
                    aria-label="Cerrar">
                ✕
            </button>

        </div>

        <div class="modal-body">

            <input type="hidden"
                   id="clienteId"
                   name="clienteId">

            <input type="hidden"
                   id="accion"
                   name="accion"
                   value="guardar">

            <div class="form-grid">

                <div class="form-group span-2">

                    <label for="nombre">Nombre o razón social *</label>

                    <input
                        class="form-control"
                        id="nombre"
                        name="nombre"
                        required
                        maxlength="150"
                        placeholder="Ej. Empresa ABC S.A.C."
                    >

                </div>

                <div class="form-group">

                    <label for="documento">Documento / RUC</label>

                    <input
                        class="form-control"
                        id="documento"
                        name="documento"
                        maxlength="20"
                        placeholder="DNI o RUC"
                    >

                </div>

                <div class="form-group">

                    <label for="telefono">Teléfono</label>

                    <input
                        class="form-control"
                        id="telefono"
                        name="telefono"
                        maxlength="20"
                        placeholder="Número de contacto"
                    >

                </div>

                <div class="form-group span-2">

                    <label for="correo">Correo electrónico</label>

                    <input
                        class="form-control"
                        type="email"
                        id="correo"
                        name="correo"
                        maxlength="150"
                        placeholder="contacto@empresa.com"
                    >

                </div>

                <div class="form-group span-2">

                    <label for="direccion">Dirección</label>

                    <textarea
                        class="form-control"
                        id="direccion"
                        name="direccion"
                        maxlength="250"
                        placeholder="Dirección del cliente"
                    ></textarea>

                </div>

            </div>

        </div>

        <div class="modal-footer">

            <button type="button"
                    class="btn btn-outline"
                    onclick="closeModal()">
                Cancelar
            </button>

            <button type="submit"
                    class="btn btn-primary"
                    id="saveClientButton">
                Guardar cliente
            </button>

        </div>

    </form>
</div>

<script>
    "use strict";

    const contextoApp = "<%= contexto %>";
    const modal = document.getElementById("clientModal");
    const clientForm = document.getElementById("clientForm");

    function obtenerIniciales(nombre) {
        const partes = (nombre || "")
            .trim()
            .split(/\s+/)
            .filter(Boolean);

        if (partes.length === 0) {
            return "UL";
        }

        if (partes.length === 1) {
            return partes[0].substring(0, 2).toUpperCase();
        }

        return (
            partes[0].charAt(0) +
            partes[partes.length - 1].charAt(0)
        ).toUpperCase();
    }

    function cargarPerfil() {
        const nombre =
            document.body.dataset.nombreUsuario || "Usuario Lumyn";

        const rol =
            document.body.dataset.rolUsuario || "Usuario";

        const iniciales = obtenerIniciales(nombre);

        document.getElementById("sidebarUserName").textContent = nombre;
        document.getElementById("sidebarUserRole").textContent = rol;
        document.getElementById("sidebarAvatar").textContent = iniciales;
        document.getElementById("topbarAvatar").textContent = iniciales;
    }

    function showToast(mensaje) {
        const anterior = document.getElementById("clientToast");

        if (anterior) {
            anterior.remove();
        }

        const toast = document.createElement("div");
        toast.id = "clientToast";
        toast.className = "toast";
        toast.textContent = mensaje;

        document.body.appendChild(toast);

        setTimeout(function () {
            toast.remove();
        }, 3000);
    }

    function showModuleNotice(event, nombreModulo) {
        event.preventDefault();

        showToast(
            nombreModulo + ": módulo pendiente de implementación."
        );
    }

    function openCreateModal() {
        clientForm.reset();

        document.getElementById("clienteId").value = "";
        document.getElementById("accion").value = "guardar";

        document.getElementById("modalTitle").textContent =
            "Registrar cliente";

        document.getElementById("saveClientButton").textContent =
            "Guardar cliente";

        modal.hidden = false;

        document.getElementById("nombre").focus();
    }

    function editClient(button) {
        const fila = button.closest("tr");

        if (!fila) {
            return;
        }

        document.getElementById("clienteId").value =
            button.dataset.id;

        document.getElementById("accion").value =
            "actualizar";

        document.getElementById("nombre").value =
            fila.dataset.nombre || "";

        document.getElementById("documento").value =
            fila.dataset.documento || "";

        document.getElementById("correo").value =
            fila.dataset.correo || "";

        document.getElementById("telefono").value =
            fila.dataset.telefono || "";

        document.getElementById("direccion").value =
            fila.dataset.direccion || "";

        document.getElementById("modalTitle").textContent =
            "Editar cliente";

        document.getElementById("saveClientButton").textContent =
            "Guardar cambios";

        modal.hidden = false;

        document.getElementById("nombre").focus();
    }

    function closeModal() {
        modal.hidden = true;
        clientForm.reset();

        document.getElementById("clienteId").value = "";
        document.getElementById("accion").value = "guardar";
    }

    modal.addEventListener("click", function (event) {
        if (event.target === modal) {
            closeModal();
        }
    });

    document.addEventListener("keydown", function (event) {
        if (event.key === "Escape" && !modal.hidden) {
            closeModal();
        }
    });

    document.getElementById("searchClients")
        .addEventListener("input", function () {
            const busqueda = this.value.toLowerCase().trim();

            const filas = document.querySelectorAll(".client-row");

            let visibles = 0;

            filas.forEach(function (fila) {
                const nombre =
                    (fila.dataset.nombre || "").toLowerCase();

                const documento =
                    (fila.dataset.documento || "").toLowerCase();

                const correo =
                    (fila.dataset.correo || "").toLowerCase();

                const telefono =
                    (fila.dataset.telefono || "").toLowerCase();

                const coincide =
                    nombre.includes(busqueda) ||
                    documento.includes(busqueda) ||
                    correo.includes(busqueda) ||
                    telefono.includes(busqueda);

                fila.style.display = coincide ? "" : "none";

                if (coincide) {
                    visibles++;
                }
            });

            document.getElementById("tableCount").textContent =
                "Mostrando " + visibles + " de "
                + filas.length + " clientes";
        });

    clientForm.addEventListener("submit", function (event) {
        const nombre =
            document.getElementById("nombre").value.trim();

        if (!nombre) {
            event.preventDefault();
            showToast("El nombre del cliente es obligatorio.");
            return;
        }

        const boton =
            document.getElementById("saveClientButton");

        boton.disabled = true;
        boton.textContent = "Guardando...";
    });

    document.getElementById("pageDate").textContent =
        new Intl.DateTimeFormat("es-PE", {
            dateStyle: "medium"
        }).format(new Date());

    cargarPerfil();

    const parametros = new URLSearchParams(window.location.search);
    const resultado = parametros.get("resultado");

    if (resultado === "ok") {
        showToast("La operación se procesó correctamente.");

        window.history.replaceState(
            {},
            document.title,
            window.location.pathname
        );
    }
</script>

</body>
</html>
