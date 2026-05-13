import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/portfolio_model.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final ApiService _api = ApiService();
  List<Portfolio> _portfolios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  Future<void> _loadPortfolios() async {
    setState(() => _isLoading = true);
    
    final result = await _api.getPortfolios();
    
    if (mounted) {
      setState(() {
        if (result['success'] && result['data'] != null) {
          final portfoliosData = result['data']['portfolios'] ?? result['data'];
          if (portfoliosData is List) {
            _portfolios = portfoliosData.map((e) => Portfolio.fromJson(e)).toList();
          }
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePortfolio(int id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Portfolio'),
        content: Text('Apakah Anda yakin ingin menghapus "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final result = await _api.deletePortfolio(id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );
    
    if (result['success']) {
      _loadPortfolios();
    }
  }

  void _showAddPortfolioDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tambah Portfolio Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL Gambar (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Judul tidak boleh kosong')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              final result = await _api.createPortfolio({
                'title': titleCtrl.text,
                'description': descCtrl.text,
                'category': categoryCtrl.text.isEmpty ? 'General' : categoryCtrl.text,
                'image_url': imageUrlCtrl.text.isEmpty ? null : imageUrlCtrl.text,
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message']),
                  backgroundColor: result['success'] ? Colors.green : Colors.red,
                ),
              );
              
              if (result['success']) {
                _loadPortfolios();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Portfolio Saya',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1A4B84)),
            onPressed: _showAddPortfolioDialog,
            tooltip: 'Tambah Portfolio',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _portfolios.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 80,
                        color: const Color(0xFF424750).withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada portfolio',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF424750),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tambah portfolio untuk menarik klien',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF424750),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddPortfolioDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Portfolio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006D77),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _portfolios.length,
                  itemBuilder: (context, index) {
                    final portfolio = _portfolios[index];
                    return _PortfolioCard(
                      portfolio: portfolio,
                      onDelete: () => _deletePortfolio(portfolio.id, portfolio.title),
                    );
                  },
                ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final Portfolio portfolio;
  final VoidCallback onDelete;
  
  const _PortfolioCard({required this.portfolio, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image/Thumbnail
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFEAE7ED),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: portfolio.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(portfolio.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: portfolio.imageUrl == null
                ? const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: Color(0xFF424750),
                    ),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  portfolio.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  portfolio.category,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF006D77),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  portfolio.description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF424750),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}