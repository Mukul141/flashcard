import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/flashcard.dart';
import '../widgets/flashcard_widget.dart';

class FlashcardScreen extends StatefulWidget {
  final String category;

  const FlashcardScreen({super.key, required this.category});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  static const String boxName = "flashcardsBox";
  late Box<Flashcard> _box;

  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;

  Offset _cardOffset = Offset.zero;
  double _cardRotation = 0.0;

  String get _kProgress => "progress_${widget.category}";
  String get _kOrder => "order_${widget.category}";
  String get _kLastCategory => "lastCategory";

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showAnswer = false;
      });
    }
  }

  Future<void> _nextCard() async {
    if (_currentIndex < _flashcards.length) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
        _cardOffset = Offset.zero;
        _cardRotation = 0.0;
      });
      await _saveProgress();
    }
  }

  void _toggleAnswer() {
    setState(() => _showAnswer = !_showAnswer);
  }

  Future<void> _shuffleCards() async {
    if (_flashcards.isEmpty || _currentIndex >= _flashcards.length) return;

    setState(() {
      final seen = _flashcards.sublist(0, _currentIndex);
      final remaining = _flashcards.sublist(_currentIndex);
      remaining.shuffle();
      _flashcards = [...seen, ...remaining];
      _showAnswer = false;
      _cardOffset = Offset.zero;
      _cardRotation = 0.0;
    });

    await _saveOrder();
    await _saveProgress();
  }

  // ---------------------------------------------------------------------------
  // Flashcard CRUD
  // ---------------------------------------------------------------------------

  Future<void> _addFlashcard() async {
    final q = TextEditingController();
    final a = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Flashcard"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: q, decoration: const InputDecoration(labelText: "Question")),
            TextField(controller: a, decoration: const InputDecoration(labelText: "Answer")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (q.text.isNotEmpty && a.text.isNotEmpty) {
                final newCard = Flashcard(
                  question: q.text,
                  answer: a.text,
                  category: widget.category == "favorites" ? "General" : widget.category,
                );
                await _box.add(newCard);

                final prefs = await SharedPreferences.getInstance();
                final list = prefs.getStringList(_kOrder) ?? [];
                list.add((newCard.key as int).toString());
                await prefs.setStringList(_kOrder, list);

                await _loadFlashcardsAndProgress();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _editFlashcard() async {
    if (_currentIndex >= _flashcards.length) return;
    final card = _flashcards[_currentIndex];
    final q = TextEditingController(text: card.question);
    final a = TextEditingController(text: card.answer);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Flashcard"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: q, decoration: const InputDecoration(labelText: "Question")),
            TextField(controller: a, decoration: const InputDecoration(labelText: "Answer")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await card.delete();
              setState(() {
                _flashcards.removeAt(_currentIndex);
                if (_currentIndex >= _flashcards.length && _flashcards.isNotEmpty) {
                  _currentIndex = _flashcards.length - 1;
                }
              });
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
              card.question = q.text;
              card.answer = a.text;
              await card.save();
              setState(() {});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(Flashcard card) async {
    card.isFavorite = !card.safeFavorite;
    await card.save();

    if (widget.category.toLowerCase() == "favorites") {
      await _loadFlashcardsAndProgress();
    } else {
      setState(() {});
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    _box = Hive.box<Flashcard>(boxName);
    await _saveLastCategory(widget.category);
    await _loadFlashcardsAndProgress();
  }

  Future<void> _saveLastCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastCategory, category);
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kProgress, _currentIndex.clamp(0, _flashcards.length));
  }

  Future<int> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kProgress) ?? 0;
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final order = _flashcards.map((c) => (c.key as int).toString()).toList();
    await prefs.setStringList(_kOrder, order);
  }

  Future<List<int>?> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kOrder);
    return list?.map((e) => int.tryParse(e)).whereType<int>().toList();
  }

  Future<void> _loadFlashcardsAndProgress() async {
    final category = widget.category.toLowerCase();
    List<Flashcard> cards;

    if (category == "favorites") {
      cards = _box.values.where((c) => c.safeFavorite && !c.safeIsPlaceholder).toList();
    } else if (category == "general") {
      cards = _box.values.where((c) => !c.safeIsPlaceholder).toList();
    } else {
      cards = _box.values
          .where((c) => c.safeCategory.toLowerCase() == category && !c.safeIsPlaceholder)
          .toList();
    }

    if (category != "favorites") {
      final savedOrder = await _loadOrder();
      if (savedOrder != null && savedOrder.isNotEmpty) {
        final byKey = {for (final c in cards) (c.key as int): c};
        final ordered = <Flashcard>[];
        for (final k in savedOrder) {
          final c = byKey[k];
          if (c != null) ordered.add(c);
        }
        for (final c in cards) {
          if (!savedOrder.contains(c.key as int)) ordered.add(c);
        }
        cards = ordered;
      }
    }

    var savedIndex = await _loadProgress();
    if (savedIndex > cards.length) savedIndex = cards.length;

    setState(() {
      _flashcards = cards;
      _currentIndex = savedIndex;
      _showAnswer = false;
      _cardOffset = Offset.zero;
      _cardRotation = 0.0;
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get _canEdit => _flashcards.isNotEmpty && _currentIndex < _flashcards.length;
  bool get _canShuffle => _flashcards.length > 1 && _currentIndex < _flashcards.length;

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final progress = _flashcards.isEmpty
        ? 0.0
        : (_currentIndex / _flashcards.length).clamp(0.0, 1.0);

    if (_flashcards.isNotEmpty && _currentIndex >= _flashcards.length) {
      return _deckCompleteView();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _flashcards.isEmpty
          ? Center(
        child: Text(
          "No flashcards yet",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 20,
          ),
        ),
      )
          : Column(
        children: [
          _buildProgressBar(progress),
          _buildDeck(size),
          const SizedBox(height: 20),
          _buildBottomButtons(),
          const SizedBox(height: 30),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  AppBar _buildAppBar() {
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
          setState(() {
            _currentIndex = 0;
            _showAnswer = false;
            _cardOffset = Offset.zero;
            _cardRotation = 0.0;
          });
          await _saveProgress();
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: _addFlashcard,
        ),
        IconButton(
          icon: Icon(Icons.edit, color: _canEdit ? Theme.of(context).colorScheme.onPrimary : Colors.grey.shade400),
          onPressed: _canEdit ? _editFlashcard : null,
        ),
        IconButton(
          icon: Icon(Icons.shuffle, color: _canShuffle ? Theme.of(context).colorScheme.onPrimary : Colors.grey.shade400),
          onPressed: _canShuffle ? _shuffleCards : null,
        ),
      ],
    );
  }

  Widget _buildProgressBar(double value) {
    final total = _flashcards.length;
    final completed = _currentIndex.clamp(0, total);

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

  Widget _buildDeck(Size size) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onPanUpdate: (d) {
            if (_currentIndex < _flashcards.length) {
              setState(() {
                _cardOffset += d.delta;
                _cardRotation = _cardOffset.dx / 300;
              });
            }
          },
          onPanEnd: (_) {
            if (_cardOffset.dx.abs() > 100 || _cardOffset.dy.abs() > 100) {
              _nextCard();
            } else {
              setState(() {
                _cardOffset = Offset.zero;
                _cardRotation = 0.0;
              });
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: _flashcards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;
              if (index < _currentIndex) return const SizedBox.shrink();

              final offset = (index - _currentIndex) * 15.0;
              final isTop = index == _currentIndex;

              if (isTop) {
                return Transform.translate(
                  offset: _cardOffset,
                  child: Transform.rotate(
                    angle: _cardRotation * pi / 12,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: size.width * 0.85,
                          height: size.height * 0.6,
                          child: FlashcardWidget(flashcard: card, showAnswer: _showAnswer),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconButton(
                            icon: Icon(card.safeFavorite ? Icons.star : Icons.star_border, color: Colors.orange),
                            onPressed: () => _toggleFavorite(card),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Positioned(
                  top: offset,
                  child: SizedBox(
                    width: size.width * 0.8,
                    height: size.height * 0.6,
                    child: FlashcardWidget(flashcard: card, showAnswer: false),
                  ),
                );
              }
            }).toList().reversed.toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 56,
          child: ElevatedButton(
            onPressed: (_currentIndex > 0 && _currentIndex < _flashcards.length) ? _prevCard : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_currentIndex > 0 && _currentIndex < _flashcards.length)
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).disabledColor,
              foregroundColor: (_currentIndex > 0 && _currentIndex < _flashcards.length)
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.undo),
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 80,
          height: 56,
          child: ElevatedButton(
            onPressed: (_currentIndex < _flashcards.length) ? _toggleAnswer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_currentIndex < _flashcards.length)
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).disabledColor,
              foregroundColor: (_currentIndex < _flashcards.length)
                  ? Theme.of(context).colorScheme.onSecondary
                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Icon(_showAnswer ? Icons.visibility_off : Icons.visibility, size: 28),
          ),
        ),
      ],
    );
  }

  Scaffold _deckCompleteView() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
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
                setState(() => _currentIndex = 0);
                await _saveProgress();
              },
              child: const Text("Restart Deck"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

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
}
