// lib/screens/login_page.dart
// =============================================================================
// login_page.dart — Terintegrasi dengan AuthService (Reusable Auth Logic)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'umkm_dashboard.dart';
import 'creative_dashboard.dart';

// ── Design tokens (identik dengan registrasi_screen.dart) ─────────────────────

const _cDark         = Color(0xFF1B1B1F);
const _cMid          = Color(0xFF424750);
const _cBlueDeep     = Color(0xFF003466);
const _cBlueMain     = Color(0xFF1A4B84);
const _cInputBg      = Color(0xFFEAE7ED);
const _cWhiteBg      = Color(0xFFFBF8FE);
const _cTopBarBorder = Color(0x26C3C6D1);
const _cError        = Color(0xFFB00020);

const _gradientBtn = LinearGradient(
  begin: Alignment(-0.55, -0.83),
  end:   Alignment(0.55, 0.83),
  colors: [_cBlueDeep, _cBlueMain],
);

// =============================================================================
// SCREEN
// =============================================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _obscurePass  = true;
  bool  _isLoading    = false;
  
  // Instance AuthService
  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Validators ──────────────────────────────────────────────────────────────

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(v.trim())) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Kata sandi tidak boleh kosong';
    if (v.length < 8) return 'Kata sandi minimal 8 karakter';
    return null;
  }

  // ── Snackbar ─────────────────────────────────────────────────────────────────

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Submit Login (Menggunakan AuthService) ───────────────────────────────────

  Future<void> _onLogin() async {
    // Tutup keyboard
    FocusScope.of(context).unfocus();
    
    // Validasi form
    if (!_formKey.currentState!.validate()) return;

    // Tampilkan loading
    setState(() => _isLoading = true);

    // Gunakan AuthService untuk login
    final result = await _auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      _showSnackbar(result['message'], isError: false);
      
      final userType = result['userType'];
      
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          if (userType == 'umkm') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UmkmDashboard()),
            );
          } else if (userType == 'creative_worker') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CreativeDashboard()),
            );
          } else if (userType == 'admin') {
            // TODO: Navigasi ke halaman admin dashboard
            _showSnackbar('Redirect ke halaman admin (belum dibuat)', isError: false);
            Navigator.pop(context);
          } else {
            // Default: kembali ke halaman sebelumnya
            Navigator.pop(context);
          }
        }
      });
    } else {
      _showSnackbar(result['message'], isError: true);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final w  = constraints.maxWidth;
          final h  = constraints.maxHeight;
          final sw = w / 390;
          final sh = h / 730;
          final s  = sw < sh ? sw : sh;

          return Stack(
            children: [
              // ── Konten utama di bawah AppBar ─────────────────────────────
              Positioned(
                top: 56 * sh,
                left: 0, right: 0, bottom: 0,
                child: _buildBody(sw, sh, s),
              ),

              // ── AppBar ────────────────────────────────────────────────────
              _buildAppBar(sw, sh, s),

              // ── Loading overlay ───────────────────────────────────────────
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ── AppBar (identik dengan registrasi_screen) ─────────────────────────────────

  Widget _buildAppBar(double sw, double sh, double s) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        height: 56 * sh,
        padding: EdgeInsets.symmetric(horizontal: 24 * sw),
        decoration: BoxDecoration(
          color: _cWhiteBg.withOpacity(0.8),
          border: const Border(bottom: BorderSide(color: _cTopBarBorder)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D1B1B1F),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ PERUBAHAN: Tombol back mengarah ke /get-started
            GestureDetector(
              onTap: () {
                // Navigasi ke Get Started dan hapus semua route sebelumnya
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/get-started',
                  (route) => false,
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, size: 16 * s, color: _cBlueMain),
                  SizedBox(width: 16 * s),
                  Text(
                    'Back',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 18 * s,
                      letterSpacing: -0.45,
                      color: _cBlueMain,
                      height: 28 / 18,
                    ),
                  ),
                ],
              ),
            ),

            // Kanan: "Konekin" dengan gradient
            ShaderMask(
              shaderCallback: (b) => _gradientBtn.createShader(b),
              blendMode: BlendMode.srcIn,
              child: Text(
                'Konekin',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 20 * s,
                  color: Colors.white,
                  height: 28 / 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────────

  Widget _buildBody(double sw, double sh, double s) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(top: 20 * sh),
                child: _Card(sw: sw, sh: sh, s: s, children: [
                  // ── Heading ───────────────────────────────────────────────
                  Text(
                    'Selamat datang\nkembali!',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 26 * s,
                      letterSpacing: -0.5,
                      color: _cDark,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 8 * sh),

                  // ── Sub-heading ───────────────────────────────────────────
                  Text(
                    'Masuk ke ruang kerja kreatif Anda\nyang telah dirancang khusus.',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 14 * s,
                      color: _cMid,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24 * sh),

                  // ── Field Alamat Email ────────────────────────────────────
                  _Field(
                    label: 'Alamat Email',
                    placeholder: 'name@company.com',
                    leadingIcon: Icons.mail_outline,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    s: s, sh: sh,
                  ),
                  SizedBox(height: 15 * sh),

                  // ── Field Kata Sandi + Lupa ───────────────────────────────
                  _PasswordFieldWithForgot(
                    controller: _passwordCtrl,
                    obscure: _obscurePass,
                    onToggleObscure: () =>
                        setState(() => _obscurePass = !_obscurePass),
                    validator: _validatePassword,
                    s: s, sh: sh,
                    onForgotTap: () {
                      // TODO: navigasi ke halaman lupa kata sandi
                      _showSnackbar('Fitur lupa password sedang dalam pengembangan', isError: false);
                    },
                  ),
                  SizedBox(height: 11 * sh),
                ]),
              ),
            ),
          ),

          // ── Tombol Login ────────────────────────────────────
          _BottomBtn(label: 'Login', onTap: _onLogin, s: s, sw: sw, sh: sh),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED WIDGETS — diambil dari registrasi_screen.dart
// =============================================================================

// ── Card container ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  final double sw, sh, s;

  const _Card({
    required this.children,
    required this.sw,
    required this.sh,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24 * sw),
      padding: EdgeInsets.fromLTRB(32 * s, 11 * s, 32 * s, 11 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * s),
        boxShadow: const [
          BoxShadow(color: Color(0x0F1B1B1F), blurRadius: 40),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// ── Field standar (identik dengan _Field di registrasi_screen) ─────────────────

class _Field extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData leadingIcon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final FormFieldValidator<String>? validator;
  final double s, sh;

  const _Field({
    required this.label,
    required this.placeholder,
    required this.leadingIcon,
    required this.controller,
    required this.s,
    required this.sh,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.obscure = true,
    this.onToggleObscure,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14 * s,
            color: _cDark,
            height: 20 / 14,
          ),
        ),
        SizedBox(height: 8 * sh),
        TextFormField(
          controller: controller,
          obscureText: isPassword && obscure,
          keyboardType: keyboardType,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            fontSize: 16 * s,
            color: _cMid,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w400,
              fontSize: 16 * s,
              color: _cMid.withOpacity(0.6),
            ),
            filled: true,
            fillColor: _cInputBg,
            contentPadding: EdgeInsets.only(
              left:   48 * s,
              right:  isPassword ? 44 * s : 16 * s,
              top:    16 * s,
              bottom: 16 * s,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * s),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * s),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * s),
              borderSide: const BorderSide(color: _cBlueMain, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * s),
              borderSide: const BorderSide(color: _cError, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * s),
              borderSide: const BorderSide(color: _cError, width: 1.5),
            ),
            errorStyle: GoogleFonts.inter(
              fontSize: 12 * s,
              color: _cError,
              height: 1.4,
            ),
            errorMaxLines: 2,
            isDense: true,
            prefixIcon: Icon(leadingIcon, size: 18 * s, color: _cMid),
            prefixIconConstraints: BoxConstraints(minWidth: 44 * s, minHeight: 0),
            suffixIcon: isPassword
                ? GestureDetector(
                    onTap: onToggleObscure,
                    child: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20 * s,
                      color: _cMid,
                    ),
                  )
                : null,
            suffixIconConstraints: BoxConstraints(minWidth: 44 * s, minHeight: 0),
          ),
        ),
      ],
    );
  }
}

// ── Field Kata Sandi dengan baris label + "Lupa Kata Sandi?" ───────────────────

class _PasswordFieldWithForgot extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final FormFieldValidator<String>? validator;
  final VoidCallback onForgotTap;
  final double s, sh;

  const _PasswordFieldWithForgot({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.onForgotTap,
    required this.s,
    required this.sh,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kata Sandi',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14 * s,
                color: _cDark,
                height: 20 / 14,
              ),
            ),
            GestureDetector(
              onTap: onForgotTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                'Lupa Kata Sandi?',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13 * s,
                  color: _cBlueMain,
                  height: 20 / 13,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * sh),

        // Input
        TextFormField(
          controller: controller,
          obscureText: obscure,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            fontSize: 16 * s,
            color: _cMid,
          ),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w400,
              fontSize: 16 * s,
              color: _cMid.withOpacity(0.6),
            ),
            filled: true,
            fillColor: _cInputBg,
            contentPadding: EdgeInsets.only(
              left:   48 * s,
              right:  44 * s,
              top:    16 * s,
              bottom: 16 * s,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * s),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * s),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * s),
              borderSide: const BorderSide(color: _cBlueMain, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * s),
              borderSide: const BorderSide(color: _cError, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * s),
              borderSide: const BorderSide(color: _cError, width: 1.5),
            ),
            errorStyle: GoogleFonts.inter(
              fontSize: 12 * s,
              color: _cError,
              height: 1.4,
            ),
            errorMaxLines: 2,
            isDense: true,
            prefixIcon: Icon(Icons.lock_outline, size: 18 * s, color: _cMid),
            prefixIconConstraints: BoxConstraints(minWidth: 44 * s, minHeight: 0),
            suffixIcon: GestureDetector(
              onTap: onToggleObscure,
              child: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20 * s,
                color: _cMid,
              ),
            ),
            suffixIconConstraints: BoxConstraints(minWidth: 44 * s, minHeight: 0),
          ),
        ),
      ],
    );
  }
}

// ── Tombol bawah (identik dengan _BottomBtn di registrasi_screen) ──────────────

class _BottomBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double s, sw, sh;

  const _BottomBtn({
    required this.label,
    required this.onTap,
    required this.s,
    required this.sw,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _cTopBarBorder)),
      ),
      padding: EdgeInsets.only(top: 20 * sh, bottom: 20 * sh),
      child: Center(
        child: Container(
          width: 278 * sw,
          height: 52 * s,
          decoration: BoxDecoration(
            gradient: _gradientBtn,
            borderRadius: BorderRadius.circular(8 * s),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8 * s),
              onTap: onTap,
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 16 * s,
                    color: Colors.white,
                    height: 24 / 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}