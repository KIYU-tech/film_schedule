// カンファレンス セッション表画面
// 登壇者・会場・形式・資料・通訳を管理
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

class ConferenceSessionScreen extends StatelessWidget {
  const ConferenceSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final sessions = provider.conferenceSessions;
    final totalMin = sessions.fold(0, (a, b) => a + b.minutes);

    return Scaffold(
      body: Column(
        children: [
          if (sessions.isNotEmpty)
            SummaryBar(children: [
              StatChip(label: '合計', value: '${totalMin ~/ 60}h${totalMin % 60}m'),
              StatChip(label: 'セッション', value: '${sessions.length}件'),
              StatChip(label: '通訳あり',
                value: '${sessions.where((s) => s.hasInterpreter).length}件',
                color: Colors.blue),
            ]),
          Expanded(
            child: sessions.isEmpty
                ? EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'セッションがありません',
                    action: OutlinedButton(
                      onPressed: () => _showAdd(context, provider),
                      child: const Text('セッションを追加')))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: sessions.length,
                    itemBuilder: (_, i) => _SessionTile(
                      session: sessions[i], provider: provider)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, provider),
        child: const Icon(Icons.add)),
    );
  }

  void _showAdd(BuildContext ctx, ProjectProvider provider) {
    showAppSheet(ctx, _SessionEditSheet(
      projectId: provider.currentProject!.id, provider: provider));
  }
}

class _SessionTile extends StatelessWidget {
  final ConferenceSession session;
  final ProjectProvider provider;
  const _SessionTile({required this.session, required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showAppSheet(context, _SessionEditSheet(
          projectId: session.projectId, provider: provider, session: session)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Tag(session.format, color: Colors.purple),
                if (session.hall.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Tag(session.hall, color: Colors.blue),
                ],
                if (session.hasInterpreter) ...[
                  const SizedBox(width: 8),
                  Tag('通訳あり', color: Colors.orange),
                ],
                const Spacer(),
                if (session.time.isNotEmpty)
                  Text(session.time, style: tt.labelMedium),
                if (session.minutes > 0) ...[
                  const SizedBox(width: 8),
                  Text('${session.minutes}分',
                    style: tt.titleMedium?.copyWith(color: glightGreen)),
                ],
              ]),
              const SizedBox(height: 8),
              Text(session.sessionName.isEmpty ? '（セッション名未設定）' : session.sessionName,
                style: tt.titleMedium),
              if (session.speakers.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.person_outline, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(child: Text(session.speakers, style: tt.bodySmall)),
                ]),
              ],
              if (session.hasMaterial) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.description_outlined, size: 13, color: glightGreen),
                  const SizedBox(width: 4),
                  Text('資料あり', style: tt.bodySmall?.copyWith(color: glightGreen)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final ConferenceSession? session;
  const _SessionEditSheet({required this.projectId, required this.provider, this.session});

  @override
  State<_SessionEditSheet> createState() => _SessionEditSheetState();
}

class _SessionEditSheetState extends State<_SessionEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _speakersCtrl;
  late TextEditingController _hallCtrl;
  late TextEditingController _memoCtrl;
  String _format = '講演';
  bool _hasInterpreter = false;
  bool _hasMaterial = false;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _nameCtrl     = TextEditingController(text: s?.sessionName ?? '');
    _timeCtrl     = TextEditingController(text: s?.time ?? '');
    _minCtrl      = TextEditingController(text: s != null && s.minutes > 0 ? '${s.minutes}' : '');
    _speakersCtrl = TextEditingController(text: s?.speakers ?? '');
    _hallCtrl     = TextEditingController(text: s?.hall ?? '');
    _memoCtrl     = TextEditingController(text: s?.memo ?? '');
    _format         = s?.format ?? '講演';
    _hasInterpreter = s?.hasInterpreter ?? false;
    _hasMaterial    = s?.hasMaterial ?? false;
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _timeCtrl, _minCtrl,
        _speakersCtrl, _hallCtrl, _memoCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.session != null;

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
              Text(isEdit ? 'セッションを編集' : 'セッションを追加',
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              // 形式
              Text('形式', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6,
                children: ConferenceSession.formats.map((f) => ChoiceChip(
                  label: Text(f), selected: _format == f,
                  onSelected: (_) => setState(() => _format = f))).toList()),
              const SizedBox(height: 12),
              TextField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'セッション名')),
              const SizedBox(height: 12),
              TextField(controller: _speakersCtrl,
                decoration: const InputDecoration(
                  labelText: '登壇者',
                  hintText: '1行に1人'),
                maxLines: 3),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _timeCtrl,
                  decoration: const InputDecoration(
                    labelText: '開始時刻', hintText: '10:00'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _minCtrl,
                  decoration: const InputDecoration(labelText: '尺（分）'),
                  keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _hallCtrl,
                decoration: const InputDecoration(
                  labelText: '会場・ホール',
                  hintText: '例：メインホール、Room A')),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _hasInterpreter,
                onChanged: (v) => setState(() => _hasInterpreter = v),
                title: const Text('同時通訳あり'),
                activeColor: glightGreen, contentPadding: EdgeInsets.zero),
              SwitchListTile(
                value: _hasMaterial,
                onChanged: (v) => setState(() => _hasMaterial = v),
                title: const Text('配布資料あり'),
                activeColor: glightGreen, contentPadding: EdgeInsets.zero),
              TextField(controller: _memoCtrl,
                decoration: const InputDecoration(labelText: '備考'), maxLines: 2),
              const SizedBox(height: 20),
              Row(children: [
                if (isEdit) ...[
                  Expanded(child: OutlinedButton(
                    onPressed: () {
                      widget.provider.deleteConferenceSession(widget.session!.id);
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
    final s = ConferenceSession(
      id: widget.session?.id, projectId: widget.projectId,
      time: _timeCtrl.text.trim(), sessionName: _nameCtrl.text.trim(),
      minutes: int.tryParse(_minCtrl.text) ?? 0,
      speakers: _speakersCtrl.text.trim(), hall: _hallCtrl.text.trim(),
      format: _format, hasInterpreter: _hasInterpreter, hasMaterial: _hasMaterial,
      memo: _memoCtrl.text.trim(),
      sortKey: widget.session?.sortKey ?? widget.provider.conferenceSessions.length,
    );
    if (widget.session != null) {
      widget.provider.updateConferenceSession(s);
    } else {
      widget.provider.addConferenceSession(s);
    }
    Navigator.pop(context);
  }
}
