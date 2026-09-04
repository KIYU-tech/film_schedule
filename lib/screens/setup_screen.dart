import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import '../widgets/type_card.dart';
import '../widgets/ui_kit.dart';

class SetupScreen extends StatelessWidget {
  final bool settingsMode;
  const SetupScreen({super.key, this.settingsMode = false});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final project = provider.currentProject;
    if (project == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        if (settingsMode) ...[
          // ===== 表示設定 =====
          const SectionHeader(title: '表示設定'),
          Card(
            child: Column(
              children: [
                _ThemeOption(
                  label: 'ダークモード',
                  icon: Icons.dark_mode_outlined,
                  selected: themeProvider.mode == ThemeMode.dark,
                  onTap: () => themeProvider.setMode(ThemeMode.dark)),
                const Divider(),
                _ThemeOption(
                  label: 'ライトモード',
                  icon: Icons.light_mode_outlined,
                  selected: themeProvider.mode == ThemeMode.light,
                  onTap: () => themeProvider.setMode(ThemeMode.light)),
                const Divider(),
                _ThemeOption(
                  label: 'システム設定に従う',
                  icon: Icons.settings_brightness_outlined,
                  selected: themeProvider.mode == ThemeMode.system,
                  onTap: () => themeProvider.setMode(ThemeMode.system)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ===== 制作の種類 =====
          const SectionHeader(title: '制作の種類'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 10,
              mainAxisSpacing: 10, childAspectRatio: 1.3),
            itemCount: ProjectType.values.length,
            itemBuilder: (_, i) {
              final t = ProjectType.values[i];
              return TypeCard(type: t, selected: project.type == t,
                onTap: () => provider.updateProject(
                  project.copyWith(typeKey: t.name)));
            },
          ),
          const SizedBox(height: 24),

          // ===== 危険な操作 =====
          const SectionHeader(title: 'プロジェクト管理'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFE5484D)),
              title: const Text('このプロジェクトを削除',
                style: TextStyle(color: Color(0xFFE5484D))),
              subtitle: const Text('すべてのデータが削除されます'),
              onTap: () => _confirmDelete(context, provider, project),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ===== 案件情報 =====
        const SectionHeader(title: '案件情報'),
        _InfoForm(project: project),
      ],
    );
  }

  void _confirmDelete(BuildContext ctx, ProjectProvider provider, Project project) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('プロジェクトを削除'),
        content: Text('「${project.title.isEmpty ? '（タイトル未設定）' : project.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteProject(project.id);
              Navigator.pop(ctx);
            },
            child: const Text('削除', style: TextStyle(color: Color(0xFFE5484D)))),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({required this.label, required this.icon,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? glightGreen : null),
      title: Text(label,
        style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      trailing: selected
          ? const Icon(Icons.check_circle, color: glightGreen)
          : null,
      onTap: onTap,
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
    _titleCtrl.dispose(); _directorCtrl.dispose();
    _venueCtrl.dispose(); _memoCtrl.dispose();
    for (final c in _extra.values) c.dispose();
    super.dispose();
  }

  TextEditingController _ec(String key) => _extra.putIfAbsent(key,
    () => TextEditingController(text: widget.project.extraInfo[key] ?? ''));

  void _save() {
    final provider = context.read<ProjectProvider>();
    final info = Map<String, String>.from(widget.project.extraInfo);
    for (final e in _extra.entries) info[e.key] = e.value.text;
    provider.updateProject(widget.project.copyWith(
      title: _titleCtrl.text, director: _directorCtrl.text,
      venue: _venueCtrl.text, memo: _memoCtrl.text, extraInfo: info));
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
      controller: ctrl, maxLines: maxLines,
      onChanged: (_) => _save(),
      decoration: InputDecoration(labelText: label, hintText: hint));
  }

  Widget _dropdown(String label, String value, List<String> opts,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: opts.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      dropdownColor: Theme.of(context).colorScheme.surface,
      items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged);
  }

  Widget _dateField(String label, DateTime? value,
      ValueChanged<DateTime?> onChanged) {
    final cs = Theme.of(context).colorScheme;
    final text = value != null
        ? '${value.year}/${value.month.toString().padLeft(2,'0')}/${value.day.toString().padLeft(2,'0')}'
        : '未設定';
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020), lastDate: DateTime(2030));
        onChanged(d);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
        child: Text(text,
          style: TextStyle(
            color: value == null ? cs.onSurfaceVariant : cs.onSurface)),
      ),
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
          _field('配信先・チャンネル', _ec('channel'), hint: 'YouTube Live / Zoom など'),
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
          _field('イベント種別', _ec('category'), hint: '式典 / 展示会 / 発表会'),
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
          _field('言語・通訳', _ec('language'), hint: '日本語 / 日英同時通訳'),
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
          _field('ジャンル', _ec('genre'), hint: '劇映画 / ドラマ / ショートフィルム'),
          const SizedBox(height: 14),
          _field('尺（分）', _ec('runtime'), hint: '90'),
        ];
    }
  }
}
