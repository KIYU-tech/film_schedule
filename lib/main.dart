import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/project_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: const HomeScreen(),
    );
  }
}