import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Animated placeholder shown while Yerepouni's (slow, 10s+) search endpoint
/// is in flight: shimmering skeleton cards plus rotating status text so the
/// long wait reads as active progress instead of a frozen spinner.
class SearchLoading extends StatefulWidget {
  const SearchLoading({super.key});

  @override
  State<SearchLoading> createState() => _SearchLoadingState();
}

class _SearchLoadingState extends State<SearchLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  Timer? _messageTimer;
  int _messageIndex = 0;

  static const _messages = [
    'Searching Yerepouni News…',
    'Looking through recent articles…',
    'Still searching — almost there…',
    'Their search can take a little while…',
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _messages[_messageIndex],
                key: ValueKey(_messageIndex),
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          ),
        ),
        ...List.generate(5, (i) => _SkeletonCard(animation: _shimmerController)),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final opacity = 0.35 + 0.25 * (0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2));
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 120,
                  height: 92,
                  color: AppColors.divider.withValues(alpha: opacity),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(width: 60, height: 18, opacity: opacity, radius: 999),
                    const SizedBox(height: 8),
                    _bar(width: double.infinity, height: 14, opacity: opacity),
                    const SizedBox(height: 6),
                    _bar(width: 140, height: 14, opacity: opacity),
                    const SizedBox(height: 10),
                    _bar(width: 80, height: 10, opacity: opacity),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bar({required double width, required double height, required double opacity, double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
