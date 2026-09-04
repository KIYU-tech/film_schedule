// 技術構成・機材リスト画面
// 配信設定と機材の管理・貸出返却を行う
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

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
  const _TechSettingsView({required this.project, required this.provider});

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
        f.$1: TextEditingController(text: widget.project.extraInfo[f.$1] ?? '')
    };
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
    widget.provider.updateProject(widget.project.copyWith(extraInfo: info));
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
                const SectionHeader(title: '配信設定'),
                ...(_fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _ctrls[f.$1],
                    decoration: InputDecoration(labelText: f.$2, hintText: f.$3),
                    onChanged: (_) => _save()),
                ))),
                TextField(
                  controller: _ctrls['trouble'],
                  decoration: const InputDecoration(
                    labelText: 'トラブル時の対応手順',
                    hintText: '回線断→予備回線に切替'),
                  maxLines: 4,
                  onChanged: (_) => _save()),
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
    final loaned = items.where((e) => e.loanFrom.isNotEmpty && !e.isReturned).length;

    return Scaffold(
      body: Column(
        children: [
          if (items.isNotEmpty)
            SummaryBar(children: [
              StatChip(label: '準備済', value: '$done/${items.length}'),
              StatChip(label: '貸出中', value: '$loaned件',
                color: loaned > 0 ? Colors.orange : Colors.grey),
            ]),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.videocam_outlined,
                    title: '機材がありません',
                    action: OutlinedButton(
                      onPressed: () => _addPreset(provider),
                      child: const Text('標準機材を入れる')))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _EquipmentTile(
                      item: items[i], provider: provider)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, provider),
        child: const Icon(Icons.add)),
    );
  }

  void _showAdd(BuildContext ctx, ProjectProvider provider) {
    showAppSheet(ctx, _EquipmentEditSheet(
      projectId: provider.currentProject!.id, provider: provider));
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
        category: p.$1, name: p.$2, qty: p.$3));
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
    final tt = Theme.of(context).textTheme;
    // 貸出中かつ未返却の場合はオレンジ表示
    final isOnLoan = item.loanFrom.isNotEmpty && !item.isReturned;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showAppSheet(context, _EquipmentEditSheet(
          projectId: item.projectId, provider: provider, item: item)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              // 準備済チェック
              GestureDetector(
                onTap: () => provider.updateEquipment(EquipmentItem(
                  id: item.id, projectId: item.projectId,
                  category: item.category, name: item.name,
                  qty: item.qty, owner: item.owner, memo: item.memo,
                  isDone: !item.isDone,
                  loanFrom: item.loanFrom, loanDate: item.loanDate,
                  returnDate: item.returnDate, isReturned: item.isReturned)),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: item.isDone ? glightGreen : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: item.isDone ? glightGreen : cs.outline)),
                  child: item.isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : null),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Tag(item.category, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.name,
                        style: tt.titleMedium?.copyWith(
                          decoration: item.isDone
                              ? TextDecoration.lineThrough : null),
                        overflow: TextOverflow.ellipsis)),
                      Text('×${item.qty}',
                        style: tt.bodySmall),
                    ]),
                    // 貸出情報
                    if (item.loanFrom.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(
                          isOnLoan ? Icons.swap_horiz : Icons.check_circle_outline,
                          size: 13,
                          color: isOnLoan ? Colors.orange : Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          isOnLoan
                              ? '貸出中：${item.loanFrom}　返却予定：${item.returnDate}'
                              : '返却済：${item.loanFrom}',
                          style: TextStyle(fontSize: 11,
                            color: isOnLoan ? Colors.orange : Colors.green)),
                      ]),
                    ],
                    if (item.owner.isNotEmpty)
                      Text('担当：${item.owner}', style: tt.bodySmall),
                  ],
                ),
              ),
              // 返却ボタン（貸出中のとき）
              if (isOnLoan)
                TextButton(
                  onPressed: () => provider.updateEquipment(EquipmentItem(
                    id: item.id, projectId: item.projectId,
                    category: item.category, name: item.name,
                    qty: item.qty, owner: item.owner, memo: item.memo,
                    isDone: item.isDone,
                    loanFrom: item.loanFrom, loanDate: item.loanDate,
                    returnDate: item.returnDate, isReturned: true)),
                  child: const Text('返却済',
                    style: TextStyle(fontSize: 12))),
              IconButton(icon: const Icon(Icons.more_vert, size: 18),
                onPressed: () => _showOptions(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext ctx) {
    showModalBottomSheet(context: ctx, builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('編集'),
          onTap: () { Navigator.pop(ctx);
            showAppSheet(ctx, _EquipmentEditSheet(
              projectId: item.projectId, provider: provider, item: item));
          }),
        ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('削除', style: TextStyle(color: Colors.red)),
          onTap: () { Navigator.pop(ctx); provider.deleteEquipment(item.id); }),
      ]),
    ));
  }
}

class _EquipmentEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final EquipmentItem? item;
  const _EquipmentEditSheet({required this.projectId,
    required this.provider, this.item});

  @override
  State<_EquipmentEditSheet> createState() => _EquipmentEditSheetState();
}

class _EquipmentEditSheetState extends State<_EquipmentEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _memoCtrl;
  late TextEditingController _loanFromCtrl;
  late TextEditingController _loanDateCtrl;
  late TextEditingController _returnDateCtrl;
  String _category = 'カメラ';
  bool _isDone = false;
  bool _isReturned = false;

  static const _categories = [
    'カメラ','スイッチャー','音声','照明',
    'PC・配信','回線','ケーブル','電源','衣装','小道具','その他'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.item;
    _nameCtrl       = TextEditingController(text: e?.name ?? '');
    _qtyCtrl        = TextEditingController(text: e != null ? '${e.qty}' : '1');
    _ownerCtrl      = TextEditingController(text: e?.owner ?? '');
    _memoCtrl       = TextEditingController(text: e?.memo ?? '');
    _loanFromCtrl   = TextEditingController(text: e?.loanFrom ?? '');
    _loanDateCtrl   = TextEditingController(text: e?.loanDate ?? '');
    _returnDateCtrl = TextEditingController(text: e?.returnDate ?? '');
    _category  = e?.category ?? 'カメラ';
    _isDone    = e?.isDone ?? false;
    _isReturned = e?.isReturned ?? false;
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _qtyCtrl, _ownerCtrl, _memoCtrl,
        _loanFromCtrl, _loanDateCtrl, _returnDateCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.item != null;
    final hasLoan = _loanFromCtrl.text.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            SheetHeader(
              title: isEdit ? '機材を編集' : '機材を追加',
              trailing: isEdit ? TextButton(
                onPressed: () {
                  widget.provider.deleteEquipment(widget.item!.id);
                  Navigator.pop(context);
                },
                child: const Text('削除', style: TextStyle(color: Colors.red))) : null),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text('区分', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6,
                    children: _categories.map((c) => ChoiceChip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c))).toList()),
                  const SizedBox(height: 12),
                  TextField(controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: '機材名')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: _qtyCtrl,
                      decoration: const InputDecoration(labelText: '数量'),
                      keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _ownerCtrl,
                      decoration: const InputDecoration(labelText: '担当'))),
                  ]),
                  const SizedBox(height: 12),
                  // 貸出管理セクション
                  const SectionHeader(title: '貸出管理'),
                  TextField(controller: _loanFromCtrl,
                    decoration: const InputDecoration(
                      labelText: '貸出元（会社・氏名）',
                      hintText: '空欄＝自社所有'),
                    onChanged: (_) => setState(() {})),
                  if (hasLoan) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(controller: _loanDateCtrl,
                        decoration: const InputDecoration(
                          labelText: '貸出日', hintText: '9/15'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _returnDateCtrl,
                        decoration: const InputDecoration(
                          labelText: '返却予定日', hintText: '9/16'))),
                    ]),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _isReturned,
                      onChanged: (v) => setState(() => _isReturned = v),
                      title: const Text('返却済み'),
                      activeColor: glightGreen,
                      contentPadding: EdgeInsets.zero),
                  ],
                  const SizedBox(height: 12),
                  TextField(controller: _memoCtrl,
                    decoration: const InputDecoration(labelText: '備考')),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _isDone,
                    onChanged: (v) => setState(() => _isDone = v ?? false),
                    title: const Text('準備済み'),
                    activeColor: glightGreen,
                    contentPadding: EdgeInsets.zero),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _save,
                    child: Text(isEdit ? '更新' : '追加')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final e = EquipmentItem(
      id: widget.item?.id, projectId: widget.projectId,
      category: _category, name: _nameCtrl.text.trim(),
      qty: int.tryParse(_qtyCtrl.text) ?? 1,
      owner: _ownerCtrl.text.trim(), memo: _memoCtrl.text.trim(),
      isDone: _isDone,
      loanFrom: _loanFromCtrl.text.trim(),
      loanDate: _loanDateCtrl.text.trim(),
      returnDate: _returnDateCtrl.text.trim(),
      isReturned: _isReturned,
    );
    if (widget.item != null) {
      widget.provider.updateEquipment(e);
    } else {
      widget.provider.addEquipment(e);
    }
    Navigator.pop(context);
  }
}
