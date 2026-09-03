
class PronunciationGuide {
  final String word;
  final String arabicText;
  final String transliteration;
  final String audioUrl;
  final String meaning;
  
  const PronunciationGuide({
    required this.word,
    required this.arabicText,
    required this.transliteration,
    required this.audioUrl,
    required this.meaning,
  });
}

class PronunciationService {
  static Future<PronunciationGuide> getWordPronunciation(String word) async {
    return PronunciationGuide(
      word: word,
      arabicText: word,
      transliteration: 'transliteration',
      audioUrl: 'assets/audio/word.mp3',
      meaning: 'meaning',
    );
  }
}
