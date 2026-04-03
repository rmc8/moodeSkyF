import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// MoodeSky common shimmer effect
class MoodeSkyShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const MoodeSkyShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark 
          ? Colors.grey[800]! 
          : Colors.grey[300]!,
      highlightColor: isDark 
          ? Colors.grey[700]! 
          : Colors.grey[100]!,
      child: child,
    );
  }
}

/// Shimmer placeholder boxes
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
