class Article {
  final String title;
  final String link;
  final String date;
  final String excerpt;
  final String content;
  final String category;
  final String image;

  Article({
    required this.title,
    required this.link,
    required this.date,
    required this.excerpt,
    required this.content,
    required this.category,
    required this.image,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        title: json['title'] ?? '',
        link: json['link'] ?? '',
        date: json['date'] ?? '',
        excerpt: json['excerpt'] ?? '',
        content: json['content'] ?? '',
        category: json['category'] ?? '',
        image: json['image'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'link': link,
        'date': date,
        'excerpt': excerpt,
        'content': content,
        'category': category,
        'image': image,
      };
}
