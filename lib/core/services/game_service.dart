
class MemorizationGame {
  final String gameType;
  final int surah;
  final int difficulty;
  final List<String> questions;
  
  const MemorizationGame({
    required this.gameType,
    required this.surah,
    required this.difficulty,
    required this.questions,
  });
}

class GameService {
  static Future<MemorizationGame> generateQuiz(int surah) async {
    return MemorizationGame(
      gameType: 'quiz',
      surah: surah,
      difficulty: 3,
      questions: [],
    );
  }
}
