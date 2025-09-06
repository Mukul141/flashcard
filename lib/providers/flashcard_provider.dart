// providers/flashcard_provider.dart
import 'package:flutter/material.dart';
import '../model/flashcard.dart';
import '../services/flashcard_service.dart';
import '../data/flashcard_repository.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardService _service = FlashcardService();
  final FlashcardRepository _repo = FlashcardRepository();

  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;

  List<Flashcard> get flashcards => _flashcards;
  int get currentIndex => _currentIndex;

  Future<void> loadDeck(String category) async {
    final result = await _service.loadDeck(category);
    _flashcards = result.cards;
    _currentIndex = result.index;
    notifyListeners();
  }

  Future<void> nextCard(String category) async {
    if (_currentIndex < _flashcards.length) {
      _currentIndex++;
      await _service.saveProgress(category, _currentIndex);
      notifyListeners();
    }
  }

  /// Restarts a deck by resetting progress and reloading.
  Future<void> restartDeck(String category) async {
    // reset stored progress in SharedPreferences (via service)
    await _service.saveProgress(category, 0);

    // reset provider internal index
    _currentIndex = 0;

    // reload deck (loadDeck reads the saved progress — now 0)
    await loadDeck(category);

    // notify UI
    notifyListeners();
  }

  void prevCard() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  Future<void> shuffleDeck(String category) async {
    final seen = _flashcards.sublist(0, _currentIndex);
    final remaining = _flashcards.sublist(_currentIndex);
    remaining.shuffle();
    _flashcards = [...seen, ...remaining];
    await _service.saveOrder(category, _flashcards);
    notifyListeners();
  }

  Future<void> addFlashcard(String category, String q, String a) async {
    final card = Flashcard(question: q, answer: a, category: category);
    await _repo.addFlashcard(card);
    await loadDeck(category);
  }

  Future<void> editFlashcard(Flashcard card, String q, String a) async {
    card.question = q;
    card.answer = a;
    await _repo.updateFlashcard(card);
    notifyListeners();
  }

  Future<void> deleteFlashcard(Flashcard card, String category) async {
    await _repo.deleteFlashcard(card.key as int);
    await loadDeck(category);
  }

  Future<void> toggleFavorite(Flashcard card, String category) async {
    card.isFavorite = !card.safeFavorite;
    await _repo.updateFlashcard(card);
    await loadDeck(category);
  }
}
