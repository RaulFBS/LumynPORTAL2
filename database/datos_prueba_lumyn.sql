-- ============================================================================
-- Datos de Prueba Completos - Agencia LUMYN (MySQL / MariaDB)
-- ============================================================================
USE lumyn_portal;

-- 1. Usuarios de prueba (uno por cada rol + cuenta inactiva)
INSERT INTO usuarios (nombres, apellidos, correo, password_hash, rol_id, estado, intentos_fallidos) VALUES
('Valeria', 'Mendoza', 'gestor@lumyn.pe', '$2a$12$QD0mKxKNqdSLL5hSUBafAOCmvkDfZTYryVpNjdgAvXePTkyKZvl1e', 2, 'activo', 0),
('Diego', 'Quispe', 'colaborador@lumyn.pe', '$2a$12$4idvjpOr4Lw2ZG1.MAMnWODa6T2iGehs9sPeIxlKMB4iZQ6VIOjJS', 3, 'activo', 0),
('Camila', 'Rojas', 'revisor@lumyn.pe', '$2a$12$bSVBuuBA2h0YKj.W4XPYt.vvcYGJEjovECRpYnAO.uIHv2oDYDEXe', 4, 'activo', 0),
('Mateo', 'Paredes', 'inactivo@lumyn.pe', '$2a$12$5/nAk1cUytveq/m0rjjvBOL2817ECThlflUZij9VT5F16OdM25xnm', 3, 'inactivo', 2)
ON DUPLICATE KEY UPDATE
    password_hash = VALUES(password_hash),
    rol_id = VALUES(rol_id),
    estado = VALUES(estado);

-- 2. Clientes de prueba
INSERT IGNORE INTO clientes (cliente_id, nombre, documento, correo, telefono, direccion, estado) VALUES
(3, 'Inmobiliaria Horizonte Sur S.A.C.', '20548796321', 'proyectos@horizontesur.pe', '991223344', 'Av. Benavides 1980, Surco', 'activo'),
(4, 'Restaurante La Marisquería E.I.R.L.', '20601122334', 'admin@lamarisqueria.pe', '984556677', 'Calle Berlín 315, Miraflores', 'activo'),
(5, 'Academia Preuniversitaria Sigma', '20519988776', 'informes@academiasigma.edu.pe', '977889900', 'Av. Arequipa 2450, Lince', 'activo'),
(6, 'Importadora Andina S.R.L.', '20493344551', 'compras@andinaimport.pe', '966112200', 'Jr. Huallaga 520, Cercado de Lima', 'inactivo');

-- 3. Proyectos de prueba (cubriendo todos los estados)
INSERT IGNORE INTO proyectos (proyecto_id, cliente_id, nombre, descripcion, fecha_inicio, fecha_fin, estado) VALUES
(3, 3, 'Plataforma Catálogo Inmobiliario', 'Buscador de departamentos, cotizador y panel de asesores.', '2026-08-15', '2026-10-20', 'completado'),
(4, 4, 'Carta Digital QR y Reservas', 'Menú interactivo móvil y reservas por mesa.', '2026-09-05', '2026-10-10', 'completado'),
(5, 5, 'Aula Virtual y Landing Matrículas', 'Sistema de inscripción en línea y aula virtual.', '2026-11-01', '2026-12-28', 'en_progreso'),
(6, 6, 'Tienda B2B Mayorista', 'Proyecto pausado por reestructuración comercial.', '2026-07-01', '2026-08-30', 'cancelado'),
(7, 3, 'Campaña Landing Proyecto Miraflores', 'Sitio promocional para nuevo edificio residencial.', '2026-12-01', '2027-01-15', 'planificado');

-- 4. Solicitudes SOLPED de prueba
INSERT IGNORE INTO solped (solped_id, cliente_id, proyecto_id, usuario_id, fecha_solicitud, descripcion_requerimiento, estado) VALUES
(3, 3, 3, (SELECT id FROM usuarios WHERE correo='gestor@lumyn.pe' LIMIT 1), '2026-08-10 10:30:00', 'Desarrollo de catálogo inmobiliario administrable', 'convertida'),
(4, 4, 4, (SELECT id FROM usuarios WHERE correo='gestor@lumyn.pe' LIMIT 1), '2026-09-02 15:15:00', 'Carta digital QR + integración WhatsApp Reservas', 'convertida'),
(5, 5, 5, (SELECT id FROM usuarios WHERE correo='gestor@lumyn.pe' LIMIT 1), '2026-10-25 11:00:00', 'Landing de admisión 2027 + pasarela de pagos', 'aprobada'),
(6, 3, 7, (SELECT id FROM usuarios WHERE correo='gestor@lumyn.pe' LIMIT 1), '2026-11-18 16:40:00', 'Micrositio lanzamiento torre Miraflores', 'en_revision'),
(7, 6, 6, (SELECT id FROM usuarios WHERE correo='gestor@lumyn.pe' LIMIT 1), '2026-07-12 09:20:00', 'E-commerce B2B con catálogo de 500 SKUs', 'rechazada');

INSERT IGNORE INTO solped_detalle (solped_detalle_id, solped_id, servicio, descripcion, cantidad, precio_unitario) VALUES
(4, 3, 'Diseño UI/UX', 'Sistema de diseño y prototipo', 1, 2200.00),
(5, 3, 'Desarrollo Backend + BD', 'API y buscador inmobiliario', 1, 4500.00),
(6, 4, 'Carta Digital QR', 'Maquetación móvil y panel', 1, 1900.00),
(7, 5, 'Landing Matrículas', 'Formulario y pasarela Culqi/Niubiz', 1, 3500.00),
(8, 6, 'Micrositio Promocional', 'Diseño y formulario de leads', 1, 2400.00),
(9, 7, 'Tienda B2B', 'Implementación base', 1, 6000.00);

-- 5. Ventas en distintos meses (para gráficos de Apache ECharts)
INSERT IGNORE INTO ventas (venta_id, solped_id, cliente_id, proyecto_id, fecha_venta, subtotal, impuesto, total, estado) VALUES
(3, 3, 3, 3, '2026-08-20 14:00:00', 6700.00, 1206.00, 7906.00, 'pagada'),
(4, 4, 4, 4, '2026-09-12 17:30:00', 1900.00, 342.00, 2242.00, 'pagada');

INSERT IGNORE INTO venta_detalle (venta_detalle_id, venta_id, servicio, descripcion, cantidad, precio_unitario) VALUES
(4, 3, 'Diseño UI/UX', 'Sistema de diseño y prototipo', 1, 2200.00),
(5, 3, 'Desarrollo Backend + BD', 'API y buscador inmobiliario', 1, 4500.00),
(6, 4, 'Carta Digital QR', 'Maquetación móvil y panel', 1, 1900.00);

-- 6. Tareas asignadas al Colaborador y al Gestor
INSERT IGNORE INTO tareas (tarea_id, proyecto_id, usuario_id, titulo, descripcion, prioridad, avance, fecha_limite, estado) VALUES
(4, 5, (SELECT id FROM usuarios WHERE correo='colaborador@lumyn.pe' LIMIT 1), 'Diseñar formulario de matrícula', 'Validación de DNI, carrera y turno', 'alta', 65, '2026-12-02', 'en_progreso'),
(5, 5, (SELECT id FROM usuarios WHERE correo='colaborador@lumyn.pe' LIMIT 1), 'Integrar envío de constancia PDF', 'Generación automática tras registro', 'media', 20, '2026-12-10', 'en_progreso'),
(6, 3, (SELECT id FROM usuarios WHERE correo='colaborador@lumyn.pe' LIMIT 1), 'Optimizar imágenes del catálogo', 'Conversión a WebP y carga diferida', 'baja', 100, '2026-10-15', 'completada'),
(7, 7, (SELECT id FROM usuarios WHERE correo='gestor@lumyn.pe' LIMIT 1), 'Reunión de kickoff con cliente', 'Definir cronograma y entregables', 'alta', 0, '2026-12-03', 'pendiente');

-- 7. Entregables y Observaciones
INSERT IGNORE INTO entregables (entregable_id, proyecto_id, usuario_id, titulo, descripcion, version, url_archivo, estado) VALUES
(3, 3, (SELECT id FROM usuarios WHERE correo='colaborador@lumyn.pe' LIMIT 1), 'Catálogo Inmobiliario Producción', 'Despliegue final validado en staging', 'v2.0', 'https://horizontesur.pe/demo', 'aprobado'),
(4, 5, (SELECT id FROM usuarios WHERE correo='colaborador@lumyn.pe' LIMIT 1), 'Mockup Aula Virtual', 'Pantallas principales de alumno y docente', 'v1.0', 'https://figma.com/file/sigma-aula', 'observado'),
(5, 5, (SELECT id FROM usuarios WHERE correo='colaborador@lumyn.pe' LIMIT 1), 'Módulo de Inscripción en Línea', 'Primera versión funcional para revisión QA', 'v1.1', 'https://staging.academiasigma.edu.pe', 'pendiente');

INSERT IGNORE INTO entregable_observaciones (observacion_id, entregable_id, usuario_id, comentario) VALUES
(2, 3, (SELECT id FROM usuarios WHERE correo='revisor@lumyn.pe' LIMIT 1), 'Cumple con todos los requerimientos visuales y de velocidad.'),
(3, 4, (SELECT id FROM usuarios WHERE correo='revisor@lumyn.pe' LIMIT 1), 'Ajustar contraste de botones en vista móvil y agregar botón de descarga.');
