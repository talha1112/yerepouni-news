import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/feed_service.dart' show resolveImageUrl;

class AdBanner extends StatelessWidget {
  const AdBanner({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 78,
      margin: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Image.network(
        resolveImageUrl(imageUrl),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
