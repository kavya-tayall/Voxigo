// File: theme_provider.dart
import 'package:flutter/material.dart';
import 'package:test_app/cache_utility.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppTheme {
  final String id;
  final String name;
  final ThemeData theme;

  AppTheme(this.id, this.name, this.theme);
}

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData;
  String _themeName;

  ThemeProvider([ThemeData? themeData, String? themeName])
      : _themeData = themeData ?? lightTheme,
        _themeName = themeName ?? 'light';

  ThemeData get themeData => _themeData;
  String get themeName => _themeName;

  static final Map<String, ThemeData> _themeMap = {
    'default': defaultTheme,
    'light': lightTheme,
    'dark': midnightGlowTheme,
    'teal': tealHarmonyTheme,
    'orange': sunriseBlissTheme,
    'green': zenGardenTheme,
  };

  static final List<AppTheme> themes = _themeMap.entries
      .map((entry) => AppTheme(entry.key, _capitalize(entry.key), entry.value))
      .toList();

  Future<void> setTheme(String themeName) async {
    final newTheme = _themeMap[themeName];
    if (newTheme == null) {
      throw ArgumentError('Theme not found: $themeName');
    }

    _themeName = themeName;
    _themeData = newTheme;

    try {
      await saveThemeToFirebase(themeName);
    } catch (e) {
      // Log error or handle Firebase failure
      debugPrint('Failed to save theme: $e');
    }

    notifyListeners();
  }

  Future<void> setChildTheme(String themeName, String childId) async {
    try {
      await setChildThemeToFirebase(themeName, childId);
    } catch (e) {
      // Log error or handle Firebase failure
      debugPrint('Failed to save theme: $e');
    }
  }

  Future<void> loadTheme({bool isChild = false}) async {
    try {
      final fetchedThemeName = await getThemeFromFirebase(isChild);
      print("fetched theme name: $fetchedThemeName");
      _themeName = _themeMap.containsKey(fetchedThemeName)
          ? fetchedThemeName
          : 'light'; // Fallback to default theme
      _themeData = _themeMap[_themeName]!;
    } catch (e) {
      // Log error or handle Firebase failure
      debugPrint('Failed to load theme: $e');
      _themeName = 'light';
      _themeData = lightTheme;
    }
    notifyListeners();
  }

  Future<void> setdefaultTheme() async {
    _themeName = 'default';
    _themeData = defaultTheme;

    notifyListeners();
  }

  static String _capitalize(String input) {
    return input
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

final ThemeData defaultTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color.fromARGB(255, 33, 34, 38),
    brightness: Brightness.light, // Ensures a light theme for readability
  ),
  // Accessible text theme
  textTheme: TextTheme(
    headlineLarge: TextStyle(
        fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black),
    headlineMedium: TextStyle(
        fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black),
    bodyLarge: TextStyle(fontSize: 18.0, color: Colors.black),
    bodyMedium: TextStyle(fontSize: 16.0, color: Colors.black),
    labelLarge: TextStyle(
        fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    titleTextStyle: TextStyle(
        fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black),
    elevation: 2.0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue, width: 2.0),
    ),
    labelStyle: TextStyle(color: Colors.black),
    hintStyle: TextStyle(color: Colors.grey.shade600),
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    shadowColor: Colors.grey.shade200,
    elevation: 2.0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    elevation: 3.0,
  ),
  iconTheme: IconThemeData(
    color: Colors.blue, // Default icon color for high contrast
  ),
  disabledColor: Colors.grey.shade400, // Disabled state color for contrast
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 18.0),
      backgroundColor: Colors.blue.withOpacity(0.1), // Active background
      foregroundColor: Colors.blue, // Active text/icon color
      disabledForegroundColor: Colors.grey.shade600, // Disabled text/icon color
      disabledBackgroundColor:
          Colors.grey.withOpacity(0.2), // Disabled background
    ),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
    titleTextStyle: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    contentTextStyle: TextStyle(
      fontSize: 16.0,
      color: Colors.black,
    ),
    elevation: 4.0,
  ),
  dividerColor:
      Colors.grey.shade300, // Dividers for structure without distraction
  visualDensity:
      VisualDensity.adaptivePlatformDensity, // Adaptive for accessibility
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blue,
    textTheme: ButtonTextTheme.primary,
    disabledColor: Colors.grey.shade400,
  ),
);

final ThemeData lightTheme = ThemeData(
  primarySwatch: Colors.blue,
  primaryColorDark: Colors.blue.shade200,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.blue.shade900,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.blue.shade800,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.blue.shade700,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 20,
      color: Colors.black87,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 18,
      color: Colors.black87,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.black54,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.blue.shade800,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 12,
      color: Colors.blue.shade600,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue.shade500,
    elevation: 4,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 24,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blue.shade600,
    textTheme: ButtonTextTheme.primary,
    height: 48,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade200,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
    ),
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      color: Colors.blue.shade700,
    ),
    hintStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.black54,
    ),
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    shadowColor: Colors.grey.shade300,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  iconTheme: IconThemeData(
    color: Colors.blue.shade700,
    size: 24,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey.shade200,
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: Colors.blue.shade700,
    ),
    secondaryLabelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: Colors.blue.shade900,
    ),
    secondarySelectedColor: Colors.blue.shade600,
    selectedColor: Colors.blue.shade500,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  focusColor: Colors.blue.shade200,
  hoverColor: Colors.blue.shade50,
  splashColor: Colors.blue.withOpacity(0.2),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Colors.blue.shade600,
    contentTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      color: Colors.white,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  dividerColor: Colors.grey.shade300,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.blue.shade700,
    unselectedItemColor: Colors.grey.shade500,
    showUnselectedLabels: true,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.blue.shade800,
    ),
    contentTextStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.black87,
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  primarySwatch: Colors.blueGrey,
  primaryColorDark: Colors.blueGrey.shade800,
  primaryColorLight: Colors.blueGrey.shade700,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade200,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade300,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 20,
      color: Colors.grey.shade400,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 18,
      color: Colors.grey.shade300,
    ),
    bodySmall: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 16,
      color: Colors.grey.shade500,
    ),
    labelLarge: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade200,
    ),
    labelSmall: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 12,
      color: Colors.grey.shade500,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 24,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blueGrey.shade700,
    textTheme: ButtonTextTheme.primary,
    height: 48,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueGrey.shade700,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.blueGrey.shade900,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blueGrey.shade800, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blueGrey.shade700, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blueGrey.shade500, width: 2),
    ),
    labelStyle: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 18,
      color: Colors.grey.shade300,
    ),
    hintStyle: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 16,
      color: Colors.grey.shade500,
    ),
  ),
  cardTheme: CardTheme(
    color: Colors.blueGrey.shade900,
    shadowColor: Colors.black,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  iconTheme: IconThemeData(
    color: Colors.grey.shade200,
    size: 24,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.blueGrey.shade800,
    labelStyle: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 14,
      color: Colors.grey.shade200,
    ),
    secondaryLabelStyle: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 14,
      color: Colors.grey.shade400,
    ),
    secondarySelectedColor: Colors.blueGrey.shade700,
    selectedColor: Colors.blueGrey.shade600,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  focusColor: Colors.blueGrey.shade700,
  hoverColor: Colors.blueGrey.shade900,
  splashColor: Colors.grey.withOpacity(0.2),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Colors.blueGrey.shade800,
    contentTextStyle: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 16,
      color: Colors.white,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  dividerColor: Colors.blueGrey.shade700,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.black,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.grey.shade600,
    showUnselectedLabels: true,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.blueGrey.shade900,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    titleTextStyle: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade200,
    ),
    contentTextStyle: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 16,
      color: Colors.grey.shade400,
    ),
  ),
);

final ThemeData tealHarmonyTheme = ThemeData(
  primarySwatch: Colors.teal,
  primaryColorDark: Colors.teal.shade200,
  primaryColorLight: Colors.teal.shade100,
  primaryColor: Colors.teal.shade900,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.grey.shade100,
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.teal.shade900,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.teal.shade900,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 18,
      color: Colors.black87,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.black54,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.teal,
    elevation: 4,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 24,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.teal,
    textTheme: ButtonTextTheme.primary,
    height: 48,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade200,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.teal, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.teal.shade300, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
    ),
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      color: Colors.teal.shade800,
    ),
    hintStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.teal.shade500,
    ),
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    shadowColor: Colors.grey.shade400,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  iconTheme: IconThemeData(
    color: Colors.teal.shade700,
    size: 24,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey.shade200,
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: Colors.teal.shade900,
    ),
    secondaryLabelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: Colors.teal.shade700,
    ),
    secondarySelectedColor: Colors.teal.shade400,
    selectedColor: Colors.teal.shade300,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  focusColor: Colors.teal.shade200,
  hoverColor: Colors.teal.shade50,
  splashColor: Colors.teal.withOpacity(0.2),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Colors.teal,
    contentTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      color: Colors.white,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  dividerColor: Colors.teal.shade300,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.teal.shade700,
    unselectedItemColor: Colors.teal.shade400,
    showUnselectedLabels: true,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.teal.shade900,
    ),
    contentTextStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.black87,
    ),
  ),
);

final ThemeData cosmicNightTheme = ThemeData(
  primarySwatch: Colors.deepPurple,
  primaryColorLight: Colors.deepPurple.shade200,
  primaryColorDark: Colors.deepPurple.shade400,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.deepPurple.shade800,
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.deepPurple.shade200,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.deepPurple.shade300,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 18,
      height: 1.5,
      color: Colors.white,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      height: 1.5,
      color: Colors.deepPurple.shade100,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.deepPurple.shade200,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.deepPurple.shade700,
    elevation: 4,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 28,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.deepPurple.shade500,
    textTheme: ButtonTextTheme.primary,
    height: 48,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple.shade600,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.deepPurple.shade700,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.deepPurple.shade500, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.deepPurple.shade200, width: 2),
    ),
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      color: Colors.deepPurple.shade200,
    ),
    hintStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.deepPurple.shade400,
    ),
  ),
  cardTheme: CardTheme(
    color: Colors.deepPurple.shade700,
    shadowColor: Colors.black,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  iconTheme: IconThemeData(
    color: Colors.deepPurple.shade200,
    size: 28,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.deepPurple.shade600,
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      color: Colors.white,
    ),
    secondaryLabelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      color: Colors.deepPurple.shade300,
    ),
    secondarySelectedColor: Colors.deepPurple.shade500,
    selectedColor: Colors.deepPurple.shade700,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  focusColor: Colors.deepPurple.shade300,
  hoverColor: Colors.deepPurple.shade600,
  splashColor: Colors.deepPurple.withOpacity(0.2),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Colors.deepPurple.shade800,
    contentTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      color: Colors.white,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  dividerColor: Colors.deepPurple.shade500,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.deepPurple.shade800,
    selectedItemColor: Colors.deepPurple.shade300,
    unselectedItemColor: Colors.deepPurple.shade500,
    showUnselectedLabels: true,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.deepPurple.shade700,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.deepPurple.shade300,
    ),
    contentTextStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 18,
      color: Colors.white,
    ),
  ),
);

final ThemeData sunriseBlissTheme = ThemeData(
  primarySwatch: Colors.orange,
  primaryColorLight: Colors.orange.shade200,
  primaryColorDark: Colors.orange.shade300,
  primaryColor: Colors.orange.shade900,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.orange.shade50,
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.orange.shade900,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.orange.shade900,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.orange.shade800,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 18,
      color: Colors.orange.shade700,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.orange.shade600,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.orange.shade800,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.orange.shade400,
    elevation: 4,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 24,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.orange.shade500,
    textTheme: ButtonTextTheme.primary,
    height: 48,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange.shade600,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.orange.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.orange.shade300, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.orange.shade500, width: 2),
    ),
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      color: Colors.orange.shade800,
    ),
    hintStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.orange.shade600,
    ),
  ),
  cardTheme: CardTheme(
    color: Colors.orange.shade50,
    shadowColor: Colors.orange.shade200,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  iconTheme: IconThemeData(
    color: Colors.orange.shade800,
    size: 24,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.orange.shade100,
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: Colors.orange.shade800,
    ),
    secondaryLabelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: Colors.orange.shade900,
    ),
    secondarySelectedColor: Colors.orange.shade400,
    selectedColor: Colors.orange.shade300,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  focusColor: Colors.orange.shade200,
  hoverColor: Colors.orange.shade100,
  splashColor: Colors.orange.withOpacity(0.2),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Colors.orange.shade600,
    contentTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      color: Colors.white,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  dividerColor: Colors.orange.shade300,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.orange.shade50,
    selectedItemColor: Colors.orange.shade800,
    unselectedItemColor: Colors.orange.shade500,
    showUnselectedLabels: true,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.orange.shade100,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.orange.shade900,
    ),
    contentTextStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.orange.shade700,
    ),
  ),
);
final ThemeData midnightGlowTheme = ThemeData(
  primarySwatch: Colors.blueGrey,
  primaryColorLight: Colors.blueGrey.shade300, // Added primaryColorLight
  primaryColorDark: Colors.blueGrey.shade400,
  primaryColor: Colors.blueGrey.shade900,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.blueGrey.shade900,
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.blueGrey.shade200,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.blueGrey.shade300,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 20,
      height: 1.5,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 18,
      height: 1.5,
      color: Colors.blueGrey.shade200,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      height: 1.5,
      color: Colors.blueGrey.shade100,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.blueGrey.shade200,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blueGrey.shade800,
    elevation: 4,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 28,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blueGrey.shade600,
    textTheme: ButtonTextTheme.primary,
    height: 48,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueGrey.shade700,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.blueGrey.shade800,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blueGrey.shade600, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blueGrey.shade500, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blueGrey.shade300, width: 2),
    ),
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      color: Colors.blueGrey.shade300,
    ),
    hintStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.blueGrey.shade400,
    ),
  ),
  cardTheme: CardTheme(
    color: Colors.blueGrey.shade700,
    shadowColor: Colors.black.withOpacity(0.4),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  iconTheme: IconThemeData(
    color: Colors.blueGrey.shade200,
    size: 28,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.blueGrey.shade600,
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      color: Colors.white,
    ),
    secondaryLabelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      color: Colors.blueGrey.shade300,
    ),
    secondarySelectedColor: Colors.blueGrey.shade500,
    selectedColor: Colors.blueGrey.shade700,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  focusColor: Colors.blueGrey.shade400,
  hoverColor: Colors.blueGrey.shade600,
  splashColor: Colors.blueGrey.withOpacity(0.2),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Colors.blueGrey.shade700,
    contentTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      color: Colors.white,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  dividerColor: Colors.blueGrey.shade600,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.blueGrey.shade900,
    selectedItemColor: Colors.blueGrey.shade300,
    unselectedItemColor: Colors.blueGrey.shade500,
    showUnselectedLabels: true,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.blueGrey.shade700,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    contentTextStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 18,
      color: Colors.white,
    ),
  ),
);

final ThemeData zenGardenTheme = ThemeData(
  primarySwatch: Colors.green,
  primaryColorDark: Colors.green.shade400,
  primaryColorLight: Colors.green.shade300,
  primaryColor: Colors.green.shade900,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.green.shade50,
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.green.shade900,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.green.shade900,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.green.shade800,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 20,
      color: Colors.green.shade800,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 18,
      color: Colors.green.shade700,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.green.shade600,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.green.shade900,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.green.shade400,
    elevation: 4,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 24,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      // Dynamic background color
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.green.shade300; // Disabled button color
        } else if (states.contains(WidgetState.pressed)) {
          return Colors.green.shade700; // Pressed button color
        }
        return Colors.green.shade500; // Default button color
      }),
      // Dynamic text and icon color
      foregroundColor: WidgetStateProperty.all(Colors.white),
      // Text style for buttons
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Rounded corners
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // Padding for buttons
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.green.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.green.shade500, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.green.shade400, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.green.shade700, width: 2),
    ),
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      color: Colors.green.shade800,
    ),
    hintStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.green.shade600,
    ),
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    shadowColor: Colors.green.shade200,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  iconTheme: IconThemeData(
    color: Colors.green.shade700,
    size: 24,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.green.shade100,
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: Colors.green.shade800,
    ),
    secondaryLabelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: Colors.green.shade700,
    ),
    secondarySelectedColor: Colors.green.shade400,
    selectedColor: Colors.green.shade300,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  focusColor: Colors.green.shade300,
  hoverColor: Colors.green.shade100,
  splashColor: Colors.green.withOpacity(0.2),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Colors.green.shade400,
    contentTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      color: Colors.white,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  dividerColor: Colors.green.shade300,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.green.shade50,
    selectedItemColor: Colors.green.shade700,
    unselectedItemColor: Colors.green.shade400,
    showUnselectedLabels: true,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.green.shade50,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.green.shade800,
    ),
    contentTextStyle: TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 16,
      color: Colors.green.shade700,
    ),
  ),
);

Future<String> getThemeFromFirebase(bool isChild) async {
  final user = FirebaseAuth.instance.currentUser;
  print('user is $user');
  if (user != null) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(isChild ? 'children' : 'parents')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['settings']?['theme'] ?? 'light';
      }
    } catch (e) {
      debugPrint('Failed to fetch theme from Firebase: $e');
    }
  }
  return 'light';
}

Future<void> saveThemeToFirebase(String theme) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      await FirebaseFirestore.instance.collection('parents').doc(user.uid).set({
        'settings': {'theme': theme},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save theme to Firebase: $e');
    }
  }
}

Future<void> setChildThemeToFirebase(
  String theme,
  String childId,
) async {
  try {
    await FirebaseFirestore.instance.collection('children').doc(childId).set({
      'settings': {'theme': theme},
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('Failed to set child theme to Firebase: $e');
  }
}
