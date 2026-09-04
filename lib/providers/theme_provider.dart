// テーマ（ダーク/ライト）の切り替えを管理するプロバイダー
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // ThemeMode.system → OSの設定に従う
  // ThemeMode.dark   → 常にダーク
  // ThemeMode.light  → 常にライト
  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  // 起動時に保存された設定を読み込む
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode') ?? 'dark';
    _mode = _fromString(saved);
    notifyListeners();
  }

  // テーマを切り替える
  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _toString(mode));
  }

  // ダーク/ライトをトグル
  Future<void> toggle() async {
    await setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':  return ThemeMode.light;
      case 'system': return ThemeMode.system;
      default:       return ThemeMode.dark;
    }
  }

  String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:  return 'light';
      case ThemeMode.system: return 'system';
      default:               return 'dark';
    }
  }
}
