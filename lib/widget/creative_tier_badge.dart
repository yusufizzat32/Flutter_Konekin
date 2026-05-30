// lib/widgets/creative_tier_badge.dart
// Badge gelar creative worker - tampil di profile card, halaman detail, dll.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CreativeTier { none, beginner, intermediate, expert }

class CreativeTierBadge extends StatelessWidget {
  final CreativeTier tier;
  final bool showLabel;
  final double size; // 'small', 'medium', 'large' → pakai size
  final int? fiveStarCount;

  const CreativeTierBadge({
    super.key,
    required this.tier,
    this.showLabel = true,
    this.size = 1.0,
    this.fiveStarCount,
  });

  /// Parse dari string yang dikirim backend
  static CreativeTier fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'beginner': return CreativeTier.beginner;
      case 'intermediate': return CreativeTier.intermediate;
      case 'expert': return CreativeTier.expert;
      default: return CreativeTier.none;
    }
  }

  static String tierLabel(CreativeTier tier) {
    switch (tier) {
      case CreativeTier.beginner: return 'Beginner';
      case CreativeTier.intermediate: return 'Intermediate';
      case CreativeTier.expert: return 'Expert';
      case CreativeTier.none: return '';
    }
  }

  // Gradient warna per tier
  static List<Color> tierGradient(CreativeTier tier) {
    switch (tier) {
      case CreativeTier.beginner:
        return [const Color(0xFF546E7A), const Color(0xFF78909C)];
      case CreativeTier.intermediate:
        return [const Color(0xFF0D47A1), const Color(0xFF1976D2)];
      case CreativeTier.expert:
        return [const Color(0xFFBF360C), const Color(0xFFFF8F00)];
      case CreativeTier.none:
        return [const Color(0xFFBDBDBD), const Color(0xFF9E9E9E)];
    }
  }

  static IconData tierIcon(CreativeTier tier) {
    switch (tier) {
      case CreativeTier.beginner: return Icons.emoji_events_outlined;
      case CreativeTier.intermediate: return Icons.workspace_premium_outlined;
      case CreativeTier.expert: return Icons.military_tech;
      case CreativeTier.none: return Icons.star_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tier == CreativeTier.none) return const SizedBox.shrink();

    final gradColors = tierGradient(tier);
    final iconData = tierIcon(tier);
    final label = tierLabel(tier);
    final iconSize = 14.0 * size;
    final fontSize = 10.0 * size;
    final padH = 8.0 * size;
    final padV = 4.0 * size;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradColors.last.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: iconSize, color: Colors.white),
          if (showLabel) ...[
            SizedBox(width: 4 * size),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
          if (fiveStarCount != null && showLabel) ...[
            SizedBox(width: 4 * size),
            Text(
              '• $fiveStarCount ⭐',
              style: GoogleFonts.inter(
                fontSize: (fontSize - 1).clamp(8, 20),
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Profile Card Banner dengan warna berbeda tiap tier
/// Dipakai di halaman profil creative worker
class CreativeTierBanner extends StatelessWidget {
  final CreativeTier tier;
  final String name;
  final String? avatarUrl;
  final double avgRating;
  final int totalRatings;
  final int fiveStarCount;
  final String? city;
  final String? category;

  const CreativeTierBanner({
    super.key,
    required this.tier,
    required this.name,
    this.avatarUrl,
    this.avgRating = 0,
    this.totalRatings = 0,
    this.fiveStarCount = 0,
    this.city,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final gradColors = CreativeTierBadge.tierGradient(tier);
    final hasTier = tier != CreativeTier.none;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasTier
              ? gradColors
              : [const Color(0xFF1A4B84), const Color(0xFF003070)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge tier (jika ada)
          if (hasTier) ...[
            CreativeTierBadge(tier: tier, fiveStarCount: fiveStarCount),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        category!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    if (city != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text(
                            city!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              _statChip(Icons.star_rounded, '${avgRating.toStringAsFixed(1)}', 'Avg Rating'),
              const SizedBox(width: 10),
              _statChip(Icons.rate_review_outlined, '$totalRatings', 'Total Rating'),
              if (hasTier) ...[
                const SizedBox(width: 10),
                _statChip(Icons.star_rounded, '$fiveStarCount', 'Bintang 5'),
              ],
            ],
          ),

          // Progress ke tier berikutnya
          if (hasTier) ...[
            const SizedBox(height: 12),
            _buildTierProgress(),
          ],
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text(value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
              ],
            ),
            Text(label,
                style: GoogleFonts.inter(fontSize: 9, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildTierProgress() {
    // Hitung progress ke tier berikutnya
    String nextTierLabel = '';
    int current = fiveStarCount;
    int target = 0;

    if (tier == CreativeTier.beginner) {
      nextTierLabel = 'Intermediate';
      target = 5;
    } else if (tier == CreativeTier.intermediate) {
      nextTierLabel = 'Expert';
      target = 15;
    } else {
      // Expert = sudah maksimal
      return Row(
        children: [
          const Icon(Icons.verified, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Gelar tertinggi telah dicapai! 🏆',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
          ),
        ],
      );
    }

    final progress = (current / target).clamp(0.0, 1.0);
    final remaining = target - current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Menuju $nextTierLabel',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
            Text(
              remaining > 0 ? '$remaining lagi' : 'Hampir!',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            color: Colors.white,
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}