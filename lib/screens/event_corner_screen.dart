// イベント・式典 コーナー表画面
// 時間・きっかけ・担当を一覧で管理する進行共有用の表
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

class EventCornerScreen extends StatelessWidget {
  const EventCornerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final corners = provider.eventCorners;
    final totalMin = corners.fold(0, (a, b) => a + b.minutes);

    return Scaffold(
      body: Column(
        children: [
          if (corners.isNotEmpty)
            SummaryBar(children: [
              StatChip(label: '合計',
                value: '${totalMin ~/ 60}h${totalMin % 60}m'),
              StatChip(label: 'コーナー数', value: '${corners.length}件'),
            ]),
          Expanded(
            child: corners.isEmpty
                ? EmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'コーナーがありません',
                    action: OutlinedButton(
                      onPressed: () => _showAdd(context, provider),
                      child: const Text('コーナーを追加')))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: corners.length,
                    itemBuilder: (_, i) => _CornerTile(
                      corner: corners[i], provider: provider,
                      index: i + 1)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, provider),
        child: const Icon(Icons.add)),
    );
  }

  void _showAdd(BuildContext ctx, ProjectProvider provider) {
    showAppSheet(ctx, _CornerEditSheet(
      projectId: provider.currentProject!.id, provider: provider));
  }
}

class _CornerTile extends StatelessWidget {
  final EventCorner corner;
  final ProjectProvider provider;
  final int index;
  const _CornerTile({required this.corner, required this.provider, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showAppSheet(context, _CornerEditSheet(
          projectId: corner.projectId, provider: provider, corner: corner)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 番号・時刻
              SizedBox(width: 60,
                child: Column(children: [
                  Text('$index', style: tt.titleLarge?.copyWith(color: glightGreen)),
                  if (corner.time.isNotEmpty)
                    Text(corner.time, style: tt.labelSmall),
                ])),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(corner.name.isEmpty ? '（コーナー名未設定）' : corner.name,
                      style: tt.titleMedium),
                    const SizedBox(height: 4),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      if (corner.presenter.isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.person_outline, size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(corner.presenter, style: tt.bodySmall),
                        ]),
                      if (corner.owner.isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.badge_outlined, size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(corner.owner, style: tt.bodySmall),
                        ]),
                      if (corner.cue.isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.play_circle_outline, size: 13, color: Colors.orange),
                          const SizedBox(width: 3),
                          Text('きっかけ: ${corner.cue}',
                            style: tt.bodySmall?.copyWith(color: Colors.orange)),
                        ]),
                    ]),
                  ],
                ),
              ),
              if (corner.minutes > 0)
                Text('${corner.minutes}分',
                  style: tt.titleMedium?.copyWith(color: glightGreen)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final EventCorner? corner;
  const _CornerEditSheet({required this.projectId, required this.provider, this.corner});

  @override
  State<_CornerEditSheet> createState() => _CornerEditSheetState();
}

class _CornerEditSheetState extends State<_CornerEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _presenterCtrl;
  late TextEditingController _cueCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _memoCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.corner;
    _nameCtrl      = TextEditingController(text: c?.name ?? '');
    _timeCtrl      = TextEditingController(text: c?.time ?? '');
    _minCtrl       = TextEditingController(text: c != null && c.minutes > 0 ? '${c.minutes}' : '');
    _presenterCtrl = TextEditingController(text: c?.presenter ?? '');
    _cueCtrl       = TextEditingController(text: c?.cue ?? '');
    _ownerCtrl     = TextEditingController(text: c?.owner ?? '');
    _memoCtrl      = TextEditingController(text: c?.memo ?? '');
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _timeCtrl, _minCtrl, _presenterCtrl,
        _cueCtrl, _ownerCtrl, _memoCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.corner != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'コーナーを編集' : 'コーナーを追加',
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'コーナー名・内容')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _timeCtrl,
                  decoration: const InputDecoration(
                    labelText: '開始時刻', hintText: '13:00'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _minCtrl,
                  decoration: const InputDecoration(labelText: '尺（分）'),
                  keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _presenterCtrl,
                decoration: const InputDecoration(
                  labelText: '登壇者・司会',
                  hintText: '例：山田太郎、田中司会')),
              const SizedBox(height: 12),
              TextField(controller: _cueCtrl,
                decoration: const InputDecoration(
                  labelText: 'きっかけ',
                  hintText: '例：BGMフェードアウト→司会登壇')),
              const SizedBox(height: 12),
              TextField(controller: _ownerCtrl,
                decoration: const InputDecoration(labelText: '担当')),
              const SizedBox(height: 12),
              TextField(controller: _memoCtrl,
                decoration: const InputDecoration(labelText: '備考'), maxLines: 2),
              const SizedBox(height: 20),
              Row(children: [
                if (isEdit) ...[
                  Expanded(child: OutlinedButton(
                    onPressed: () {
                      widget.provider.deleteEventCorner(widget.corner!.id);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('削除'))),
                  const SizedBox(width: 12),
                ],
                Expanded(child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isEdit ? '更新' : '追加'))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final c = EventCorner(
      id: widget.corner?.id, projectId: widget.projectId,
      time: _timeCtrl.text.trim(), name: _nameCtrl.text.trim(),
      minutes: int.tryParse(_minCtrl.text) ?? 0,
      presenter: _presenterCtrl.text.trim(),
      cue: _cueCtrl.text.trim(), owner: _ownerCtrl.text.trim(),
      memo: _memoCtrl.text.trim(),
      sortKey: widget.corner?.sortKey ?? widget.provider.eventCorners.length,
    );
    if (widget.corner != null) {
      widget.provider.updateEventCorner(c);
    } else {
      widget.provider.addEventCorner(c);
    }
    Navigator.pop(context);
  }
}
