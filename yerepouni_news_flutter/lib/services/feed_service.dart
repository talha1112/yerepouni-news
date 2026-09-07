import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/article.dart';

/// Set once at app startup from main.dart so [resolveImageUrl] can reach it
/// without threading FeedService through every widget that shows an image.
String feedProxyBaseUrl = 'http://localhost:3000';

/// On Flutter web, the browser blocks Yerepouni's images via CORS since that
/// server sends no Access-Control-Allow-Origin header. Route images through
/// the proxy's /api/image endpoint there; native platforms load them
/// directly.
String resolveImageUrl(String imageUrl) {
  if (imageUrl.isEmpty) return imageUrl;
  if (!kIsWeb) return imageUrl;
  final uri = Uri.parse('$feedProxyBaseUrl/api/image').replace(
    queryParameters: {'url': imageUrl},
  );
  return uri.toString();
}

/// Base URL of the existing Express proxy (server.js) that fetches and
/// parses Yerepouni RSS feeds. Point this at wherever that server is
/// deployed (e.g. https://your-domain.com or http://10.0.2.2:3000 for the
/// Android emulator talking to a locally running server).
class FeedService {
  FeedService({required this.proxyBaseUrl});

  final String proxyBaseUrl;

  Future<List<Article>> fetchFeed(String rssUrl) async {
    final uri = Uri.parse('$proxyBaseUrl/api/feed').replace(
      queryParameters: {'url': rssUrl},
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Feed unavailable');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List? ?? [])
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList();
    return items;
  }

  /// RSS feeds only expose a truncated excerpt as content. Fetch the full
  /// article HTML body from WordPress's REST API using the article's link.
  Future<String?> fetchFullArticleContent(String articleUrl) async {
    final uri = Uri.parse('$proxyBaseUrl/api/article').replace(
      queryParameters: {'url': articleUrl},
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['content'] as String?;
  }

  Future<List<Article>> search(String query) async {
    final uri = Uri.parse('$proxyBaseUrl/api/search').replace(
      queryParameters: {'q': query},
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Search unavailable');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List? ?? [])
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList();
    return items;
  }
}
