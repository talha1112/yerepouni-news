import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class BookmarkService {
  static const _key = 'yerepouni_bookmarks';

  Future<Map<String, Article>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, Article.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(Map<String, Article> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(bookmarks.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString(_key, raw);
  }

  Future<bool> isBookmarked(String url) async {
    final bookmarks = await load();
    return bookmarks.containsKey(url);
  }

  Future<bool> toggle(String url, Article article) async {
    final bookmarks = await load();
    bool nowOn;
    if (bookmarks.containsKey(url)) {
      bookmarks.remove(url);
      nowOn = false;
    } else {
      bookmarks[url] = article;
      nowOn = true;
    }
    await _save(bookmarks);
    return nowOn;
  }
}
