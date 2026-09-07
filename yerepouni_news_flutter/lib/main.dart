import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'models/config.dart';
import 'services/config_service.dart';
import 'services/feed_service.dart';
import 'screens/root_shell.dart';

/// Base URL of the Yerepouni feed proxy (see yerepouni-news-app/server.js).
/// Change this to wherever that Express server is deployed.
/// - Android emulator talking to a proxy on your dev machine: http://10.0.2.2:3000
/// - iOS simulator talking to a proxy on your dev machine: http://localhost:3000
/// - Production: your deployed server's URL, e.g. https://api.yerepouni-news.com
const String kFeedProxyBaseUrl = String.fromEnvironment(
  'FEED_PROXY_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

void main() {
  runApp(const YerepouniApp());
}

class YerepouniApp extends StatelessWidget {
  const YerepouniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yerepouni News',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AppLoader(),
    );
  }
}

class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  late Future<AppConfig> _configFuture;

  @override
  void initState() {
    super.initState();
    _configFuture = ConfigService.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppConfig>(
      future: _configFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Failed to load app configuration.')),
          );
        }
        final config = snapshot.data!;
        feedProxyBaseUrl = kFeedProxyBaseUrl;
        final feedService = FeedService(proxyBaseUrl: kFeedProxyBaseUrl);
        return RootShell(config: config, feedService: feedService);
      },
    );
  }
}
