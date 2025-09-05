import 'package:flutter/material.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          isFavorite ? Icons.star : Icons.category,
          color: isFavorite ? Colors.orange : Colors.blue,
        ),
        title: Text(title),
        subtitle: Text("$cardCount cards"),
        onTap: onTap,
      ),
    );
  }
}
