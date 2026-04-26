import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'registrasi_screen.dart'; // Import screen registrasi
import 'login_page.dart'; // Tambahkan import ini

const _illustrationUrl =
    'https://www.figma.com/api/mcp/asset/1de17eca-2590-4965-8da4-0f84b446139b';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height - mq.padding.top - mq.padding.bottom;
    
    final scale = (screenW / 390).clamp(0.8, 1.2);
    
    // Hitung proporsi agar semua muat tanpa scroll
    final illustrationFlex = (screenH - (430 * scale)).clamp(100.0, 280.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24 * scale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Spacer atas biar proporsional
              Expanded(child: SizedBox(height: 20 * scale)),
              
              // ── Label pill "KONEKIN" ──
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 6 * scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5E3FF).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'KONEKIN',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12 * scale,
                    letterSpacing: 0.3,
                    color: const Color(0xFF144780),
                  ),
                ),
              ),

              SizedBox(height: 24 * scale),

              // ── Heading ──
              Text(
                'Jembatan Kreativitas\n& Peluang Bisnis',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 32 * scale,
                  letterSpacing: -1.5,
                  color: const Color(0xFF1B1B1F),
                  height: 1.2,
                ),
              ),

              SizedBox(height: 24 * scale),

              // ── Ilustrasi ──
              SizedBox(
                height: illustrationFlex,
                child: Image.network(
                  _illustrationUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_outlined,
                    size: 100 * scale,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),

              SizedBox(height: 24 * scale),

              // ── Teks deskripsi ──
              Text(
                'Hubungkan UMKM dengan talenta kreatif terbaik untuk digitalisasi bisnis yang efektif dan berdampak luas.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 13 * scale,
                  color: const Color(0xFF424750),
                  height: 1.4,
                ),
              ),

              SizedBox(height: 32 * scale),

              // ── Tombol UMKM ──
              _buildButtonUmkm(context, scale),

              SizedBox(height: 16 * scale),

              // ── Tombol Creative Worker ──
              _buildButtonCreative(context, scale),

              SizedBox(height: 24 * scale),

              // ── Login Link ──
              // ── Login Link ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 13 * scale,
                      color: const Color(0xFF424750),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigasi ke halaman login
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Masuk',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13 * scale,
                        color: const Color(0xFF144780),
                      ),
                    ),
                  ),
                ],
              ),

              // Spacer bawah biar proporsional
              Expanded(child: SizedBox(height: 20 * scale)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonUmkm(BuildContext context, double scale) {
    return Container(
      width: double.infinity,
      height: 67 * scale,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.55, -0.83),
          end: Alignment(0.55, 0.83),
          colors: [Color(0xFF003466), Color(0xFF1A4B84)],
        ),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16 * scale),
          onTap: () {
            // Navigasi ke halaman registrasi dengan tipe UMKM
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegistrasiScreen(
                  userType: UserType.umkm,  // ← Kirim tipe UMKM
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24 * scale),
            child: Row(
              children: [
                Icon(Icons.storefront, color: Colors.white, size: 28 * scale),
                SizedBox(width: 20 * scale),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar sebagai',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 18 * scale,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'UMKM',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 18 * scale,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonCreative(BuildContext context, double scale) {
    return Container(
      width: double.infinity,
      height: 67 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F2F8),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16 * scale),
          onTap: () {
            // Navigasi ke halaman registrasi dengan tipe Creative Worker
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegistrasiScreen(
                  userType: UserType.creativeWorker,  // ← Kirim tipe Creative Worker
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24 * scale),
            child: Row(
              children: [
                Icon(Icons.brush, color: const Color(0xFF0E0E0E), size: 28 * scale),
                SizedBox(width: 20 * scale),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar sebagai',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 18 * scale,
                        color: const Color(0xFF0E0E0E),
                      ),
                    ),
                    Text(
                      'Creative Worker',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 18 * scale,
                        color: const Color(0xFF0E0E0E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}