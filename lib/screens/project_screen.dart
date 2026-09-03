import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import 'cast_screen.dart';
import 'rundown_screen.dart';
import 'scene_screen.dart';
import 'segment_screen.dart';
import 'setup_screen.dart';

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
    final project = provider.currentProject;
    if (project == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()));
    }

    final tabs = _buildTabs(project.type);
    if (_index >= tabs.length) _index = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          project.title.isEmpty
              ? '（タイトル未設定）' : project.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              final i = tabs.indexWhere(
                (t) => t.id == 'settings');
              if (i >= 0) setState(() => _index = i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: glightGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: glightGreen.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7, height: 7,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: glightGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(project.type.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: glightGreen,
                      fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) =>
          setState(() => _index = i),
        destinations: tabs.map((t) => NavigationDestination(
          icon: Icon(t.icon),
          label: t.label,
        )).toList(),
      ),
    );
  }

  List<_Tab> _buildTabs(ProjectType type) {
    final tabs = <_Tab>[
      _Tab(
        id: 'setup',
        label: '概要',
        icon: Icons.home_outlined,
        screen: const SetupScreen(),
      ),
      _Tab(
        id: 'cast',
        label: type.castWord,
        icon: Icons.people_outline,
        screen: const CastScreen(),
      ),
    ];

    // 種類ごとにタブを追加
    switch (type) {
      case ProjectType.film:
      case ProjectType.video:
        tabs.add(_Tab(
          id: 'scenes',
          label: '香盤表',
          icon: Icons.grid_view_outlined,
          screen: const SceneScreen(),
        ));
        if (type == ProjectType.film) {
          tabs.add(_Tab(
            id: 'rundown',
            label: '進行',
            icon: Icons.list_alt_outlined,
            screen: const RundownScreen(),
          ));
        }
        break;

      case ProjectType.broadcast:
        tabs.add(_Tab(
          id: 'segments',
          label: '香盤表',
          icon: Icons.view_list_outlined,
          screen: const SegmentScreen(),
        ));
        tabs.add(_Tab(
          id: 'rundown',
          label: '進行表',
          icon: Icons.list_alt_outlined,
          screen: const RundownScreen(),
        ));
        break;

      case ProjectType.live:
      case ProjectType.event:
      case ProjectType.conference:
        tabs.add(_Tab(
          id: 'rundown',
          label: '進行表',
          icon: Icons.list_alt_outlined,
          screen: const RundownScreen(),
        ));
        break;
    }

    tabs.add(_Tab(
      id: 'settings',
      label: '設定',
      icon: Icons.settings_outlined,
      screen: const SetupScreen(settingsMode: true),
    ));

    return tabs;
  }
}

class _Tab {
  final String id;
  final String label;
  final IconData icon;
  final Widget screen;
  const _Tab({
    required this.id,
    required this.label,
    required this.icon,
    required this.screen,
  });
}