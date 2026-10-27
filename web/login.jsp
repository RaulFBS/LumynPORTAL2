```jsp
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Iniciar sesión | LUMYN</title>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/css/styles.css">
</head>
<body>

<div class="login-page">

    <section class="login-brand">
        <a href="${pageContext.request.contextPath}/login.jsp"
           class="brand-logo">
            LUM<span>Y</span>N
        </a>

        <div class="brand-description">
            <div class="eyebrow">Gestión inteligente</div>

            <h1>
                Ideas que se convierten en
                <span>proyectos.</span>
            </h1>

            <p>
                Organiza el trabajo, conecta a tu equipo y mantén
                cada proyecto bajo control desde un solo lugar.
            </p>
        </div>

        <div class="brand-footer">
            © 2026 LUMYN · Gestión operativa y proyectos
        </div>
    </section>

    <main class="login-content">
        <form class="login-form"
              action="${pageContext.request.contextPath}/login"
              method="POST">

            <div class="small-label">Portal interno</div>

            <h2>Bienvenido de nuevo</h2>

            <p class="login-subtitle">
                Ingresa tus credenciales para acceder a tu espacio de trabajo.
            </p>

            <% if (request.getAttribute("error") != null) { %>
                <p class="login-error" role="alert">
                    <%= org.springframework.web.util.HtmlUtils.htmlEscape(
                        String.valueOf(request.getAttribute("error"))) %>
                </p>
            <% } %>

            <div class="form-group">
                <label for="correo">Correo electrónico</label>

                <div class="input-wrap">
                    <span class="input-icon">✉</span>
                    <input
                        class="form-control"
                        type="email"
                        id="correo"
                        name="correo"
                        placeholder="nombre@lumyn.com"
                        autocomplete="username"
                        required>
                </div>
            </div>

            <div class="form-group">
                <label for="password">Contraseña</label>

                <div class="input-wrap">
                    <span class="input-icon">●</span>
                    <input
                        class="form-control"
                        type="password"
                        id="password"
                        name="password"
                        placeholder="Ingresa tu contraseña"
                        autocomplete="current-password"
                        required>
                </div>
            </div>

            <div class="login-options">
                <span></span>
                <a href="#" id="forgotLink">
                    ¿Olvidaste tu contraseña?
                </a>
            </div>

            <button type="submit" class="btn btn-primary btn-full">
                Iniciar sesión <span>→</span>
            </button>

        </form>
    </main>

</div>

<script>
    document.getElementById("forgotLink").addEventListener(
        "click",
        function (event) {
            event.preventDefault();
            alert("La recuperación de contraseña se implementará más adelante.");
        }
    );
</script>

</body>
</html>
```