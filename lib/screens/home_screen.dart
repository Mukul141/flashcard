import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/flashcard.dart';
import 'flashcard_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(bool)? onThemeToggle;

  const HomeScreen({super.key, this.onThemeToggle});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String boxName = "flashcardsBox";
  late Box<Flashcard> _box;

  bool _isDark = false;

  Map<String, List<Flashcard>> _byCategory = {};
  Map<String, int> _progressByCategory = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ---------------------------------------------------------------------------
  // Data Loading
  // ---------------------------------------------------------------------------

  Future<void> _loadData() async {
    _box = Hive.box<Flashcard>(boxName);
    final grouped = <String, List<Flashcard>>{};

    // Build per-category lists
    for (final card in _box.values) {
      final cat = card.safeCategory;
      if (cat != "General") {
        grouped.putIfAbsent(cat, () => []);
        if (!card.safeIsPlaceholder) grouped[cat]!.add(card);
      }
    }

    // "General" contains all non-placeholder cards
    grouped["General"] = _box.values.where((c) => !c.safeIsPlaceholder).toList();

    // Restore progress
    final prefs = await SharedPreferences.getInstance();
    final progressMap = <String, int>{
      for (final cat in grouped.keys) cat: prefs.getInt("progress_$cat") ?? 0
    };

    // Ensure "General" comes first
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

  // ---------------------------------------------------------------------------
  // Category Management
  // ---------------------------------------------------------------------------

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
              if (["general", "favorites"].contains(newName.toLowerCase())) {
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

              // Create placeholder so category is visible immediately
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

  // ---------------------------------------------------------------------------
  // UI Helpers
  // ---------------------------------------------------------------------------

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
              // Header row: title + menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

              // Progress bar
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

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final favCount = _box.values.where((c) => c.safeFavorite).length;

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
                value: _isDark,
                onChanged: (value) {
                  setState(() => _isDark = value);
                  widget.onThemeToggle?.call(value);
                },
                activeColor: Theme.of(context).colorScheme.onPrimary,
                activeTrackColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
                inactiveThumbColor: Theme.of(context).colorScheme.onPrimary,
                inactiveTrackColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
              ),
              Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Favorites + new set
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
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
                        await _loadData();
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
                            Text("$favCount cards", style: const TextStyle(color: Colors.grey)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

          // Categories list
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView(
                padding: const EdgeInsets.only(top: 20),
                children: _byCategory.entries
                    .map((e) => _buildCategoryTile(e.key, e.value))
                    .toList(),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) async {
          if (i == 1) {
            final prefs = await SharedPreferences.getInstance();
            final lastCategory = prefs.getString("lastCategory");
            final categoryToOpen = (lastCategory != null && _byCategory.containsKey(lastCategory))
                ? lastCategory
                : (_byCategory.keys.isNotEmpty ? _byCategory.keys.first : "General");

            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FlashcardScreen(category: categoryToOpen)),
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
