// lib/screens/ai_recommendation_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'creative_detail_page.dart';

class AiRecommendationPage extends StatefulWidget {
  const AiRecommendationPage({super.key});

  @override
  State<AiRecommendationPage> createState() => _AiRecommendationPageState();
}

class _AiRecommendationPageState extends State<AiRecommendationPage>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _omsetCtrl = TextEditingController();
  final _labaCtrl = TextEditingController();
  final _asetCtrl = TextEditingController();
  final _tahunBerdiriCtrl = TextEditingController();
  final _tenagaKerjaPerempuanCtrl = TextEditingController();
  final _tenagaKerjaLakiCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();

  // Dropdown values — sesuai opsi dari screenshot
  String _selectedJenisUsaha = 'Jasa';
  String _selectedMarketplace = 'Shopee';
  String _selectedLegalitas = 'Terdaftar';
  String _selectedLevelPengalaman = 'Semua tingkat';
  String _selectedJumlahHasil = 'Top 5';

  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>>? _results;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Opsi dropdown sesuai screenshot ──────────────────────────────────────

  final List<String> _jenisUsahaOptions = [
    'Jasa',
    'Perdagangan',
    'Kesehatan',
    'Pendidikan',
    'Makanan & Minuman',
    'Fashion',
    'Perusahaan',
    'Lainnya / Unknown',
  ];

  final List<String> _marketplaceOptions = [
    'Tokopedia',
    'Shopee',
    'Bukalapak',
    'Lazada',
    'Website Sendiri',
    'Tidak Ada',
    'Lainnya / Unknown',
  ];

  final List<String> _legalitasOptions = [
    'Terdaftar',
    'Belum Terdaftar',
    'Lainnya / Unknown',
  ];

  final List<String> _levelPengalamanOptions = [
    'Semua tingkat',
    'Beginner',
    'Intermediate',
    'Expert',
  ];

  final List<String> _jumlahHasilOptions = [
    'Top 3',
    'Top 5',
    'Top 10',
    'Top 15',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _omsetCtrl.dispose();
    _labaCtrl.dispose();
    _asetCtrl.dispose();
    _tahunBerdiriCtrl.dispose();
    _tenagaKerjaPerempuanCtrl.dispose();
    _tenagaKerjaLakiCtrl.dispose();
    _budgetMaxCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  int _parseNumber(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  int _parseJumlahHasil(String val) {
    final num = int.tryParse(val.replaceAll(RegExp(r'[^\d]'), ''));
    return num ?? 5;
  }

  Future<void> _runRecommendation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = {
      'omset': _parseNumber(_omsetCtrl.text),
      'laba': _parseNumber(_labaCtrl.text),
      'aset': _parseNumber(_asetCtrl.text),
      'tahun_berdiri':
          int.tryParse(_tahunBerdiriCtrl.text) ?? DateTime.now().year,
      'jenis_usaha': _selectedJenisUsaha,
      'marketplace': _selectedMarketplace,
      'status_legalitas': _selectedLegalitas,
      'tenaga_kerja_perempuan':
          int.tryParse(_tenagaKerjaPerempuanCtrl.text) ?? 0,
      'tenaga_kerja_laki':
          int.tryParse(_tenagaKerjaLakiCtrl.text) ?? 0,
      'level_pengalaman': _selectedLevelPengalaman,
      'jumlah_hasil': _parseJumlahHasil(_selectedJumlahHasil),
      'budget_maksimal': _parseNumber(_budgetMaxCtrl.text),
    };

    final result = await _api.getAiRecommendations(payload);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'];
          List<Map<String, dynamic>> parsed = [];
          if (data is List) {
            parsed =
                data.map((e) => Map<String, dynamic>.from(e)).toList();
          } else if (data is Map) {
            final recs = data['recommendations'] ??
                data['creatives'] ??
                data['data'] ??
                [];
            if (recs is List) {
              parsed =
                  recs.map((e) => Map<String, dynamic>.from(e)).toList();
            }
          }
          if (parsed.isEmpty) {
            _errorMessage =
                'Tidak ada rekomendasi ditemukan. Coba ubah parameter.';
          } else {
            // Debug: print field names dari item pertama
            if (parsed.isNotEmpty) {
              // ignore: avoid_print
              print('[DEBUG] Flask fields: \${parsed.first.keys.toList()}');
              // ignore: avoid_print
              print('[DEBUG] First item: \${parsed.first}');
            }
            _results = parsed;
            _fadeController.reset();
            _fadeController.forward();
          }
        } else {
          _errorMessage = result['message'] ??
              'Gagal mendapatkan rekomendasi. Pastikan server berjalan.';
        }
      });
    }
  }

  void _resetForm() {
    setState(() {
      _results = null;
      _errorMessage = null;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // AppBar tanpa teks judul — judul sudah ada di header banner
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderBanner(),
              const SizedBox(height: 20),
              if (_results == null) ...[
                _buildFormCard(),
                const SizedBox(height: 12),
                if (_errorMessage != null) _buildErrorBanner(),
                const SizedBox(height: 20),
                _buildRunButton(),
                const SizedBox(height: 32),
              ] else ...[
                _buildResultsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER BANNER
  // ============================================================

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A6B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'AI ANALYTICS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF68FADD),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rekomendasi AI',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Temukan Kreatormu ✶',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF68FADD),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Input data UMKM Anda untuk mendapatkan rekomendasi kreator yang paling sesuai berdasarkan industri, skala bisnis, dan anggaran yang tersedia.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.75),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM CARD
  // ============================================================

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Omset & Laba
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _omsetCtrl,
                    label: 'Omset',
                    hint: '5.000.000',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _labaCtrl,
                    label: 'Laba',
                    hint: '8.000.000',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Aset & Tahun Berdiri
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _asetCtrl,
                    label: 'Aset',
                    hint: '2.000.000',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _tahunBerdiriCtrl,
                    label: 'Tahun Berdiri',
                    hint: '2024',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Jenis Usaha
            _buildDropdown(
              label: 'Jenis Usaha',
              value: _selectedJenisUsaha,
              items: _jenisUsahaOptions,
              onChanged: (v) =>
                  setState(() => _selectedJenisUsaha = v!),
            ),
            const SizedBox(height: 14),

            // Marketplace & Legalitas — dropdown (bukan TextField)
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Marketplace',
                    value: _selectedMarketplace,
                    items: _marketplaceOptions,
                    onChanged: (v) =>
                        setState(() => _selectedMarketplace = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Legalitas',
                    value: _selectedLegalitas,
                    items: _legalitasOptions,
                    onChanged: (v) =>
                        setState(() => _selectedLegalitas = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tenaga Kerja P & L
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _tenagaKerjaPerempuanCtrl,
                    label: 'Tenaga Kerja (P)',
                    hint: '5',
                    keyboardType: TextInputType.number,
                    required: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _tenagaKerjaLakiCtrl,
                    label: 'Tenaga Kerja (L)',
                    hint: '5',
                    keyboardType: TextInputType.number,
                    required: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Filter Level Pengalaman & Jumlah Hasil
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Filter Level Pengalaman',
                    value: _selectedLevelPengalaman,
                    items: _levelPengalamanOptions,
                    onChanged: (v) =>
                        setState(() => _selectedLevelPengalaman = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Jumlah Hasil',
                    value: _selectedJumlahHasil,
                    items: _jumlahHasilOptions,
                    onChanged: (v) =>
                        setState(() => _selectedJumlahHasil = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Anggaran Maksimal
            _buildField(
              controller: _budgetMaxCtrl,
              label: 'Anggaran Maksimal (Rp)',
              hint: '400.000',
              required: false,
              helperText:
                  'Opsional, kalau ingin menyaring berdasarkan anggaran.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.red.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _runRecommendation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A3A6B),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF1A3A6B).withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Jalankan Rekomendasi',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // RESULTS SECTION
  // ============================================================

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hasil Rekomendasi',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF1B1B1F),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A6B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_results!.length} Kreator',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A3A6B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _resetForm,
          icon:
              const Icon(Icons.arrow_back_ios_new, size: 12),
          label: Text(
            'Ubah Parameter',
            style: GoogleFonts.inter(fontSize: 12),
          ),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1A3A6B),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 12),
        ..._results!.asMap().entries.map(
              (e) => _buildCreativeCard(e.value, e.key),
            ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCreativeCard(
      Map<String, dynamic> creative, int index) {
    final name = (creative['full_name'] ??
        creative['name'] ??
        '').toString();
    final role = (creative['specific_role'] ??
        creative['job_category'] ??
        creative['role'] ??
        '').toString();
    final matchScore = double.tryParse(
        (creative['similarity_score'] ??
         creative['match_score'] ??
         0).toString()) ?? 0.0;
    final rating = double.tryParse(
        (creative['client_rating'] ??
         creative['average_rating'] ??
         creative['rating'] ??
         0).toString()) ?? 0.0;
    final projects = int.tryParse(
        (creative['jobs_completed'] ??
         creative['completed_projects'] ??
         creative['projects_count'] ??
         0).toString()) ?? 0;
    final successRate = double.tryParse(
        (creative['success_rate_job'] ??
         creative['rehire_rate'] ??
         creative['success_rate'] ??
         0).toString()) ?? 0.0;
    final budget = int.tryParse(
        (creative['min_budget_idr'] ??
         creative['budget'] ??
         creative['harga_mulai'] ??
         0).toString()) ?? 0;
    // Flask bisa kirim skills sebagai String "A, B, C" atau List — handle keduanya
    final List<String> skills = () {
      final raw = creative['skills'];
      if (raw == null) return <String>[];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return <String>[];
    }();
    final photo = (creative['profile_photo'] ??
        creative['foto'] ??
        creative['avatar'] ??
        creative['photo'] ??
        creative['image'] ??
        '').toString();
    final bio = (creative['bio'] ??
        creative['description'] ??
        creative['about'] ??
        '').toString();
    final experienceLevel = (creative['experience_level'] ?? '').toString();
    final experienceYears = (creative['experience_years'] ?? '').toString();

    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    const gradients = [
      [Color(0xFF1A3A6B), Color(0xFF2563EB)],
      [Color(0xFF065F46), Color(0xFF059669)],
      [Color(0xFF7C2D12), Color(0xFFEA580C)],
      [Color(0xFF4C1D95), Color(0xFF7C3AED)],
      [Color(0xFF1E3A5F), Color(0xFF0EA5E9)],
    ];
    final grad = gradients[index % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: grad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  image: photo.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photo),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: photo.isEmpty
                    ? Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF1B1B1F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (matchScore > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: Text(
                              'MATCH ${matchScore.toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            role,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        if (experienceLevel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Text(
                              experienceLevel,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (skills.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: skills.take(4).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    skill.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                );
              }).toList(),
            ),

          if (skills.isNotEmpty) const SizedBox(height: 12),

          Row(
            children: [
              _buildStat('RATING', rating > 0 ? rating.toStringAsFixed(1) : '-'),
              _buildStatDivider(),
              _buildStat('PROYEK', '$projects'),
              _buildStatDivider(),
              _buildStat('SUKSES', successRate > 0 ? '${successRate.toStringAsFixed(0)}%' : '-'),
              _buildStatDivider(),
              _buildStat('MULAI', budget > 0 ? _formatCurrency(budget) : '-'),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            bio,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              height: 1.45,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreativeDetailPage(
                      creativeId:
                          creative['id']?.toString() ?? '',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A6B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Hire Now',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFE5E7EB),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ============================================================
  // FORM WIDGETS
  // ============================================================

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.number,
    bool required = true,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF1B1B1F)),
          validator: required
              ? (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Wajib diisi';
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
            helperText: helperText,
            helperStyle: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF9CA3AF),
              fontStyle: FontStyle.italic,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF1A3A6B), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Colors.red, width: 1.5),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF6B7280),
                size: 20,
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1B1B1F),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
              onChanged: onChanged,
              items: items
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final num =
        value is int ? value : int.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    }
    if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(0)}k';
    }
    return num.toString();
  }
}