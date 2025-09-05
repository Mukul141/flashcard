import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/flashcard.dart';
import 'flashcard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String boxName = "flashcardsBox";
  late Box<Flashcard> _box;

  // Category -> cards mapping
  Map<String, List<Flashcard>> _byCategory = {};

  // Category -> number of completed cards
  Map<String, int> _progressByCategory = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads flashcards, groups them by category,
  /// and restores progress from shared preferences.
  Future<void> _loadData() async {
    _box = Hive.box<Flashcard>(boxName);

    final grouped = <String, List<Flashcard>>{};

    // Build category lists, skipping "General" for now
    for (final card in _box.values) {
      final cat = card.safeCategory;
      if (cat != "General") {
        grouped.putIfAbsent(cat, () => []);
        if (!card.safeIsPlaceholder) {
          grouped[cat]!.add(card);
        }
      }
    }

    // "General" always contains all non-placeholder cards
    final allCards = _box.values.where((c) => !c.safeIsPlaceholder).toList();
    grouped["General"] = allCards;

    // Restore progress
    final prefs = await SharedPreferences.getInstance();
    final progressMap = <String, int>{};
    for (final cat in grouped.keys) {
      progressMap[cat] = prefs.getInt("progress_$cat") ?? 0;
    }

    // Ensure "General" comes first, rest follow in insertion order
    setState(() {
      final ordered = <String, List<Flashcard>>{};
      if (grouped.containsKey("General")) {
        ordered["General"] = grouped["General"]!;
      }
      grouped.keys.where((k) => k != "General").forEach((k) {
        ordered[k] = grouped[k]!;
      });

      _byCategory = ordered;
      _progressByCategory = progressMap;
    });
  }

  /// Opens a dialog to create a new category (set).
  Future<void> _createNewSet() async {
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
              final newName = controller.text.trim();

              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Category name cannot be empty")),
                );
                return;
              }

              // Prevent reserved or duplicate names
              if (newName.toLowerCase() == "general" ||
                  newName.toLowerCase() == "favorites") {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("That name is reserved.")),
                );
                return;
              }
              if (_byCategory.keys.any((c) => c.toLowerCase() == newName.toLowerCase())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("A set named \"$newName\" already exists")),
                );
                return;
              }

              // Create placeholder entry so the category appears
              final placeholder = Flashcard(
                question: "placeholder",
                answer: "placeholder",
                category: newName,
                isPlaceholder: true,
              );

              await _box.add(placeholder);
              await _loadData();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  /// Builds a single category tile with progress bar and optional delete menu.
  Widget _buildCategoryTile(String title, List<Flashcard> cards) {
    final total = cards.where((c) => !c.safeIsPlaceholder).length;
    final saved = (_progressByCategory[title] ?? 0).clamp(0, total);
    final progress = total == 0 ? 0.0 : saved / total;

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
          await _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: category name + options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (title != "General")
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == "delete") {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Set"),
                              content: Text("Are you sure you want to delete \"$title\"?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text("Delete",
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final keysToDelete = _box.keys
                                .where((k) => _box.get(k)!.safeCategory == title)
                                .toList();
                            await _box.deleteAll(keysToDelete);
                            await _loadData();
                          }
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

              // Progress indicator
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      color: Colors.teal,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "$saved/$total",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favCount = _box.values.where((c) => c.safeFavorite).length;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Column(
        children: [
          // Top section: favorites and "new set"
          Container(
            height: screenHeight * 0.4,
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text("Categories",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const FlashcardScreen(category: "favorites")),
                            );
                            await _loadData();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.orange, size: 40),
                                const SizedBox(height: 12),
                                const Text("My favorites",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 6),
                                Text("$favCount cards",
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _createNewSet,
                          child: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.add, color: Colors.blue, size: 40),
                                SizedBox(height: 12),
                                Text("New set",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 6),
                                Text("Create category",
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category list
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: ListView(
                padding: const EdgeInsets.only(top: 20),
                children: [
                  ..._byCategory.entries.map((e) =>
                      _buildCategoryTile(e.key, e.value)),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom navigation: category view vs. last opened card view
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) async {
          if (i == 1) {
            final prefs = await SharedPreferences.getInstance();
            final lastCategory = prefs.getString("lastCategory");
            final categoryToOpen = (lastCategory != null &&
                _byCategory.containsKey(lastCategory))
                ? lastCategory
                : (_byCategory.keys.isNotEmpty
                ? _byCategory.keys.first
                : "General");

            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => FlashcardScreen(category: categoryToOpen)),
            );
            await _loadData();
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
