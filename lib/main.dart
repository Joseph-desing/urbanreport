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
