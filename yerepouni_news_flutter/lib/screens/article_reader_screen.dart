import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../services/feed_service.dart';
import '../widgets/article_card.dart';

class ArticleReaderScreen extends StatefulWidget {
  const ArticleReaderScreen({super.key, required this.article, this.relatedRssUrl, this.feedService});

  final Article article;

  /// RSS feed to pull "Articles you might love" suggestions from (typically
  /// the category or language feed the article was opened from).
  final String? relatedRssUrl;
  final FeedService? feedService;

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  final _bookmarkService = BookmarkService();
  bool _isBookmarked = false;

  late Article _article;
  bool _loadingFullArticle = true;

  List<Article> _related = [];
  Map<String, Article> _relatedBookmarks = {};
  bool _relatedLoading = false;

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    _bookmarkService.isBookmarked(widget.article.link).then((v) {
      if (mounted) setState(() => _isBookmarked = v);
    });
    _loadFullArticle();
    _loadRelated();
  }

  Future<void> _loadFullArticle() async {
    if (widget.feedService == null) {
      setState(() => _loadingFullArticle = false);
      return;
    }
    try {
      final content = await widget.feedService!.fetchFullArticleContent(widget.article.link);
      if (content != null && content.isNotEmpty && mounted) {
        setState(() => _article = Article(
              title: _article.title,
              link: _article.link,
              date: _article.date,
              excerpt: _article.excerpt,
              content: content,
              category: _article.category,
              image: _article.image,
            ));
      }
    } catch (_) {
      // Keep showing the RSS excerpt if the full article can't be fetched.
    }
    if (mounted) setState(() => _loadingFullArticle = false);
  }

  Future<void> _loadRelated() async {
    if (widget.relatedRssUrl == null || widget.feedService == null) return;
    setState(() => _relatedLoading = true);
    try {
      final items = await widget.feedService!.fetchFeed(widget.relatedRssUrl!);
      final filtered = items.where((a) => a.link != widget.article.link).take(6).toList();
      _relatedBookmarks = await _bookmarkService.load();
      if (mounted) setState(() => _related = filtered);
    } catch (_) {
      // Silently skip suggestions if the related feed fails to load.
    }
    if (mounted) setState(() => _relatedLoading = false);
  }

  Future<void> _toggleRelatedBookmark(Article a) async {
    await _bookmarkService.toggle(a.link, a);
    _relatedBookmarks = await _bookmarkService.load();
    if (mounted) setState(() {});
  }

  Future<void> _toggleBookmark() async {
    final on = await _bookmarkService.toggle(widget.article.link, widget.article);
    if (mounted) setState(() => _isBookmarked = on);
  }

  Future<void> _openOriginal() async {
    final uri = Uri.tryParse(widget.article.link);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final a = _article;
    final body = a.content.isNotEmpty ? a.content : a.excerpt;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 4,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton.icon(
              onPressed: _openOriginal,
              icon: const Icon(Icons.open_in_new, size: 16, color: Colors.white),
              label: const Text('Open in web', style: TextStyle(color: Colors.white, fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _toggleBookmark,
            icon: Icon(
              _isBookmarked ? Icons.star : Icons.star_border,
              color: _isBookmarked ? const Color(0xFFE0A800) : Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a.image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(resolveImageUrl(a.image), height: 220, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.lightAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(a.category.isNotEmpty ? a.category : 'News',
                  style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 10),
            Text(a.title,
                style: const TextStyle(fontFamily: 'Georgia', fontSize: 26, color: AppColors.accent, height: 1.15)),
            const SizedBox(height: 8),
            Text(formatDate(a.date), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 16),
            if (_loadingFullArticle)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent),
                      ),
                      SizedBox(height: 12),
                      Text('Loading article…', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              HtmlWidget(
                body,
                textStyle: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF3A3440)),
                customStylesBuilder: (element) {
                  if (element.localName == 'img') {
                    return {'border-radius': '10px', 'margin': '10px 0'};
                  }
                  if (element.localName == 'a') {
                    return {'color': '#482B6F'};
                  }
                  return null;
                },
              ),
            if (widget.relatedRssUrl != null) ...[
              const SizedBox(height: 28),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 20),
              const Text(
                'Articles you might love',
                style: TextStyle(fontFamily: 'Georgia', fontSize: 22, color: AppColors.accent),
              ),
              const SizedBox(height: 4),
              if (_relatedLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Loading…', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                )
              else if (_related.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No related articles found.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                )
              else
                ..._related.map((r) => ArticleCard(
                      article: r,
                      isBookmarked: _relatedBookmarks.containsKey(r.link),
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ArticleReaderScreen(
                            article: r,
                            relatedRssUrl: widget.relatedRssUrl,
                            feedService: widget.feedService,
                          ),
                        ),
                      ),
                      onBookmarkTap: () => _toggleRelatedBookmark(r),
                    )),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
