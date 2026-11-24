-- ============================================================================
-- Base de datos: lumyn_portal
-- Sistema Web para la Gestión Operativa y Control de Proyectos - Agencia LUMYN
-- Motor: MySQL 8.0+ (3ra Forma Normal)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS lumyn_portal
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE lumyn_portal;

-- 1. Catálogo de Roles
CREATE TABLE IF NOT EXISTS roles (
    rol_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NULL
) ENGINE=InnoDB;

-- 2. Usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombres VARCHAR(80) NOT NULL,
    apellidos VARCHAR(80) NOT NULL,
    correo VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    rol_id INT NOT NULL,
    estado ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo',
    intentos_fallidos INT NOT NULL DEFAULT 0,
    bloqueado_hasta DATETIME NULL,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_rol FOREIGN KEY (rol_id) REFERENCES roles (rol_id),
    INDEX idx_usuarios_correo (correo),
    INDEX idx_usuarios_estado (estado)
) ENGINE=InnoDB;

-- 3. Clientes
CREATE TABLE IF NOT EXISTS clientes (
    cliente_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    documento VARCHAR(20) NOT NULL UNIQUE,
    correo VARCHAR(120) NOT NULL,
    telefono VARCHAR(25) NULL,
    direccion VARCHAR(255) NULL,
    estado ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo',
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_clientes_nombre (nombre),
    INDEX idx_clientes_estado (estado)
) ENGINE=InnoDB;

-- 4. Proyectos
CREATE TABLE IF NOT EXISTS proyectos (
    proyecto_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    fecha_inicio DATE NULL,
    fecha_fin DATE NULL,
    estado ENUM('planificado', 'en_progreso', 'completado', 'cancelado')
        NOT NULL DEFAULT 'planificado',
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_proyectos_cliente FOREIGN KEY (cliente_id) REFERENCES clientes (cliente_id),
    INDEX idx_proyectos_cliente (cliente_id),
    INDEX idx_proyectos_estado (estado)
) ENGINE=InnoDB;

-- 5. SOLPED (Solicitud de Pedido / Cotización - Cabecera)
CREATE TABLE IF NOT EXISTS solped (
    solped_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    proyecto_id INT NULL,
    usuario_id INT NULL,
    fecha_solicitud TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descripcion_requerimiento TEXT NOT NULL,
    estado ENUM('pendiente', 'en_revision', 'aprobada', 'rechazada', 'convertida')
        NOT NULL DEFAULT 'pendiente',
    CONSTRAINT fk_solped_cliente FOREIGN KEY (cliente_id) REFERENCES clientes (cliente_id),
    CONSTRAINT fk_solped_proyecto FOREIGN KEY (proyecto_id) REFERENCES proyectos (proyecto_id),
    CONSTRAINT fk_solped_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id),
    INDEX idx_solped_estado (estado),
    INDEX idx_solped_fecha (fecha_solicitud)
) ENGINE=InnoDB;

-- 6. SOLPED Detalle
CREATE TABLE IF NOT EXISTS solped_detalle (
    solped_detalle_id INT AUTO_INCREMENT PRIMARY KEY,
    solped_id INT NOT NULL,
    servicio VARCHAR(150) NOT NULL,
    descripcion VARCHAR(255) NULL,
    cantidad DECIMAL(10, 2) NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(12, 2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT fk_solped_detalle_solped FOREIGN KEY (solped_id)
        REFERENCES solped (solped_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 7. Ventas (Cabecera)
CREATE TABLE IF NOT EXISTS ventas (
    venta_id INT AUTO_INCREMENT PRIMARY KEY,
    solped_id INT NOT NULL UNIQUE,
    cliente_id INT NOT NULL,
    proyecto_id INT NULL,
    fecha_venta TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    impuesto DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    estado ENUM('confirmada', 'pagada', 'anulada') NOT NULL DEFAULT 'confirmada',
    CONSTRAINT fk_ventas_solped FOREIGN KEY (solped_id) REFERENCES solped (solped_id),
    CONSTRAINT fk_ventas_cliente FOREIGN KEY (cliente_id) REFERENCES clientes (cliente_id),
    CONSTRAINT fk_ventas_proyecto FOREIGN KEY (proyecto_id) REFERENCES proyectos (proyecto_id),
    INDEX idx_ventas_fecha (fecha_venta),
    INDEX idx_ventas_estado (estado)
) ENGINE=InnoDB;

-- 8. Ventas Detalle
CREATE TABLE IF NOT EXISTS venta_detalle (
    venta_detalle_id INT AUTO_INCREMENT PRIMARY KEY,
    venta_id INT NOT NULL,
    servicio VARCHAR(150) NOT NULL,
    descripcion VARCHAR(255) NULL,
    cantidad DECIMAL(10, 2) NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(12, 2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT fk_venta_detalle_venta FOREIGN KEY (venta_id)
        REFERENCES ventas (venta_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 9. Tareas de Proyectos
CREATE TABLE IF NOT EXISTS tareas (
    tarea_id INT AUTO_INCREMENT PRIMARY KEY,
    proyecto_id INT NOT NULL,
    usuario_id INT NULL,
    titulo VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    prioridad ENUM('baja', 'media', 'alta') NOT NULL DEFAULT 'media',
    avance INT NOT NULL DEFAULT 0,
    fecha_limite DATE NULL,
    estado ENUM('pendiente', 'en_progreso', 'completada', 'vencida') NOT NULL DEFAULT 'pendiente',
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tareas_proyecto FOREIGN KEY (proyecto_id) REFERENCES proyectos (proyecto_id) ON DELETE CASCADE,
    CONSTRAINT fk_tareas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id),
    INDEX idx_tareas_proyecto (proyecto_id),
    INDEX idx_tareas_estado (estado)
) ENGINE=InnoDB;

-- 10. Entregables de Proyectos
CREATE TABLE IF NOT EXISTS entregables (
    entregable_id INT AUTO_INCREMENT PRIMARY KEY,
    proyecto_id INT NOT NULL,
    usuario_id INT NULL,
    titulo VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    version VARCHAR(20) NOT NULL DEFAULT 'v1.0',
    url_archivo VARCHAR(255) NULL,
    estado ENUM('pendiente', 'aprobado', 'observado') NOT NULL DEFAULT 'pendiente',
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_entregables_proyecto FOREIGN KEY (proyecto_id) REFERENCES proyectos (proyecto_id) ON DELETE CASCADE,
    CONSTRAINT fk_entregables_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id),
    INDEX idx_entregables_proyecto (proyecto_id),
    INDEX idx_entregables_estado (estado)
) ENGINE=InnoDB;

-- 11. Observaciones de Entregables
CREATE TABLE IF NOT EXISTS entregable_observaciones (
    observacion_id INT AUTO_INCREMENT PRIMARY KEY,
    entregable_id INT NOT NULL,
    usuario_id INT NULL,
    comentario TEXT NOT NULL,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_obs_entregable FOREIGN KEY (entregable_id) REFERENCES entregables (entregable_id) ON DELETE CASCADE,
    CONSTRAINT fk_obs_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE=InnoDB;

-- ============================================================================
-- Datos iniciales (Roles)
-- ============================================================================
INSERT INTO roles (rol_id, nombre, descripcion) VALUES
    (1, 'Administrador', 'Acceso total al sistema'),
    (2, 'Gestor de proyectos', 'Gestión de clientes, proyectos, SOLPED, ventas y reportes'),
    (3, 'Colaborador', 'Consulta operativa de tareas asignadas'),
    (4, 'Revisor', 'Validación y revisión de proyectos')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);
