// Configuración de Supabase
// IMPORTANTE: Reemplaza estos valores con tus credenciales reales de Supabase

class SupabaseConfig {
  // Obtén estas credenciales de tu proyecto en Supabase
  static const String supabaseUrl = 'https://fqmhtmvbgjtzglnoscer.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_aXjTOZHyQHl2rk1ZXLw6Dw_H_Hn8kZL';
  
  // Nombres de tablas en la base de datos
  static const String usersTable = 'users';
  static const String reportsTable = 'reports';
  
  // Nombre del bucket para almacenar imágenes
  static const String reportImagesBucket = 'report-images';
}
