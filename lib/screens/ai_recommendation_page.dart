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

class _AiRecommendationPageState extends State<AiRecommendationPage> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _omsetCtrl = TextEditingController();
  final _labaCtrl = TextEditingController();
  final _asetCtrl = TextEditingController();
  final _tahunBerdiriCtrl = TextEditingController();
  final _tenagaKerjaPerempuanCtrl = TextEditingController();
  final _tenagaKerjaLakiCtrl = TextEditingController();
  final _budgetMinCtrl = TextEditingController();

  // Dropdown values
  String _selectedJenisUsaha = 'Jasa';
  String _selectedMarketplace = 'Shopee';
  String _selectedLegalitas = 'Terdaftar';
  String _selectedLevelPengalaman = 'Semua tingkat';
  String _selectedJumlahHasil = 'Top 5';

  // State
  bool _isLoading = false;
  bool _flaskConnected = false;
  bool _modelLoaded = false;
  List<Map<String, dynamic>>? _results;

  final List<String> _jenisUsahaOptions = [
    'Jasa', 'Dagang', 'Manufaktur', 'Pertanian', 'Peternakan', 'Perikanan', 'Lainnya'
  ];
  final List<String> _marketplaceOptions = [
    'Shopee', 'Tokopedia', 'Lazada', 'Bukalapak', 'Blibli', 'Tidak Ada'
  ];
  final List<String> _legalitasOptions = [
    'Terdaftar', 'Belum Terdaftar', 'Dalam Proses'
  ];
  final List<String> _levelPengalamanOptions = [
    'Semua tingkat', 'Pemula', 'Menengah', 'Senior'
  ];
  final List<String> _jumlahHasilOptions = [
    'Top 5', 'Top 10', 'Top 20', 'Semua'
  ];

  @override
  void initState() {
    super.initState();
    _checkFlaskStatus();
  }

  Future<void> _checkFlaskStatus() async {
    final status = await _api.checkFlaskStatus();
    if (mounted) {
      setState(() {
        _flaskConnected = status['connected'] ?? false;
        _modelLoaded = status['model_loaded'] ?? false;
      });
    }
  }

  Future<void> _runRecommendation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      'omset': _parseNumber(_omsetCtrl.text),
      'laba': _parseNumber(_labaCtrl.text),
      'aset': _parseNumber(_asetCtrl.text),
      'tahun_berdiri': int.tryParse(_tahunBerdiriCtrl.text) ?? DateTime.now().year,
      'jenis_usaha': _selectedJenisUsaha,
      'marketplace': _selectedMarketplace,
      'status_legalitas': _selectedLegalitas,
      'tenaga_kerja_perempuan': int.tryParse(_tenagaKerjaPerempuanCtrl.text) ?? 0,
      'tenaga_kerja_laki': int.tryParse(_tenagaKerjaLakiCtrl.text) ?? 0,
      'jumlah_hasil': _selectedJumlahHasil,
      'level_pengalaman': _selectedLevelPengalaman,
      'budget_minimum': _parseNumber(_budgetMinCtrl.text),
    };

    final result = await _api.getAiRecommendations(payload);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'];
          if (data is List) {
            _results = data.map((e) => Map<String, dynamic>.from(e)).toList();
          } else if (data is Map && data['recommendations'] is List) {
            _results = (data['recommendations'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
      });
    }
  }

  int _parseNumber(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  void _resetForm() {
    setState(() {
      _results = null;
    });
  }

  @override
  void dispose() {
    _omsetCtrl.dispose();
    _labaCtrl.dispose();
    _asetCtrl.dispose();
    _tahunBerdiriCtrl.dispose();
    _tenagaKerjaPerempuanCtrl.dispose();
    _tenagaKerjaLakiCtrl.dispose();
    _budgetMinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Rekomendasi Kreator AI',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Gradient
            _buildHeaderBanner(),
            const SizedBox(height: 20),

            // Flask Status
            _buildFlaskStatusCard(),
            const SizedBox(height: 20),

            if (_results == null) ...[
              // Form Input UMKM
              _buildFormSection(),
            ] else ...[
              // Hasil Rekomendasi
              _buildResultsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003466), Color(0xFF1A4B84)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B84).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF68FADD), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Rekomendasi Kreator AI untuk UMKM Kamu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Masukkan data UMKM yang kamu butuhkan, kirim ke Flask ML service, lalu temukan creative worker yang paling cocok dengan proyek kamu.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStepBadge('1', 'Input data bisnis UMKM'),
              const SizedBox(width: 8),
              _buildMiniStepBadge('2', 'Flask ML prediksi cluster'),
              const SizedBox(width: 8),
              _buildMiniStepBadge('3', 'Lihat rekomendasi kreator'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStepBadge(String step, String text) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF68FADD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                step,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF003466),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Colors.white70,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlaskStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _flaskConnected
              ? const Color(0xFF006D77).withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _flaskConnected
                  ? const Color(0xFF006D77).withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _flaskConnected ? Icons.check_circle_outline : Icons.error_outline,
              color: _flaskConnected ? const Color(0xFF006D77) : Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Flask',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF424750),
                  ),
                ),
                Text(
                  _flaskConnected ? 'Terhubung · Model Ready' : 'Tidak terhubung',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _flaskConnected ? const Color(0xFF006D77) : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _flaskConnected ? const Color(0xFF006D77) : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FORM INPUT ====================

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data UMKM',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Isi parameter untuk analisis model (KMeans + TF-IDF)',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF424750),
          ),
        ),
        const SizedBox(height: 14),

        Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Row 1: Omset & Laba
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _omsetCtrl,
                        label: 'OMSET',
                        hint: '50.000.000',
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _labaCtrl,
                        label: 'LABA',
                        hint: '10.000.000',
                        icon: Icons.savings_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 2: Aset & Tahun Berdiri
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _asetCtrl,
                        label: 'ASET',
                        hint: '20.000.000',
                        icon: Icons.account_balance_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _tahunBerdiriCtrl,
                        label: 'TAHUN BERDIRI',
                        hint: '2026',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 3: Jenis Usaha & Marketplace
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'JENIS USAHA',
                        value: _selectedJenisUsaha,
                        items: _jenisUsahaOptions,
                        onChanged: (v) => setState(() => _selectedJenisUsaha = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'MARKETPLACE',
                        value: _selectedMarketplace,
                        items: _marketplaceOptions,
                        onChanged: (v) => setState(() => _selectedMarketplace = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 4: Status Legalitas
                _buildDropdownField(
                  label: 'STATUS LEGALITAS',
                  value: _selectedLegalitas,
                  items: _legalitasOptions,
                  onChanged: (v) => setState(() => _selectedLegalitas = v!),
                ),
                const SizedBox(height: 14),

                // Row 5: Tenaga Kerja
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _tenagaKerjaPerempuanCtrl,
                        label: 'TENAGA KERJA ♀',
                        hint: '0',
                        icon: Icons.people_outline,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _tenagaKerjaLakiCtrl,
                        label: 'TENAGA KERJA ♂',
                        hint: '0',
                        icon: Icons.people_outline,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 6: Jumlah Hasil & Level Pengalaman
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'JUMLAH HASIL',
                        value: _selectedJumlahHasil,
                        items: _jumlahHasilOptions,
                        onChanged: (v) => setState(() => _selectedJumlahHasil = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'LEVEL PENGALAMAN',
                        value: _selectedLevelPengalaman,
                        items: _levelPengalamanOptions,
                        onChanged: (v) => setState(() => _selectedLevelPengalaman = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 7: Budget Minimum
                _buildInputField(
                  controller: _budgetMinCtrl,
                  label: 'BUDGET MINIMUM KREATOR',
                  hint: '3.000.000',
                  icon: Icons.attach_money,
                  helperText: 'Opsional. Kosongkan jika tidak ingin filter budget.',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Kenapa ini penting?
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A4B84).withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1A4B84).withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 20, color: const Color(0xFF1A4B84)),
                  const SizedBox(width: 8),
                  Text(
                    'Kenapa Ini Penting?',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF1A4B84),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Kamu tidak perlu menebak role mana yang cocok. Model machine learning membantu menyeleksi creative worker berdasarkan pola UMKM yang mirip.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF424750),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'Catatan: Kamu boleh mengetik angka pakai pemisah ribuan. Sistem akan membersihkannya otomatis.',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF424750).withOpacity(0.5),
            fontStyle: FontStyle.italic,
          ),
        ),

        const SizedBox(height: 20),

        // Tombol Jalankan
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _runRecommendation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A4B84),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Jalankan Rekomendasi AI',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ==================== HASIL REKOMENDASI ====================

  Widget _buildResultsSection() {
    final clusterName = _results!.isNotEmpty
        ? (_results![0]['cluster_name'] ?? 'Cluster Rekomendasi')
        : 'Hasil Rekomendasi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                clusterName,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFF1B1B1F),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _resetForm,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                'Input Ulang',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ),
          ],
        ),
        Text(
          'Total kandidat ditemukan: ${_results!.length}',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF424750),
          ),
        ),
        const SizedBox(height: 16),

        ..._results!.map((creative) => _buildCreativeResultCard(creative)),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCreativeResultCard(Map<String, dynamic> creative) {
    final name = creative['name'] ?? '';
    final role = creative['role'] ?? '';
    final verified = creative['verified'] == true;
    final matchScore = creative['match_score'] ?? 0.0;
    final rating = (creative['rating'] ?? 0.0).toDouble();
    final projects = creative['projects_count'] ?? 0;
    final successRate = (creative['success_rate'] ?? 0.0).toDouble();
    final budget = creative['budget'] ?? 0;
    final skills = creative['skills'] as List<dynamic>? ?? [];
    final city = creative['city'] ?? 'Lokasi tidak diatur';
    final photo = creative['profile_photo'] ?? '';
    final bio = creative['bio'] ?? 'Creative worker yang direkomendasikan oleh model machine learning.';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B84).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEAE7ED).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A4B84), Color(0xFF006D77)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  image: photo.isNotEmpty
                      ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover)
                      : null,
                ),
                child: photo.isEmpty
                    ? Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
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
                        if (verified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006D77).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 12, color: const Color(0xFF006D77)),
                                const SizedBox(width: 3),
                                Text(
                                  'Terverifikasi',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF006D77),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF424750)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Match Score
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A4B84), Color(0xFF003466)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MATCH ${matchScore.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.location_on_outlined, size: 12, color: const Color(0xFF424750).withOpacity(0.5)),
              const SizedBox(width: 2),
              Text(
                city,
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750).withOpacity(0.6)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Skills
          if (skills.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: skills.take(5).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    skill.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A4B84),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 10),

          // Stats Row
          Row(
            children: [
              _buildMiniStat('RATING', rating.toStringAsFixed(1), Icons.star_rounded, Colors.amber),
              const SizedBox(width: 16),
              _buildMiniStat('PROJECT', '$projects', Icons.work_outline, const Color(0xFF1A4B84)),
              const SizedBox(width: 16),
              _buildMiniStat('SUCCESS', '${successRate.toStringAsFixed(1)}%', Icons.trending_up, const Color(0xFF006D77)),
              const Spacer(),
              _buildMiniStat('BUDGET', 'Rp ${_formatCurrency(budget)}', Icons.attach_money, const Color(0xFFE29578)),
            ],
          ),

          const SizedBox(height: 10),

          // Bio
          Text(
            bio,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF424750),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreativeDetailPage(
                      creativeId: creative['id']?.toString() ?? '',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_outline, size: 16),
              label: Text(
                'Lihat Profile',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A4B84),
                side: const BorderSide(color: Color(0xFF1A4B84)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF424750),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final num = value is int ? value : int.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(0)}K';
    return num.toString();
  }

  // ==================== WIDGET HELPER FORM ====================

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.number,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: const Color(0xFF1B1B1F),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF424750).withOpacity(0.5),
            ),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF1A4B84)),
            filled: true,
            fillColor: const Color(0xFFF5F3F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1A4B84), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF424750).withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField({
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
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: const Color(0xFF1B1B1F),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A4B84)),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1B1B1F),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}