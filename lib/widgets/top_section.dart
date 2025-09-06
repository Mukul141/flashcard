// lib/widgets/top_section.dart
import 'package:flutter/material.dart';

/// The top section on the home screen.
///
/// Displays:
/// - A **Favorites** card showing the count of favorite flashcards.
/// - A **New Set** card for creating new categories.
class TopSection extends StatelessWidget {
  final int favCount;
  final VoidCallback onFavoritesTap;
  final VoidCallback onNewSetTap;

  const TopSection({
    super.key,
    required this.favCount,
    required this.onFavoritesTap,
    required this.onNewSetTap,
  });

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // UI
    // -------------------------------------------------------------------------
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // -------------------------------------------------------------------
          // Favorites Card
          // -------------------------------------------------------------------
          Expanded(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onFavoritesTap,
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
                      Text(
                        "$favCount cards",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // -------------------------------------------------------------------
          // New Set Card
          // -------------------------------------------------------------------
          Expanded(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onNewSetTap,
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.add, color: Colors.blue, size: 40),
                      SizedBox(height: 12),
                      Text(
                        "New set",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 6),
                      Text("Create category", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
