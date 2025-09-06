// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'model/flashcard.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/category_provider.dart';
import 'providers/flashcard_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Hive Initialization
  // ---------------------------------------------------------------------------
  await Hive.initFlutter();
  Hive.registerAdapter(FlashcardAdapter());
  await Hive.openBox<Flashcard>("flashcardsBox");

  // ---------------------------------------------------------------------------
  // Run App
  // ---------------------------------------------------------------------------
  runApp(const MyApp());
}

/// Root widget of the application.
/// Provides [ThemeProvider], [CategoryProvider], and [FlashcardProvider].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Flashcards',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
