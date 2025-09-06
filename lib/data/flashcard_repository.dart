// repositories/flashcard_repository.dart
import 'package:hive/hive.dart';
import '../model/flashcard.dart';

/// Repository for managing flashcards in Hive.
/// Encapsulates all direct Hive box operations (CRUD + helpers).
class FlashcardRepository {
  static const String boxName = "flashcardsBox";

  /// Opens the Hive box.
  Future<Box<Flashcard>> _openBox() async {
    return await Hive.openBox<Flashcard>(boxName);
  }

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  /// Adds a new flashcard.
  Future<void> addFlashcard(Flashcard card) async {
    final box = await _openBox();
    await box.add(card);
  }

  /// Adds a placeholder flashcard for a new category (so it shows up immediately).
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

  /// Returns all flashcards stored in the box.
  Future<List<Flashcard>> getAllFlashcards() async {
    final box = await _openBox();
    return box.values.toList();
  }

  /// Returns flashcards for a specific category.
  Future<List<Flashcard>> getByCategory(String category) async {
    final box = await _openBox();

    if (category.toLowerCase() == "favorites") {
      return box.values
          .where((c) => c.safeFavorite && !c.safeIsPlaceholder)
          .toList();
    } else if (category.toLowerCase() == "general") {
      return box.values
          .where((c) => !c.safeIsPlaceholder)
          .toList();
    } else {
      return box.values
          .where((c) =>
      c.safeCategory.toLowerCase() == category.toLowerCase() &&
          !c.safeIsPlaceholder)
          .toList();
    }
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  /// Updates an existing flashcard (after modifying fields, just call `card.save()`).
  Future<void> updateFlashcard(Flashcard card) async {
    await card.save();
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  /// Deletes a single flashcard by its Hive key.
  Future<void> deleteFlashcard(int key) async {
    final box = await _openBox();
    await box.delete(key);
  }

  /// Deletes all flashcards belonging to a given category.
  Future<void> deleteByCategory(String category) async {
    final box = await _openBox();
    final keysToDelete = box.keys
        .where((k) => box.get(k)!.safeCategory.toLowerCase() == category.toLowerCase())
        .toList();
    await box.deleteAll(keysToDelete);
  }

  /// Clears the entire box.
  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}
