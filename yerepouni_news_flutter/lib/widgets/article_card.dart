import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/article.dart';
import '../services/feed_service.dart' show resolveImageUrl;

String formatDate(String iso) {
  try {
    final d = DateTime.parse(iso);
    return DateFormat.yMMMMd().format(d);
  } catch (_) {
    return iso;
  }
}

String stripHtml(String html) {
  return html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

class ArticleCard extends StatelessWidget {
  const ArticleCard({
    super.key,
    required this.article,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmarkTap,
  });

  final Article article;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    final excerpt = stripHtml(article.excerpt.isNotEmpty ? article.excerpt : article.content);
    final trimmed = excerpt.length > 150 ? '${excerpt.substring(0, 150)}…' : excerpt;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 120,
                height: 92,
                child: article.image.isNotEmpty
                    ? Image.network(resolveImageUrl(article.image), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300))
                    : Container(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Tag(text: article.category.isNotEmpty ? article.category : 'News'),
                        const SizedBox(height: 6),
                        Text(
                          article.title,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 17,
                            height: 1.15,
                            color: AppColors.text,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(formatDate(article.date),
                            style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                        const SizedBox(height: 5),
                        Text(trimmed,
                            style: const TextStyle(fontSize: 12, color: AppColors.cardMuted, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: onBookmarkTap,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isBookmarked ? Icons.star : Icons.star_border,
                        color: isBookmarked ? const Color(0xFFE0A800) : AppColors.accent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightAccent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
