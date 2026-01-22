import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urbanreport/config/supabase_config.dart';
import 'package:urbanreport/models/report.dart';
import 'package:urbanreport/providers/auth_provider.dart';
import 'package:urbanreport/providers/report_provider.dart';
import 'package:urbanreport/screens/create_report_screen.dart';
import 'package:urbanreport/screens/home_screen.dart';
import 'package:urbanreport/screens/login_screen.dart';
import 'package:urbanreport/screens/report_detail_screen.dart';
import 'package:urbanreport/screens/reset_password_screen.dart';
import 'package:urbanreport/screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'UrbanReport',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoginMode = true;
  Report? _selectedReport;
  String _currentScreen = 'auth';
  String? _authErrorMessage;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _handleAuthErrorFromRedirect();
    _handleRecoveryRedirect();

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        setState(() {
          _currentScreen = 'resetPassword';
          _selectedReport = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _handleAuthErrorFromRedirect() {
    final uri = Uri.base;
    final error = uri.queryParameters['error'];
    if (error == null) return;

    _authErrorMessage = uri.queryParameters['error_description'] ??
        'El enlace de correo es inválido o ha expirado. Solicita uno nuevo.';

    Future.microtask(() async {
      if (!mounted) return;
      await context.read<AuthProvider>().signout();
      if (!mounted) return;
      setState(() {
        _isLoginMode = true;
        _currentScreen = 'auth';
        _selectedReport = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authErrorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  Future<void> _handleRecoveryRedirect() async {
    final uri = Uri.base;
    final query = uri.queryParameters;
    Map<String, String> fragment = {};
    if (uri.fragment.isNotEmpty) {
      try {
        fragment = Uri.splitQueryString(uri.fragment);
      } catch (_) {
        fragment = {};
      }
    }

    final code = query['code'] ?? fragment['code'];
    final refreshToken = query['refresh_token'] ?? fragment['refresh_token'];
    final accessToken = query['access_token'] ?? fragment['access_token'];
    final isRecovery = query['type'] == 'recovery' || fragment['type'] == 'recovery';

    if (code == null && refreshToken == null && accessToken == null) return;

    try {
      // Preferimos refresh_token porque viene en el fragmento del link de Supabase
      if (refreshToken != null) {
        await Supabase.instance.client.auth.setSession(refreshToken);
      } else if (code != null) {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
      }

      if (!mounted) return;
      setState(() {
        _currentScreen = 'resetPassword';
        _selectedReport = null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el enlace de recuperación. Solicita uno nuevo.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Si no está autenticado, mostrar pantallas de autenticación
        if (!authProvider.isAuthenticated) {
          return Scaffold(
            body: _isLoginMode
                ? LoginScreen(
                    onLoginSuccess: () {
                      setState(() => _currentScreen = 'home');
                    },
                    onSwitchToSignup: () {
                      setState(() => _isLoginMode = false);
                    },
                  )
                : SignupScreen(
                    onSignupSuccess: () {
                      setState(() => _isLoginMode = true);
                    },
                    onSwitchToLogin: () {
                      setState(() => _isLoginMode = true);
                    },
                  ),
          );
        }

        // Si está autenticado, mostrar el flujo principal
        if (_selectedReport != null) {
          return ReportDetailScreen(
            report: _selectedReport!,
            onReportUpdated: () {
              setState(() => _selectedReport = null);
            },
          );
        }

        if (_currentScreen == 'createReport') {
          return CreateReportScreen(
            onReportCreated: () {
              setState(() => _currentScreen = 'home');
            },
          );
        }

        if (_currentScreen == 'resetPassword') {
          return ResetPasswordScreen(
            onResetComplete: () {
              setState(() {
                _isLoginMode = true;
                _currentScreen = 'auth';
                _selectedReport = null;
              });
            },
          );
        }

        // Home screen (mapa)
        return HomeScreen(
          onCreateReport: () {
            setState(() => _currentScreen = 'createReport');
          },
          onViewReport: (report) {
            setState(() => _selectedReport = report);
          },
          onLogout: () {
            setState(() {
              _isLoginMode = true;
              _currentScreen = 'auth';
              _selectedReport = null;
            });
          },
        );
      },
    );
  }
}
