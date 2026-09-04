import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';
import 'ai_screen.dart';
import 'availability_screen.dart';
import 'budget_screen.dart';
import 'cast_screen.dart';
import 'character_screen.dart';
import 'conference_session_screen.dart';
import 'event_corner_screen.dart';
import 'gantt_screen.dart';
import 'live_act_screen.dart';
import 'location_screen.dart';
import 'pdf_export_screen.dart';
import 'production_screen.dart';
import 'rundown_screen.dart';
import 'scene_screen.dart';
import 'script_screen.dart';
import 'segment_screen.dart';
import 'setup_screen.dart';
import 'tech_screen.dart';
import 'transport_screen.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  int _index = 0;
  late List<_Tab> _tabs;
  late List<String> _tabOrder;

  @override
  void initState() {
    super.initState();
    _loadTabOrder();
  }

  Future<void> _loadTabOrder() async {
    final provider = context.read<ProjectProvider>();
    final project = provider.currentProject;
    if (project == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'tab_order_${project.id}_${project.type.name}';
    final saved = prefs.getStringList(key);

    _tabs = _buildTabs(project.type);
    
    if (saved != null && saved.isNotEmpty) {
      _tabOrder = saved;
      // タブを保存された順序でソート
      _tabs.sort((a, b) => _tabOrder.indexOf(a.id).compareTo(_tabOrder.indexOf(b.id)));
    } else {
      _tabOrder = _tabs.map((t) => t.id).toList();
    }

    setState(() {});
  }

  Future<void> _saveTabOrder() async {
    final provider = context.read<ProjectProvider>();
    final project = provider.currentProject;
    if (project == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'tab_order_${project.id}_${project.type.name}';
    _tabOrder = _tabs.map((t) => t.id).toList();
    await prefs.setStringList(key, _tabOrder);
  }

  void _moveTab(int from, int to) {
    setState(() {
      if (to < 0 || to >= _tabs.length) return;
      final tab = _tabs.removeAt(from);
      _tabs.insert(to, tab);
      if (_index == from) {
        _index = to;
      } else if (from < _index && _index <= to) {
        _index--;
      } else if (to <= _index && _index < from) {
        _index++;
      }
    });
    _saveTabOrder();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final project = provider.currentProject;
    if (project == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_tabs.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_index >= _tabs.length) _index = 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(project.title.isEmpty ? '（タイトル未設定）' : project.title,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis),
            Text(_tabs[_index].label,
              style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDark
                ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => themeProvider.toggle()),
          GestureDetector(
            onTap: () {
              final i = _tabs.indexWhere((t) => t.id == 'settings');
              if (i >= 0) setState(() => _index = i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: glightGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: glightGreen.withOpacity(0.35))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: glightGreen, shape: BoxShape.circle)),
                Text(project.type.label,
                  style: const TextStyle(fontSize: 12,
                    color: glightGreen, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _tabs.map((t) => t.screen).toList()),
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? ScrollableBottomNav(
              selectedIndex: _index,
              onSelected: (i) => setState(() => _index = i),
              items: _tabs.map((t) => (icon: t.icon, label: t.label)).toList())
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: _tabs.map((t) => NavigationDestination(
                icon: Icon(t.icon), label: t.label)).toList()),
    );
  }

  List<_Tab> _buildTabs(ProjectType type) {
    // 全種別共通（前半）
    final tabs = <_Tab>[
      _Tab(id: 'setup', label: '概要', icon: Icons.home_outlined,
        screen: const SetupScreen()),
      _Tab(id: 'cast', label: type.castWord, icon: Icons.people_outline,
        screen: const CastScreen()),
      _Tab(id: 'avail', label: '日程', icon: Icons.calendar_month_outlined,
        screen: const AvailabilityScreen()),
    ];

    switch (type) {
      // -----------------------------------------------
      case ProjectType.film:
      // 映画：シーン香盤・脚本・役設定・ロケ地・進行・機材・交通費・制作物
        tabs.addAll([
          _Tab(id: 'scenes', label: '香盤表',
            icon: Icons.grid_view_outlined, screen: const SceneScreen()),
          _Tab(id: 'script', label: '脚本',
            icon: Icons.description_outlined, screen: const ScriptScreen()),
          _Tab(id: 'character', label: '役設定',
            icon: Icons.theater_comedy_outlined, screen: const CharacterScreen()),
          _Tab(id: 'locations', label: 'ロケ地',
            icon: Icons.location_on_outlined, screen: const LocationScreen()),
          _Tab(id: 'rundown', label: '進行',
            icon: Icons.list_alt_outlined, screen: const RundownScreen()),
          _Tab(id: 'equipment', label: '機材',
            icon: Icons.videocam_outlined, screen: const TechScreen()),
          _Tab(id: 'transport', label: '交通費',
            icon: Icons.directions_car_outlined, screen: const TransportScreen()),
          _Tab(id: 'production', label: '制作物',
            icon: Icons.checklist_outlined, screen: const ProductionScreen()),
        ]);
        break;

      // -----------------------------------------------
      case ProjectType.video:
      // 動画：シーン香盤・台本・ロケ地・機材・交通費・制作物（進行表なし）
        tabs.addAll([
          _Tab(id: 'scenes', label: '香盤表',
            icon: Icons.grid_view_outlined, screen: const SceneScreen()),
          _Tab(id: 'script', label: '台本',
            icon: Icons.description_outlined, screen: const ScriptScreen()),
          _Tab(id: 'locations', label: 'ロケ地',
            icon: Icons.location_on_outlined, screen: const LocationScreen()),
          _Tab(id: 'equipment', label: '機材',
            icon: Icons.videocam_outlined, screen: const TechScreen()),
          _Tab(id: 'transport', label: '交通費',
            icon: Icons.directions_car_outlined, screen: const TransportScreen()),
          _Tab(id: 'production', label: '制作物',
            icon: Icons.checklist_outlined, screen: const ProductionScreen()),
        ]);
        break;

      // -----------------------------------------------
      case ProjectType.broadcast:
      // 配信番組：配信向け香盤・進行表・配信設定（機材含む）・交通費・制作物
        tabs.addAll([
          _Tab(id: 'segments', label: '香盤表',
            icon: Icons.view_list_outlined, screen: const SegmentScreen()),
          _Tab(id: 'rundown', label: '進行表',
            icon: Icons.list_alt_outlined, screen: const RundownScreen()),
          _Tab(id: 'tech', label: '配信設定',
            icon: Icons.settings_input_component_outlined,
            screen: const TechScreen()),
          _Tab(id: 'transport', label: '交通費',
            icon: Icons.directions_car_outlined, screen: const TransportScreen()),
          _Tab(id: 'production', label: '制作物',
            icon: Icons.checklist_outlined, screen: const ProductionScreen()),
        ]);
        break;

      // -----------------------------------------------
      case ProjectType.live:
      // ライブ：出番表（アクト型）・進行表・会場・機材・交通費・制作物
        tabs.addAll([
          _Tab(id: 'liveActs', label: '出番表',
            icon: Icons.music_note_outlined, screen: const LiveActScreen()),
          _Tab(id: 'scenes', label: '香盤表',
            icon: Icons.grid_view_outlined, screen: const SceneScreen()),
          _Tab(id: 'rundown', label: '進行表',
            icon: Icons.list_alt_outlined, screen: const RundownScreen()),
          _Tab(id: 'locations', label: '会場',
            icon: Icons.location_on_outlined, screen: const LocationScreen()),
          _Tab(id: 'equipment', label: '機材',
            icon: Icons.videocam_outlined, screen: const TechScreen()),
          _Tab(id: 'transport', label: '交通費',
            icon: Icons.directions_car_outlined, screen: const TransportScreen()),
          _Tab(id: 'production', label: '制作物',
            icon: Icons.checklist_outlined, screen: const ProductionScreen()),
        ]);
        break;

      // -----------------------------------------------
      case ProjectType.event:
      // イベント：コーナー表・香盤表・進行表・会場・機材・交通費・制作物
        tabs.addAll([
          _Tab(id: 'corners', label: 'コーナー表',
            icon: Icons.event_note_outlined, screen: const EventCornerScreen()),
          _Tab(id: 'scenes', label: '香盤表',
            icon: Icons.grid_view_outlined, screen: const SceneScreen()),
          _Tab(id: 'rundown', label: '進行表',
            icon: Icons.list_alt_outlined, screen: const RundownScreen()),
          _Tab(id: 'locations', label: '会場',
            icon: Icons.location_on_outlined, screen: const LocationScreen()),
          _Tab(id: 'equipment', label: '機材',
            icon: Icons.videocam_outlined, screen: const TechScreen()),
          _Tab(id: 'transport', label: '交通費',
            icon: Icons.directions_car_outlined, screen: const TransportScreen()),
          _Tab(id: 'production', label: '制作物',
            icon: Icons.checklist_outlined, screen: const ProductionScreen()),
        ]);
        break;

      // -----------------------------------------------
      case ProjectType.conference:
      // カンファレンス：セッション表・香盤表・進行表・会場・機材・交通費・制作物
        tabs.addAll([
          _Tab(id: 'sessions', label: 'セッション',
            icon: Icons.groups_outlined, screen: const ConferenceSessionScreen()),
          _Tab(id: 'scenes', label: '香盤表',
            icon: Icons.grid_view_outlined, screen: const SceneScreen()),
          _Tab(id: 'rundown', label: '進行表',
            icon: Icons.list_alt_outlined, screen: const RundownScreen()),
          _Tab(id: 'locations', label: '会場',
            icon: Icons.location_on_outlined, screen: const LocationScreen()),
          _Tab(id: 'equipment', label: '機材',
            icon: Icons.videocam_outlined, screen: const TechScreen()),
          _Tab(id: 'transport', label: '交通費',
            icon: Icons.directions_car_outlined, screen: const TransportScreen()),
          _Tab(id: 'production', label: '制作物',
            icon: Icons.checklist_outlined, screen: const ProductionScreen()),
        ]);
        break;
    }

    // 全種別共通（後半）
    tabs.addAll([
      _Tab(id: 'gantt', label: 'ガント',
        icon: Icons.view_timeline_outlined, screen: const GanttScreen()),
      _Tab(id: 'budget', label: '予算',
        icon: Icons.account_balance_wallet_outlined, screen: const BudgetScreen()),
      _Tab(id: 'ai', label: 'AI',
        icon: Icons.auto_awesome_outlined, screen: const AiScreen()),
      _Tab(id: 'pdf', label: 'PDF',
        icon: Icons.picture_as_pdf_outlined, screen: const PdfExportScreen()),
      _Tab(id: 'settings', label: '設定',
        icon: Icons.settings_outlined,
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
