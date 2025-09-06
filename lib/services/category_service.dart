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

  /// Load categories and their progress values.
  Future<CategoryResult> loadCategories() async {
    final allCards = await _repo.getAllFlashcards();
    final grouped = <String, List<Flashcard>>{};

    // Group by category, skipping General for now
    for (final card in allCards) {
      final cat = card.safeCategory;
      if (cat != "General") {
        grouped.putIfAbsent(cat, () => []);
        if (!card.safeIsPlaceholder) grouped[cat]!.add(card);
      }
    }

    // General = all non-placeholder cards
    grouped["General"] = allCards.where((c) => !c.safeIsPlaceholder).toList();

    // Load saved progress
    final prefs = await SharedPreferences.getInstance();
    final progress = <String, int>{
      for (final cat in grouped.keys) cat: prefs.getInt("progress_$cat") ?? 0
    };

    // Ensure General comes first
    final ordered = <String, List<Flashcard>>{};
    if (grouped.containsKey("General")) ordered["General"] = grouped["General"]!;
    grouped.keys.where((k) => k != "General").forEach((k) {
      ordered[k] = grouped[k]!;
    });

    return CategoryResult(ordered, progress);
  }

  /// Create a new category with a placeholder card.
  Future<void> createCategory(String name) async {
    await _repo.addCategoryPlaceholder(name);
  }

  /// Delete an entire category and its cards.
  Future<void> deleteCategory(String name) async {
    await _repo.deleteByCategory(name);
  }

  /// Save the progress (current index) for a category.
  Future<void> saveProgress(String category, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("progress_$category", index);
  }

  /// Load saved progress for a category.
  Future<int> loadProgress(String category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("progress_$category") ?? 0;
  }
}
