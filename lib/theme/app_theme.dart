import 'package:flutter/material.dart';

class AgriSmartTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32), // Vert Agri
        secondary: const Color(0xFFF37021), // Orange Moov
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}