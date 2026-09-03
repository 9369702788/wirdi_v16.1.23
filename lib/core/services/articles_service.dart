
class IslamicArticle {
  final String id;
  final String title;
  final String content;
  final String author;
  final String category;
  final String publishDate;
  
  const IslamicArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.category,
    required this.publishDate,
  });
}

class ArticlesService {
  static const List<IslamicArticle> articles = [
    IslamicArticle(
      id: '1',
      title: 'Understanding Tawheed',
      content: 'Tawheed is the foundation of Islamic belief...',
      author: 'Islamic Scholar',
      category: 'Aqeedah',
      publishDate: '2024-01-01',
    ),
    IslamicArticle(
      id: '2',
      title: 'The Importance of Salah',
      content: 'Prayer is the pillar of Islam...',
      author: 'Islamic Scholar',
      category: 'Ibadah',
      publishDate: '2024-01-02',
    ),
  ];
  
  static Future<List<IslamicArticle>> getArticlesByCategory(String category) async {
    return articles.where((a) => a.category == category).toList();
  }
}
