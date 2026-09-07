class AppLanguage {
  final String id;
  final String label;
  final String general;

  AppLanguage({required this.id, required this.label, required this.general});

  factory AppLanguage.fromJson(Map<String, dynamic> json) => AppLanguage(
        id: json['id'] ?? '',
        label: json['label'] ?? '',
        general: json['general'] ?? '',
      );
}

class NewsCategory {
  final String language;
  final String languageLabel;
  final String parent;
  final String name;
  final String url;
  final String rss;

  NewsCategory({
    required this.language,
    required this.languageLabel,
    required this.parent,
    required this.name,
    required this.url,
    required this.rss,
  });

  factory NewsCategory.fromJson(Map<String, dynamic> json) => NewsCategory(
        language: json['language'] ?? '',
        languageLabel: json['languageLabel'] ?? '',
        parent: json['parent'] ?? '',
        name: json['name'] ?? '',
        url: json['url'] ?? '',
        rss: json['rss'] ?? '',
      );

  String get displayName => name.isNotEmpty ? name : parent;
}

class Brand {
  final String accent;
  final String lightAccent;
  final String logo;
  final String ad;

  Brand({required this.accent, required this.lightAccent, required this.logo, required this.ad});

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        accent: json['accent'] ?? '#482B6F',
        lightAccent: json['lightAccent'] ?? '#FFCAC5',
        logo: json['logo'] ?? '',
        ad: json['ad'] ?? '',
      );
}

class AppConfig {
  final Brand brand;
  final List<AppLanguage> languages;
  final String featured;
  final String todayInHistory;
  final List<NewsCategory> categories;
  final String contact;
  final String website;
  final String facebook;

  AppConfig({
    required this.brand,
    required this.languages,
    required this.featured,
    required this.todayInHistory,
    required this.categories,
    required this.contact,
    required this.website,
    required this.facebook,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        brand: Brand.fromJson(json['brand'] ?? {}),
        languages: (json['languages'] as List? ?? [])
            .map((e) => AppLanguage.fromJson(e))
            .toList(),
        featured: json['featured'] ?? '',
        todayInHistory: json['todayInHistory'] ?? '',
        categories: (json['categories'] as List? ?? [])
            .map((e) => NewsCategory.fromJson(e))
            .toList(),
        contact: json['contact'] ?? '',
        website: json['website'] ?? '',
        facebook: json['facebook'] ?? '',
      );

  List<NewsCategory> categoriesFor(String lang) =>
      categories.where((c) => c.language == lang).toList();
}
