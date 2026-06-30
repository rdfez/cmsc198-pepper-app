// App Theme Colors

import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color.fromARGB(255, 255, 238, 214);
  static const Color primary = Color.fromARGB(255, 165, 175, 121);
  static const Color secondary = Color.fromARGB(255, 130, 113, 72);
  static const Color tertiary = Color.fromARGB(255, 232, 160, 124);
  static const Color white = Color.fromARGB(255, 247, 240, 240);
}

const BACKGROUND_COLOR = AppColors.background;
const PRIMARY_COLOR = AppColors.primary;
const SECONDARY_COLOR = AppColors.secondary;
const TERTIARY_COLOR = AppColors.tertiary;
const WHITE_SHADE = AppColors.white;

ThemeData appTheme = ThemeData(
  fontFamily: 'Poppins',
  colorScheme: const ColorScheme.light(
    primary: PRIMARY_COLOR,
    secondary: SECONDARY_COLOR,
    tertiary: TERTIARY_COLOR,
  ),
  scaffoldBackgroundColor: BACKGROUND_COLOR,

  // Text Theme
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ), // Heading
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ), // Subheading
    bodyMedium: TextStyle(fontSize: 16),
  ),

  // AppBar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: PRIMARY_COLOR,
  ),

  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtonStyles.primary),
);

class AppButtonStyles {
  static final ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: PRIMARY_COLOR,
    foregroundColor: WHITE_SHADE,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );

  static final ButtonStyle secondary = ElevatedButton.styleFrom(
    backgroundColor: SECONDARY_COLOR,
    foregroundColor: WHITE_SHADE,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );

  static final ButtonStyle tertiary = ElevatedButton.styleFrom(
    backgroundColor: TERTIARY_COLOR,
    foregroundColor: WHITE_SHADE,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );
}