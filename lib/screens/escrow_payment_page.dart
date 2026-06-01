// lib/screens/escrow_payment_page.dart
// UMKM melakukan pembayaran escrow untuk proyek yang sudah di-approve creative-nya

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../models/project_model.dart';

class EscrowPaymentPage extends StatefulWidget {
  final Project project;

  const EscrowPaymentPage({super.key, required this.project});

  @override
  State<EscrowPaymentPage> createState() => _EscrowPaymentPageState();
}

class _EscrowPaymentPageState extends State<EscrowPaymentPage> {
  final ApiService _api = ApiService();
  final PaymentService _paymentService = PaymentService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _hasPayment = false;
  PaymentData? _paymentData;
  Map<String, dynamic>? _statusInfo;
  
  // Upload form fields
  File? _proofFile;
  String? _selectedPaymentMethod;
  DateTime? _paymentDate;
  final TextEditingController _notesController = TextEditingController();
  
  // Page state
  bool _showUploadForm = false;
  String? _errorMessage;

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'virtual_account', 'label': 'Virtual Account (BCA)'},
    {'value': 'transfer', 'label': 'Transfer Bank'},
    {'value': 'e-wallet', 'label': 'E-Wallet'},
    {'value': 'other', 'label': 'Lainnya'},
  ];

  @override
  void initState() {
    super.initState();
    _checkPaymentStatus();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkPaymentStatus() async {
    setState(() => _isLoading = true);
    
    final result = await _paymentService.checkPaymentStatus(widget.project.id);
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      setState(() {
        _hasPayment = result['has_payment'] ?? false;
        if (_hasPayment && result['data'] != null) {
          _paymentData = PaymentData.fromJson(result['data']);
        }
        _statusInfo = result['status_info'];
        
        // If payment exists and is pending, show upload form
        if (_hasPayment && _paymentData?.canUploadProof == true) {
          _showUploadForm = true;
        }
        
        // If payment is already verified or awaiting verification, show status
        if (_hasPayment && (_paymentData?.isVerified == true || _paymentData?.isAwaitingVerification == true)) {
          _showUploadForm = false;
        }
        
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['message'];
      });
    }
  }

  Future<void> _createPayment() async {
    setState(() => _isLoading = true);
    
    final result = await _paymentService.createPaymentInvoice(widget.project.id);
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      setState(() {
        _paymentData = PaymentData.fromJson(result['data']);
        _hasPayment = true;
        _showUploadForm = true;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invoice pembayaran berhasil dibuat. Silakan transfer ke VA dan upload bukti.'),
        backgroundColor: Color(0xFF006D77),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Gagal membuat pembayaran'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _pickProofImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _proofFile = File(image.path);
      });
    }
  }

  Future<void> _pickProofPDF() async {
    final XFile? file = await _imagePicker.pickMedia();
    
    if (file != null && file.path.toLowerCase().endsWith('.pdf')) {
      setState(() {
        _proofFile = File(file.path);
      });
    } else if (file != null) {
      // If not PDF, pick as image
      _pickProofImage();
    }
  }

  Future<void> _showFilePickerDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1A4B84)),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickProofImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Pilih File PDF'),
              onTap: () {
                Navigator.pop(context);
                _pickProofPDF();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPaymentDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _submitPaymentProof() async {
    if (_proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Silakan pilih file bukti pembayaran'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Silakan pilih metode pembayaran'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    
    if (_paymentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Silakan pilih tanggal pembayaran'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    
    setState(() => _isLoading = true);
    
    final result = await _paymentService.uploadPaymentProof(
      projectId: widget.project.id,
      proofFile: _proofFile!,
      paymentMethod: _selectedPaymentMethod!,
      paymentDate: _paymentDate!,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      setState(() {
        _showUploadForm = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bukti pembayaran berhasil diupload! Menunggu verifikasi admin.'),
        backgroundColor: Color(0xFF006D77),
        behavior: SnackBarBehavior.floating,
      ));
      
      // Refresh payment status after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _checkPaymentStatus();
        }
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Gagal upload bukti pembayaran'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  String _formatBudget(String budget) {
    try {
      final num = double.parse(budget.replaceAll(RegExp(r'[^0-9.]'), ''));
      final formatted = num.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
      return 'Rp $formatted';
    } catch (_) {
      return 'Rp $budget';
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1B1B1F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pembayaran Escrow',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading && _paymentData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // ── Info Proyek ──────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detail Proyek',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: const Color(0xFF1B1B1F))),
                        const SizedBox(height: 16),
                        _infoRow('Nama Proyek', project.title),
                        _infoRow('Kategori', project.category),
                        _infoRow('Durasi', project.duration),
                        _infoRow(
                          'Creative',
                          project.selectedCreativeName ?? '-',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Ringkasan Pembayaran ─────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ringkasan Pembayaran',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: const Color(0xFF1B1B1F))),
                        const SizedBox(height: 16),
                        _payRow('Budget Proyek', _formatBudget(project.budget)),
                        const Divider(height: 24),
                        _payRow(
                          'Total Escrow',
                          _formatBudget(project.budget),
                          isBold: true,
                          color: const Color(0xFF1A4B84),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Payment Status / VA Info ─────────────────────────────────
                  if (_paymentData != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusBackgroundColor(_paymentData!.status),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(PaymentService.getStatusColor(_paymentData!.status))
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                PaymentService.getStatusIcon(_paymentData!.status),
                                color: Color(PaymentService.getStatusColor(_paymentData!.status)),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _paymentData!.statusLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(PaymentService.getStatusColor(_paymentData!.status)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_paymentData!.virtualAccountNumber != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text('Virtual Account BCA',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: const Color(0xFF424750))),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _paymentData!.virtualAccountNumber!,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: const Color(0xFF1A4B84),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20, color: Color(0xFF1A4B84)),
                                  onPressed: () {
                                    // TODO: Implement copy to clipboard
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Nomor VA disalin'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Text(
                              'Transfer ke nomor VA di atas melalui BCA mobile banking, ATM, atau cabang BCA',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF6B6B6B),
                              ),
                            ),
                          ],
                          if (_paymentData!.paymentDueAt != null) ...[
                            const SizedBox(height: 8),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Batas Pembayaran: ${DateFormat('dd MMM yyyy HH:mm').format(_paymentData!.paymentDueAt!)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                          if (_paymentData!.rejectionReason != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Alasan ditolak: ${_paymentData!.rejectionReason}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── Info Escrow ──────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1A4B84).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: Color(0xFF1A4B84), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dana Anda akan disimpan secara aman oleh sistem escrow Konekin dan hanya akan diteruskan ke creative setelah Anda menyetujui hasil kerja.',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF1A4B84),
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Upload Form (if needed) ──────────────────────────────────
                  if (_showUploadForm && _paymentData != null) ...[
                    _buildUploadForm(),
                    const SizedBox(height: 16),
                  ],

                  // ── Action Buttons ───────────────────────────────────────────
                  if (!_hasPayment)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A4B84),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFFEAE7ED),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                'Buat Invoice Pembayaran',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                      ),
                    ),

                  if (_hasPayment && !_showUploadForm && _paymentData?.isAwaitingVerification == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.hourglass_empty,
                              color: Colors.orange, size: 22),
                          const SizedBox(width: 8),
                          Text('Menunggu Verifikasi Admin',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.orange)),
                        ],
                      ),
                    ),

                  if (_hasPayment && !_showUploadForm && _paymentData?.isVerified == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006D77).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF006D77)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF006D77), size: 22),
                          const SizedBox(width: 8),
                          Text('Pembayaran Berhasil! Dana Tersimpan di Escrow',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: const Color(0xFF006D77))),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Kembali',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF424750),
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUploadForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload Bukti Pembayaran',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: const Color(0xFF1B1B1F))),
          const SizedBox(height: 16),
          
          // Proof file picker
          GestureDetector(
            onTap: _showFilePickerDialog,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF9F9F9),
              ),
              child: _proofFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 40, color: const Color(0xFF1A4B84).withOpacity(0.6)),
                        const SizedBox(height: 8),
                        Text('Tap untuk upload bukti pembayaran',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: const Color(0xFF8E8E93))),
                        Text('JPG, PNG, PDF (max 10MB)',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: const Color(0xFFAEAEB2))),
                      ],
                    )
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _proofFile!.path.toLowerCase().endsWith('.pdf')
                              ? Container(
                                  height: 120,
                                  color: const Color(0xFFF0F0F0),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.picture_as_pdf,
                                            size: 48, color: Colors.red),
                                        SizedBox(height: 8),
                                        Text('File PDF terpilih'),
                                      ],
                                    ),
                                  ),
                                )
                              : Image.file(
                                  _proofFile!,
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _proofFile = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 20, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Payment method dropdown
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: InputDecoration(
              labelText: 'Metode Pembayaran',
              labelStyle: GoogleFonts.inter(color: const Color(0xFF8E8E93)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _paymentMethods.map((method) {
              return DropdownMenuItem(
                value: method['value'],
                child: Text(method['label']!,
                    style: GoogleFonts.inter(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedPaymentMethod = value),
          ),
          
          const SizedBox(height: 16),
          
          // Payment date picker
          GestureDetector(
            onTap: _pickPaymentDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDDDDD)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _paymentDate == null
                        ? 'Tanggal Pembayaran'
                        : DateFormat('dd MMM yyyy').format(_paymentDate!),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _paymentDate == null ? const Color(0xFF8E8E93) : const Color(0xFF1B1B1F),
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF8E8E93)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notes
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Catatan (Opsional)',
              labelStyle: GoogleFonts.inter(color: const Color(0xFF8E8E93)),
              hintText: 'Contoh: Sudah transfer melalui mobile banking BCA',
              hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFAEAEB2)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPaymentProof,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4B84),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFEAE7ED),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      'Kirim Bukti Pembayaran',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF9E9E9E))),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B1B1F))),
          ),
        ],
      ),
    );
  }

  Widget _payRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                color: color ?? const Color(0xFF424750))),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: color ?? const Color(0xFF1B1B1F))),
      ],
    );
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFF8E1);
      case 'paid':
        return const Color(0xFFE3F2FD);
      case 'failed':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }
}