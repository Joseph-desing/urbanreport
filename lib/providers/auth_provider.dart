import 'package:flutter/material.dart';
import 'package:urbanreport/models/user.dart';
import 'package:urbanreport/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Constructor
  AuthProvider() {
    _checkAuthStatus();
    _listenToAuthChanges();
  }

  // Verificar estado de autenticación
  Future<void> _checkAuthStatus() async {
    _currentUser = _authService.getCurrentUser();
    _isAuthenticated = _currentUser != null;
    notifyListeners();
  }

  // Escuchar cambios de autenticación
  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((state) {
      _checkAuthStatus();
    });
  }

  // Registrar
  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      // No asumir sesión activa si Supabase requiere confirmar el correo
      _isAuthenticated = _authService.isAuthenticated();
      if (!_isAuthenticated) {
        _currentUser = null;
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Iniciar sesión
  Future<void> signin({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      _isAuthenticated = _authService.isAuthenticated();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cerrar sesión
  Future<void> signout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _isAuthenticated = false;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Recuperar contraseña
  Future<void> resetPassword({required String email}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.resetPassword(email: email);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
