// model/flashcard.dart
import 'package:hive/hive.dart';

part 'flashcard.g.dart';

/// Hive model for a flashcard.
/// Each card stores its content, category, and optional state flags.
@HiveType(typeId: 0)
class Flashcard extends HiveObject {
  @HiveField(0)
  String question;

  @HiveField(1)
  String answer;

  @HiveField(2)
  String category;

  @HiveField(3)
  bool? isFavorite;

  @HiveField(4)
  bool? isLearned;

  @HiveField(5)
  bool? isPlaceholder;

  Flashcard({
    required this.question,
    required this.answer,
    required this.category,
    this.isFavorite = false,
    this.isLearned = false,
    this.isPlaceholder = false,
  });

  // ---------------------------------------------------------------------------
  // Safe accessors (normalize nullable values)
  // ---------------------------------------------------------------------------

  /// Returns a valid category (defaults to "General" if empty).
  String get safeCategory => category.isNotEmpty ? category : "General";

  /// Returns whether the card is marked favorite.
  bool get safeFavorite => isFavorite ?? false;

  /// Returns whether the card is marked as learned.
  bool get safeIsLearned => isLearned ?? false;

  /// Returns whether this card is only a placeholder.
  bool get safeIsPlaceholder => isPlaceholder ?? false;
}
