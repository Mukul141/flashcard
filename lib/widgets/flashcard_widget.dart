// lib/widgets/flashcard_widget.dart
import 'package:flutter/material.dart';
import '../model/flashcard.dart';

/// UI widget for displaying a single flashcard.
///
/// - Shows either the question or the answer depending on [showAnswer].
/// - Provides consistent rounded styling and padding.
/// - Can be reused in different deck layouts.
class FlashcardWidget extends StatelessWidget {
  final Flashcard flashcard;
  final bool showAnswer;
  final double elevation;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
    required this.showAnswer,
    this.elevation = 2, // default small shadow
  });

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // UI
    // -------------------------------------------------------------------------
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            showAnswer ? flashcard.answer : flashcard.question,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
