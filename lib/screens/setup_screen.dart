import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/type_card.dart';

class SetupScreen extends StatefulWidget {
  final bool settingsMode;
  const SetupScreen({super.key, this.settingsMode = false});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.currentProject;
    if (project == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.settingsMode) ...[
          _sectionHeader('制作の種類'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
              ),
            itemCount: ProjectType.values.length,
            itemBuilder: (_, i) {
              final t = ProjectType.values[i];
              return TypeCard(
                type: t,
                selected: project.type == t,
                onTap: () {
                  provider.updateProject(
                    project.copyWith(typeKey: t.name));
                },
              );
            },
          ),
          const SizedBox(height: 24),
          _sectionHeader('タブ並び替え'),
          const SizedBox(height: 12),
          _TabManager(project: project),
          const SizedBox(height: 24),
        ],
        _sectionHeader('案件情報'),
        const SizedBox(height: 12),
        _InfoForm(project: project),
      ],
    );
  }

  Widget _sectionHeader(String label) {
    return Row(
      children: [
        Container(
          width: 3, height: 18,
          decoration: BoxDecoration(
            color: glightGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
          style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TabManager extends StatefulWidget {
  final Project project;
  const _TabManager({required this.project});

  @override
  State<_TabManager> createState() => _TabManagerState();
}

class _TabManagerState extends State<_TabManager> {
  late List<String> _tabIds;

  @override
  void initState() {
    super.initState();
    _loadTabOrder();
  }

  Future<void> _loadTabOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tab_order_${widget.project.id}_${widget.project.type.name}';
    final saved = prefs.getStringList(key);

    // タブの基本リストを取得
    final allTabs = _getDefaultTabIds(widget.project.type);

    if (saved != null && saved.isNotEmpty) {
      _tabIds = saved;
    } else {
      _tabIds = allTabs;
    }

    setState(() {});
  }

  Future<void> _saveTabOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tab_order_${widget.project.id}_${widget.project.type.name}';
    await prefs.setStringList(key, _tabIds);
  }

  List<String> _getDefaultTabIds(ProjectType type) {
    final tabs = <String>['setup', 'cast', 'avail'];

    switch (type) {
      case ProjectType.film:
        tabs.addAll(['scenes', 'script', 'character', 'locations', 'rundown', 'equipment', 'transport', 'production']);
        break;
      case ProjectType.video:
        tabs.addAll(['scenes', 'script', 'locations', 'equipment', 'transport', 'production']);
        break;
      case ProjectType.broadcast:
        tabs.addAll(['segments', 'rundown', 'tech', 'transport', 'production']);
        break;
      case ProjectType.live:
        tabs.addAll(['liveActs', 'scenes', 'rundown', 'locations', 'equipment', 'transport', 'production']);
        break;
      case ProjectType.event:
        tabs.addAll(['corners', 'scenes', 'rundown', 'locations', 'equipment', 'transport', 'production']);
        break;
      case ProjectType.conference:
        tabs.addAll(['sessions', 'scenes', 'rundown', 'locations', 'equipment', 'transport', 'production']);
        break;
    }

    tabs.addAll(['gantt', 'budget', 'ai', 'pdf', 'settings']);
    return tabs;
  }

  String _getTabLabel(String id) {
    final labels = {
      'setup': '概要',
      'cast': '出演者',
      'avail': '日程',
      'scenes': '香盤表',
      'script': '脚本・台本',
      'character': '役設定',
      'locations': 'ロケ地・会場',
      'rundown': '進行表',
      'equipment': '機材',
      'transport': '交通費',
      'production': '制作物',
      'segments': '香盤表',
      'tech': '配信設定',
      'liveActs': '出番表',
      'corners': 'コーナー表',
      'sessions': 'セッション',
      'gantt': 'ガント',
      'budget': '予算',
      'ai': 'AI',
      'pdf': 'PDF',
      'settings': '設定',
    };
    return labels[id] ?? id;
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final temp = _tabIds[index];
      _tabIds[index] = _tabIds[index - 1];
      _tabIds[index - 1] = temp;
    });
    _saveTabOrder();
  }

  void _moveDown(int index) {
    if (index >= _tabIds.length - 1) return;
    setState(() {
      final temp = _tabIds[index];
      _tabIds[index] = _tabIds[index + 1];
      _tabIds[index + 1] = temp;
    });
    _saveTabOrder();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabIds.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _tabIds.length,
        itemBuilder: (_, i) {
          final id = _tabIds[i];
          final label = _getTabLabel(id);
          return ListTile(
            dense: true,
            title: Text(label, style: const TextStyle(fontSize: 14)),
            leading: Icon(Icons.drag_handle, size: 20),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: i > 0 ? () => _moveUp(i) : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  onPressed: i < _tabIds.length - 1 ? () => _moveDown(i) : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoForm extends StatefulWidget {
  final Project project;
  const _InfoForm({required this.project});

  @override
  State<_InfoForm> createState() => _InfoFormState();
}

class _InfoFormState extends State<_InfoForm> {
  late TextEditingController _titleCtrl;
  late TextEditingController _directorCtrl;
  late TextEditingController _venueCtrl;
  late TextEditingController _memoCtrl;
  final Map<String, TextEditingController> _extra = {};

  @override
  void initState() {
    super.initState();
    _titleCtrl    = TextEditingController(text: widget.project.title);
    _directorCtrl = TextEditingController(text: widget.project.director);
    _venueCtrl    = TextEditingController(text: widget.project.venue);
    _memoCtrl     = TextEditingController(text: widget.project.memo);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _directorCtrl.dispose();
    _venueCtrl.dispose();
    _memoCtrl.dispose();
    for (final c in _extra.values) c.dispose();
    super.dispose();
  }

  TextEditingController _ec(String key) {
    return _extra.putIfAbsent(key, () =>
      TextEditingController(
        text: widget.project.extraInfo[key] ?? ''));
  }

  void _save() {
    final provider = context.read<ProjectProvider>();
    final info = Map<String, String>.from(widget.project.extraInfo);
    for (final e in _extra.entries) info[e.key] = e.value.text;
    provider.updateProject(widget.project.copyWith(
      title: _titleCtrl.text,
      director: _directorCtrl.text,
      venue: _venueCtrl.text,
      memo: _memoCtrl.text,
      extraInfo: info,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.project.type;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(type.titleLabel, _titleCtrl),
            const SizedBox(height: 14),
            _field(type.directorLabel, _directorCtrl),
            const SizedBox(height: 14),
            ..._typeFields(type),
            const SizedBox(height: 14),
            _field('メモ・備考', _memoCtrl, maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      onChanged: (_) => _save(),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _dropdown(String label, String value, List<String> opts,
      ValueChanged<String?> onChanged) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      value: opts.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      dropdownColor: cs.surface,
      items: opts.map((o) =>
        DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _dateField(String label, DateTime? value,
      ValueChanged<DateTime?> onChanged) {
    final text = value != null
        ? '${value.year}/${value.month.toString().padLeft(2,'0')}/${value.day.toString().padLeft(2,'0')}'
        : '未設定';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label,
        style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(text,
        style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.calendar_today_outlined, size: 20),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        onChanged(picked);
      },
    );
  }

  List<Widget> _typeFields(ProjectType type) {
    final p = widget.project;
    final pv = context.read<ProjectProvider>();
    switch (type) {
      case ProjectType.broadcast:
        return [
          _dropdown('放送形式', p.formatType,
            ['生放送','収録配信','ハイブリッド（生＋収録）'],
            (v) => pv.updateProject(p.copyWith(formatType: v ?? ''))),
          const SizedBox(height: 14),
          _field('配信先・チャンネル', _ec('channel'),
            hint: 'YouTube Live / Zoom など'),
          const SizedBox(height: 14),
          _field('放送尺（分）', _ec('runtime'), hint: '60'),
          const SizedBox(height: 14),
          _dateField('リハーサル日', p.rehearsalDate,
            (d) => pv.updateProject(p.copyWith(rehearsalDate: d))),
        ];

      case ProjectType.live:
        return [
          _field('会場名', _venueCtrl),
          const SizedBox(height: 14),
          _field('収容人数', _ec('capacity'), hint: '2000'),
          const SizedBox(height: 14),
          _dropdown('形式', p.formatType,
            ['有観客のみ','無観客・配信のみ','有観客＋配信（ハイブリッド）'],
            (v) => pv.updateProject(p.copyWith(formatType: v ?? ''))),
          const SizedBox(height: 14),
          _dateField('リハーサル日', p.rehearsalDate,
            (d) => pv.updateProject(p.copyWith(rehearsalDate: d))),
          const SizedBox(height: 14),
          _dateField('搬入・仕込み日', p.loadinDate,
            (d) => pv.updateProject(p.copyWith(loadinDate: d))),
        ];

      case ProjectType.event:
        return [
          _field('会場名', _venueCtrl),
          const SizedBox(height: 14),
          _field('来場予定数', _ec('capacity'), hint: '500名'),
          const SizedBox(height: 14),
          _dropdown('形式', p.formatType,
            ['オフラインのみ','オンラインのみ','ハイブリッド'],
            (v) => pv.updateProject(p.copyWith(formatType: v ?? ''))),
          const SizedBox(height: 14),
          _field('イベント種別', _ec('category'),
            hint: '式典 / 展示会 / 発表会'),
          const SizedBox(height: 14),
          _dateField('リハーサル日', p.rehearsalDate,
            (d) => pv.updateProject(p.copyWith(rehearsalDate: d))),
        ];

      case ProjectType.conference:
        return [
          _field('会場名', _venueCtrl),
          const SizedBox(height: 14),
          _field('参加予定数', _ec('capacity'), hint: '200名'),
          const SizedBox(height: 14),
          _dropdown('形式', p.formatType,
            ['オフラインのみ','オンラインのみ（ウェビナー）','ハイブリッド'],
            (v) => pv.updateProject(p.copyWith(formatType: v ?? ''))),
          const SizedBox(height: 14),
          _field('セッション数', _ec('sessionCount'), hint: '8セッション'),
          const SizedBox(height: 14),
          _field('言語・通訳', _ec('language'),
            hint: '日本語 / 日英同時通訳'),
        ];

      case ProjectType.video:
        return [
          _field('クライアント名', _ec('clientName'), hint: '株式会社〇〇'),
          const SizedBox(height: 14),
          _field('納品形式', _ec('format'), hint: 'MP4 / MOV'),
          const SizedBox(height: 14),
          _field('尺（秒/分）', _ec('runtime'), hint: '30秒'),
        ];

      default:
        return [
          _field('ジャンル', _ec('genre'),
            hint: '劇映画 / ドラマ / ショートフィルム'),
          const SizedBox(height: 14),
          _field('尺（分）', _ec('runtime'), hint: '90'),
        ];
    }
  }
}
