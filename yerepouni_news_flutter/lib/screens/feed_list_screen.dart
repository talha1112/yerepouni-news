import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../services/feed_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/article_card.dart';
import 'article_reader_screen.dart';

/// Generic list screen used for Latest / Category / Today-in-history.
/// Pass [staticItems] instead of [rssUrl] to render a pre-fetched list
/// (used by the Bookmarks/Saved screen).
class FeedListScreen extends StatefulWidget {
  const FeedListScreen({
    super.key,
    required this.title,
    this.editionLabel,
    this.rssUrl,
    this.staticItems,
    this.feedService,
    this.emptyMessage = 'No articles found.',
    this.adImageUrl,
  });

  final String title;
  final String? editionLabel;
  final String? rssUrl;
  final List<Article>? staticItems;
  final FeedService? feedService;
  final String emptyMessage;
  final String? adImageUrl;

  @override
  State<FeedListScreen> createState() => _FeedListScreenState();
}

class _FeedListScreenState extends State<FeedListScreen> {
  final _bookmarkService = BookmarkService();
  List<Article> _items = [];
  Map<String, Article> _bookmarks = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.staticItems != null) {
        _items = widget.staticItems!;
      } else if (widget.rssUrl != null && widget.feedService != null) {
        _items = await widget.feedService!.fetchFeed(widget.rssUrl!);
      }
      _bookmarks = await _bookmarkService.load();
    } catch (e) {
      _error = 'Feed unavailable.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleBookmark(Article a) async {
    await _bookmarkService.toggle(a.link, a);
    _bookmarks = await _bookmarkService.load();
    if (mounted) setState(() {});
  }

  void _openArticle(Article a) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ArticleReaderScreen(
        article: a,
        relatedRssUrl: widget.rssUrl,
        feedService: widget.feedService,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.editionLabel != null)
                    Text(widget.editionLabel!.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11, letterSpacing: 1.1, color: AppColors.accent, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 7),
                  Text(widget.title,
                      style: const TextStyle(fontFamily: 'Georgia', fontSize: 29, color: AppColors.accent, height: 1.08)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text('Loading…', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            )
          else if (_items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text(widget.emptyMessage, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final a = _items[i];
                    final card = ArticleCard(
                      article: a,
                      isBookmarked: _bookmarks.containsKey(a.link),
                      onTap: () => _openArticle(a),
                      onBookmarkTap: () => _toggleBookmark(a),
                    );
                    if (widget.adImageUrl != null && i > 0 && i % 5 == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [AdBanner(imageUrl: widget.adImageUrl!), card],
                      );
                    }
                    return card;
                  },
                  childCount: _items.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }
}
