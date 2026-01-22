## GUÍA RÁPIDA - PRIMEROS PASOS

### 1️⃣ PREPARAR EL PROYECTO

```bash
# Navegar al directorio
cd c:\Users\HP\Desktop\urbanreport

# Descargar dependencias
flutter pub get

# Verificar que todo está bien
flutter doctor
```

### 2️⃣ CONFIGURAR SUPABASE

#### Opción A: Crear nuevo proyecto en Supabase
1. Ve a [supabase.com](https://supabase.com)
2. Crea una cuenta o inicia sesión
3. Crea un nuevo proyecto
4. En el dashboard, copia:
   - **Project URL** → `SupabaseConfig.supabaseUrl`
   - **Anon/Public Key** → `SupabaseConfig.supabaseAnonKey`

#### Opción B: Crear tablas en tu proyecto
En el SQL Editor de Supabase, ejecuta este script:

```sql
-- Habilitar extensión UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabla de usuarios
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de reportes
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

-- Crear índices
CREATE INDEX idx_reports_usuario_id ON reports(usuario_id);
CREATE INDEX idx_reports_created_at ON reports(created_at DESC);
CREATE INDEX idx_reports_estado ON reports(estado);

-- Crear bucket para imágenes
-- Hazlo desde la interfaz: Storage → New Bucket → "report-images"
```

#### Opción C: Actualizar configuración
Edita `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://tu-proyecto.supabase.co';
  static const String supabaseAnonKey = 'tu-clave-anon';
  
  static const String usersTable = 'users';
  static const String reportsTable = 'reports';
  static const String reportImagesBucket = 'report-images';
}
```

### 3️⃣ EJECUTAR LA APLICACIÓN

```bash
# Ejecutar en general (iOS/Android según dispositivo disponible)
flutter run

# Ejecutar en Android
flutter run -d android

# Ejecutar en iOS
flutter run -d ios

# Ejecutar en navegador
flutter run -d chrome

# Con modo debug
flutter run --debug

# Con modo release
flutter run --release
```

### 4️⃣ PRUEBAS BÁSICAS

#### 4A. Registro
1. Abre la app
2. Haz clic en "Regístrate"
3. Completa:
   - Nombre: ej. "Juan Pérez"
   - Correo: ej. "juan@example.com"
   - Contraseña: ej. "Password123"
   - Confirmar: ej. "Password123"
4. Haz clic en "Registrarse"
5. Verifica tu correo (revisa spam)

#### 4B. Iniciar sesión
1. Usa las credenciales registradas
2. Haz clic en "Iniciar sesión"

#### 4C. Ver mapa
1. Después de iniciar sesión, verás el mapa
2. Los puntos de colores son reportes
3. Haz clic en un punto para ver detalles

#### 4D. Crear reporte
1. Haz clic en el botón flotante (+)
2. Rellena el formulario:
   - **Título**: ej. "Bache en Av. Principal"
   - **Descripción**: ej. "Bache de 1 metro en la cuadra 5"
   - **Categoría**: Selecciona "Bache"
3. En el mapa:
   - Haz clic para seleccionar ubicación, O
   - Haz clic en "Mi ubicación actual" (necesita GPS)
4. Toma una foto con "Tomar foto"
5. Haz clic en "Crear Reporte"

#### 4E. Ver detalles
1. Desde el mapa, haz clic en un marcador
2. O desde la lista, toca un reporte
3. Puedes cambiar el estado (si es tu reporte)
4. Puedes eliminarlo (si es tu reporte)

### 5️⃣ SOLUCIONAR PROBLEMAS

#### ❌ "Target of URI doesn't exist: 'package:latlong2/latlong2.dart'"
**Solución:**
```bash
flutter pub get
flutter clean
flutter pub get
```

#### ❌ "Error de autenticación"
**Verifica:**
- La URL de Supabase es correcta
- La clave anónima es válida
- Las tablas existen en la BD
- Email y contraseña son válidos

#### ❌ "Permiso de cámara denegado"
**En Android** - Verifica `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

**En iOS** - Verifica `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación</string>
```

#### ❌ "No se puede cargar el mapa"
**Verifica:**
- Conexión a internet
- OpenStreetMap está disponible
- No hay problemas de CORS en web

### 6️⃣ ARCHIVOS IMPORTANTES

```
urbanreport/
├── lib/
│   ├── main.dart                    👈 Punto de entrada
│   ├── config/supabase_config.dart  👈 EDITAR: Credenciales
│   ├── services/
│   │   ├── auth_service.dart        👈 Autenticación
│   │   └── report_service.dart      👈 Reportes
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── home_screen.dart
│   │   ├── create_report_screen.dart
│   │   └── report_detail_screen.dart
│   └── providers/
│       ├── auth_provider.dart
│       └── report_provider.dart
├── pubspec.yaml                     👈 Dependencias
└── README.md                        👈 Documentación

```

### 7️⃣ COMANDOS ÚTILES

```bash
# Ver todas las dependencias
flutter pub deps

# Actualizar dependencias
flutter pub upgrade

# Limpiar compilación
flutter clean

# Generar APK (Android)
flutter build apk

# Generar IPA (iOS)
flutter build ios

# Verificar calidad del código
flutter analyze

# Formato de código
dart format lib/

# Ver logs
flutter logs

# Conectar a dispositivo
flutter devices

# Ejecutar con modo verbose
flutter run -v
```

### 8️⃣ NOTAS IMPORTANTES

⚠️ **SEGURIDAD**
- Las credenciales de Supabase en `supabase_config.dart` son públicas (anonKey)
- Para producción, implementa autenticación segura en backend
- No guardes tokens en texto plano

⚠️ **PERMISOS**
- La app solicita permiso de cámara y ubicación en tiempo de ejecución
- En Android, necesitas aceptar en Settings
- En iOS, aparece un diálogo la primera vez

⚠️ **ALMACENAMIENTO**
- Las imágenes se guardan en Supabase Storage
- Necesitan permisos RLS configurados

### 9️⃣ CONTACTO/SOPORTE

Para problemas:
1. Revisa [Flutter Docs](https://flutter.dev)
2. Revisa [Supabase Docs](https://supabase.com/docs)
3. Busca en [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

---

## ¡LISTO PARA COMENZAR! 🚀

Sigue estos pasos y tendrás UrbanReport funcionando en minutos.
