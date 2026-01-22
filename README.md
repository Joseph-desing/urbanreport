# UrbanReport

Una aplicación móvil Flutter que permite a los ciudadanos reportar problemas urbanos en su comunidad. Permite reportar baches, luminarias dañadas, acumulación de basura, alcantarillas obstruidas y otros problemas mediante fotografías y ubicación geográfica.



## Requisitos Previos

- Flutter SDK 3.10.1 o superior
- Dart 3.10.1 o superior
- Cuenta en [Supabase](https://supabase.com)
- Git

## Instalación

### 1. Clonamos el repositorio

### 2. Instalamos dependencias

```bash
flutter pub get
```

### 3. Configuramos Supabase

1. Se crea un proyecto en [Supabase](https://supabase.com)
2. En el proyecto, se actualiza el archivo `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://tu-proyecto.supabase.co';
  static const String supabaseAnonKey = 'tu-anon-key';
  
  static const String usersTable = 'users';
  static const String reportsTable = 'reports';
  static const String reportImagesBucket = 'report-images';
}
```

### 4. Creamos las tablas en Supabase

En el SQL Editor de Supabase, se ejecuta:

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


```



### 6. Estructura del Proyecto

```
lib/
├── config/
│   └── supabase_config.dart       
├── models/
│   ├── user.dart                  
│   └── report.dart                
├── services/
│   ├── auth_service.dart          
│   └── report_service.dart        
├── providers/
│   ├── auth_provider.dart         
│   └── report_provider.dart       
├── screens/
│   ├── login_screen.dart          
│   ├── signup_screen.dart         
│   ├── home_screen.dart           
│   ├── create_report_screen.dart  
│   └── report_detail_screen.dart  
├── widgets/                        
├── utils/                          
└── main.dart                       
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
Se Agrega en `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```




