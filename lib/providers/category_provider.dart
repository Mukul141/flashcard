// providers/category_provider.dart
import 'package:flutter/material.dart';
import '../model/flashcard.dart';
import '../services/category_service.dart';

/// Provider for managing categories and progress state.
/// Wraps [CategoryService] and exposes data to the UI with [ChangeNotifier].
class CategoryProvider extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  Map<String, List<Flashcard>> _categories = {};
  Map<String, int> _progress = {};

  /// Public getters for UI.
  Map<String, List<Flashcard>> get categories => _categories;
  Map<String, int> get progress => _progress;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Constructor automatically loads categories on startup.
  CategoryProvider() {
    load();
  }

  // ---------------------------------------------------------------------------
  // Data Loading
  // ---------------------------------------------------------------------------

  /// Loads categories and progress from [CategoryService].
  Future<void> load() async {
    final result = await _service.loadCategories();
    _categories = result.categories;
    _progress = result.progress;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Category Management
  // ---------------------------------------------------------------------------

  /// Creates a new category and refreshes state.
  Future<void> createCategory(String name) async {
    await _service.createCategory(name);
    await load();
  }

  /// Deletes a category and refreshes state.
  Future<void> deleteCategory(String name) async {
    await _service.deleteCategory(name);
    await load();
  }

  // ---------------------------------------------------------------------------
  // Progress Tracking
  // ---------------------------------------------------------------------------

  /// Saves progress for a category and updates local state.
  Future<void> saveProgress(String category, int index) async {
    await _service.saveProgress(category, index);
    _progress[category] = index;
    notifyListeners();
  }
}
