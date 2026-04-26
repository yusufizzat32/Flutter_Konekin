import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/get_started_screen.dart';
import 'screens/login_page.dart';
import 'screens/registrasi_screen.dart';
import 'screens/umkm_dashboard.dart';
import 'screens/creative_dashboard.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation to match Figma designs
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar to transparent so splash bg shows through
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KonekinApp());
}

class KonekinApp extends StatelessWidget {
  const KonekinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Konekin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Color scheme derived from Figma design tokens
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A4B84),
          primary: const Color(0xFF1A4B84),
          secondary: const Color(0xFF68FADD),
          surface: const Color(0xFFFBF8FE),
          onPrimary: Colors.white,
          onSurface: const Color(0xFF1B1B1F),
        ),
        // Font families used in Figma design
        fontFamily: 'PlusJakartaSans',
        scaffoldBackgroundColor: const Color(0xFFFBF8FE),
        // Remove default splash/highlight effects for a cleaner look
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      // Named routes
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/get-started': (context) => const GetStartedScreen(),
        '/login': (context) => const LoginPage(),
        '/register/umkm': (context) => const RegistrasiScreen(userType: UserType.umkm),
        '/register/creative': (context) => const RegistrasiScreen(userType: UserType.creativeWorker),
      },
      // Handle dynamic routes and protected routes
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/get-started':
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (_, __, ___) => const GetStartedScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            );
          
          case '/umkm/dashboard':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: _checkAuthAndRole(context, ['umkm']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.data == true) {
                    return const UmkmDashboard();
                  }
                  return const SizedBox.shrink();
                },
              ),
            );
          
          case '/creative/dashboard':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: _checkAuthAndRole(context, ['creative_worker']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.data == true) {
                    return const CreativeDashboard();
                  }
                  return const SizedBox.shrink();
                },
              ),
            );
          
          default:
            return null;
        }
      },
    );
  }


  Future<bool> _checkAuthAndRole(BuildContext context, List<String> allowedRoles) async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    
    if (!isLoggedIn) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
      return false;
    }
    
    final userType = await authService.getUserType();
    
    if (userType == null || !allowedRoles.contains(userType)) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/get-started', (route) => false);
      });
      return false;
    }
    
    return true;
  }
}