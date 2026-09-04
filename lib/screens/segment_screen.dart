import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

class SegmentScreen extends StatefulWidget {
  const SegmentScreen({super.key});

  @override
  State<SegmentScreen> createState() => _SegmentScreenState();
}

class _SegmentScreenState extends State<SegmentScreen> {
  BroadcastGenre _genre = BroadcastGenre.vtuber;
  static const _startTime = '19:00';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final segments = provider.segments;
    final timed = provider.calcSegmentTimes(_startTime);
    final totalMin = segments.fold(0, (a, b) => a + b.minutes);

    return Scaffold(
      body: Column(
        children: [
          _GenreBar(
            selected: _genre,
            onChanged: (g) => setState(() => _genre = g),
          ),
          if (segments.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Text('$_startTime 開始',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  Text('合計 ${totalMin}分',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  const Spacer(),
                  Text(
                    '終了 ${timed.isNotEmpty ? timed.last['endLabel'] : '--:--'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Expanded(
            child: segments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.view_list_outlined,
                          size: 56, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text('コーナーがありません',
                          style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => _addPreset(context, provider),
                          child: const Text('基本構成を入れる'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: timed.length,
                    onReorder: (old, nw) =>
                      provider.reorderSegments(old, nw),
                    itemBuilder: (_, i) {
                      final t = timed[i];
                      final seg = t['segment'] as BroadcastSegment;
                      return _SegmentTile(
                        key: ValueKey(seg.id),
                        segment: seg,
                        startLabel: t['startLabel'] as String,
                        endLabel: t['endLabel'] as String,
                        genre: _genre,
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
      builder: (_) => _SegmentEditSheet(
        projectId: provider.currentProject!.id,
        provider: provider,
        genre: _genre,
      ),
    );
  }

  Future<void> _addPreset(BuildContext ctx, ProjectProvider provider) async {
    final presets = [
      ('オープニング', 'OP・挨拶', 5),
      ('メイン', 'メインコーナー', 30),
      ('コーナー', 'サブコーナー', 20),
      ('エンディング', 'ED・告知・締め', 5),
    ];
    for (var i = 0; i < presets.length; i++) {
      await provider.addSegment(BroadcastSegment(
        projectId: provider.currentProject!.id,
        kind: presets[i].$1,
        title: presets[i].$2,
        minutes: presets[i].$3,
        sortKey: i,
      ));
    }
  }
}

class _GenreBar extends StatelessWidget {
  final BroadcastGenre selected;
  final ValueChanged<BroadcastGenre> onChanged;
  const _GenreBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: BroadcastGenre.values.map((g) {
          final isSelected = g == selected;
          return GestureDetector(
            onTap: () => onChanged(g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? glightGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? glightGreen : Colors.grey.shade700),
              ),
              child: Text(g.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.black : Colors.grey.shade400)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  final BroadcastSegment segment;
  final String startLabel;
  final String endLabel;
  final BroadcastGenre genre;
  final ProjectProvider provider;

  const _SegmentTile({
    super.key,
    required this.segment,
    required this.startLabel,
    required this.endLabel,
    required this.genre,
    required this.provider,
  });

  Color _kindColor() {
    switch (segment.kind) {
      case 'オープニング': return Colors.teal.shade400;
      case 'メイン':      return glightGreen;
      case 'ゲーム':      return Colors.purple.shade400;
      case 'インタビュー': return Colors.blue.shade400;
      case 'トーク':      return Colors.orange.shade400;
      case 'エンディング': return Colors.pink.shade400;
      case 'CM・休憩':    return Colors.grey.shade500;
      default:            return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showEdit(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(startLabel,
                        style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 13,
                          fontWeight: FontWeight.w700)),
                      Text(endLabel,
                        style: TextStyle(
                          fontFamily: 'monospace', fontSize: 11,
                          color: cs.onSurface.withOpacity(0.5))),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kindColor().withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _kindColor().withOpacity(0.4)),
                    ),
                    child: Text(segment.kind,
                      style: TextStyle(
                        fontSize: 11, color: _kindColor(),
                        fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(segment.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                      overflow: TextOverflow.ellipsis)),
                  Text('${segment.minutes}分',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.5))),
                  IconButton(
                    icon: Icon(Icons.more_vert, size: 18,
                      color: cs.onSurface.withOpacity(0.4)),
                    onPressed: () => _showOptions(context),
                  ),
                ],
              ),
              if (segment.gameTitle.isNotEmpty ||
                  segment.players.isNotEmpty ||
                  segment.telop.isNotEmpty ||
                  segment.commentMemo.isNotEmpty ||
                  segment.obsMemo.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12, runSpacing: 6,
                  children: [
                    if (segment.gameTitle.isNotEmpty)
                      _info(Icons.sports_esports_outlined,
                        segment.gameTitle),
                    if (segment.players.isNotEmpty)
                      _info(Icons.person_outline, segment.players),
                    if (segment.telop.isNotEmpty)
                      _info(Icons.closed_caption_outlined,
                        segment.telop),
                    if (segment.commentMemo.isNotEmpty)
                      _info(Icons.chat_bubble_outline,
                        segment.commentMemo),
                    if (segment.obsMemo.isNotEmpty)
                      _info(Icons.videocam_outlined, segment.obsMemo),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
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
              onTap: () { Navigator.pop(ctx); _showEdit(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('削除',
                style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                provider.deleteSegment(segment.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SegmentEditSheet(
        projectId: segment.projectId,
        provider: provider,
        genre: genre,
        segment: segment,
      ),
    );
  }
}

class _SegmentEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final BroadcastGenre genre;
  final BroadcastSegment? segment;

  const _SegmentEditSheet({
    required this.projectId,
    required this.provider,
    required this.genre,
    this.segment,
  });

  @override
  State<_SegmentEditSheet> createState() => _SegmentEditSheetState();
}

class _SegmentEditSheetState extends State<_SegmentEditSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _gameTitleCtrl;
  late TextEditingController _playersCtrl;
  late TextEditingController _telopCtrl;
  late TextEditingController _commentCtrl;
  late TextEditingController _obsCtrl;
  late TextEditingController _memoCtrl;
  late String _kind;

  @override
  void initState() {
    super.initState();
    final s = widget.segment;
    _titleCtrl    = TextEditingController(text: s?.title ?? '');
    _minCtrl      = TextEditingController(
      text: s != null && s.minutes > 0 ? '${s.minutes}' : '');
    _gameTitleCtrl = TextEditingController(text: s?.gameTitle ?? '');
    _playersCtrl  = TextEditingController(text: s?.players ?? '');
    _telopCtrl    = TextEditingController(text: s?.telop ?? '');
    _commentCtrl  = TextEditingController(text: s?.commentMemo ?? '');
    _obsCtrl      = TextEditingController(text: s?.obsMemo ?? '');
    _memoCtrl     = TextEditingController(text: s?.memo ?? '');
    _kind         = s?.kind ?? 'メイン';
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _minCtrl.dispose();
    _gameTitleCtrl.dispose(); _playersCtrl.dispose();
    _telopCtrl.dispose(); _commentCtrl.dispose();
    _obsCtrl.dispose(); _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.segment != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(isEdit ? 'コーナーを編集' : 'コーナーを追加',
                    style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: glightGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(widget.genre.label,
                      style: const TextStyle(
                        fontSize: 11, color: glightGreen,
                        fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  if (isEdit)
                    TextButton(
                      onPressed: () {
                        widget.provider.deleteSegment(
                          widget.segment!.id);
                        Navigator.pop(context);
                      },
                      child: const Text('削除',
                        style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text('コーナー種別',
                    style: TextStyle(
                      fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: BroadcastSegment.kinds.map((k) =>
                      ChoiceChip(
                        label: Text(k,
                          style: const TextStyle(fontSize: 12)),
                        selected: _kind == k,
                        onSelected: (_) =>
                          setState(() => _kind = k),
                      )).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'コーナー名'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _minCtrl,
                        decoration: const InputDecoration(
                          labelText: '尺（分）'),
                        keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _gameTitleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ゲームタイトル',
                      hintText: '例：マリオカート8DX')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _playersCtrl,
                    decoration: const InputDecoration(
                      labelText: 'プレイヤー・出演者')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _telopCtrl,
                    decoration: const InputDecoration(
                      labelText: 'テロップ内容'),
                    maxLines: 2),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentCtrl,
                    decoration: const InputDecoration(
                      labelText: '配信橋・コメントメモ'),
                    maxLines: 2),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _obsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'OBSシーン・切り替えメモ')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _memoCtrl,
                    decoration: const InputDecoration(
                      labelText: '備考'),
                    maxLines: 2),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? '更新' : '追加')),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final s = BroadcastSegment(
      id: widget.segment?.id,
      projectId: widget.projectId,
      kind: _kind,
      title: _titleCtrl.text.trim(),
      minutes: int.tryParse(_minCtrl.text) ?? 0,
      gameTitle: _gameTitleCtrl.text.trim(),
      players: _playersCtrl.text.trim(),
      telop: _telopCtrl.text.trim(),
      commentMemo: _commentCtrl.text.trim(),
      obsMemo: _obsCtrl.text.trim(),
      memo: _memoCtrl.text.trim(),
      sortKey: widget.segment?.sortKey
          ?? widget.provider.segments.length,
    );
    if (widget.segment != null) {
      widget.provider.updateSegment(s);
    } else {
      widget.provider.addSegment(s);
    }
    Navigator.pop(context);
  }
}
