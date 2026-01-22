# UrbanReport

Una aplicación móvil Flutter que permite a los ciudadanos reportar problemas urbanos en su comunidad. Permite reportar baches, luminarias dañadas, acumulación de basura, alcantarillas obstruidas y otros problemas mediante fotografías y ubicación geográfica.

## Características

- **Autenticación de usuarios** con verificación por correo electrónico
- **Operaciones CRUD** en reportes almacenados en la nube
- **Almacenamiento de imágenes** en Supabase Storage
- **Integración de mapas interactivos** con OpenStreetMap
- **Geolocalización automática** de problemas reportados
- **Gestión de estado** con Provider
- **Categorización de reportes**: Baches, Luminarias, Basura, Alcantarillas, Otro

## Requisitos Previos

- Flutter SDK 3.10.1 o superior
- Dart 3.10.1 o superior
- Cuenta en [Supabase](https://supabase.com)
- Git

## Instalación

### 1. Clonar el repositorio

```bash
git clone <tu-repo>
cd urbanreport
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Supabase

1. Crea un proyecto en [Supabase](https://supabase.com)
2. En tu proyecto, actualiza el archivo `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://tu-proyecto.supabase.co';
  static const String supabaseAnonKey = 'tu-anon-key';
  
  static const String usersTable = 'users';
  static const String reportsTable = 'reports';
  static const String reportImagesBucket = 'report-images';
}
```

### 4. Crear las tablas en Supabase

En el SQL Editor de Supabase, ejecuta:

```sql
-- Tabla de usuarios
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
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

-- Crear índices para mejor rendimiento
CREATE INDEX reports_usuario_id ON reports(usuario_id);
CREATE INDEX reports_created_at ON reports(created_at DESC);
CREATE INDEX reports_estado ON reports(estado);
```

### 5. Configurar Storage en Supabase

1. En Supabase, ve a Storage
2. Crea un bucket llamado `report-images`
3. Configura las políticas de acceso según sea necesario

### 6. Ejecutar la aplicación

```bash
flutter run
```

Para ejecutar en plataforma específica:

```bash
flutter run -d android   # Android
flutter run -d ios       # iOS
flutter run -d web       # Web
flutter run -d windows   # Windows
flutter run -d linux     # Linux
```

## Estructura del Proyecto

```
lib/
├── config/
│   └── supabase_config.dart       # Configuración de Supabase
├── models/
│   ├── user.dart                  # Modelo de usuario
│   └── report.dart                # Modelo de reporte
├── services/
│   ├── auth_service.dart          # Servicio de autenticación
│   └── report_service.dart        # Servicio de reportes
├── providers/
│   ├── auth_provider.dart         # Provider de autenticación
│   └── report_provider.dart       # Provider de reportes
├── screens/
│   ├── login_screen.dart          # Pantalla de inicio de sesión
│   ├── signup_screen.dart         # Pantalla de registro
│   ├── home_screen.dart           # Pantalla principal con mapa
│   ├── create_report_screen.dart  # Pantalla de creación de reportes
│   └── report_detail_screen.dart  # Pantalla de detalles del reporte
├── widgets/                        # Componentes reutilizables
├── utils/                          # Utilidades y helpers
└── main.dart                       # Punto de entrada
```

## Flujo de la Aplicación

1. **Autenticación**: El usuario se registra o inicia sesión
2. **Home (Mapa)**: Visualiza todos los reportes en el mapa
3. **Crear Reporte**: Selecciona ubicación en mapa, captura foto, agrega detalles
4. **Ver Detalles**: Consulta información completa de reportes
5. **Actualizar Estado**: El usuario propietario puede actualizar el estado del reporte

## Dependencias Principales

- `supabase_flutter`: Backend y autenticación
- `flutter_map`: Visualización de mapas
- `latlong2`: Coordenadas geográficas
- `geolocator`: Acceso a ubicación del dispositivo
- `image_picker`: Selección de imágenes
- `permission_handler`: Gestión de permisos
- `provider`: Gestión de estado

## Permisos Requeridos

### Android
Agrega en `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS
Agrega en `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Esta aplicación necesita acceso a tu ubicación para reportar problemas urbanos.</string>
<key>NSCameraUsageDescription</key>
<string>Esta aplicación necesita acceso a la cámara para capturar fotos de los problemas.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Esta aplicación necesita acceso a tu galería de fotos.</string>
```

## Contribución

Para contribuir al proyecto:

1. Fork el repositorio
2. Crea una rama con tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la licencia MIT. Ver `LICENSE` para más detalles.

## Soporte

Para reportar bugs o solicitar features, abre un issue en el repositorio.

## Autor

Desarrollado como proyecto educativo para evaluar competencias en desarrollo de aplicaciones móviles con Flutter.
