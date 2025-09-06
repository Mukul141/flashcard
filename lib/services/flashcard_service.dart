// services/flashcard_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../model/flashcard.dart';
import '../data/flashcard_repository.dart';

/// Holds deck + progress for a category.
class DeckResult {
  final List<Flashcard> cards;
  final int index;

  DeckResult(this.cards, this.index);
}

class FlashcardService {
  final FlashcardRepository _repo = FlashcardRepository();

  /// Loads deck (with saved order + progress).
  Future<DeckResult> loadDeck(String category) async {
    final cards = await _repo.getByCategory(category);

    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt("progress_$category") ?? 0;

    final savedOrder = prefs.getStringList("order_$category");
    if (savedOrder != null && savedOrder.isNotEmpty && category.toLowerCase() != "favorites") {
      final byKey = {for (final c in cards) (c.key as int): c};
      final ordered = <Flashcard>[];
      for (final k in savedOrder.map(int.parse)) {
        final c = byKey[k];
        if (c != null) ordered.add(c);
      }
      for (final c in cards) {
        if (!savedOrder.contains((c.key as int).toString())) ordered.add(c);
      }
      return DeckResult(ordered, savedIndex.clamp(0, ordered.length));
    }

    return DeckResult(cards, savedIndex.clamp(0, cards.length));
  }

  Future<void> saveProgress(String category, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("progress_$category", index);
  }

  Future<void> saveOrder(String category, List<Flashcard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final order = cards.map((c) => (c.key as int).toString()).toList();
    await prefs.setStringList("order_$category", order);
  }

  Future<void> saveLastCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lastCategory", category);
  }
}
