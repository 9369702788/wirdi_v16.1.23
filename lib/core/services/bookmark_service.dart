import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bookmark_models.dart';

class BookmarkService {
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
  BookmarkService._();

  static const _prefsKey = 'advanced_bookmarks_v1';
  static const List<String> categories = ['ramadan', 'dua', 'family', 'study', 'personal', 'other'];

  static Future<List<BookmarkEntry>> allBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final list = decoded.map((e) => BookmarkEntry.fromJson(e as Map<String, dynamic>)).toList();
    list.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    return list;
  }

  static Future<void> addBookmark({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    required String ayahText,
    required String note,
    required String category,
  }) async {
    final bookmarks = await allBookmarks();
    bookmarks.add(BookmarkEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      surahNumber: surahNumber,
      surahName: surahName,
      ayahNumber: ayahNumber,
      ayahText: ayahText,
      note: note,
      category: category,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    ));
    await _save(bookmarks);
  }

  static Future<void> deleteBookmark(String id) async {
    final bookmarks = await allBookmarks();
    bookmarks.removeWhere((b) => b.id == id);
    await _save(bookmarks);
  }

  static Future<void> _save(List<BookmarkEntry> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(bookmarks.map((b) => b.toJson()).toList()));
  }
}
