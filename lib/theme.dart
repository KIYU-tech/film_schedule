import 'package:flutter/material.dart';

// ============================================================
// Glightブランドカラー
// C60 M000 Y100 K000 = #6FBA2C
// ============================================================
const Color glightGreen      = Color(0xFF6FBA2C);
const Color glightGreenDark  = Color(0xFF4E8A1D);
const Color glightGreenLight = Color(0xFFE8F5D5);
const Color glightGreenSoft  = Color(0xFFF3FAEA);

// ============================================================
// ダークテーマ カラーパレット
// ============================================================
const Color dBg       = Color(0xFF0B0D11);  // 最背面
const Color dSurface  = Color(0xFF13161C);  // カード・パネル
const Color dSurface2 = Color(0xFF1A1E27);  // 入力欄・二次パネル
const Color dSurface3 = Color(0xFF232838);  // ホバー・選択
const Color dOutline  = Color(0xFF2A3040);  // 境界線
const Color dInk      = Color(0xFFEEF0F5);  // 主テキスト
const Color dInk2     = Color(0xFF9DA3B4);  // 副テキスト
const Color dInk3     = Color(0xFF5C6275);  // 三次テキスト・プレースホルダー

// ============================================================
// ライトテーマ カラーパレット
// ============================================================
const Color lBg       = Color(0xFFF6F7F9);  // 最背面
const Color lSurface  = Color(0xFFFFFFFF);  // カード・パネル
const Color lSurface2 = Color(0xFFF2F4F7);  // 入力欄・二次パネル
const Color lSurface3 = Color(0xFFE9EBEF);  // ホバー・選択
const Color lOutline  = Color(0xFFDDE1E8);  // 境界線
const Color lInk      = Color(0xFF14171F);  // 主テキスト
const Color lInk2     = Color(0xFF5A6073);  // 副テキスト
const Color lInk3     = Color(0xFF9AA0B0);  // 三次テキスト

// ============================================================
// テーマ構築
// ============================================================
ThemeData buildAppTheme({required bool dark}) {
  final bg       = dark ? dBg       : lBg;
  final surface  = dark ? dSurface  : lSurface;
  final surface2 = dark ? dSurface2 : lSurface2;
  final surface3 = dark ? dSurface3 : lSurface3;
  final outline  = dark ? dOutline  : lOutline;
  final ink      = dark ? dInk      : lInk;
  final ink2     = dark ? dInk2     : lInk2;
  final ink3     = dark ? dInk3     : lInk3;

  final colorScheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: glightGreen,
    onPrimary: Colors.black,
    primaryContainer: dark ? glightGreenDark : glightGreenLight,
    onPrimaryContainer: dark ? glightGreenLight : glightGreenDark,
    secondary: glightGreenDark,
    onSecondary: Colors.white,
    surface: surface,
    onSurface: ink,
    surfaceContainerHighest: surface3,
    onSurfaceVariant: ink2,
    outline: outline,
    outlineVariant: outline.withOpacity(0.5),
    error: const Color(0xFFE5484D),
    onError: Colors.white,
    background: bg,
    onBackground: ink,
    shadow: Colors.black,
    inverseSurface: dark ? lSurface : dSurface,
    onInverseSurface: dark ? lInk : dInk,
    inversePrimary: glightGreenDark,
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: bg,
    canvasColor: surface,

    // ---- テキスト ----
    textTheme: TextTheme(
      headlineLarge: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: ink2, fontSize: 13, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: ink, fontSize: 15, height: 1.5),
      bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.5),
      bodySmall: TextStyle(color: ink2, fontSize: 12, height: 1.4),
      labelLarge: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: ink2, fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: ink3, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3),
    ),

    // ---- AppBar ----
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700),
      shape: Border(bottom: BorderSide(color: outline, width: 1)),
    ),

    // ---- Card ----
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: outline, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
    ),

    // ---- ボタン ----
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: glightGreen,
        foregroundColor: Colors.black,
        disabledBackgroundColor: surface3,
        disabledForegroundColor: ink3,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: glightGreen,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: glightGreen,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // ---- 入力欄 ----
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      isDense: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outline)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outline)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: glightGreen, width: 2)),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5484D))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: ink2, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: glightGreen, fontSize: 13, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: ink3, fontSize: 14),
      prefixIconColor: ink2,
      suffixIconColor: ink2,
    ),

    // ---- Chip ----
    chipTheme: ChipThemeData(
      backgroundColor: surface2,
      selectedColor: glightGreen,
      disabledColor: surface3,
      labelStyle: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: outline),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      showCheckmark: false,
    ),

    // ---- ナビゲーションバー ----
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: glightGreen.withOpacity(0.18),
      elevation: 0,
      height: 68,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: glightGreen, size: 24);
        }
        return IconThemeData(color: ink3, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: glightGreen, fontWeight: FontWeight.w700, fontSize: 11);
        }
        return TextStyle(color: ink3, fontSize: 11);
      }),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    // ---- TabBar ----
    tabBarTheme: TabBarThemeData(
      labelColor: glightGreen,
      unselectedLabelColor: ink2,
      indicatorColor: glightGreen,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      dividerColor: outline,
    ),

    // ---- BottomSheet ----
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      elevation: 0,
    ),

    // ---- Dialog ----
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700),
      contentTextStyle: TextStyle(color: ink2, fontSize: 14),
    ),

    // ---- Divider ----
    dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),

    // ---- ListTile ----
    listTileTheme: ListTileThemeData(
      textColor: ink,
      iconColor: ink2,
      titleTextStyle: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600),
      subtitleTextStyle: TextStyle(color: ink2, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    // ---- Checkbox / Switch ----
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? glightGreen : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: BorderSide(color: outline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? Colors.black : ink3),
      trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? glightGreen : surface3),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // ---- Slider ----
    sliderTheme: SliderThemeData(
      activeTrackColor: glightGreen,
      inactiveTrackColor: surface3,
      thumbColor: glightGreen,
      overlayColor: glightGreen.withOpacity(0.15),
      valueIndicatorColor: glightGreen,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
    ),

    // ---- FAB ----
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: glightGreen,
      foregroundColor: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),

    // ---- PopupMenu ----
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: outline)),
      textStyle: TextStyle(color: ink, fontSize: 14),
    ),

    // ---- SnackBar ----
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? lSurface : dSurface,
      contentTextStyle: TextStyle(color: dark ? lInk : dInk, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    // ---- Dropdown ----
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(surface),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
      ),
    ),

    // ---- Icon ----
    iconTheme: IconThemeData(color: ink2, size: 22),
    primaryIconTheme: const IconThemeData(color: glightGreen),

    // ---- Progress ----
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: glightGreen,
      linearTrackColor: surface3,
      circularTrackColor: surface3,
    ),

    // ---- DataTable ----
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(surface2),
      dataRowColor: WidgetStateProperty.all(surface),
      headingTextStyle: TextStyle(color: ink2, fontSize: 12, fontWeight: FontWeight.w700),
      dataTextStyle: TextStyle(color: ink, fontSize: 13),
      dividerThickness: 1,
    ),

    // ---- Divider / Splash ----
    splashColor: glightGreen.withOpacity(0.1),
    highlightColor: glightGreen.withOpacity(0.06),
    hoverColor: surface3,
  );
}
