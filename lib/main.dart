// main.dart — Updated: semua route baru terdaftar + notification provider
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
import 'screens/my_projects_umkm.dart';
import 'screens/ai_recommendation_page.dart';
import 'screens/creative_my_projects_page.dart';
import 'screens/creative_earnings_page.dart';
import 'screens/escrow_payment_page.dart';
import 'screens/approve_completion_page.dart';
import 'providers/notification_provider.dart'; // ✅ Import notification provider
import 'screens/notifications_screen.dart'; // ✅ Import notification screen
import 'models/project_model.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()), // ✅ Add notification provider
        // Add other providers here if needed
      ],
      child: MaterialApp(
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
            // ── Public ──────────────────────────────────────────────────────
            case '/':
              return _page(const SplashScreen(), settings);
            case '/get-started':
              return _page(const GetStartedScreen(), settings);
            case '/login':
              return _page(const LoginPage(), settings);
            case '/register/umkm':
              return _page(
                  const RegistrasiScreen(userType: UserType.umkm), settings);
            case '/register/creative':
              return _page(
                  const RegistrasiScreen(userType: UserType.creativeWorker),
                  settings);

            // ── UMKM Protected ──────────────────────────────────────────────
            case '/umkm/dashboard':
              return _protected(settings, (_) => const UmkmDashboard(), ['umkm']);

            case '/umkm/my-projects':
              return _protected(
                  settings, (_) => const MyProjectsUmkmPage(), ['umkm']);

            case '/create-project':
              return _protected(
                  settings, (_) => const CreateProjectPage(), ['umkm']);

            case '/ai-recommendation':
              return _protected(
                  settings, (_) => const AiRecommendationPage(), ['umkm']);

            case '/escrow-payment':
              final project = settings.arguments as Project;
              return _protected(
                settings,
                (_) => EscrowPaymentPage(project: project),
                ['umkm'],
              );

            case '/approve-completion':
              final args = settings.arguments as Map<String, dynamic>;
              return _protected(
                settings,
                (_) => ApproveCompletionPage(
                  project: args['project'] as Project,
                  progressUpdates:
                      args['progressUpdates'] as List<Map<String, dynamic>>,
                ),
                ['umkm'],
              );

            // ── Creative Protected ───────────────────────────────────────────
            case '/creative/dashboard':
              return _protected(
                  settings, (_) => const CreativeDashboard(), ['creative_worker']);

            case '/explore-projects':
              return _protected(
                  settings, (_) => const ExploreProjectsPage(), ['creative_worker']);

            case '/project-detail':
              final projectId = settings.arguments?.toString() ?? '';
              return _protected(
                settings,
                (_) => ProjectDetailPage(projectId: projectId),
                ['creative_worker'],
              );

            case '/creative/my-projects':
              return _protected(
                settings,
                (_) => const CreativeMyProjectsPage(),
                ['creative_worker'],
              );

            case '/creative/earnings':
              return _protected(
                settings,
                (_) => const CreativeEarningsPage(),
                ['creative_worker'],
              );

            case '/portfolio':
              return _protected(
                  settings, (_) => const PortfolioPage(), ['creative_worker']);

            // ✅ NOTIFICATION ROUTE
            case '/notifications':
              return _protected(
                settings,
                (_) => const NotificationsScreen(),
                ['creative_worker', 'umkm'],
              );

            // ── Shared Protected ────────────────────────────────────────────
            case '/my-projects':
              final userType =
                  settings.arguments as String? ?? 'creative';
              return _protected(
                settings,
                (_) => MyProjectsPage(userType: userType),
                ['umkm', 'creative_worker'],
              );

            case '/edit-profile':
              return _protected(
                  settings,
                  (_) => const EditProfilePage(),
                  ['umkm', 'creative_worker']);

            default:
              return null;
          }
        },
      ),
    );
  }

  PageRoute _page(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
        settings: settings, builder: (context) => page);
  }

  PageRoute _protected(
    RouteSettings settings,
    Widget Function(BuildContext) builder,
    List<String> allowedRoles,
  ) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => FutureBuilder<bool>(
        future: _checkAuth(context, allowedRoles),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == true) return builder(context);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<bool> _checkAuth(
      BuildContext context, List<String> allowedRoles) async {
    final authService = AuthService();

    final token = await authService.getToken();
    if (token == null || token.isEmpty || token == 'Bearer ') {
      _toLogin(context);
      return false;
    }

    final isValid = await authService.validateToken();
    if (!isValid) {
      final refreshResult = await authService.refreshToken();
      if (refreshResult['success'] != true) {
        _toLogin(context);
        return false;
      }
    }

    final userType = await authService.getUserType();
    if (userType == null || !allowedRoles.contains(userType)) {
      _denyAccess(context);
      return false;
    }

    return true;
  }

  void _toLogin(BuildContext context) {
    if (context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/get-started',
          (route) => false
        );
      });
    }
  }

  void _denyAccess(BuildContext context) {
    if (context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Anda tidak memiliki akses ke halaman ini'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pushNamedAndRemoveUntil(
            context, '/get-started', (route) => false);
      });
    }
  }
}