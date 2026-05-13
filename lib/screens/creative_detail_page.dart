// lib/screens/creative_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'create_project.dart';
import 'explore_creatives.dart';

class CreativeDetailPage extends StatefulWidget {
  final String creativeId;

  const CreativeDetailPage({super.key, required this.creativeId});

  @override
  State<CreativeDetailPage> createState() => _CreativeDetailPageState();
}

class _CreativeDetailPageState extends State<CreativeDetailPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final result =
        await _api.getCreativeDetail(int.tryParse(widget.creativeId) ?? 0);

    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        final raw = result['data'];
        // Backend bisa wrap di key 'user', 'creative', atau langsung
        final d = raw is Map
            ? (raw['user'] ?? raw['creative'] ?? raw) as Map<String, dynamic>
            : <String, dynamic>{};
        setState(() {
          _data = Map<String, dynamic>.from(d);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg = result['message'] ?? 'Data tidak ditemukan';
          _isLoading = false;
        });
      }
    }
  }

  // ─── helpers ────────────────────────────────────────────────────────────────
  String get _name => _data?['name'] ?? '';
  String get _role =>
      _data?['role'] ?? _data?['category'] ?? 'Creative Worker';
  String get _city => _data?['city'] ?? _data?['address'] ?? '';
  String get _phone =>
      _data?['phone'] ?? _data?['phone_number'] ?? '';
  String get _email => _data?['email'] ?? '';
  String get _bio => _data?['bio'] ?? '';
  String get _photo => _data?['profile_photo'] ?? _data?['avatar'] ?? '';
  String get _joinedAt => _data?['created_at'] != null
      ? _formatDate(_data!['created_at'].toString())
      : '';
  double get _rating =>
      double.tryParse(_data?['rating']?.toString() ?? '0') ?? 0.0;
  int get _portfolioCount => _data?['portfolio_count'] ?? 0;
  int get _completedProjects => _data?['completed_projects'] ?? 0;
  String get _status => _data?['status'] ?? 'active';

  List<Map<String, dynamic>> get _portfolios =>
      (_data?['portfolios'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      [];

  List<Map<String, dynamic>> get _ratings =>
      (_data?['recent_ratings'] ?? _data?['ratings'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      [];

  List<String> get _skills =>
      (_data?['skills'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      [];

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  // ─── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? _buildError()
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildAboutSection(),
                          _buildPortfolioSection(),
                          _buildRatingsSection(),
                          _buildInfoSection(),
                          _buildCTACard(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: const Color(0xFF424750).withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(_errorMsg!,
              style: GoogleFonts.inter(color: const Color(0xFF424750))),
          const SizedBox(height: 16),
          TextButton(
              onPressed: _load,
              child: Text('Coba lagi',
                  style: GoogleFonts.inter(color: const Color(0xFF1A4B84)))),
        ],
      ),
    );
  }

  // ─── Sliver AppBar (profile header) ─────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: const Color(0xFF1A4B84),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF002D6A), Color(0xFF1A4B84)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B8ED6),
                    borderRadius: BorderRadius.circular(16),
                    image: _photo.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(_photo), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _photo.isEmpty
                      ? Center(
                          child: Text(
                            _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                // Label "CREATIVE WORKER"
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _role.isNotEmpty ? _role.toUpperCase() : 'CREATIVE WORKER',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                // Location + phone
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_city.isNotEmpty) ...[
                      Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.white60),
                      const SizedBox(width: 3),
                      Text(_city,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.white70)),
                    ],
                    if (_city.isNotEmpty && _phone.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                            color: Colors.white38, shape: BoxShape.circle),
                      ),
                    if (_phone.isNotEmpty) ...[
                      Icon(Icons.phone_outlined,
                          size: 12, color: Colors.white60),
                      const SizedBox(width: 3),
                      Text(_phone,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Stats row (Portfolio · Proyek Selesai · Rating · Status) ───────────────

  Widget _buildStatsRow() {
    final statusLabel =
        _status == 'active' || _status == 'verified' ? 'Aktif' : _status;
    final isActive = statusLabel == 'Aktif';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _statCell('PORTFOLIO', _portfolioCount.toString()),
          _divider(),
          _statCell('PROYEK SELESAI', _completedProjects.toString()),
          _divider(),
          _statCell(
            'RATING',
            _rating.toStringAsFixed(1),
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
          ),
          _divider(),
          _statCell(
            'STATUS',
            statusLabel,
            textColor: isActive ? const Color(0xFF006D77) : null,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value,
      {IconData? icon, Color? iconColor, Color? textColor, bool isBold = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF424750).withOpacity(0.5),
                letterSpacing: 0.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: iconColor),
                const SizedBox(width: 2),
              ],
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textColor ?? const Color(0xFF1B1B1F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: const Color(0xFFEAE7ED),
      );

  // ─── About section ───────────────────────────────────────────────────────────
  Widget _buildAboutSection() {
    final bioText = _bio.isNotEmpty
        ? _bio
        : 'Kreator ini belum menambahkan bio. Namun kamu tetap bisa melihat identitas dasar dan kumpulan portfolio yang sudah mereka tampilkan di Konekin.';

    return Column(
      children: [
        // Stats strip
        _buildStatsRow(),
        const SizedBox(height: 12),
        // Tentang Kreator card
        _sectionCard(
          label: 'TENTANG KREATOR',
          title: 'Profil Singkat',
          trailing: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 10, color: Color(0xFF1A4B84)),
            label: Text(
              'Kembali',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF1A4B84),
                  fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: const Color(0xFF1A4B84).withOpacity(0.07),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bioText,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF424750),
                    height: 1.55),
              ),
              if (_skills.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: _skills.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A4B84).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF1A4B84).withOpacity(0.15)),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A4B84)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Portfolio section ───────────────────────────────────────────────────────
  Widget _buildPortfolioSection() {
    return _sectionCard(
      label: 'PORTFOLIO SHOWCASE',
      title: 'Karya Pilihan',
      child: _portfolios.isEmpty
          ? _emptyState(
              icon: Icons.image_outlined,
              title: 'Portfolio Belum Ditambahkan',
              subtitle:
                  'Kreator ini belum mengunggah karya ke profilnya. Kamu masih bisa melihat identitas dasarnya dan kembali nanti saat portfolio sudah tersedia.',
            )
          : SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _portfolios.length,
                itemBuilder: (ctx, i) {
                  final p = _portfolios[i];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEAE7ED)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: SizedBox(
                            height: 100,
                            width: double.infinity,
                            child: p['image_url'] != null &&
                                    p['image_url'].toString().isNotEmpty
                                ? Image.network(p['image_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const _PortfolioPlaceholder())
                                : const _PortfolioPlaceholder(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            p['title'] ?? '',
                            style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  // ─── Ratings section ─────────────────────────────────────────────────────────
  Widget _buildRatingsSection() {
    return _sectionCard(
      label: 'FEEDBACK UMKM',
      title: 'Ulasan Terbaru',
      trailing: Row(
        children: [
          Icon(Icons.star_rounded, size: 14, color: Colors.amber),
          const SizedBox(width: 3),
          Text(
            _rating.toStringAsFixed(1),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1B1F)),
          ),
        ],
      ),
      child: _ratings.isEmpty
          ? _emptyState(
              icon: Icons.star_outline_rounded,
              title: 'Belum Ada Ulasan',
              subtitle:
                  'Begitu UMKM memberi rating setelah proyek selesai, ulasan akan tampil di sini.',
            )
          : Column(
              children: _ratings.map((r) {
                final stars = (r['rating'] as num?)?.toInt() ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEAE7ED)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 15,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            r['from_user_name'] ?? r['umkm_name'] ?? '',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF424750),
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if ((r['comment'] ?? r['review'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          r['comment'] ?? r['review'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF424750),
                              height: 1.45),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ─── Info section ─────────────────────────────────────────────────────────────
  Widget _buildInfoSection() {
    final infoItems = <_InfoItem>[
      if (_email.isNotEmpty) _InfoItem('EMAIL', _email),
      if (_city.isNotEmpty)
        _InfoItem('DOMISILI', _city[0].toUpperCase() + _city.substring(1)),
      if (_phone.isNotEmpty) _InfoItem('KONTAK', _phone),
      if (_joinedAt.isNotEmpty) _InfoItem('BERGABUNG', _joinedAt),
    ];

    if (infoItems.isEmpty) return const SizedBox.shrink();

    return _sectionCard(
      label: 'INFORMASI RINGKAS',
      title: 'Highlight Profil',
      child: Column(
        children: infoItems.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE7ED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF424750).withOpacity(0.5),
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1B1B1F)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── CTA card ─────────────────────────────────────────────────────────────────
  Widget _buildCTACard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF002D6A), Color(0xFF1A4B84)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'NEXT STEP',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sudah cocok dengan gaya $_name?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Simpan profil ini sebagai referensi dan lanjutkan proses pencarian kreator terbaik untuk kebutuhan brand, campaign, atau konten usahamu.',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const ExploreCreativesPage()),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(
                'Lihat Kreator Lain',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateProjectPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A4B84),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
              ),
              child: Text(
                'Upload Proyek',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared section card wrapper ─────────────────────────────────────────────
  Widget _sectionCard({
    required String label,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B84).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A4B84).withOpacity(0.7),
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1B1F)),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────────
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE7ED)),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 36, color: const Color(0xFF1A4B84).withOpacity(0.25)),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1B1F)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF424750),
                height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}

class _PortfolioPlaceholder extends StatelessWidget {
  const _PortfolioPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAE7ED),
      child: const Center(
        child: Icon(Icons.image_outlined,
            color: Color(0xFF424750), size: 28),
      ),
    );
  }
}