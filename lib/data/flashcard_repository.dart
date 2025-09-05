import 'package:hive/hive.dart';
import '../model/flashcard.dart';

class FlashcardRepository {
  static const String boxName = "flashcardsBox";

  Future<void> addFlashcard(Flashcard card) async {
    final box = await Hive.openBox<Flashcard>(boxName);
    await box.add(card);
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    final box = await Hive.openBox<Flashcard>(boxName);
    return box.values.toList();
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox<Flashcard>(boxName);
    await box.clear();
  }
}
