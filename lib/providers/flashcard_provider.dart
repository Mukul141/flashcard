// providers/flashcard_provider.dart
import 'package:flutter/material.dart';
import '../model/flashcard.dart';
import '../services/flashcard_service.dart';
import '../data/flashcard_repository.dart';

/// Provider for managing a deck of flashcards.
/// Handles navigation, shuffling, CRUD, and sync with [FlashcardService].
class FlashcardProvider extends ChangeNotifier {
  final FlashcardService _service = FlashcardService();
  final FlashcardRepository _repo = FlashcardRepository();

  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;

  /// Exposed state for UI.
  List<Flashcard> get flashcards => _flashcards;
  int get currentIndex => _currentIndex;

  // ---------------------------------------------------------------------------
  // Deck Lifecycle
  // ---------------------------------------------------------------------------

  /// Loads a deck for a given [category].
  Future<void> loadDeck(String category) async {
    final result = await _service.loadDeck(category);
    _flashcards = result.cards;
    _currentIndex = result.index;
    notifyListeners();
  }

  /// Restarts a deck by resetting progress and reloading.
  Future<void> restartDeck(String category) async {
    await _service.saveProgress(category, 0); // reset persisted progress
    _currentIndex = 0;                        // reset local index
    await loadDeck(category);                 // reload fresh
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  /// Moves to the next card and saves progress.
  Future<void> nextCard(String category) async {
    if (_currentIndex < _flashcards.length) {
      _currentIndex++;
      await _service.saveProgress(category, _currentIndex);
      notifyListeners();
    }
  }

  /// Moves back to the previous card.
  void prevCard() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Deck Management
  // ---------------------------------------------------------------------------

  /// Shuffles the remaining cards while keeping seen cards in place.
  Future<void> shuffleDeck(String category) async {
    final seen = _flashcards.sublist(0, _currentIndex);
    final remaining = _flashcards.sublist(_currentIndex);
    remaining.shuffle();
    _flashcards = [...seen, ...remaining];
    await _service.saveOrder(category, _flashcards);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CRUD Operations
  // ---------------------------------------------------------------------------

  /// Adds a new flashcard to a [category].
  Future<void> addFlashcard(String category, String q, String a) async {
    final card = Flashcard(question: q, answer: a, category: category);
    await _repo.addFlashcard(card);
    await loadDeck(category);
  }

  /// Updates an existing flashcard.
  Future<void> editFlashcard(Flashcard card, String q, String a) async {
    card.question = q;
    card.answer = a;
    await _repo.updateFlashcard(card);
    notifyListeners();
  }

  /// Deletes a flashcard and refreshes the deck.
  Future<void> deleteFlashcard(Flashcard card, String category) async {
    await _repo.deleteFlashcard(card.key as int);
    await loadDeck(category);
  }

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------

  /// Toggles favorite state for a flashcard and reloads deck.
  Future<void> toggleFavorite(Flashcard card, String category) async {
    card.isFavorite = !card.safeFavorite;
    await _repo.updateFlashcard(card);
    await loadDeck(category);
  }
}
