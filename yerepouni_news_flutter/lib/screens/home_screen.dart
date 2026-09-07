import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/article.dart';
import '../models/config.dart';
import '../services/bookmark_service.dart';
import '../services/feed_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/article_card.dart';
import 'article_reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.config,
    required this.feedService,
    required this.languageId,
    required this.languageLabel,
    required this.generalRssUrl,
    required this.onOpenToday,
  });

  final AppConfig config;
  final FeedService feedService;
  final String languageId;
  final String languageLabel;
  final String generalRssUrl;
  final VoidCallback onOpenToday;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bookmarkService = BookmarkService();

  List<Article> _items = [];
  bool _feedLoading = true;
  bool _feedError = false;
  Map<String, Article> _bookmarks = {};

  /// The featured hero article must match the selected language, so it's
  /// taken from the same per-language feed as the list below rather than
  /// the site-wide "mobile-home" feed (which mixes all languages together).
  Article? get _featured => _items.isNotEmpty ? _items.first : null;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generalRssUrl != widget.generalRssUrl) {
      _loadFeed();
    }
  }

  Future<void> _loadFeed() async {
    setState(() {
      _feedLoading = true;
      _feedError = false;
    });
    try {
      _items = await widget.feedService.fetchFeed(widget.generalRssUrl);
      _bookmarks = await _bookmarkService.load();
    } catch (_) {
      _feedError = true;
    }
    if (mounted) setState(() => _feedLoading = false);
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
        relatedRssUrl: widget.generalRssUrl,
        feedService: widget.feedService,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final restItems = _items.length > 1 ? _items.sublist(1) : <Article>[];

    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.languageLabel.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11, letterSpacing: 1.1, color: AppColors.accent, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _buildFeatured(),
                  const SizedBox(height: 20),
                  const Text('Latest News',
                      style: TextStyle(fontFamily: 'Georgia', fontSize: 22, color: AppColors.accent)),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          if (_feedLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text('Loading news…', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ),
            )
          else if (_feedError)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text('The live feed could not be loaded.', style: TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final a = restItems[i];
                    final card = ArticleCard(
                      article: a,
                      isBookmarked: _bookmarks.containsKey(a.link),
                      onTap: () => _openArticle(a),
                      onBookmarkTap: () => _toggleBookmark(a),
                    );
                    if (i > 0 && i % 5 == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [AdBanner(imageUrl: widget.config.brand.ad), card],
                      );
                    }
                    return card;
                  },
                  childCount: restItems.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              child: _TodayInHistoryCard(onTap: widget.onOpenToday),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatured() {
    if (_feedLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Loading featured news…', style: TextStyle(color: AppColors.muted, fontSize: 13)),
      );
    }
    if (_feedError || _featured == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Featured News could not be loaded.', style: TextStyle(color: AppColors.error, fontSize: 13)),
      );
    }
    final x = _featured!;

    return InkWell(
      onTap: () => _openArticle(x),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 280,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (x.image.isNotEmpty)
                Image.network(resolveImageUrl(x.image), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade400))
              else
                Container(color: Colors.grey.shade400),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 1],
                    colors: [Colors.transparent, const Color(0xE813091B)],
                  ),
                ),
              ),
              Positioned(
                left: 17,
                right: 17,
                bottom: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.lightAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(x.category.isNotEmpty ? x.category : 'Featured',
                          style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 7),
                    Text(x.title,
                        style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, color: Colors.white, height: 1.12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Text(formatDate(x.date), style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayInHistoryCard extends StatelessWidget {
  const _TodayInHistoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, Color(0xFF5E3A8C)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IN HISTORY TODAY',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: .3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Notable events, births and milestones from Armenian history on this date.',
                      style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFFF0E6F5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
