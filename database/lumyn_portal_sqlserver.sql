-- ============================================================================
-- Base de datos: lumyn_portal (Versión T-SQL para SQL Server / SSMS)
-- Sistema Web para la Gestión Operativa y Control de Proyectos - Agencia LUMYN
-- ============================================================================

IF DB_ID('lumyn_portal') IS NULL
BEGIN
    CREATE DATABASE lumyn_portal;
END
GO

USE lumyn_portal;
GO

-- 1. Catálogo de Roles
IF OBJECT_ID('dbo.roles', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.roles (
        rol_id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(50) NOT NULL UNIQUE,
        descripcion NVARCHAR(150) NULL
    );
END
GO

-- 2. Usuarios
IF OBJECT_ID('dbo.usuarios', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.usuarios (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombres NVARCHAR(80) NOT NULL,
        apellidos NVARCHAR(80) NOT NULL,
        correo NVARCHAR(120) NOT NULL UNIQUE,
        password_hash NVARCHAR(255) NOT NULL,
        rol_id INT NOT NULL,
        estado NVARCHAR(15) NOT NULL DEFAULT 'activo'
            CHECK (estado IN ('activo', 'inactivo')),
        intentos_fallidos INT NOT NULL DEFAULT 0,
        bloqueado_hasta DATETIME2 NULL,
        fecha_registro DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT fk_usuarios_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles (rol_id)
    );
    CREATE INDEX idx_usuarios_correo ON dbo.usuarios (correo);
    CREATE INDEX idx_usuarios_estado ON dbo.usuarios (estado);
END
GO

-- 3. Clientes
IF OBJECT_ID('dbo.clientes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.clientes (
        cliente_id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(150) NOT NULL,
        documento NVARCHAR(20) NOT NULL UNIQUE,
        correo NVARCHAR(120) NOT NULL,
        telefono NVARCHAR(25) NULL,
        direccion NVARCHAR(255) NULL,
        estado NVARCHAR(15) NOT NULL DEFAULT 'activo'
            CHECK (estado IN ('activo', 'inactivo')),
        fecha_registro DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
    CREATE INDEX idx_clientes_nombre ON dbo.clientes (nombre);
    CREATE INDEX idx_clientes_estado ON dbo.clientes (estado);
END
GO

-- 4. Proyectos
IF OBJECT_ID('dbo.proyectos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.proyectos (
        proyecto_id INT IDENTITY(1,1) PRIMARY KEY,
        cliente_id INT NOT NULL,
        nombre NVARCHAR(150) NOT NULL,
        descripcion NVARCHAR(MAX) NULL,
        fecha_inicio DATE NULL,
        fecha_fin DATE NULL,
        estado NVARCHAR(20) NOT NULL DEFAULT 'planificado'
            CHECK (estado IN ('planificado', 'en_progreso', 'completado', 'cancelado')),
        fecha_registro DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT fk_proyectos_cliente FOREIGN KEY (cliente_id) REFERENCES dbo.clientes (cliente_id)
    );
    CREATE INDEX idx_proyectos_cliente ON dbo.proyectos (cliente_id);
    CREATE INDEX idx_proyectos_estado ON dbo.proyectos (estado);
END
GO

-- 5. SOLPED (Solicitud de Pedido / Cotización - Cabecera)
IF OBJECT_ID('dbo.solped', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.solped (
        solped_id INT IDENTITY(1,1) PRIMARY KEY,
        cliente_id INT NOT NULL,
        proyecto_id INT NULL,
        usuario_id INT NULL,
        fecha_solicitud DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        descripcion_requerimiento NVARCHAR(MAX) NOT NULL,
        estado NVARCHAR(20) NOT NULL DEFAULT 'pendiente'
            CHECK (estado IN ('pendiente', 'en_revision', 'aprobada', 'rechazada', 'convertida')),
        CONSTRAINT fk_solped_cliente FOREIGN KEY (cliente_id) REFERENCES dbo.clientes (cliente_id),
        CONSTRAINT fk_solped_proyecto FOREIGN KEY (proyecto_id) REFERENCES dbo.proyectos (proyecto_id),
        CONSTRAINT fk_solped_usuario FOREIGN KEY (usuario_id) REFERENCES dbo.usuarios (id)
    );
    CREATE INDEX idx_solped_estado ON dbo.solped (estado);
    CREATE INDEX idx_solped_fecha ON dbo.solped (fecha_solicitud);
END
GO

-- 6. SOLPED Detalle
IF OBJECT_ID('dbo.solped_detalle', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.solped_detalle (
        solped_detalle_id INT IDENTITY(1,1) PRIMARY KEY,
        solped_id INT NOT NULL,
        servicio NVARCHAR(150) NOT NULL,
        descripcion NVARCHAR(255) NULL,
        cantidad DECIMAL(10, 2) NOT NULL,
        precio_unitario DECIMAL(10, 2) NOT NULL,
        subtotal AS (CAST(cantidad * precio_unitario AS DECIMAL(12, 2))) PERSISTED,
        CONSTRAINT fk_solped_detalle_solped FOREIGN KEY (solped_id)
            REFERENCES dbo.solped (solped_id) ON DELETE CASCADE
    );
END
GO

-- 7. Ventas (Cabecera)
IF OBJECT_ID('dbo.ventas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ventas (
        venta_id INT IDENTITY(1,1) PRIMARY KEY,
        solped_id INT NOT NULL UNIQUE,
        cliente_id INT NOT NULL,
        proyecto_id INT NULL,
        fecha_venta DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
        impuesto DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
        total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
        estado NVARCHAR(20) NOT NULL DEFAULT 'confirmada'
            CHECK (estado IN ('confirmada', 'pagada', 'anulada')),
        CONSTRAINT fk_ventas_solped FOREIGN KEY (solped_id) REFERENCES dbo.solped (solped_id),
        CONSTRAINT fk_ventas_cliente FOREIGN KEY (cliente_id) REFERENCES dbo.clientes (cliente_id),
        CONSTRAINT fk_ventas_proyecto FOREIGN KEY (proyecto_id) REFERENCES dbo.proyectos (proyecto_id)
    );
    CREATE INDEX idx_ventas_fecha ON dbo.ventas (fecha_venta);
    CREATE INDEX idx_ventas_estado ON dbo.ventas (estado);
END
GO

-- 8. Ventas Detalle
IF OBJECT_ID('dbo.venta_detalle', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.venta_detalle (
        venta_detalle_id INT IDENTITY(1,1) PRIMARY KEY,
        venta_id INT NOT NULL,
        servicio NVARCHAR(150) NOT NULL,
        descripcion NVARCHAR(255) NULL,
        cantidad DECIMAL(10, 2) NOT NULL,
        precio_unitario DECIMAL(10, 2) NOT NULL,
        subtotal AS (CAST(cantidad * precio_unitario AS DECIMAL(12, 2))) PERSISTED,
        CONSTRAINT fk_venta_detalle_venta FOREIGN KEY (venta_id)
            REFERENCES dbo.ventas (venta_id) ON DELETE CASCADE
    );
END
GO

-- 9. Tareas de Proyectos
IF OBJECT_ID('dbo.tareas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tareas (
        tarea_id INT IDENTITY(1,1) PRIMARY KEY,
        proyecto_id INT NOT NULL,
        usuario_id INT NULL,
        titulo NVARCHAR(150) NOT NULL,
        descripcion NVARCHAR(MAX) NULL,
        prioridad NVARCHAR(15) NOT NULL DEFAULT 'media'
            CHECK (prioridad IN ('baja', 'media', 'alta')),
        avance INT NOT NULL DEFAULT 0 CHECK (avance BETWEEN 0 AND 100),
        fecha_limite DATE NULL,
        estado NVARCHAR(20) NOT NULL DEFAULT 'pendiente'
            CHECK (estado IN ('pendiente', 'en_progreso', 'completada', 'vencida')),
        fecha_registro DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT fk_tareas_proyecto FOREIGN KEY (proyecto_id) REFERENCES dbo.proyectos (proyecto_id) ON DELETE CASCADE,
        CONSTRAINT fk_tareas_usuario FOREIGN KEY (usuario_id) REFERENCES dbo.usuarios (id)
    );
    CREATE INDEX idx_tareas_proyecto ON dbo.tareas (proyecto_id);
    CREATE INDEX idx_tareas_estado ON dbo.tareas (estado);
END
GO

-- 10. Entregables de Proyectos
IF OBJECT_ID('dbo.entregables', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.entregables (
        entregable_id INT IDENTITY(1,1) PRIMARY KEY,
        proyecto_id INT NOT NULL,
        usuario_id INT NULL,
        titulo NVARCHAR(150) NOT NULL,
        descripcion NVARCHAR(MAX) NULL,
        version NVARCHAR(20) NOT NULL DEFAULT 'v1.0',
        url_archivo NVARCHAR(255) NULL,
        estado NVARCHAR(20) NOT NULL DEFAULT 'pendiente'
            CHECK (estado IN ('pendiente', 'aprobado', 'observado')),
        fecha_registro DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT fk_entregables_proyecto FOREIGN KEY (proyecto_id) REFERENCES dbo.proyectos (proyecto_id) ON DELETE CASCADE,
        CONSTRAINT fk_entregables_usuario FOREIGN KEY (usuario_id) REFERENCES dbo.usuarios (id)
    );
    CREATE INDEX idx_entregables_proyecto ON dbo.entregables (proyecto_id);
    CREATE INDEX idx_entregables_estado ON dbo.entregables (estado);
END
GO

-- 11. Observaciones de Entregables
IF OBJECT_ID('dbo.entregable_observaciones', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.entregable_observaciones (
        observacion_id INT IDENTITY(1,1) PRIMARY KEY,
        entregable_id INT NOT NULL,
        usuario_id INT NULL,
        comentario NVARCHAR(MAX) NOT NULL,
        fecha_registro DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT fk_obs_entregable FOREIGN KEY (entregable_id) REFERENCES dbo.entregables (entregable_id) ON DELETE CASCADE,
        CONSTRAINT fk_obs_usuario FOREIGN KEY (usuario_id) REFERENCES dbo.usuarios (id)
    );
END
GO

-- ============================================================================
-- Datos iniciales (Roles)
-- ============================================================================
SET IDENTITY_INSERT dbo.roles ON;
IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE rol_id = 1)
    INSERT INTO dbo.roles (rol_id, nombre, descripcion) VALUES (1, N'Administrador', N'Acceso total al sistema');
IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE rol_id = 2)
    INSERT INTO dbo.roles (rol_id, nombre, descripcion) VALUES (2, N'Gestor de proyectos', N'Gestión de clientes, proyectos, SOLPED, ventas y reportes');
IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE rol_id = 3)
    INSERT INTO dbo.roles (rol_id, nombre, descripcion) VALUES (3, N'Colaborador', N'Consulta operativa de tareas asignadas');
IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE rol_id = 4)
    INSERT INTO dbo.roles (rol_id, nombre, descripcion) VALUES (4, N'Revisor', N'Validación y revisión de proyectos');
SET IDENTITY_INSERT dbo.roles OFF;
GO
