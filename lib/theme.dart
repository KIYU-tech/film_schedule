import 'package:flutter/material.dart';

const Color glightGreen = Color(0xFF6FBA2C);
const Color glightGreenDark = Color(0xFF558A21);
const Color glightGreenLight = Color(0xFFE8F5D5);

const Color darkBg = Color(0xFF0C0E12);
const Color darkPanel = Color(0xFF141720);
const Color darkPanel2 = Color(0xFF1C2030);
const Color darkLine = Color(0xFF2A2E3D);
const Color darkInk = Color(0xFFE8EAF0);
const Color darkMute = Color(0xFF6B7280);

ThemeData buildAppTheme({bool dark = true}) {
  final colorScheme = dark
      ? ColorScheme.dark(
          primary: glightGreen,
          onPrimary: Colors.black,
          secondary: glightGreenDark,
          surface: darkPanel,
          onSurface: darkInk,
          background: darkBg,
          onBackground: darkInk,
          outline: darkLine,
        )
      : ColorScheme.light(
          primary: glightGreen,
          onPrimary: Colors.black,
          secondary: glightGreenDark,
          surface: Colors.white,
          onSurface: const Color(0xFF1A1A2E),
          background: const Color(0xFFF5F7FA),
          outline: const Color(0xFFE0E4EF),
        );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: dark ? darkBg : const Color(0xFFF5F7FA),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? darkPanel : Colors.white,
      foregroundColor: dark ? darkInk : const Color(0xFF1A1A2E),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
        cardTheme: CardThemeData(
      color: dark ? darkPanel : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: dark ? darkLine : const Color(0xFFE0E4EF),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: glightGreen,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? darkPanel2 : const Color(0xFFF8F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: dark ? darkLine : const Color(0xFFE0E4EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: dark ? darkLine : const Color(0xFFE0E4EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: glightGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      labelStyle:
          TextStyle(color: dark ? darkMute : Colors.grey[600]),
      hintStyle:
          TextStyle(color: dark ? darkMute : Colors.grey[500]),
    ),
    dividerTheme: DividerThemeData(
      color: dark ? darkLine : const Color(0xFFE8ECEF),
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? darkPanel : Colors.white,
      indicatorColor: glightGreenLight,
    ),
  );
}