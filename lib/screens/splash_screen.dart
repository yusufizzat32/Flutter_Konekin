import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();

    // Panggil pengecekan auth & navigasi setelah delay animasi
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Beri waktu animasi splash (tetap 3 detik)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Baca token dan userType langsung dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');   // key sesuai AuthService
    final userType = prefs.getString('user_type');

    // Token valid → arahkan ke dashboard sesuai peran
    if (token != null && token.isNotEmpty && token != 'Bearer ' &&
        userType != null) {
      if (!mounted) return;
      if (userType == 'umkm') {
        Navigator.pushReplacementNamed(context, '/umkm/dashboard');
      } else if (userType == 'creative_worker') {
        Navigator.pushReplacementNamed(context, '/creative/dashboard');
      } else {
        // fallback
        Navigator.pushReplacementNamed(context, '/get-started');
      }
    } else {
      // Belum login → ke Get Started
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/get-started');
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;

    // Proportional scale — Figma frame is 390 × 676
    final double scaleW = sw / 390.0;
    final double scaleH = sh / 676.0;
    // Always use the smaller axis so nothing overflows
    final double s = scaleW < scaleH ? scaleW : scaleH;

    // ── Logo cluster geometry (all Figma values × s) ──────────────
    final double cardSize = 128.0 * s; // central white card
    final double tealSize = 48.0 * s; // teal top-right badge
    final double darkSize = 56.0 * s; // dark-blue bottom-left badge

    // Padding so the overflow badges are fully visible inside the SizedBox
    final double padLeft = 14.0 * s;
    final double padRight = tealSize * 0.55;
    final double padTop = tealSize * 0.55;
    final double padBottom = darkSize * 0.60;

    final double clusterW = padLeft + cardSize + padRight;
    final double clusterH = padTop + cardSize + padBottom;

    return Scaffold(
      backgroundColor: const Color(0xFF1A4B84),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Glow: teal, top-right ────────────────────────────────
            Positioned(
              right: -171.0 * scaleW,
              top: -67.59 * scaleH,
              child: Container(
                width: 600.0 * scaleW,
                height: 600.0 * scaleW,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF68FADD).withOpacity(0.10),
                ),
              ),
            ),

            // ── Glow: dark blue, bottom-left ─────────────────────────
            Positioned(
              left: -39.0 * scaleW,
              bottom: -67.59 * scaleH,
              child: Container(
                width: 600.0 * scaleW,
                height: 600.0 * scaleW,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF003466).withOpacity(0.20),
                ),
              ),
            ),

            // ── Main content - Centered without overflow ────────────────
            Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Logo cluster ────────────────────────────────────
                    SizedBox(
                      width: clusterW,
                      height: clusterH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background halo
                          Positioned(
                            left: padLeft - 20.09 * s,
                            top: padTop - 20.09 * s,
                            child: Container(
                              width: 192.0 * s,
                              height: 192.0 * s,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF006B5C).withOpacity(0.05),
                              ),
                            ),
                          ),

                          // Central white card (rotate +12°) dengan huruf K
                          Positioned(
                            left: padLeft,
                            top: padTop,
                            child: Transform.rotate(
                              angle: 12 * 3.14159265 / 180,
                              child: Container(
                                width: cardSize,
                                height: cardSize,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32.0 * s),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 50.0 * s,
                                      offset: Offset(0, 25.0 * s),
                                      spreadRadius: -12.0 * s,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'K',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w900, // Black = w900
                                      fontSize: 64.0 * s,
                                      color: const Color(0xFF1A4B84),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Teal badge — top-right of card, rotate -12°
                          Positioned(
                            left: padLeft + cardSize - tealSize * 0.28,
                            top: padTop - tealSize * 0.45,
                            child: Transform.rotate(
                              angle: -12 * 3.14159265 / 180,
                              child: Container(
                                width: tealSize,
                                height: tealSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF68FADD),
                                  borderRadius: BorderRadius.circular(12.0 * s),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 15.0 * s,
                                      offset: Offset(0, 10.0 * s),
                                      spreadRadius: -3.0 * s,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 6.0 * s,
                                      offset: Offset(0, 4.0 * s),
                                      spreadRadius: -4.0 * s,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  // Replace with: Image.asset('assets/icons/grid_icon.png')
                                  child: Icon(
                                    Icons.grid_view_rounded,
                                    size: 18.0 * s,
                                    color: const Color(0xFF003466),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Dark-blue badge — bottom-left of card, rotate +6°
                          Positioned(
                            left: padLeft - 10.77 * s,
                            top: padTop + cardSize - darkSize * 0.45,
                            child: Transform.rotate(
                              angle: 6 * 3.14159265 / 180,
                              child: Container(
                                width: darkSize,
                                height: darkSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF003466),
                                  borderRadius: BorderRadius.circular(16.0 * s),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 25.0 * s,
                                      offset: Offset(0, 20.0 * s),
                                      spreadRadius: -5.0 * s,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 10.0 * s,
                                      offset: Offset(0, 8.0 * s),
                                      spreadRadius: -6.0 * s,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  // Replace with: Image.asset('assets/icons/edit_icon.png')
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 22.0 * s,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.0 * s),

                    // ── Typography Content ───────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0 * s),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // App name
                          Text(
                            'Konekin',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontWeight: FontWeight.w800,
                              fontSize: 48.0 * s,
                              height: 1.0,
                              letterSpacing: -2.4,
                              color: const Color(0xFF93BCFC),
                            ),
                          ),

                          SizedBox(height: 4.0 * s),

                          // Tagline
                          Opacity(
                            opacity: 0.80,
                            child: Text(
                              'Aplikasi penghubung creative worker\ndengan UMKM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontWeight: FontWeight.w500,
                                fontSize: 18.0 * s,
                                height: 28.0 / 18.0,
                                letterSpacing: 0.45,
                                color: const Color(0xFFA6C8FF),
                              ),
                            ),
                          ),

                          SizedBox(height: 32.0 * s),

                          // Progress bar
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, _) {
                              return Container(
                                width: 192.0 * s,
                                height: 4.0 * s,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF93BCFC).withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: _progressAnimation.value,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF68FADD),
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer attribution ──────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 24.0 * scaleH,
              child: Text(
                'SINCE 2025',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontSize: 10.0 * s,
                  height: 15.0 / 10.0,
                  letterSpacing: 3.0,
                  color: const Color(0xFF93BCFC).withOpacity(0.40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}