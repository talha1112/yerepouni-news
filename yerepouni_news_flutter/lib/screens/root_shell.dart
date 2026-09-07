import 'package:flutter/material.dart';
import '../models/article.dart';
import '../models/config.dart';
import '../services/bookmark_service.dart';
import '../services/feed_service.dart';
import '../widgets/app_drawer.dart';
import 'feed_list_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';

enum _Tab { home, latest, saved }

class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.config, required this.feedService});

  final AppConfig config;
  final FeedService feedService;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _bookmarkService = BookmarkService();

  _Tab _tab = _Tab.home;
  late String _langId;
  NewsCategory? _overrideCategory;
  int _bookmarksRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _langId = widget.config.languages.isNotEmpty ? widget.config.languages.first.id : 'western';
  }

  String get _langLabel =>
      widget.config.languages.firstWhere((l) => l.id == _langId, orElse: () => widget.config.languages.first).label;

  String get _generalRssForLang =>
      widget.config.languages.firstWhere((l) => l.id == _langId, orElse: () => widget.config.languages.first).general;

  void _selectLanguage(String id) {
    setState(() {
      _langId = id;
      _overrideCategory = null;
      _tab = _Tab.home;
    });
  }

  void _openCategory(NewsCategory c) {
    Navigator.of(context).pop(); // close drawer
    setState(() {
      _overrideCategory = c;
      _tab = _Tab.latest;
    });
  }

  void _openToday() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Today in History')),
        body: FeedListScreen(
          title: 'ՊԱՏՄՈՒԹԵԱՆ ՄԷՋ ԱՅՍՕՐ',
          rssUrl: widget.config.todayInHistory,
          feedService: widget.feedService,
          adImageUrl: widget.config.brand.ad,
        ),
      ),
    ));
  }

  void _openTodayFromDrawer() {
    Navigator.of(context).pop();
    _openToday();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 74,
        leadingWidth: 58,
        leading: IconButton(
          icon: const Icon(Icons.menu, size: 25),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: widget.config.brand.logo.isNotEmpty
            ? Image.network(resolveImageUrl(widget.config.brand.logo), height: 48, errorBuilder: (_, __, ___) => const Text('Yerepouni News'))
            : const Text('Yerepouni News'),
        centerTitle: true,
        actions: [
          SizedBox(
            width: 58,
            child: IconButton(
              icon: const Icon(Icons.search, size: 25),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SearchScreen(feedService: widget.feedService)),
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        config: widget.config,
        onSelectCategory: _openCategory,
        onSelectLanguage: _selectLanguage,
        onOpenToday: _openTodayFromDrawer,
      ),
      body: IndexedStack(
        index: _tab.index,
        children: [
          HomeScreen(
            key: ValueKey('home_$_langId'),
            config: widget.config,
            feedService: widget.feedService,
            languageId: _langId,
            languageLabel: _langLabel,
            generalRssUrl: _generalRssForLang,
            onOpenToday: _openToday,
          ),
          FeedListScreen(
            key: ValueKey('latest_${_overrideCategory?.rss ?? _generalRssForLang}'),
            title: _overrideCategory?.displayName ?? 'Latest News',
            editionLabel: _overrideCategory?.languageLabel ?? _langLabel,
            rssUrl: _overrideCategory?.rss ?? _generalRssForLang,
            feedService: widget.feedService,
            adImageUrl: widget.config.brand.ad,
          ),
          FutureBuilder<Map<String, Article>>(
            key: ValueKey('bookmarks_$_bookmarksRefreshToken'),
            future: _bookmarkService.load(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return FeedListScreen(
                title: 'Saved Articles',
                staticItems: snapshot.data!.values.toList(),
                emptyMessage: 'No saved articles yet. Tap ☆ on any article to save it.',
                adImageUrl: widget.config.brand.ad,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: (i) {
          setState(() {
            _tab = _Tab.values[i];
            if (_tab != _Tab.latest) _overrideCategory = null;
            if (_tab == _Tab.saved) _bookmarksRefreshToken++;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.article_outlined), selectedIcon: Icon(Icons.article), label: 'Latest'),
          NavigationDestination(icon: Icon(Icons.star_border), selectedIcon: Icon(Icons.star), label: 'Saved'),
        ],
      ),
    );
  }
}
