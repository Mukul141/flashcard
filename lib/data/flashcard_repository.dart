// repositories/flashcard_repository.dart
import 'package:hive/hive.dart';
import '../model/flashcard.dart';

/// Repository for managing flashcards in Hive.
/// Encapsulates all direct Hive box operations (CRUD + helpers).
class FlashcardRepository {
  static const String boxName = "flashcardsBox";

  /// Opens the Hive box for flashcards.
  Future<Box<Flashcard>> _openBox() async {
    return await Hive.openBox<Flashcard>(boxName);
  }

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  /// Adds a new flashcard to the box.
  Future<void> addFlashcard(Flashcard card) async {
    final box = await _openBox();
    await box.add(card);
  }

  /// Adds a placeholder flashcard so a new category appears immediately.
  Future<void> addCategoryPlaceholder(String name) async {
    final box = await _openBox();
    await box.add(
      Flashcard(
        question: "placeholder",
        answer: "placeholder",
        category: name,
        isPlaceholder: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns all flashcards.
  Future<List<Flashcard>> getAllFlashcards() async {
    final box = await _openBox();
    return box.values.toList();
  }

  /// Returns flashcards for a specific category.
  /// - "Favorites": only cards marked as favorite (ignores placeholders).
  /// - "General": all cards except placeholders.
  /// - Custom category: cards matching that category (ignores placeholders).
  Future<List<Flashcard>> getByCategory(String category) async {
    final box = await _openBox();
    final normalized = category.toLowerCase();

    if (normalized == "favorites") {
      return box.values
          .where((c) => c.safeFavorite && !c.safeIsPlaceholder)
          .toList();
    } else if (normalized == "general") {
      return box.values.where((c) => !c.safeIsPlaceholder).toList();
    } else {
      return box.values
          .where((c) =>
      c.safeCategory.toLowerCase() == normalized &&
          !c.safeIsPlaceholder)
          .toList();
    }
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  /// Persists changes to an existing flashcard.
  Future<void> updateFlashcard(Flashcard card) async {
    await card.save();
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  /// Deletes a single flashcard by key.
  Future<void> deleteFlashcard(int key) async {
    final box = await _openBox();
    await box.delete(key);
  }

  /// Deletes all flashcards in the given category.
  Future<void> deleteByCategory(String category) async {
    final box = await _openBox();
    final normalized = category.toLowerCase();

    final keysToDelete = box.keys
        .where((k) => box.get(k)!.safeCategory.toLowerCase() == normalized)
        .toList();

    await box.deleteAll(keysToDelete);
  }

  /// Clears the entire flashcards box.
  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}
