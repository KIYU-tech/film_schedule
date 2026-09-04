import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';
import 'ai_screen.dart';
import 'availability_screen.dart';
import 'budget_screen.dart';
import 'cast_screen.dart';
import 'gantt_screen.dart';
import 'location_screen.dart';
import 'pdf_export_screen.dart';
import 'rundown_screen.dart';
import 'scene_screen.dart';
import 'segment_screen.dart';
import 'setup_screen.dart';
import 'tech_screen.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final project = provider.currentProject;
    if (project == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = _buildTabs(project.type);
    if (_index >= tabs.length) _index = 0;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              project.title.isEmpty ? '（タイトル未設定）' : project.title,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis),
            Text(tabs[_index].label,
              style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDark
                ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'テーマ切り替え',
            onPressed: () => themeProvider.toggle()),
          GestureDetector(
            onTap: () {
              final i = tabs.indexWhere((t) => t.id == 'settings');
              if (i >= 0) setState(() => _index = i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: glightGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: glightGreen.withOpacity(0.35))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: glightGreen, shape: BoxShape.circle)),
                  Text(project.type.label,
                    style: const TextStyle(fontSize: 12,
                      color: glightGreen, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: tabs.map((t) => t.screen).toList()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: tabs.map((t) => NavigationDestination(
          icon: Icon(t.icon), label: t.label)).toList(),
      ),
    );
  }

  List<_Tab> _buildTabs(ProjectType type) {
    final tabs = <_Tab>[
      _Tab(id: 'setup', label: '概要', icon: Icons.home_outlined,
        screen: const SetupScreen()),
      _Tab(id: 'cast', label: type.castWord, icon: Icons.people_outline,
        screen: const CastScreen()),
      _Tab(id: 'avail', label: '日程', icon: Icons.calendar_month_outlined,
        screen: const AvailabilityScreen()),
    ];

    switch (type) {
      case ProjectType.film:
      case ProjectType.video:
        tabs.addAll([
          _Tab(id: 'scenes', label: '香盤表', icon: Icons.grid_view_outlined,
            screen: const SceneScreen()),
          _Tab(id: 'locations', label: 'ロケ地', icon: Icons.location_on_outlined,
            screen: const LocationScreen()),
          if (type == ProjectType.film)
            _Tab(id: 'rundown', label: '進行', icon: Icons.list_alt_outlined,
              screen: const RundownScreen()),
        ]);
        break;
      case ProjectType.broadcast:
        tabs.addAll([
          _Tab(id: 'segments', label: '香盤表', icon: Icons.view_list_outlined,
            screen: const SegmentScreen()),
          _Tab(id: 'rundown', label: '進行表', icon: Icons.list_alt_outlined,
            screen: const RundownScreen()),
          _Tab(id: 'tech', label: '技術', icon: Icons.settings_input_component_outlined,
            screen: const TechScreen()),
        ]);
        break;
      case ProjectType.live:
      case ProjectType.event:
      case ProjectType.conference:
        tabs.addAll([
          _Tab(id: 'rundown', label: '進行表', icon: Icons.list_alt_outlined,
            screen: const RundownScreen()),
          _Tab(id: 'locations', label: '会場', icon: Icons.location_on_outlined,
            screen: const LocationScreen()),
          _Tab(id: 'tech', label: '技術', icon: Icons.settings_input_component_outlined,
            screen: const TechScreen()),
        ]);
        break;
    }

    tabs.addAll([
      _Tab(id: 'gantt', label: 'ガント', icon: Icons.view_timeline_outlined,
        screen: const GanttScreen()),
      _Tab(id: 'budget', label: '予算', icon: Icons.account_balance_wallet_outlined,
        screen: const BudgetScreen()),
      _Tab(id: 'ai', label: 'AI', icon: Icons.auto_awesome_outlined,
        screen: const AiScreen()),
      _Tab(id: 'pdf', label: 'PDF', icon: Icons.picture_as_pdf_outlined,
        screen: const PdfExportScreen()),
      _Tab(id: 'settings', label: '設定', icon: Icons.settings_outlined,
        screen: const SetupScreen(settingsMode: true)),
    ]);
    return tabs;
  }
}

class _Tab {
  final String id;
  final String label;
  final IconData icon;
  final Widget screen;
  const _Tab({required this.id, required this.label,
    required this.icon, required this.screen});
}
