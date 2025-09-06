// services/flashcard_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../model/flashcard.dart';
import '../data/flashcard_repository.dart';

/// Holds a deck of flashcards and the current progress index.
class DeckResult {
  final List<Flashcard> cards;
  final int index;

  DeckResult(this.cards, this.index);
}

/// Service layer for managing flashcard decks, progress, and order.
/// Delegates persistence to [FlashcardRepository].
class FlashcardService {
  final FlashcardRepository _repo = FlashcardRepository();

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  /// Loads a deck for a given [category], applying saved progress and order if available.
  Future<DeckResult> loadDeck(String category) async {
    final cards = await _repo.getByCategory(category);

    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt("progress_$category") ?? 0;

    // Restore saved order (not for Favorites, since that list changes dynamically)
    final savedOrder = prefs.getStringList("order_$category");
    if (savedOrder != null &&
        savedOrder.isNotEmpty &&
        category.toLowerCase() != "favorites") {
      final byKey = {for (final c in cards) (c.key as int): c};
      final ordered = <Flashcard>[];

      // Add saved cards in saved order
      for (final k in savedOrder.map(int.parse)) {
        final c = byKey[k];
        if (c != null) ordered.add(c);
      }

      // Add any new cards not in the saved order
      for (final c in cards) {
        if (!savedOrder.contains((c.key as int).toString())) {
          ordered.add(c);
        }
      }

      return DeckResult(ordered, savedIndex.clamp(0, ordered.length));
    }

    return DeckResult(cards, savedIndex.clamp(0, cards.length));
  }

  // ---------------------------------------------------------------------------
  // Save Progress / Order
  // ---------------------------------------------------------------------------

  /// Saves the current progress index for a category.
  Future<void> saveProgress(String category, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("progress_$category", index);
  }

  /// Saves the order of cards for a category.
  Future<void> saveOrder(String category, List<Flashcard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final order = cards.map((c) => (c.key as int).toString()).toList();
    await prefs.setStringList("order_$category", order);
  }

  // ---------------------------------------------------------------------------
  // Last Category
  // ---------------------------------------------------------------------------

  /// Saves the last opened category (for restoring session on app restart).
  Future<void> saveLastCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lastCategory", category);
  }
}
