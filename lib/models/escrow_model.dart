// lib/models/escrow_model.dart

import 'package:flutter/material.dart';

class EscrowTransaction {
  final String id;
  final String projectId;
  final String projectTitle;
  final Map<String, dynamic> payer;
  final Map<String, dynamic> payee;
  final int amount;
  final int platformFee;
  final int netAmount;
  final String status;
  final String? disbursementId;
  final String? disbursementStatus;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final String? virtualAccountBank;
  final String? virtualAccountNumber;
  final DateTime? paymentDueAt;
  final String? proofFileUrl;
  final DateTime? paymentDate;

  EscrowTransaction({
    required this.id,
    required this.projectId,
    required this.projectTitle,
    required this.payer,
    required this.payee,
    required this.amount,
    required this.platformFee,
    required this.netAmount,
    required this.status,
    this.disbursementId,
    this.disbursementStatus,
    required this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    this.rejectedAt,
    this.virtualAccountBank,
    this.virtualAccountNumber,
    this.paymentDueAt,
    this.proofFileUrl,
    this.paymentDate,
  });

  factory EscrowTransaction.fromJson(Map<String, dynamic> json) {
    return EscrowTransaction(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      projectTitle: json['project_title'] ?? json['title'] ?? 'Proyek',
      payer: json['payer'] ?? {
        'id': json['payer_id']?.toString() ?? '',
        'name': json['payer_name'] ?? 'UMKM',
      },
      payee: json['payee'] ?? {
        'id': json['payee_id']?.toString() ?? '',
        'name': json['payee_name'] ?? 'Creative Worker',
      },
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      platformFee: (json['platform_fee'] as num?)?.toInt() ?? 0,
      netAmount: (json['net_amount'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'pending',
      disbursementId: json['disbursement_id']?.toString(),
      disbursementStatus: json['disbursement_status']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at']) 
          : null,
      verifiedBy: json['verified_by']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      rejectedAt: json['rejected_at'] != null 
          ? DateTime.parse(json['rejected_at']) 
          : null,
      virtualAccountBank: json['virtual_account_bank']?.toString(),
      virtualAccountNumber: json['virtual_account_number']?.toString(),
      paymentDueAt: json['payment_due_at'] != null 
          ? DateTime.parse(json['payment_due_at']) 
          : null,
      proofFileUrl: json['proof_file_url']?.toString(),
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : null,
    );
  }

  String get formattedAmount => 
      'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

  String get formattedPlatformFee => 
      'Rp ${platformFee.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

  String get formattedNetAmount => 
      'Rp ${netAmount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

  String get statusLabel {
    switch (status) {
      case 'held':
        return 'Ditahan';
      case 'released':
        return 'Dicairkan';
      case 'releasing':
        return 'Proses Pencairan';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'refunded':
        return 'Dikembalikan';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String get disbursementStatusLabel {
    switch (disbursementStatus) {
      case 'waiting_payment':
        return 'Menunggu Pembayaran';
      case 'waiting_verification':
        return 'Menunggu Verifikasi';
      case 'held_by_platform':
        return 'Ditahan Platform';
      case 'processing':
      case 'disbursing':
        return 'Sedang Diproses';
      case 'released':
        return 'Sudah Dicairkan';
      case 'payment_rejected':
        return 'Pembayaran Ditolak';
      case 'payment_cancelled':
        return 'Pembayaran Dibatalkan';
      case 'refunded':
        return 'Dikembalikan';
      default:
        return disbursementStatus ?? 'Unknown';
    }
  }

  bool get isHeld => status == 'held';
  bool get isReleased => status == 'released';
  bool get isReleasing => status == 'releasing';
  bool get isPending => status == 'pending';
  bool get isRefunded => status == 'refunded';
  bool get isRejected => status == 'rejected';
  bool get isVerified => verifiedAt != null;
  bool get isAwaitingVerification => status == 'pending' && disbursementStatus == 'waiting_verification';
  bool get isPaymentPending => status == 'pending' && disbursementStatus == 'waiting_payment';

  Color get statusColor {
    switch (status) {
      case 'held':
        return const Color(0xFFF59E0B); // Orange
      case 'released':
        return const Color(0xFF20C997); // Green
      case 'releasing':
        return const Color(0xFF3B82F6); // Blue
      case 'pending':
        return const Color(0xFF9CA3AF); // Grey
      case 'refunded':
        return const Color(0xFFEF4444); // Red
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'held':
        return Icons.pending_actions_rounded;
      case 'released':
        return Icons.check_circle_rounded;
      case 'releasing':
        return Icons.sync_rounded;
      case 'pending':
        return Icons.payment_outlined;
      case 'refunded':
        return Icons.money_off_rounded; // Fixed: changed from refund_rounded to money_off_rounded
      case 'rejected':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }
}

class EarningsSummary {
  final int totalEarned;
  final int pendingRelease;
  final int inDisbursement;
  final int transactionsCount;
  final int releasedCount;

  EarningsSummary.fromJson(Map<String, dynamic> json)
      : totalEarned = json['total_earned'] ?? 0,
        pendingRelease = json['pending_release'] ?? 0,
        inDisbursement = json['in_disbursement'] ?? 0,
        transactionsCount = json['transactions_count'] ?? 0,
        releasedCount = json['released_count'] ?? 0;

  String get formattedTotalEarned => 
      'Rp ${totalEarned.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  
  String get formattedPendingRelease => 
      'Rp ${pendingRelease.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  
  String get formattedInDisbursement => 
      'Rp ${inDisbursement.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}