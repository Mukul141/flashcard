// widgets/category_tile.dart
import 'package:flutter/material.dart';

/// A reusable tile widget for displaying a flashcard category.
/// Shows the category name, number of cards, and an icon (star for favorites).
class CategoryTile extends StatelessWidget {
  final String title;
  final int cardCount;
  final VoidCallback onTap;
  final bool isFavorite;

  const CategoryTile({
    super.key,
    required this.title,
    required this.cardCount,
    required this.onTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ListTile(
          leading: Icon(
            isFavorite ? Icons.star : Icons.category,
            color: isFavorite ? Colors.orange : Colors.blue,
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("$cardCount cards"),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
