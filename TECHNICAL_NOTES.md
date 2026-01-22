## NOTAS TÉCNICAS Y ARQUITECTURA

### 📐 ARQUITECTURA DEL PROYECTO

```
┌─────────────────────────────────────┐
│           PRESENTATION              │
│      (Screens/Widgets/UI)           │
├─────────────────────────────────────┤
│      BUSINESS LOGIC (Providers)     │
│   • AuthProvider                    │
│   • ReportProvider                  │
├─────────────────────────────────────┤
│          SERVICES                   │
│   • AuthService                     │
│   • ReportService                   │
├─────────────────────────────────────┤
│         DATA MODELS                 │
│   • User                            │
│   • Report                          │
├─────────────────────────────────────┤
│         EXTERNAL SERVICES           │
│   • Supabase Auth                   │
│   • Supabase Database               │
│   • Supabase Storage                │
│   • OpenStreetMap                   │
│   • Geolocator Service              │
└─────────────────────────────────────┘
```

---

### 🔄 FLUJOS PRINCIPALES

#### 1. FLUJO DE AUTENTICACIÓN

```
┌─────────────┐
│   START     │
└──────┬──────┘
       │
       ▼
  ┌─────────────────┐
  │ Usuario existe? │
  └────┬────────┬───┘
       │ NO     │ SI
       ▼        ▼
   SignUp    Login
       │        │
       ├────┬───┘
       ▼    ▼
    Supabase Auth
       │
       ├─ Email verification
       │
       ▼
  Create user profile
       │
       ▼
  AuthProvider.signin()
       │
       ▼
  Navigate to HomeScreen
```

#### 2. FLUJO DE CREAR REPORTE

```
┌────────────────────┐
│ CreateReportScreen │
└─────────┬──────────┘
          │
          ▼
    ┌──────────────┐
    │ Llenar datos │
    └──────┬───────┘
           │
      ┌────┴────┐
      ▼         ▼
   Mapa      Foto
      │         │
      └────┬────┘
           ▼
  Validar formulario
           │
           ▼
   ReportService.createReport()
           │
      ┌────┴─────┐
      ▼          ▼
   Subir foto   Crear registro
   (Storage)    (Database)
      │          │
      └────┬─────┘
           ▼
  Actualizar ReportProvider
           │
           ▼
    Navigate to HomeScreen
```

---

### 📦 PATRONES UTILIZADOS

#### 1. **Provider Pattern** (Gestión de Estado)
```dart
// AuthProvider escucha cambios
final authProvider = context.watch<AuthProvider>();

// ReportProvider acceso a métodos
final reports = context.read<ReportProvider>();
```

**Ventajas:**
- ✅ Separación de concerns
- ✅ Fácil testing
- ✅ Reactividad automática
- ✅ Evita prop drilling

#### 2. **Service Locator** (Inyección de Dependencias)
```dart
// En cada Service
final SupabaseClient _supabase = Supabase.instance.client;
```

**Ventajas:**
- ✅ Singleton automático
- ✅ Fácil de mockear
- ✅ Acceso centralizado

#### 3. **Model - Service - Provider** (MVSP)
```
Report (Model)
   ↓
ReportService (CRUD)
   ↓
ReportProvider (State Management)
   ↓
UI (Screens)
```

---

### 🔐 CONSIDERACIONES DE SEGURIDAD

#### 1. **Row Level Security (RLS)** en Supabase
✅ Implementado en tablas users y reports
✅ Solo usuarios autenticados pueden ver sus datos
✅ Solo propietario puede actualizar/eliminar

#### 2. **Validación**
✅ Validación en formularios (Frontend)
✅ Validación en base de datos (CHECK constraints)
✅ Tipos enumerados para categoría y estado

#### 3. **Autenticación**
✅ Email + contraseña
✅ Sesiones gestionadas por Supabase
✅ Tokens JWT automáticos

#### 4. **Permisos**
✅ Solicitud en tiempo de ejecución
✅ Manejo de permisos denegados
✅ Fallback si permiso no disponible

---

### ⚡ OPTIMIZACIONES

#### 1. **Índices en Base de Datos**
```sql
-- Consultas rápidas por usuario
CREATE INDEX idx_reports_usuario_id ON reports(usuario_id);

-- Ordenamientos rápidos
CREATE INDEX idx_reports_created_at ON reports(created_at DESC);

-- Filtros de estado rápidos
CREATE INDEX idx_reports_estado ON reports(estado);
```

#### 2. **Lazy Loading**
```dart
// Las imágenes cargan bajo demanda
Image.network(
  url,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, loading) { ... }
)
```

#### 3. **Cacheado**
```dart
// Providers mantienen datos en memoria
final reports = await reportProvider.fetchAllReports();
// Reutiliza sin recargar
```

---

### 🐛 MANEJO DE ERRORES

#### Estrategia de Errores
```dart
try {
  // Operación
} on SocketException catch (e) {
  // Sin internet
} on PostgrestException catch (e) {
  // Error de base de datos
} catch (e) {
  // Error genérico
}
```

#### Presentación de Errores al Usuario
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error: ${error.toString()}'),
    backgroundColor: Colors.red,
  ),
);
```

---

### 📊 ESTRUCTURA DE DATOS EN RUNTIME

#### AuthProvider State
```dart
{
  currentUser: User | null,
  isAuthenticated: bool,
  isLoading: bool
}
```

#### ReportProvider State
```dart
{
  allReports: List<Report>,
  userReports: List<Report>,
  isLoading: bool,
  errorMessage: String | null
}
```

---

### 🔌 INTEGRACIONES EXTERNAS

#### 1. **Supabase**
- Auth: `supabase.auth.signUp()`, `signIn()`, `signOut()`
- Database: `supabase.from(table).select()`, `insert()`, `update()`, `delete()`
- Storage: `supabase.storage.from(bucket).upload()`, `getPublicUrl()`

#### 2. **Geolocator**
- `getCurrentPosition()`: Ubicación actual
- `requestPermission()`: Solicitar permisos

#### 3. **ImagePicker**
- `pickImage()`: Seleccionar de galería o cámara

#### 4. **Flutter Map**
- `FlutterMap`: Widget de mapa
- `TileLayer`: Capa de tiles (OpenStreetMap)
- `MarkerLayer`: Capa de marcadores

---

### 🚀 ESCALABILIDAD FUTURA

#### Mejoras Recomendadas

1. **Caché Local**
   ```dart
   // Usar Hive o Isar para almacenamiento local
   // Sincronización offline-first
   ```

2. **Paginación**
   ```dart
   // Cargar reportes en páginas
   // Evitar cargar todos de una vez
   ```

3. **Filtros Avanzados**
   ```dart
   // Filtrar por fecha, categoría, estado
   // Búsqueda de texto
   ```

4. **Notificaciones en Tiempo Real**
   ```dart
   // Firebase Cloud Messaging
   // WebSockets de Supabase
   ```

5. **Analytics**
   ```dart
   // Rastrear uso de la app
   // Monitorear reportes
   ```

6. **Internacionalización**
   ```dart
   // Soporte para múltiples idiomas
   // Localización
   ```

---

### 🧪 TESTING

#### Pruebas Unitarias Sugeridas
```dart
// tests/auth_service_test.dart
test('signUp creates new user', () async {
  final user = await authService.signUp(
    email: 'test@test.com',
    password: 'Test123',
    fullName: 'Test User'
  );
  expect(user.email, 'test@test.com');
});

// tests/report_service_test.dart
test('createReport with valid data', () async {
  final report = await reportService.createReport(...);
  expect(report.id, isNotNull);
});
```

#### Pruebas de Integración
```dart
// test_driver/app_test.dart
testWidgets('User can register and create report', (driver) async {
  // Registrar usuario
  // Iniciar sesión
  // Crear reporte
  // Verificar en mapa
});
```

---

### 📱 COMPATIBILIDAD

#### Plataformas Soportadas
- ✅ Android 5.0+ (API 21+)
- ✅ iOS 11.0+
- ✅ Web (Chrome, Firefox, Safari)
- ✅ Windows 7+
- ✅ macOS 10.11+
- ✅ Linux

#### Dependencias Nativas
- iOS: MapKit (Flutter Map)
- Android: Google Play Services (Geolocator)

---

### 🔧 DESARROLLO

#### Hot Reload
```bash
# Presiona 'r' en la terminal durante flutter run
# Para recargar sin perder estado

# Presiona 'R' para hot restart (reinicia la app)
```

#### Debug
```bash
# Ver logs
flutter logs

# Modo verbose
flutter run -v

# Debugger
flutter run -d chrome  # Abre DevTools en navegador
```

#### Lint/Análisis
```bash
# Verificar calidad de código
flutter analyze

# Formato automático
dart format lib/

# Fijar problemas
dart fix --apply
```

---

### 📝 CONVENCIONES DE CÓDIGO

#### Nombres de Archivos
- `snake_case`: `auth_service.dart`
- `PascalCase`: `AuthService` (clase)
- `camelCase`: `currentUser` (variable)

#### Estructura de Carpetas
```
feature/
├── models/
│   └── feature_model.dart
├── services/
│   └── feature_service.dart
├── providers/
│   └── feature_provider.dart
└── screens/
    └── feature_screen.dart
```

#### Documentación
```dart
/// Crea un nuevo reporte
/// 
/// Parámetros:
///   - usuarioId: ID del usuario autenticado
///   - titulo: Título descriptivo
///   - descripcion: Descripción detallada
///   
/// Retorna: [Report] creado exitosamente
Future<Report> createReport({...}) async { }
```

---

### 📈 PERFORMANCE

#### Métricas a Monitorear
- ⏱️ Tiempo de carga inicial
- 📊 Consumo de memoria
- 🔋 Consumo de batería
- 📱 Tamaño de APK/IPA

#### Tips de Optimización
1. Usar `const` constructores
2. Implementar `shouldRebuild` en Providers
3. Usar `ListView.builder` para listas grandes
4. Evitar computaciones en build()
5. Cachear imágenes

---

**Última actualización**: 21 de enero de 2026
**Versión**: 1.0.0 - Producción
