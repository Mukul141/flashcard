// main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'model/flashcard.dart';
import 'screens/home_screen.dart';

Future<void> _seedData() async {
  final box = Hive.box<Flashcard>("flashcardsBox");
  if (box.isEmpty) {
    final sampleCards = <Flashcard>[
      // 📜 Set 1: History
      Flashcard(question: "Who was the first President of the USA?", answer: "George Washington", category: "History"),
      Flashcard(question: "In which year did World War II end?", answer: "1945", category: "History"),
      Flashcard(question: "Who was the first man to step on the moon?", answer: "Neil Armstrong", category: "History"),
      Flashcard(question: "Which empire built the Colosseum?", answer: "The Roman Empire", category: "History"),
      Flashcard(question: "Who was known as the 'Iron Lady'?", answer: "Margaret Thatcher", category: "History"),
      Flashcard(question: "Which war was fought between the North and South regions of the USA?", answer: "The American Civil War", category: "History"),
      Flashcard(question: "Who discovered America in 1492?", answer: "Christopher Columbus", category: "History"),
      Flashcard(question: "What wall divided East and West Berlin?", answer: "The Berlin Wall", category: "History"),
      Flashcard(question: "Who was the leader of the Soviet Union during WWII?", answer: "Joseph Stalin", category: "History"),
      Flashcard(question: "Which ancient civilization built the pyramids?", answer: "The Egyptians", category: "History"),

      // 🧮 Set 2: Math
      Flashcard(question: "2 + 2", answer: "4", category: "Math"),
      Flashcard(question: "Square root of 16?", answer: "4", category: "Math"),
      Flashcard(question: "What is 12 × 12?", answer: "144", category: "Math"),
      Flashcard(question: "π (Pi) rounded to 2 decimals?", answer: "3.14", category: "Math"),
      Flashcard(question: "Derivative of x²?", answer: "2x", category: "Math"),
      Flashcard(question: "Integral of 1/x dx?", answer: "ln|x| + C", category: "Math"),
      Flashcard(question: "Area of a circle?", answer: "πr²", category: "Math"),
      Flashcard(question: "Perimeter of a square with side 5?", answer: "20", category: "Math"),
      Flashcard(question: "Volume of a cube with side 3?", answer: "27", category: "Math"),
      Flashcard(question: "What is 15% of 200?", answer: "30", category: "Math"),

      // 🔬 Set 3: Science
      Flashcard(question: "What is H₂O?", answer: "Water", category: "Science"),
      Flashcard(question: "What gas do plants produce during photosynthesis?", answer: "Oxygen", category: "Science"),
      Flashcard(question: "Speed of light?", answer: "≈ 299,792 km/s", category: "Science"),
      Flashcard(question: "What planet has the most moons?", answer: "Saturn", category: "Science"),
      Flashcard(question: "Smallest unit of life?", answer: "Cell", category: "Science"),
      Flashcard(question: "Who proposed the theory of relativity?", answer: "Albert Einstein", category: "Science"),
      Flashcard(question: "What is the chemical symbol for Gold?", answer: "Au", category: "Science"),
      Flashcard(question: "Which vitamin is produced by sunlight exposure?", answer: "Vitamin D", category: "Science"),
      Flashcard(question: "What part of the cell contains DNA?", answer: "Nucleus", category: "Science"),
      Flashcard(question: "What is the powerhouse of the cell?", answer: "Mitochondria", category: "Science"),
    ];

    await box.addAll(sampleCards);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FlashcardAdapter());
  await Hive.openBox<Flashcard>("flashcardsBox");

  await _seedData(); // 👉 auto-populate if empty

  runApp(const MyApp());
}

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Hive.initFlutter();
//   Hive.registerAdapter(FlashcardAdapter());
//   await Hive.openBox<Flashcard>("flashcardsBox");
//
//   runApp(const MyApp());
// }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Flashcards",
      themeMode: _themeMode,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      home: HomeScreen(onThemeToggle: _toggleTheme),
    );
  }

  // ---------------------------------------------------------------------------
  // Light Theme
  // ---------------------------------------------------------------------------

  ThemeData get _lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.deepPurple,
    scaffoldBackgroundColor: Colors.grey[100],
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
    ),
  );

  // ---------------------------------------------------------------------------
  // Dark Theme
  // ---------------------------------------------------------------------------

  ThemeData get _darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7E57C2), // muted purple
      secondary: Color(0xFF26A69A), // teal accent
      surface: Color(0xFF1E1E1E), // card backgrounds
      background: Color(0xFF121212), // scaffold background
      onSurface: Colors.white70,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF7E57C2),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFF7E57C2),
      unselectedItemColor: Colors.grey,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
            ? const Color(0xFF26A69A)
            : Colors.grey,
      ),
      trackColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
            ? const Color(0xFF26A69A).withOpacity(0.5)
            : Colors.grey.withOpacity(0.5),
      ),
    ),
  );
}
