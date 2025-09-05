// widgets/flashcard_widget.dart
import 'package:flutter/material.dart';
import '../model/flashcard.dart';

/// A single flashcard UI widget.
/// Displays either the question or the answer depending on [showAnswer].
class FlashcardWidget extends StatelessWidget {
  final Flashcard flashcard;
  final bool showAnswer;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
    required this.showAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          showAnswer ? flashcard.answer : flashcard.question,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
