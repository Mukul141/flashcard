// home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';
import '../model/flashcard.dart';
import 'flashcard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final categories = categoryProvider.categories;
    final progress = categoryProvider.progress;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          "Categories",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        actions: [
          Row(
            children: [
              Icon(Icons.light_mode, color: Theme.of(context).colorScheme.onPrimary),
              Switch(
                value: themeProvider.mode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggle(value);
                },
                activeColor: Theme.of(context).colorScheme.onPrimary,
                inactiveThumbColor: Theme.of(context).colorScheme.onPrimary,
              ),
              Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Top section: favorites and new set
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Favorites
                Expanded(
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FlashcardScreen(category: "Favorites"),
                          ),
                        );
                        categoryProvider.load();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 40),
                            const SizedBox(height: 12),
                            const Text("My Favorites",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(
                              "${categories["Favorites"]?.length ?? 0} cards",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // New Set
                Expanded(
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        final controller = TextEditingController();
                        await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("New Set"),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(labelText: "Category name"),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final name = controller.text.trim();
                                  if (name.isNotEmpty) {
                                    await categoryProvider.createCategory(name);
                                    if (context.mounted) Navigator.pop(context);
                                  }
                                },
                                child: const Text("Create"),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.add, color: Colors.blue, size: 40),
                            SizedBox(height: 12),
                            Text("New set",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          ),

          // Category list
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView(
                padding: const EdgeInsets.only(top: 20),
                children: categories.entries.map((e) {
                  final title = e.key;
                  final cards = e.value;
                  final total = cards.where((c) => !c.safeIsPlaceholder).length;
                  final saved = (progress[title] ?? 0).clamp(0, total);
                  final progressValue = total == 0 ? 0.0 : saved / total;

                  return Card(
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FlashcardScreen(category: title)),
                        );
                        categoryProvider.load();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(title,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                                if (title != "General")
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == "delete") {
                                        await categoryProvider.deleteCategory(title);
                                      }
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
                                    value: progressValue,
                                    backgroundColor: Colors.grey[300],
                                    color: Colors.teal,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text("$saved/$total",
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) async {
          if (i == 1 && categories.isNotEmpty) {
            final lastCategory = categories.keys.first;
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FlashcardScreen(category: lastCategory)),
            );
            categoryProvider.load();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Category"),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: "Cards"),
        ],
      ),
    );
  }
}
