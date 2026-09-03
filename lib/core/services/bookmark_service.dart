class BookmarkedAyah {
  final int surah;
  final int ayah;
  final String text;
  final String surahName;
  final List<String> tags;
  final DateTime dateAdded;
  
  BookmarkedAyah({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.surahName,
    required this.tags,
    required this.dateAdded,
  });
}

class BookmarkService {
  static Future<List<BookmarkedAyah>> getAll() async {
    return [];
  }
  
  static Future<List<BookmarkedAyah>> searchBookmarks(String query) async {
    final all = await getAll();
    return all.where((b) {
      return b.text.toLowerCase().contains(query.toLowerCase()) ||
             b.surahName.toLowerCase().contains(query.toLowerCase()) ||
             b.tags.any((t) => t.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }
  
  static Future<List<BookmarkedAyah>> filterByTags(List<String> tags) async {
    final all = await getAll();
    if (tags.isEmpty) return all;
    return all.where((b) => tags.any((tag) => b.tags.contains(tag))).toList();
  }
  
  static Future<void> createCategory(String categoryName) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = prefs.getStringList('bookmark_categories') ?? [];
    if (!categories.contains(categoryName)) {
      categories.add(categoryName);
      await prefs.setStringList('bookmark_categories', categories);
    }
  }
  
  static Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('bookmark_categories') ?? [];
  }
  
  static Future<void> addColorToCategory(String categoryName, String colorHex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('color_\${categoryName}', colorHex);
  }
  
  static Future<String> getCategoryColor(String categoryName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('color_\${categoryName}') ?? '#FF6200';
  }
}
