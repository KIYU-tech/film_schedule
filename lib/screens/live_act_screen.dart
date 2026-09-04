// ライブ・コンサート 出番表画面
// アーティストの出番・転換・セットリスト・PA照明要望を管理
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

class LiveActScreen extends StatelessWidget {
  const LiveActScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final acts = provider.liveActs;
    final totalMin = acts.fold(0, (a, b) => a + b.minutes + b.changeMinutes);

    return Scaffold(
      body: Column(
        children: [
          if (acts.isNotEmpty)
            SummaryBar(children: [
              StatChip(label: '合計尺',
                value: '${totalMin ~/ 60}h${totalMin % 60}m'),
              StatChip(label: 'アクト数',
                value: '${acts.where((a) => a.actType == '本番').length}組'),
              StatChip(label: '転換',
                value: '${acts.where((a) => a.actType == '転換').length}回'),
            ]),
          Expanded(
            child: acts.isEmpty
                ? EmptyState(
                    icon: Icons.music_note_outlined,
                    title: '出番表がありません',
                    action: OutlinedButton(
                      onPressed: () => _showAdd(context, provider),
                      child: const Text('出番を追加')))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: acts.length,
                    onReorder: (o, n) => provider.reorderLiveActs(o, n),
                    itemBuilder: (_, i) => _ActTile(
                      key: ValueKey(acts[i].id),
                      act: acts[i], provider: provider)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, provider),
        child: const Icon(Icons.add)),
    );
  }

  void _showAdd(BuildContext ctx, ProjectProvider provider) {
    showAppSheet(ctx, _ActEditSheet(
      projectId: provider.currentProject!.id, provider: provider));
  }
}

class _ActTile extends StatelessWidget {
  final LiveAct act;
  final ProjectProvider provider;
  const _ActTile({super.key, required this.act, required this.provider});

  Color _typeColor() {
    switch (act.actType) {
      case '本番':     return glightGreen;
      case '転換':     return Colors.grey;
      case 'リハ':     return Colors.blue;
      case '開演前/SE': return Colors.orange;
      default:        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showAppSheet(context, _ActEditSheet(
          projectId: act.projectId, provider: provider, act: act)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // アクト種別バッジ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _typeColor().withOpacity(0.4))),
                  child: Text(act.actType,
                    style: TextStyle(fontSize: 12, color: _typeColor(),
                      fontWeight: FontWeight.w700))),
                if (act.actNo.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('#${act.actNo}',
                    style: tt.labelSmall),
                ],
                const SizedBox(width: 8),
                Expanded(child: Text(
                  act.artist.isEmpty ? '（アーティスト未設定）' : act.artist,
                  style: tt.titleMedium, overflow: TextOverflow.ellipsis)),
                // 時間表示
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (act.minutes > 0)
                    Text('${act.minutes}分', style: tt.titleMedium?.copyWith(
                      color: glightGreen)),
                  if (act.changeMinutes > 0)
                    Text('転換${act.changeMinutes}分', style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant)),
                ]),
                ReorderableDragStartListener(
                  index: provider.liveActs.indexOf(act),
                  child: const Icon(Icons.drag_handle, size: 20)),
              ]),
              // セットリスト・PA・照明
              if (act.setlist.isNotEmpty || act.paMemo.isNotEmpty || act.lightMemo.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 6),
                if (act.setlist.isNotEmpty) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.queue_music_outlined, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text(
                      act.setlist.split('\n').take(3).join(' / ') +
                        (act.setlist.split('\n').length > 3 ? '...' : ''),
                      style: tt.bodySmall)),
                  ]),
                ],
                if (act.paMemo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.speaker_outlined, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text('PA: ${act.paMemo}', style: tt.bodySmall)),
                  ]),
                ],
                if (act.lightMemo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.lightbulb_outline, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text('照明: ${act.lightMemo}', style: tt.bodySmall)),
                  ]),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final LiveAct? act;
  const _ActEditSheet({required this.projectId, required this.provider, this.act});

  @override
  State<_ActEditSheet> createState() => _ActEditSheetState();
}

class _ActEditSheetState extends State<_ActEditSheet> {
  late TextEditingController _actNoCtrl;
  late TextEditingController _artistCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _changeMinCtrl;
  late TextEditingController _setlistCtrl;
  late TextEditingController _paCtrl;
  late TextEditingController _lightCtrl;
  late TextEditingController _memoCtrl;
  String _actType = '本番';

  @override
  void initState() {
    super.initState();
    final a = widget.act;
    _actNoCtrl    = TextEditingController(text: a?.actNo ?? '');
    _artistCtrl   = TextEditingController(text: a?.artist ?? '');
    _minCtrl      = TextEditingController(text: a != null && a.minutes > 0 ? '${a.minutes}' : '');
    _changeMinCtrl = TextEditingController(text: a != null && a.changeMinutes > 0 ? '${a.changeMinutes}' : '');
    _setlistCtrl  = TextEditingController(text: a?.setlist ?? '');
    _paCtrl       = TextEditingController(text: a?.paMemo ?? '');
    _lightCtrl    = TextEditingController(text: a?.lightMemo ?? '');
    _memoCtrl     = TextEditingController(text: a?.memo ?? '');
    _actType      = a?.actType ?? '本番';
  }

  @override
  void dispose() {
    for (final c in [_actNoCtrl, _artistCtrl, _minCtrl, _changeMinCtrl,
        _setlistCtrl, _paCtrl, _lightCtrl, _memoCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.act != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            SheetHeader(
              title: isEdit ? '出番を編集' : '出番を追加',
              trailing: isEdit ? TextButton(
                onPressed: () {
                  widget.provider.deleteLiveAct(widget.act!.id);
                  Navigator.pop(context);
                },
                child: const Text('削除', style: TextStyle(color: Colors.red))) : null),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // アクト種別
                  Wrap(spacing: 8, runSpacing: 6,
                    children: LiveAct.actTypes.map((t) => ChoiceChip(
                      label: Text(t), selected: _actType == t,
                      onSelected: (_) => setState(() => _actType = t))).toList()),
                  const SizedBox(height: 12),
                  Row(children: [
                    SizedBox(width: 80, child: TextField(controller: _actNoCtrl,
                      decoration: const InputDecoration(labelText: '出番#'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _artistCtrl,
                      decoration: const InputDecoration(
                        labelText: 'アーティスト・出演者名'))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: _minCtrl,
                      decoration: const InputDecoration(labelText: '尺（分）'),
                      keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _changeMinCtrl,
                      decoration: const InputDecoration(labelText: '転換時間（分）'),
                      keyboardType: TextInputType.number)),
                  ]),
                  if (_actType == '本番') ...[
                    const SizedBox(height: 14),
                    const SectionHeader(title: 'セットリスト'),
                    TextField(controller: _setlistCtrl,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 13, height: 1.7),
                      decoration: const InputDecoration(
                        hintText: '1. 曲名\n2. 曲名\n3. 曲名')),
                    const SizedBox(height: 14),
                    const SectionHeader(title: 'PA・照明要望'),
                    TextField(controller: _paCtrl,
                      decoration: const InputDecoration(
                        labelText: 'PA要望',
                        hintText: '例：SE曲あり、MC時はリバーブ薄め')),
                    const SizedBox(height: 12),
                    TextField(controller: _lightCtrl,
                      decoration: const InputDecoration(
                        labelText: '照明要望',
                        hintText: '例：1曲目はスポット、サビでストロボ')),
                  ],
                  const SizedBox(height: 12),
                  TextField(controller: _memoCtrl,
                    decoration: const InputDecoration(labelText: '備考')),
                  const SizedBox(height: 20),
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
    final a = LiveAct(
      id: widget.act?.id, projectId: widget.projectId,
      actNo: _actNoCtrl.text.trim(), artist: _artistCtrl.text.trim(),
      actType: _actType,
      minutes: int.tryParse(_minCtrl.text) ?? 0,
      changeMinutes: int.tryParse(_changeMinCtrl.text) ?? 0,
      setlist: _setlistCtrl.text, paMemo: _paCtrl.text.trim(),
      lightMemo: _lightCtrl.text.trim(), memo: _memoCtrl.text.trim(),
      sortKey: widget.act?.sortKey ?? widget.provider.liveActs.length,
    );
    if (widget.act != null) {
      widget.provider.updateLiveAct(a);
    } else {
      widget.provider.addLiveAct(a);
    }
    Navigator.pop(context);
  }
}
