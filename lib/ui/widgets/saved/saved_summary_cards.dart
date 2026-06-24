import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SavedSummaryCards extends StatelessWidget {
  final int savedCount;
  final int liveCount;

  const SavedSummaryCards({
    super.key,
    required this.savedCount,
    required this.liveCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: '💚',
            count: savedCount,
            label: 'SAVED',
            backgroundColor: AppColors.surface,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: '▶️',
            count: liveCount,
            label: 'LIVE NOW',
            backgroundColor: const Color(0x26E5383B), // Red tint matching screenshot
            borderColor: const Color(0x33E5383B),
            countColor: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String icon;
  final int count;
  final String label;
  final Color backgroundColor;
  final Color? borderColor;
  final Color countColor;

  const _SummaryCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.backgroundColor,
    this.borderColor,
    this.countColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor ?? AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: countColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
