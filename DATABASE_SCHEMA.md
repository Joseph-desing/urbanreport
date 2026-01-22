## ESTRUCTURA DE BASE DE DATOS - SUPABASE

### Tablas Necesarias

#### 1. Tabla `auth.users` (Automática de Supabase)
Supabase gestiona automáticamente esta tabla para autenticación.

```
- id (UUID) - Primary Key
- email (TEXT) - Único
- encrypted_password (TEXT)
- email_confirmed_at (TIMESTAMP)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
- ...otros campos de Supabase
```

---

#### 2. Tabla `users` (Perfil de Usuario)

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- Política de seguridad (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios pueden ver su propio perfil"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Usuarios pueden actualizar su propio perfil"
  ON users FOR UPDATE
  USING (auth.uid() = id);
```

**Campos:**
- `id`: UUID único (referencia a auth.users)
- `email`: Correo único del usuario
- `full_name`: Nombre completo
- `created_at`: Timestamp de creación
- `updated_at`: Timestamp de última actualización

---

#### 3. Tabla `reports` (Reportes de Problemas)

```sql
CREATE TABLE reports (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  usuario_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  titulo TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  categoria TEXT NOT NULL CHECK (categoria IN ('bache', 'luminaria', 'basura', 'alcantarilla', 'otro')),
  estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'en_proceso', 'resuelto')),
  latitud DOUBLE PRECISION NOT NULL,
  longitud DOUBLE PRECISION NOT NULL,
  foto_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para mejor rendimiento
CREATE INDEX idx_reports_usuario_id ON reports(usuario_id);
CREATE INDEX idx_reports_created_at ON reports(created_at DESC);
CREATE INDEX idx_reports_estado ON reports(estado);
CREATE INDEX idx_reports_categoria ON reports(categoria);
CREATE INDEX idx_reports_ubicacion ON reports(latitud, longitud);

-- Política de seguridad (RLS)
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Cualquiera puede ver reportes"
  ON reports FOR SELECT
  USING (true);

CREATE POLICY "Usuarios autenticados pueden crear reportes"
  ON reports FOR INSERT
  WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Usuarios pueden actualizar sus propios reportes"
  ON reports FOR UPDATE
  USING (auth.uid() = usuario_id);

CREATE POLICY "Usuarios pueden eliminar sus propios reportes"
  ON reports FOR DELETE
  USING (auth.uid() = usuario_id);
```

**Campos:**
- `id`: UUID único
- `usuario_id`: FK a tabla users (quién reportó)
- `titulo`: Título descriptivo (ej: "Bache en Av. Principal")
- `descripcion`: Descripción detallada
- `categoria`: ENUM (bache, luminaria, basura, alcantarilla, otro)
- `estado`: ENUM (pendiente, en_proceso, resuelto)
- `latitud`: Coordenada de latitud
- `longitud`: Coordenada de longitud
- `foto_url`: URL de la imagen en Storage
- `created_at`: Fecha de creación
- `updated_at`: Fecha de última actualización

---

### Storage Bucket

#### Bucket `report-images`

```
report-images/
├── {usuario_id}/
│   ├── usuario_id_timestamp1.jpg
│   ├── usuario_id_timestamp2.jpg
│   └── ...
```

**Configuración:**
```sql
-- Permitir lectura pública
CREATE POLICY "Public Access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'report-images');

-- Permitir upload autenticado
CREATE POLICY "Authenticated users can upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'report-images'
    AND auth.role() = 'authenticated'
  );

-- Permitir delete de propios uploads
CREATE POLICY "Users can delete own uploads"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'report-images'
    AND auth.uid()::text = owner
  );
```

---

### Consultas Útiles para Pruebas

#### Ver todos los usuarios
```sql
SELECT * FROM users;
```

#### Ver todos los reportes
```sql
SELECT 
  r.id, 
  r.titulo, 
  u.full_name as creado_por,
  r.categoria, 
  r.estado,
  r.created_at
FROM reports r
JOIN users u ON r.usuario_id = u.id
ORDER BY r.created_at DESC;
```

#### Ver reportes pendientes
```sql
SELECT * FROM reports
WHERE estado = 'pendiente'
ORDER BY created_at DESC;
```

#### Ver reportes por categoría
```sql
SELECT categoria, COUNT(*) as total
FROM reports
GROUP BY categoria
ORDER BY total DESC;
```

#### Ver reportes cercanos (ejemplo: 5km de coordenadas)
```sql
SELECT 
  *,
  -- Fórmula Haversine para calcular distancia
  (
    6371 * 
    acos(
      cos(radians(37.7749)) * 
      cos(radians(latitud)) * 
      cos(radians(longitud) - radians(-122.4194)) + 
      sin(radians(37.7749)) * 
      sin(radians(latitud))
    )
  ) as distancia_km
FROM reports
HAVING distancia_km <= 5
ORDER BY distancia_km ASC;
```

#### Eliminar un reporte específico
```sql
DELETE FROM reports 
WHERE id = 'uuid-del-reporte';
```

#### Actualizar estado de un reporte
```sql
UPDATE reports
SET estado = 'resuelto', updated_at = NOW()
WHERE id = 'uuid-del-reporte';
```

---

### Migraciones Recomendadas

Para versiones futuras:

```sql
-- Agregar calificación de reportes
ALTER TABLE reports ADD COLUMN calificacion INTEGER CHECK (calificacion >= 1 AND calificacion <= 5);

-- Agregar comentarios
CREATE TABLE report_comments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  usuario_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  comentario TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Agregar historial de estados
CREATE TABLE report_history (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  estado_anterior TEXT,
  estado_nuevo TEXT NOT NULL,
  cambio_por UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Agregar notificaciones
CREATE TABLE notificaciones (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  usuario_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  titulo TEXT NOT NULL,
  mensaje TEXT,
  leida BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

### Respaldo y Recuperación

#### Exportar datos
```bash
# Usando pg_dump
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres -t users > users.sql
```

#### Importar datos
```bash
# Usando psql
psql -h db.xxxxx.supabase.co -U postgres -d postgres -f backup.sql
```

---

### Monitoring

#### Ver tamaño de tabla
```sql
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

#### Ver reportes activos en las últimas 24 horas
```sql
SELECT COUNT(*) as reportes_nuevos
FROM reports
WHERE created_at > NOW() - INTERVAL '24 hours';
```

---

**Última actualización**: 21 de enero de 2026
**Estado**: Listo para producción
