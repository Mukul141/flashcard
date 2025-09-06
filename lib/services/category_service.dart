// services/category_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../model/flashcard.dart';
import '../data/flashcard_repository.dart';

/// Holds both categories and their progress counts.
class CategoryResult {
  final Map<String, List<Flashcard>> categories;
  final Map<String, int> progress;

  CategoryResult(this.categories, this.progress);
}

/// Service layer for managing categories and progress.
/// Uses the repository for persistence, keeps business logic here.
class CategoryService {
  final FlashcardRepository _repo = FlashcardRepository();

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  /// Load categories and their progress values.
  /// - Groups flashcards into categories
  /// - Creates virtual "General" and "Favorites"
  /// - Loads saved progress from SharedPreferences
  Future<CategoryResult> loadCategories() async {
    final allCards = await _repo.getAllFlashcards();
    final grouped = <String, List<Flashcard>>{};

    // Group by category (excluding "General" and "Favorites")
    for (final card in allCards) {
      final cat = card.safeCategory;
      if (cat != "General" && cat != "Favorites") {
        grouped.putIfAbsent(cat, () => []);
        if (!card.safeIsPlaceholder) grouped[cat]!.add(card);
      }
    }

    // General = all non-placeholder cards
    grouped["General"] = allCards.where((c) => !c.safeIsPlaceholder).toList();

    // Favorites = all cards marked as favorite
    grouped["Favorites"] = allCards
        .where((c) => c.safeFavorite && !c.safeIsPlaceholder)
        .toList();

    // Load saved progress
    final prefs = await SharedPreferences.getInstance();
    final progress = <String, int>{
      for (final cat in grouped.keys) cat: prefs.getInt("progress_$cat") ?? 0
    };

    // Ensure display order: General → Favorites → user categories
    final ordered = <String, List<Flashcard>>{};
    if (grouped.containsKey("General")) {
      ordered["General"] = grouped["General"]!;
    }
    if (grouped.containsKey("Favorites")) {
      ordered["Favorites"] = grouped["Favorites"]!;
    }
    grouped.keys.where((k) => k != "General" && k != "Favorites").forEach((k) {
      ordered[k] = grouped[k]!;
    });

    return CategoryResult(ordered, progress);
  }

  // ---------------------------------------------------------------------------
  // Create / Delete
  // ---------------------------------------------------------------------------

  /// Create a new category with a placeholder card
  /// (ensures it shows up immediately in the UI).
  Future<void> createCategory(String name) async {
    await _repo.addCategoryPlaceholder(name);
  }

  /// Delete an entire category and its flashcards.
  Future<void> deleteCategory(String name) async {
    await _repo.deleteByCategory(name);
  }

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  /// Save the progress (current card index) for a category.
  Future<void> saveProgress(String category, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("progress_$category", index);
  }

  /// Load the saved progress (defaults to 0 if none found).
  Future<int> loadProgress(String category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("progress_$category") ?? 0;
  }
}
