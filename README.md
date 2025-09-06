# 📚 Flashcards App

A simple and modern **Flashcards App** built with **Flutter** and **Hive** for local storage.  
It allows you to create, edit, and review flashcards by category, mark favorites, and track progress.  
Supports both **Light and Dark mode**. 🌙☀️  

---

## Features

- 🗂️ **Categories**  
  Organize flashcards into different categories (sets).  
  - Predefined **General** category contains all cards.  
  - Create and delete custom sets.  

- ⭐ **Favorites**  
  Mark any flashcard as a favorite and quickly access them in the **Favorites deck**.  

- 📊 **Progress Tracking**  
  - Tracks progress for each category.  
  - Progress is saved locally using **SharedPreferences**.  
  - Resumes where you left off.  

- 🔀 **Card Management**  
  - Add, edit, and delete flashcards.  
  - Shuffle cards within a category.  
  - Swipe through flashcards with smooth animations.  

- 🎨 **Themes**  
  - Built-in support for **Light and Dark mode**.  
  - Follows system theme by default.  
  - Toggle available directly in the Home screen.  

---

## Tech Stack

- [Flutter](https://flutter.dev) (UI framework)  
- [Hive](https://docs.hivedb.dev) (local NoSQL database for flashcards)  
- [SharedPreferences](https://pub.dev/packages/shared_preferences) (for saving progress and settings)  

---

## Screenshots

### Light Mode  
| Home | Flashcards | Deck Complete |
|------|------------|---------------|
| <img src="screenshots/home_light.png" width="250"/> | <img src="screenshots/flashcard_light.png" width="250"/> | <img src="screenshots/deckComplete_light.png" width="250"/> |

### Dark Mode  
| Home | Flashcards | Deck Complete |
|------|------------|---------------|
| <img src="screenshots/home_dark.png" width="250"/> | <img src="screenshots/flashcard_dark.png" width="250"/> | <img src="screenshots/deckComplete_dark.png" width="250"/> |


---

## Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/your-username/flashcard.git
cd flashcard
````

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

```bash
flutter run
```

---

## Project Structure

```
lib/
│── main.dart                 # App entry point (theme, routing)
│
├── model/
│   └── flashcard.dart        # Hive model for Flashcards
│
├── screens/
│   ├── home_screen.dart      # Home screen (categories, favorites, theme toggle)
│   └── flashcard_screen.dart # Flashcard deck screen
│
├── widgets/
│   ├── flashcard_widget.dart # UI for flashcard front/back
│   └── category_tile.dart    # Reusable tile for categories
│
└── repository/
    └── flashcard_repository.dart # Hive data access layer
```


