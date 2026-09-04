import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'theme.dart';
import 'providers/project_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final projectProvider = ProjectProvider();
  final themeProvider = ThemeProvider();
  await Future.wait([
    projectProvider.init(),
    themeProvider.init(),
  ]);

  runApp(
    // MultiProvider → 複数のProviderをまとめて登録
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: projectProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const FilmScheduleApp(),
    ),
  );
}

class FilmScheduleApp extends StatelessWidget {
  const FilmScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ThemeProviderを監視して、テーマ変更時に再描画
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: '制作スケジュール帳',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(dark: false),  // ライトテーマ
      darkTheme: buildAppTheme(dark: true), // ダークテーマ
      themeMode: themeProvider.mode,        // 現在のモードを反映
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          if (session != null) return const HomeScreen();
          return const AuthScreen();
        },
      ),
    );
  }
}
