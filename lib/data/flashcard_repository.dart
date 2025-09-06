// repositories/flashcard_repository.dart
import 'package:hive/hive.dart';
import '../model/flashcard.dart';

/// Repository layer for managing flashcards in Hive.
/// Keeps all box-related operations in one place.
class FlashcardRepository {
  static const String boxName = "flashcardsBox";

  /// Opens the Hive box for flashcards.
  Future<Box<Flashcard>> _openBox() async {
    return await Hive.openBox<Flashcard>(boxName);
  }

  /// Adds a new flashcard to the box.
  Future<void> addFlashcard(Flashcard card) async {
    final box = await _openBox();
    await box.add(card);
  }

  /// Returns all flashcards stored in the box.
  Future<List<Flashcard>> getAllFlashcards() async {
    final box = await _openBox();
    return box.values.toList();
  }

  /// Deletes a flashcard by its key.
  Future<void> deleteFlashcard(int key) async {
    final box = await _openBox();
    await box.delete(key);
  }

  /// Clears all flashcards from the box.
  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}
