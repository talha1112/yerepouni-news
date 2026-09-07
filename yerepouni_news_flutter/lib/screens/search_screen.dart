import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../services/feed_service.dart';
import '../widgets/article_card.dart';
import '../widgets/search_loading.dart';
import 'article_reader_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.feedService});

  final FeedService feedService;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _bookmarkService = BookmarkService();
  Timer? _debounce;

  // Yerepouni's WordPress search endpoint is slow (10s+) regardless of
  // paging/field params — that latency lives entirely on their server.
  // Caching results client-side at least makes repeat searches instant,
  // and a longer debounce avoids firing several of these slow requests
  // back-to-back while the user is still typing.
  static final Map<String, List<Article>> _cache = {};

  List<Article> _results = [];
  Map<String, Article> _bookmarks = {};
  bool _loading = false;
  bool _searched = false;
  String? _error;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _error = null;
      });
      return;
    }
    final cached = _cache[query];
    if (cached != null) {
      setState(() {
        _results = cached;
        _searched = true;
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final results = await widget.feedService.search(query);
      _cache[query] = results;
      _bookmarks = await _bookmarkService.load();
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = 'Search failed. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _toggleBookmark(Article a) async {
    await _bookmarkService.toggle(a.link, a);
    _bookmarks = await _bookmarkService.load();
    if (mounted) setState(() {});
  }

  void _openArticle(Article a) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleReaderScreen(article: a)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          onSubmitted: (v) {
            final q = v.trim();
            if (q.isNotEmpty) _runSearch(q);
          },
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Search Yerepouni News',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_searched) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Type to search articles.', style: TextStyle(color: AppColors.muted)),
        ),
      );
    }
    if (_loading) {
      return const SearchLoading();
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)));
    }
    if (_results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No articles found.', style: TextStyle(color: AppColors.muted)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final a = _results[i];
        return ArticleCard(
          article: a,
          isBookmarked: _bookmarks.containsKey(a.link),
          onTap: () => _openArticle(a),
          onBookmarkTap: () => _toggleBookmark(a),
        );
      },
    );
  }
}
