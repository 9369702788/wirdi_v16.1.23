
class FatwaRuling {
  final String question;
  final String answer;
  final String scholar;
  final String source;
  final String category;
  
  const FatwaRuling({
    required this.question,
    required this.answer,
    required this.scholar,
    required this.source,
    required this.category,
  });
}

class FatwaService {
  static Future<List<FatwaRuling>> getFatwaByCategory(String category) async {
    return [];
  }
}
