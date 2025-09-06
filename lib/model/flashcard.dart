// model/flashcard.dart
import 'package:hive/hive.dart';

part 'flashcard.g.dart';

/// Hive model for a flashcard.
/// Stores question, answer, category, and optional state flags.
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
  // Safe Accessors (handle nullables gracefully)
  // ---------------------------------------------------------------------------

  String get safeCategory => category.isNotEmpty ? category : "General";
  bool get safeFavorite => isFavorite ?? false;
  bool get safeIsLearned => isLearned ?? false;
  bool get safeIsPlaceholder => isPlaceholder ?? false;
}
