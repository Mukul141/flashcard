// lib/widgets/favorite_card.dart
import 'package:flutter/material.dart';

class FavoriteCard extends StatelessWidget {
  final int favCount;
  final VoidCallback onTap;

  const FavoriteCard({super.key, required this.favCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 40),
              const SizedBox(height: 12),
              const Text(
                "My Favorites",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text("$favCount cards", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
