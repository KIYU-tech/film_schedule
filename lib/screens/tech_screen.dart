import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

class TechScreen extends StatelessWidget {
  const TechScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.currentProject;
    if (project == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: '配信設定'),
            Tab(text: '機材リスト'),
          ]),
          Expanded(
            child: TabBarView(children: [
              _TechSettingsView(project: project, provider: provider),
              _EquipmentView(provider: provider),
            ]),
          ),
        ],
      ),
    );
  }
}

// ===== 配信設定 =====
class _TechSettingsView extends StatefulWidget {
  final Project project;
  final ProjectProvider provider;
  const _TechSettingsView({
    required this.project, required this.provider});

  @override
  State<_TechSettingsView> createState() => _TechSettingsViewState();
}

class _TechSettingsViewState extends State<_TechSettingsView> {
  late Map<String, TextEditingController> _ctrls;

  final _fields = [
    ('platform',  '配信プラットフォーム', 'YouTube Live / Zoom / Vimeo'),
    ('url',       '配信URL・イベントID', 'https://...'),
    ('res',       '解像度・フレームレート', '1920x1080 / 30fps'),
    ('bitrate',   'ビットレート', '6000 kbps'),
    ('software',  '配信ソフト', 'OBS / vMix / ATEM'),
    ('network',   '回線（主回線／予備）', '有線1Gbps ／ LTEバックアップ'),
    ('audio',     '音声構成', 'ミキサー・マイク本数・返し'),
    ('record',    '収録（バックアップ）', 'ローカル収録あり'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final f in _fields)
        f.$1: TextEditingController(
          text: widget.project.extraInfo[f.$1] ?? '')
    };
    // troubleも追加
    _ctrls['trouble'] = TextEditingController(
      text: widget.project.extraInfo['trouble'] ?? '');
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  void _save() {
    final info = Map<String, String>.from(widget.project.extraInfo);
    for (final entry in _ctrls.entries) {
      info[entry.key] = entry.value.text;
    }
    widget.provider.updateProject(
      widget.project.copyWith(extraInfo: info));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('配信設定',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                ...(_fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _ctrls[f.$1],
                    decoration: InputDecoration(
                      labelText: f.$2, hintText: f.$3),
                    onChanged: (_) => _save(),
                  ),
                ))),
                TextField(
                  controller: _ctrls['trouble'],
                  decoration: const InputDecoration(
                    labelText: 'トラブル時の対応手順',
                    hintText: '回線断→予備回線に切替、映像断→スタンバイ画面'),
                  maxLines: 4,
                  onChanged: (_) => _save(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ===== 機材リスト =====
class _EquipmentView extends StatelessWidget {
  final ProjectProvider provider;
  const _EquipmentView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final items = provider.equipmentItems;
    final done = items.where((e) => e.isDone).length;

    return Scaffold(
      body: Column(
        children: [
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Text('$done / ${items.length} 準備済',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _addPreset(provider),
                    child: const Text('標準機材を入れる'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_outlined,
                          size: 56, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text('機材がありません',
                          style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => _addPreset(provider),
                          child: const Text('標準機材を入れる'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _EquipmentTile(
                      item: items[i], provider: provider),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, provider),
        backgroundColor: glightGreen,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAdd(BuildContext ctx, ProjectProvider provider) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EquipmentEditSheet(
        projectId: provider.currentProject!.id,
        provider: provider,
      ),
    );
  }

  Future<void> _addPreset(ProjectProvider provider) async {
    final presets = [
      ('カメラ', 'ビデオカメラ', 2),
      ('カメラ', '三脚', 2),
      ('スイッチャー', 'ATEM Mini', 1),
      ('PC・配信', '配信用PC', 1),
      ('PC・配信', 'キャプチャーボード', 1),
      ('音声', 'ミキサー', 1),
      ('音声', 'ハンドマイク', 2),
      ('音声', 'ピンマイク', 2),
      ('照明', 'LEDライト', 2),
      ('回線', '有線LAN（主回線）', 1),
      ('回線', 'LTEルーター（予備）', 1),
      ('ケーブル', 'SDI/HDMIケーブル', 6),
      ('電源', '電源タップ', 3),
      ('その他', 'モニター（確認用）', 1),
    ];
    for (final p in presets) {
      await provider.addEquipment(EquipmentItem(
        projectId: provider.currentProject!.id,
        category: p.$1, name: p.$2, qty: p.$3,
      ));
    }
  }
}

class _EquipmentTile extends StatelessWidget {
  final EquipmentItem item;
  final ProjectProvider provider;
  const _EquipmentTile({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: item.isDone,
          activeColor: glightGreen,
          onChanged: (v) => provider.updateEquipment(
            item..isDone = v ?? false),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: glightGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(item.category,
                style: const TextStyle(
                  fontSize: 11, color: glightGreen)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(item.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: item.isDone
                      ? TextDecoration.lineThrough : null,
                  color: item.isDone
                      ? cs.onSurface.withOpacity(0.4)
                      : cs.onSurface))),
          ],
        ),
        subtitle: Row(
          children: [
            Text('数量: ${item.qty}',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.5))),
            if (item.owner.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text('担当: ${item.owner}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5))),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, size: 18,
            color: cs.onSurface.withOpacity(0.4)),
          onPressed: () => _showOptions(context),
        ),
      ),
    );
  }

  void _showOptions(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('編集'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _EquipmentEditSheet(
                    projectId: item.projectId,
                    provider: provider,
                    item: item,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline, color: Colors.red),
              title: const Text('削除',
                style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                provider.deleteEquipment(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final EquipmentItem? item;
  const _EquipmentEditSheet({
    required this.projectId,
    required this.provider,
    this.item,
  });

  @override
  State<_EquipmentEditSheet> createState() =>
    _EquipmentEditSheetState();
}

class _EquipmentEditSheetState extends State<_EquipmentEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _memoCtrl;
  String _category = 'カメラ';

  static const _categories = [
    'カメラ','スイッチャー','音声','照明',
    'PC・配信','回線','ケーブル','電源','その他'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.item;
    _nameCtrl  = TextEditingController(text: e?.name ?? '');
    _qtyCtrl   = TextEditingController(
      text: e != null ? '${e.qty}' : '1');
    _ownerCtrl = TextEditingController(text: e?.owner ?? '');
    _memoCtrl  = TextEditingController(text: e?.memo ?? '');
    _category  = e?.category ?? 'カメラ';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _qtyCtrl.dispose();
    _ownerCtrl.dispose(); _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.item != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? '機材を編集' : '機材を追加',
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Text('区分',
              style: TextStyle(
                fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: _categories.map((c) => ChoiceChip(
                label: Text(c,
                  style: const TextStyle(fontSize: 12)),
                selected: _category == c,
                onSelected: (_) =>
                  setState(() => _category = c),
              )).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '機材名')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  decoration: const InputDecoration(
                    labelText: '数量'),
                  keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ownerCtrl,
                  decoration: const InputDecoration(
                    labelText: '担当'))),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _memoCtrl,
              decoration: const InputDecoration(
                labelText: '備考')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? '更新' : '追加')),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final e = EquipmentItem(
      id: widget.item?.id,
      projectId: widget.projectId,
      category: _category,
      name: _nameCtrl.text.trim(),
      qty: int.tryParse(_qtyCtrl.text) ?? 1,
      owner: _ownerCtrl.text.trim(),
      memo: _memoCtrl.text.trim(),
      isDone: widget.item?.isDone ?? false,
    );
    if (widget.item != null) {
      widget.provider.updateEquipment(e);
    } else {
      widget.provider.addEquipment(e);
    }
    Navigator.pop(context);
  }
}
