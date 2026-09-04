import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'theme.dart';
import 'providers/project_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

// main関数はアプリの起動点
// async → 非同期処理を使うための宣言
void main() async {
  // Flutter本体の初期化（非同期処理の前に必要）
  WidgetsFlutterBinding.ensureInitialized();

  // Supabaseの初期化
  // url と anonKey は supabase_config.dart から読み込む
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final provider = ProjectProvider();
  await provider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const FilmScheduleApp(),
    ),
  );
}

class FilmScheduleApp extends StatelessWidget {
  const FilmScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '制作スケジュール帳',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(dark: true),
      darkTheme: buildAppTheme(dark: true),
      themeMode: ThemeMode.dark,
      // StreamBuilder → データの流れ（Stream）を監視してUIを更新する
      // Supabaseのログイン状態の変化を監視している
      home: StreamBuilder<AuthState>(
        // onAuthStateChange → ログイン・ログアウト時に発火するStream
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // snapshot.data → Streamから届いたデータ
          final session = snapshot.data?.session;

          // セッションがあれば（ログイン済み）ホーム画面
          // なければログイン画面
          if (session != null) {
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
