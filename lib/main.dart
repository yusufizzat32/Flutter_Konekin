// main.dart - Fixed Version dengan SplashScreen dan AuthGuard yang benar
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/get_started_screen.dart';
import 'screens/login_page.dart';
import 'screens/registrasi_screen.dart';
import 'screens/umkm_dashboard.dart';
import 'screens/creative_dashboard.dart';
import 'screens/explore_projects.dart';
import 'screens/project_detail.dart';
import 'screens/my_projects.dart';
import 'screens/portfolio_page.dart';
import 'screens/edit_profile.dart';
import 'screens/create_project.dart';
import 'services/auth_service.dart';
import 'screens/explore_creatives.dart';
import 'screens/creative_detail_page.dart';
import 'screens/my_projects_umkm.dart';
import 'screens/profile_umkm.dart';
import 'screens/ai_recommendation_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A4B84),
          primary: const Color(0xFF1A4B84),
          secondary: const Color(0xFF68FADD),
          surface: const Color(0xFFFBF8FE),
          onPrimary: Colors.white,
          onSurface: const Color(0xFF1B1B1F),
        ),
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        scaffoldBackgroundColor: const Color(0xFFFBF8FE),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _buildPageRoute(const SplashScreen(), settings);
          case '/get-started':
            return _buildPageRoute(const GetStartedScreen(), settings);
          case '/login':
            return _buildPageRoute(const LoginPage(), settings);
          case '/register/umkm':
            return _buildPageRoute(const RegistrasiScreen(userType: UserType.umkm), settings);
          case '/register/creative':
            return _buildPageRoute(const RegistrasiScreen(userType: UserType.creativeWorker), settings);
          
          // Protected Routes
          case '/umkm/dashboard':
            return _buildProtectedRoute(
              settings,
              (context) => const UmkmDashboard(),
              ['umkm'],
            );
          case '/creative/dashboard':
            return _buildProtectedRoute(
              settings,
              (context) => const CreativeDashboard(),
              ['creative_worker'],
            );
          case '/explore-projects':
            return _buildProtectedRoute(
              settings,
              (context) => const ExploreProjectsPage(),
              ['creative_worker'],
            );
          case '/project-detail':
            final projectId = settings.arguments?.toString() ?? '';
            return _buildProtectedRoute(
              settings,
              (context) => ProjectDetailPage(projectId: projectId),
              ['creative_worker'],
            );
          case '/my-projects':
            final userType = settings.arguments as String? ?? 'creative';
            return _buildProtectedRoute(
              settings,
              (context) => MyProjectsPage(userType: userType),
              ['umkm', 'creative_worker'],
            );
          case '/umkm/my-projects':
            return _buildProtectedRoute(
              settings,
              (context) => const MyProjectsUmkmPage(),
              ['umkm'],
            );
          case '/portfolio':
            return _buildProtectedRoute(
              settings,
              (context) => const PortfolioPage(),
              ['creative_worker'],
            );
          case '/edit-profile':
            return _buildProtectedRoute(
              settings,
              (context) => const EditProfilePage(),
              ['umkm', 'creative_worker'],
            );
          case '/create-project':
            return _buildProtectedRoute(
              settings,
              (context) => const CreateProjectPage(),
              ['umkm'],
            );
          case '/ai-recommendation':
            return _buildProtectedRoute(
              settings,
              (context) => const AiRecommendationPage(),
              ['umkm'],
            );
          default:
            return null;
        }
      },
    );
  }

  PageRoute _buildPageRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => page,
    );
  }

  PageRoute _buildProtectedRoute(
    RouteSettings settings,
    Widget Function(BuildContext) builder,
    List<String> allowedRoles,
  ) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => FutureBuilder<bool>(
        future: _checkAuthAndRole(context, allowedRoles),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == true) {
            return builder(context);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<bool> _checkAuthAndRole(BuildContext context, List<String> allowedRoles) async {
    final authService = AuthService();
    
    // 1. Cek token ada
    final token = await authService.getToken();
    if (token == null || token.isEmpty || token == 'Bearer ') {
      _redirectToLogin(context);
      return false;
    }
    
    // 2. Validasi token ke server (cek expired)
    final isValid = await authService.validateToken();
    if (!isValid) {
      // Coba refresh token
      final refreshResult = await authService.refreshToken();
      if (refreshResult['success'] != true) {
        _redirectToLogin(context);
        return false;
      }
    }
    
    // 3. Cek role
    final userType = await authService.getUserType();
    if (userType == null || !allowedRoles.contains(userType)) {
      _showAccessDenied(context);
      return false;
    }
    
    return true;
  }
  
  void _redirectToLogin(BuildContext context) {
    if (context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    }
  }
  
  void _showAccessDenied(BuildContext context) {
    if (context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda tidak memiliki akses ke halaman ini'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/get-started', (route) => false);
      });
    }
  }
}