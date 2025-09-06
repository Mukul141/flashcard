// providers/category_provider.dart
import 'package:flutter/material.dart';
import '../model/flashcard.dart';
import '../services/category_service.dart';

/// Provider for managing categories and their progress.
class CategoryProvider extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  Map<String, List<Flashcard>> _categories = {};
  Map<String, int> _progress = {};

  Map<String, List<Flashcard>> get categories => _categories;
  Map<String, int> get progress => _progress;

  /// Constructor automatically loads categories on startup.
  CategoryProvider() {
    load(); // ✅ trigger data load immediately
  }

  /// Loads categories and progress.
  Future<void> load() async {
    final result = await _service.loadCategories();
    _categories = result.categories;
    _progress = result.progress;
    notifyListeners();
  }

  /// Creates a new category.
  Future<void> createCategory(String name) async {
    await _service.createCategory(name);
    await load();
  }

  /// Deletes an existing category.
  Future<void> deleteCategory(String name) async {
    await _service.deleteCategory(name);
    await load();
  }

  /// Saves current progress for a category.
  Future<void> saveProgress(String category, int index) async {
    await _service.saveProgress(category, index);
    _progress[category] = index;
    notifyListeners();
  }
}
