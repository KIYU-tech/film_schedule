import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

class RundownScreen extends StatelessWidget {
  const RundownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final items = provider.rundownItems;
    const startTime = '09:00';
    final timed = provider.calcRundownTimes(startTime);
    final totalMin =
        items.fold(0, (a, b) => a + b.minutes);

    return Scaffold(
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt_outlined,
                    size: 56, color: Colors.grey[700]),
                  const SizedBox(height: 12),
                  Text('進行表がありません',
                    style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () =>
                      _addPreset(context, provider),
                    child: const Text('標準進行を入れる'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // ヘッダー
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      Text('$startTime 開始',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Text('合計 ${totalMin}分',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13)),
                      const Spacer(),
                      Text(
                        '終了 ${timed.isNotEmpty ? timed.last['endLabel'] : '--:--'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: timed.length,
                    onReorder: (old, nw) =>
                      provider.reorderRundown(old, nw),
                    itemBuilder: (_, i) {
                      final t = timed[i];
                      final item = t['item'] as RundownItem;
                      return _RundownTile(
                        key: ValueKey(item.id),
                        item: item,
                        startLabel: t['startLabel'] as String,
                        endLabel: t['endLabel'] as String,
                        provider: provider,
                      );
                    },
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
      builder: (_) => _RundownEditSheet(
        projectId: provider.currentProject!.id,
        provider: provider,
      ),
    );
  }

  Future<void> _addPreset(
      BuildContext ctx, ProjectProvider provider) async {
    final presets = [
      ('準備', '機材搬入・設営', 60),
      ('準備', '配線・映像音声チェック', 45),
      ('リハ', 'カメラリハ', 30),
      ('リハ', '通しリハーサル', 45),
      ('転換', '出演者スタンバイ', 15),
      ('本番', '配信開始・オープニング', 5),
      ('本番', '本編', 60),
      ('本番', 'クロージング・配信終了', 5),
      ('撤収', '機材撤収', 45),
    ];
    for (var i = 0; i < presets.length; i++) {
      final p = presets[i];
      await provider.addRundownItem(RundownItem(
        projectId: provider.currentProject!.id,
        kind: p.$1,
        name: p.$2,
        minutes: p.$3,
        sortKey: i,
      ));
    }
  }
}

class _RundownTile extends StatelessWidget {
  final RundownItem item;
  final String startLabel;
  final String endLabel;
  final ProjectProvider provider;

  const _RundownTile({
    super.key,
    required this.item,
    required this.startLabel,
    required this.endLabel,
    required this.provider,
  });

  Color _kindColor() {
    switch (item.kind) {
      case '本番': return Colors.red.shade400;
      case 'リハ': return Colors.orange.shade400;
      case '転換': return Colors.blue.shade400;
      case '撤収': return Colors.purple.shade400;
      default:     return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(startLabel,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w700)),
            Text(endLabel,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.5))),
          ],
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _kindColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(item.kind,
                style: TextStyle(
                  fontSize: 11,
                  color: _kindColor(),
                  fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600))),
          ],
        ),
        subtitle: Text(
          '${item.minutes}分'
          '${item.owner.isNotEmpty ? "　${item.owner}" : ""}'
          '${item.memo.isNotEmpty ? "　${item.memo}" : ""}',
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.5)),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _showEdit(context),
            ),
            const Icon(Icons.drag_handle,
              size: 20, color: Colors.grey),
          ],
        ),
        onTap: () => _showEdit(context),
      ),
    );
  }

  void _showEdit(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RundownEditSheet(
        projectId: item.projectId,
        provider: provider,
        item: item,
      ),
    );
  }
}

class _RundownEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final RundownItem? item;
  const _RundownEditSheet({
    required this.projectId,
    required this.provider,
    this.item,
  });

  @override
  State<_RundownEditSheet> createState() =>
    _RundownEditSheetState();
}

class _RundownEditSheetState extends State<_RundownEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _memoCtrl;
  late String _kind;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(
      text: widget.item?.name ?? '');
    _minCtrl   = TextEditingController(
      text: widget.item != null ? '${widget.item!.minutes}' : '');
    _ownerCtrl = TextEditingController(
      text: widget.item?.owner ?? '');
    _memoCtrl  = TextEditingController(
      text: widget.item?.memo ?? '');
    _kind      = widget.item?.kind ?? '本番';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minCtrl.dispose();
    _ownerCtrl.dispose();
    _memoCtrl.dispose();
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
            Text(isEdit ? '項目を編集' : '項目を追加',
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: RundownItem.kinds.map((k) =>
                ChoiceChip(
                  label: Text(k,
                    style: const TextStyle(fontSize: 12)),
                  selected: _kind == k,
                  onSelected: (_) =>
                    setState(() => _kind = k),
                )).toList(),
            ),
            const SizedBox(height: 14),
            TextField(controller: _nameCtrl,
              decoration:
                const InputDecoration(labelText: '項目名')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  decoration:
                    const InputDecoration(labelText: '尺（分）'),
                  keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ownerCtrl,
                  decoration:
                    const InputDecoration(labelText: '担当'))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _memoCtrl,
              decoration:
                const InputDecoration(labelText: '備考')),
            const SizedBox(height: 16),
            Row(children: [
              if (isEdit) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.provider.deleteRundownItem(
                        widget.item!.id);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                        color: Colors.red)),
                    child: const Text('削除')),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isEdit ? '更新' : '追加')),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _save() {
    final r = RundownItem(
      id: widget.item?.id,
      projectId: widget.projectId,
      kind: _kind,
      name: _nameCtrl.text.trim(),
      minutes: int.tryParse(_minCtrl.text) ?? 0,
      owner: _ownerCtrl.text.trim(),
      memo: _memoCtrl.text.trim(),
      sortKey: widget.item?.sortKey ?? 0,
    );
    if (widget.item != null) {
      widget.provider.updateRundownItem(r);
    } else {
      widget.provider.addRundownItem(r);
    }
    Navigator.pop(context);
  }
}