// =============================================================================
// registrasi_screen.dart — Menggunakan AuthService (Reusable Auth Logic)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'umkm_dashboard.dart';
import 'creative_dashboard.dart';

// ── Tipe user ─────────────────────────────────────────────────────────────────

enum UserType { umkm, creativeWorker }

extension UserTypeX on UserType {
  String get apiValue => switch (this) {
        UserType.umkm           => 'umkm',
        UserType.creativeWorker => 'creative_worker',
      };

  String get appBarTitle => switch (this) {
        UserType.umkm           => 'Daftar UMKM',
        UserType.creativeWorker => 'Daftar Creative Worker',
      };
}

// ── Design tokens ─────────────────────────────────────────────────────────────

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
  end: Alignment(0.55, 0.83),
  colors: [_cBlueDeep, _cBlueMain],
);

// =============================================================================
// SCREEN
// =============================================================================

class RegistrasiScreen extends StatefulWidget {
  final UserType userType;

  const RegistrasiScreen({super.key, required this.userType});

  @override
  State<RegistrasiScreen> createState() => _RegistrasiScreenState();
}

class _RegistrasiScreenState extends State<RegistrasiScreen> {
  final _formKey    = GlobalKey<FormState>();

  final _namaCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _teleponCtrl  = TextEditingController();
  final _lokasiCtrl   = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _konfPassCtrl = TextEditingController();

  bool _obscurePass     = true;
  bool _obscureKonfPass = true;
  bool _isLoading       = false;

  // Instance AuthService
  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _teleponCtrl.dispose();
    _lokasiCtrl.dispose();
    _passCtrl.dispose();
    _konfPassCtrl.dispose();
    super.dispose();
  }

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _validateNama(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nama lengkap tidak boleh kosong';
    if (v.trim().length < 3) return 'Nama minimal 3 karakter';
    if (!RegExp(r"^[a-zA-Z\s'.,-]+$").hasMatch(v.trim())) {
      return 'Nama hanya boleh mengandung huruf dan spasi';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(v.trim())) return 'Format email tidak valid';
    return null;
  }

  String? _validateTelepon(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nomor telepon tidak boleh kosong';
    final digits = v.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(digits)) {
      return 'Nomor telepon hanya boleh berisi angka';
    }
    if (digits.length < 9 || digits.length > 15) {
      return 'Nomor telepon harus 9–15 digit';
    }
    return null;
  }

  String? _validateLokasi(String? v) {
    if (v == null || v.trim().isEmpty) return 'Kota/Kabupaten tidak boleh kosong';
    if (v.trim().length < 3) return 'Nama kota minimal 3 karakter';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Kata sandi tidak boleh kosong';
    if (v.length < 8) return 'Kata sandi minimal 8 karakter';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Harus mengandung minimal 1 huruf kapital';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Harus mengandung minimal 1 angka';
    return null;
  }

  String? _validateKonfirmasi(String? v) {
    if (v == null || v.isEmpty) return 'Konfirmasi kata sandi tidak boleh kosong';
    if (v != _passCtrl.text) return 'Kata sandi tidak cocok';
    return null;
  }

  // ── Show Snackbar ─────────────────────────────────────────────────────────

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

  // ── Submit Registrasi (Menggunakan AuthService) ────────────────────────────

  Future<void> _onDaftar() async {
    // Tutup keyboard sebelum validasi
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Gunakan AuthService untuk registrasi
    final result = await _auth.register(
      type: widget.userType.apiValue,
      name: _namaCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      passwordConfirmation: _konfPassCtrl.text,
      phone: _teleponCtrl.text.trim(),
      city: _lokasiCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

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
          } else {
            // Default: kembali ke halaman login
            Navigator.pop(context);
          }
        }
      });
    } else {
      _showSnackbar(result['message'], isError: true);
    }
  }

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
              Positioned(
                top: 56 * sh,
                left: 0, right: 0, bottom: 0,
                child: _buildBody(sw, sh, s),
              ),
              _buildAppBar(sw, sh, s),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

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
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, size: 16 * s, color: _cBlueMain),
                  SizedBox(width: 16 * s),
                  Text(
                    widget.userType.appBarTitle,
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
                  _Field(
                    label: 'Nama Lengkap',
                    placeholder: 'Masukkan nama lengkap Anda',
                    leadingIcon: Icons.person_outline,
                    controller: _namaCtrl,
                    keyboardType: TextInputType.name,
                    validator: _validateNama,
                    s: s, sh: sh,
                  ),
                  SizedBox(height: 15 * sh),
                  _Field(
                    label: 'Alamat Email',
                    placeholder: 'nama@perusahaan.com',
                    leadingIcon: Icons.mail_outline,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    s: s, sh: sh,
                  ),
                  SizedBox(height: 15 * sh),
                  _Field(
                    label: 'Nomor Telepon',
                    placeholder: '+62',
                    leadingIcon: Icons.phone_outlined,
                    controller: _teleponCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]'))],
                    validator: _validateTelepon,
                    s: s, sh: sh,
                  ),
                  SizedBox(height: 15 * sh),
                  _Field(
                    label: 'Kota/Kabupaten',
                    placeholder: 'Masukkan kota/kabupaten Anda',
                    leadingIcon: Icons.location_on_outlined,
                    controller: _lokasiCtrl,
                    keyboardType: TextInputType.streetAddress,
                    validator: _validateLokasi,
                    s: s, sh: sh,
                  ),
                  SizedBox(height: 15 * sh),
                  _Field(
                    label: 'Kata Sandi',
                    placeholder: '••••••••',
                    leadingIcon: Icons.lock_outline,
                    controller: _passCtrl,
                    isPassword: true,
                    obscure: _obscurePass,
                    onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
                    validator: _validatePassword,
                    s: s, sh: sh,
                  ),
                  SizedBox(height: 15 * sh),
                  _Field(
                    label: 'Konfirmasi Kata Sandi',
                    placeholder: '••••••••',
                    leadingIcon: Icons.lock_outline,
                    controller: _konfPassCtrl,
                    isPassword: true,
                    obscure: _obscureKonfPass,
                    onToggleObscure: () => setState(() => _obscureKonfPass = !_obscureKonfPass),
                    validator: _validateKonfirmasi,
                    s: s, sh: sh,
                  ),
                  SizedBox(height: 11 * sh),
                ]),
              ),
            ),
          ),
          _BottomBtn(label: 'Daftar', onTap: _onDaftar, s: s, sw: sw, sh: sh),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

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
  final List<TextInputFormatter>? inputFormatters;
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
    this.inputFormatters,
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
          inputFormatters: inputFormatters,
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