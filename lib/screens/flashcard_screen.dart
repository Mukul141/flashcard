// screens/flashcard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../model/flashcard.dart';
import '../widgets/flashcard_widget.dart';

/// Screen for viewing and managing a flashcard deck.
/// Supports flipping, swiping, shuffling, favorites, and progress tracking.
class FlashcardScreen extends StatefulWidget {
  final String category;

  const FlashcardScreen({super.key, required this.category});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  // ---------------------------------------------------------------------------
  // Local UI state (only for animations + answer toggle)
  // ---------------------------------------------------------------------------

  bool _showAnswer = false;
  Offset _cardOffset = Offset.zero;
  double _cardRotation = 0.0;

  @override
  void initState() {
    super.initState();
    // Load flashcards for the given category on startup
    Future.microtask(() {
      context.read<FlashcardProvider>().loadDeck(widget.category);
    });
  }

  /// Flips current card to show/hide answer.
  void _toggleAnswer() {
    setState(() => _showAnswer = !_showAnswer);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final flashcards = provider.flashcards;
    final currentIndex = provider.currentIndex;

    final size = MediaQuery.of(context).size;
    final progress = flashcards.isEmpty
        ? 0.0
        : (currentIndex / flashcards.length).clamp(0.0, 1.0);

    // Deck completed state
    if (flashcards.isNotEmpty && currentIndex >= flashcards.length) {
      return _deckCompleteView(provider, widget.category);
    }

    // Normal deck state
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(provider, flashcards, currentIndex),
      body: flashcards.isEmpty
          ? _emptyState()
          : Column(
        children: [
          _buildProgressBar(progress, flashcards.length, currentIndex),
          _buildDeck(size, flashcards, currentIndex, provider),
          const SizedBox(height: 20),
          _buildBottomButtons(flashcards, currentIndex, provider),
          const SizedBox(height: 30),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  AppBar _buildAppBar(
      FlashcardProvider provider, List<Flashcard> flashcards, int currentIndex) {
    final canEdit = flashcards.isNotEmpty && currentIndex < flashcards.length;
    final canShuffle = flashcards.length > 1 && currentIndex < flashcards.length;

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: Text(
        widget.category,
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
      ),
      leading: IconButton(
        icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
        tooltip: "Restart Deck",
        onPressed: () async {
          await provider.restartDeck(widget.category);
          setState(() {
            _showAnswer = false;
            _cardOffset = Offset.zero;
            _cardRotation = 0.0;
          });
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => _showAddDialog(provider),
        ),
        IconButton(
          icon: Icon(Icons.edit,
              color: canEdit
                  ? Theme.of(context).colorScheme.onPrimary
                  : Colors.grey.shade400),
          onPressed: canEdit
              ? () => _showEditDialog(provider, flashcards[currentIndex])
              : null,
        ),
        IconButton(
          icon: Icon(Icons.shuffle,
              color: canShuffle
                  ? Theme.of(context).colorScheme.onPrimary
                  : Colors.grey.shade400),
          onPressed:
          canShuffle ? () => provider.shuffleDeck(widget.category) : null,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // States
  // ---------------------------------------------------------------------------

  /// Empty deck state (no flashcards).
  Widget _emptyState() {
    return Center(
      child: Text(
        "No flashcards yet",
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: 20,
        ),
      ),
    );
  }

  /// Deck complete state (all cards reviewed).
  Scaffold _deckCompleteView(FlashcardProvider provider, String category) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(provider, provider.flashcards, provider.currentIndex),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Deck Complete!",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
              onPressed: () async {
                await provider.restartDeck(widget.category);
                setState(() {
                  _showAnswer = false;
                  _cardOffset = Offset.zero;
                  _cardRotation = 0.0;
                });
              },
              child: const Text("Restart Deck"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ---------------------------------------------------------------------------
  // Progress Bar
  // ---------------------------------------------------------------------------

  Widget _buildProgressBar(double value, int total, int currentIndex) {
    final completed = currentIndex.clamp(0, total);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              color: Theme.of(context).colorScheme.secondary,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "$completed/$total",
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Flashcard Deck
  // ---------------------------------------------------------------------------

  Widget _buildDeck(Size size, List<Flashcard> flashcards, int currentIndex,
      FlashcardProvider provider) {
    final topCardWidth = size.width * 0.85;
    final topCardHeight = size.height * 0.55;
    final backCardWidth = size.width * 0.8;
    final backCardHeight = size.height * 0.5;

    const maxPeekCards = 3; // show top card + 2 stacked behind

    return Expanded(
      child: Center(
        child: GestureDetector(
          onPanUpdate: (d) {
            if (currentIndex < flashcards.length) {
              setState(() {
                _cardOffset += d.delta;
                _cardRotation = _cardOffset.dx / 300;
              });
            }
          },
          onPanEnd: (_) {
            if (_cardOffset.dx.abs() > 100 || _cardOffset.dy.abs() > 100) {
              provider.nextCard(widget.category);
              setState(() {
                _cardOffset = Offset.zero;
                _cardRotation = 0.0;
                _showAnswer = false;
              });
            } else {
              setState(() {
                _cardOffset = Offset.zero;
                _cardRotation = 0.0;
              });
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: flashcards
                .asMap()
                .entries
                .where((entry) =>
            entry.key >= currentIndex &&
                entry.key < currentIndex + maxPeekCards)
                .map((entry) {
              final index = entry.key;
              final card = entry.value;
              final distance = index - currentIndex;
              final isTop = distance == 0;

              if (isTop) {
                // Top card (draggable)
                return Transform.translate(
                  offset: _cardOffset,
                  child: Transform.rotate(
                    angle: _cardRotation * pi / 12,
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          SizedBox(
                            width: topCardWidth,
                            height: topCardHeight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FlashcardWidget(
                                flashcard: card,
                                showAnswer: _showAnswer,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              icon: Icon(
                                card.safeFavorite
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.orange,
                              ),
                              onPressed: () => provider.toggleFavorite(
                                  card, widget.category),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // Peek cards (stacked behind)
                final topOffset = distance * 14.0;
                final scale = (1.0 - (distance * 0.05)).clamp(0.85, 0.95);
                return Positioned(
                  top: topOffset,
                  child: Transform.scale(
                    scale: scale,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.transparent,
                      child: SizedBox(
                        width: backCardWidth,
                        height: backCardHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: FlashcardWidget(
                              flashcard: card, showAnswer: false),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }).toList().reversed.toList(),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Controls
  // ---------------------------------------------------------------------------

  Widget _buildBottomButtons(
      List<Flashcard> flashcards, int currentIndex, FlashcardProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous card
        SizedBox(
          width: 80,
          height: 56,
          child: ElevatedButton(
            onPressed: (currentIndex > 0 && currentIndex < flashcards.length)
                ? provider.prevCard
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (currentIndex > 0 && currentIndex < flashcards.length)
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).disabledColor,
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.undo),
          ),
        ),
        const SizedBox(width: 20),
        // Toggle answer
        SizedBox(
          width: 80,
          height: 56,
          child: ElevatedButton(
            onPressed: (currentIndex < flashcards.length) ? _toggleAnswer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (currentIndex < flashcards.length)
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).disabledColor,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Icon(
              _showAnswer ? Icons.visibility_off : Icons.visibility,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Nav
  // ---------------------------------------------------------------------------

  BottomNavigationBar _bottomNav() {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (i) {
        if (i == 0) Navigator.pop(context);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.category), label: "Category"),
        BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: "Cards"),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  /// Add new flashcard dialog.
  Future<void> _showAddDialog(FlashcardProvider provider) async {
    final q = TextEditingController();
    final a = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Flashcard"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: q,
                decoration: const InputDecoration(labelText: "Question")),
            TextField(
                controller: a,
                decoration: const InputDecoration(labelText: "Answer")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (q.text.isNotEmpty && a.text.isNotEmpty) {
                await provider.addFlashcard(widget.category, q.text, a.text);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  /// Edit flashcard dialog (supports delete).
  Future<void> _showEditDialog(
      FlashcardProvider provider, Flashcard card) async {
    final q = TextEditingController(text: card.question);
    final a = TextEditingController(text: card.answer);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Flashcard"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: q,
                decoration: const InputDecoration(labelText: "Question")),
            TextField(
                controller: a,
                decoration: const InputDecoration(labelText: "Answer")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await provider.deleteFlashcard(card, widget.category);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.editFlashcard(card, q.text, a.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
