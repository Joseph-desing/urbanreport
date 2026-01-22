import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urbanreport/config/supabase_config.dart';
import 'package:urbanreport/models/user.dart' as user_model;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener usuario actual
  user_model.User? getCurrentUser() {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final user = session.user;
    return user_model.User(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'] ?? '',
      createdAt: DateTime.parse(user.createdAt.toString()),
    );
  }

  // Registrar nuevo usuario
  Future<user_model.User> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user == null) {
        throw Exception('Error al registrar el usuario');
      }

      // Crear entrada en tabla users
      try {
        await _supabase.from(SupabaseConfig.usersTable).insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Si ya existe (por trigger u otro motivo), continuar
        debugPrint('Nota: Usuario ya existe en tabla users: $e');
      }

      return user_model.User(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error de registro: $e');
    }
  }

  // Iniciar sesión
  Future<user_model.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error al iniciar sesión');
      }

      final userData = await _supabase
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', response.user!.id)
          .single();

      return user_model.User.fromJson(userData);
    } catch (e) {
      throw Exception('Error de inicio de sesión: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Recuperar contraseña
  Future<void> resetPassword({required String email}) async {
    try {
      // Obtener la URL actual para el redirect
      String redirectUrl;
      if (kIsWeb) {
        // Para Flutter Web, usar la URL actual del navegador
        redirectUrl = Uri.base.origin;
      } else {
        // Para apps móviles, usar deep link (ajustar según tu configuración)
        redirectUrl = 'urbanreport://reset-password';
      }

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );
    } on AuthApiException {
      // Re-lanzar la excepción de Supabase sin modificarla
      rethrow;
    } catch (e) {
      // Para otros errores, lanzar como están
      rethrow;
    }
  }

  // Escuchar cambios de autenticación
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  // Verificar si el usuario está autenticado
  bool isAuthenticated() {
    return _supabase.auth.currentSession != null;
  }
}
