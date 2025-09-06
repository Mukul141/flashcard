// lib/widgets/new_set_card.dart
import 'package:flutter/material.dart';

/// Card widget for creating a new flashcard category (set).
///
/// - Displays an "Add" icon with label text.
/// - Taps trigger the [onTap] callback (e.g., show a dialog).
class NewSetCard extends StatelessWidget {
  final VoidCallback onTap;

  const NewSetCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // UI
    // -------------------------------------------------------------------------
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
              Text(
                "Create category",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
