import 'package:flutter/material.dart';
import 'package:moodesky/core/theme/app_themes.dart';
import 'package:moodesky/shared/widgets/common/shimmer_loading.dart';
import 'package:moodesky/shared/widgets/common/theme_helpers.dart';

/// Shimmer loading state for a post item
class ShimmerPostItem extends StatelessWidget {
  const ShimmerPostItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.isLight ? Colors.white : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1.0,
          ),
          boxShadow: context.isLight ? AppThemes.premiumShadow : null,
        ),
        child: MoodeSkyShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShimmerBox(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerBox(width: 120, height: 14),
                        const SizedBox(height: 6),
                        const ShimmerBox(width: 80, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const ShimmerBox(width: double.infinity, height: 14),
              const SizedBox(height: 8),
              const ShimmerBox(width: double.infinity, height: 14),
              const SizedBox(height: 8),
              const ShimmerBox(width: 200, height: 14),
              const SizedBox(height: 20),
              Row(
                children: [
                  const ShimmerBox(width: 40, height: 20, borderRadius: 10),
                  const SizedBox(width: 24),
                  const ShimmerBox(width: 40, height: 20, borderRadius: 10),
                  const SizedBox(width: 24),
                  const ShimmerBox(width: 40, height: 20, borderRadius: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
