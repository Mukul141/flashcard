import 'package:flutter/material.dart';
import '../model/flashcard.dart';

class CategoryTile extends StatelessWidget {
  final String title;
  final List<Flashcard> cards;
  final int progress;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const CategoryTile({
    super.key,
    required this.title,
    required this.cards,
    required this.progress,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final total = cards.where((c) => !c.safeIsPlaceholder).length;
    final clampedProgress = progress.clamp(0, total);
    final fraction = total == 0 ? 0.0 : clampedProgress / total;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (title != "General")
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == "delete") onDelete();
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(
                          value: "delete",
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text("Delete set"),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: LinearProgressIndicator(
                      value: fraction,
                      backgroundColor: Colors.grey[300],
                      color: Colors.teal,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text("$clampedProgress/$total",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
