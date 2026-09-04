import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

class GanttScreen extends StatefulWidget {
  const GanttScreen({super.key});

  @override
  State<GanttScreen> createState() => _GanttScreenState();
}

class _GanttScreenState extends State<GanttScreen> {
  static const _rowH = 52.0;
  static const _dayW = 36.0;
  static const _labelW = 140.0;

  final _vertScroll = ScrollController();
  final _horizScroll = ScrollController();
  final _headerScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _horizScroll.addListener(() {
      if (_headerScroll.hasClients) {
        _headerScroll.jumpTo(_horizScroll.offset);
      }
    });
  }

  @override
  void dispose() {
    _vertScroll.dispose();
    _horizScroll.dispose();
    _headerScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final tasks = provider.ganttTasks;

    if (tasks.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_outlined,
                size: 56, color: Colors.grey[700]),
              const SizedBox(height: 12),
              Text('タスクがありません',
                style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _addPreset(context, provider),
                child: const Text('標準タスクを入れる'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAdd(context, provider),
          backgroundColor: glightGreen,
          foregroundColor: Colors.black,
          child: const Icon(Icons.add),
        ),
      );
    }

    // 日付範囲を計算
    final dates = _buildDateRange(tasks);
    final today = DateTime.now();

    return Scaffold(
      body: Column(
        children: [
          // ヘッダー行（日付）
          Container(
            color: Theme.of(context).colorScheme.surface,
            height: 40,
            child: Row(
              children: [
                SizedBox(width: _labelW,
                  child: Center(
                    child: Text('タスク',
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)))),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerScroll,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: dates.map((d) {
                        final isToday = _sameDay(d, today);
                        return Container(
                          width: _dayW,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isToday
                                ? glightGreen.withOpacity(0.15)
                                : null,
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey.withOpacity(0.15))),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${d.month}/${d.day}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isToday
                                      ? glightGreen : Colors.grey,
                                  fontWeight: isToday
                                      ? FontWeight.w700 : FontWeight.normal)),
                              Text(_weekday(d.weekday),
                                style: TextStyle(
                                  fontSize: 8,
                                  color: d.weekday >= 6
                                      ? Colors.red.withOpacity(0.7)
                                      : Colors.grey.withOpacity(0.6))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // タスク行
          Expanded(
            child: SingleChildScrollView(
              controller: _vertScroll,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左側：タスク名
                  SizedBox(
                    width: _labelW,
                    child: Column(
                      children: tasks.map((t) =>
                        _TaskLabel(task: t, height: _rowH,
                          provider: provider,
                          onTap: () => _showEdit(context, provider, t))).toList(),
                    ),
                  ),
                  // 右側：バー
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _horizScroll,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: dates.length * _dayW,
                        child: Column(
                          children: tasks.map((t) =>
                            _GanttBar(
                              task: t, dates: dates,
                              dayW: _dayW, rowH: _rowH,
                              today: today)).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

  List<DateTime> _buildDateRange(List<GanttTask> tasks) {
    if (tasks.isEmpty) return [];
    var minD = tasks.first.startDate;
    var maxD = tasks.first.endDate;
    for (final t in tasks) {
      if (t.startDate.isBefore(minD)) minD = t.startDate;
      if (t.endDate.isAfter(maxD)) maxD = t.endDate;
    }
    // 前後に余白
    minD = minD.subtract(const Duration(days: 3));
    maxD = maxD.add(const Duration(days: 3));
    final list = <DateTime>[];
    var d = minD;
    while (!d.isAfter(maxD)) {
      list.add(d);
      d = d.add(const Duration(days: 1));
    }
    return list;
  }

  bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekday(int w) {
    const days = ['月','火','水','木','金','土','日'];
    return days[w - 1];
  }

  void _showAdd(BuildContext ctx, ProjectProvider provider) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GanttEditSheet(
        projectId: provider.currentProject!.id,
        provider: provider,
      ),
    );
  }

  void _showEdit(BuildContext ctx, ProjectProvider provider,
      GanttTask task) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GanttEditSheet(
        projectId: task.projectId,
        provider: provider,
        task: task,
      ),
    );
  }

  Future<void> _addPreset(BuildContext ctx,
      ProjectProvider provider) async {
    final type = provider.currentProject!.type;
    final now = DateTime.now();
    final presets = _getPresets(type, now);
    for (final p in presets) {
      await provider.addGanttTask(GanttTask(
        projectId: provider.currentProject!.id,
        category: p.$1, name: p.$2,
        startDate: p.$3, endDate: p.$4,
      ));
    }
  }

  List<(String, String, DateTime, DateTime)> _getPresets(
      ProjectType type, DateTime now) {
    DateTime d(int days) =>
        now.add(Duration(days: days));
    switch (type) {
      case ProjectType.film:
      case ProjectType.video:
        return [
          ('企画', '企画・脚本', d(0), d(14)),
          ('準備', 'キャスティング', d(7), d(21)),
          ('準備', 'ロケハン', d(14), d(21)),
          ('準備', '機材手配', d(14), d(28)),
          ('撮影', '撮影', d(28), d(35)),
          ('編集', '編集・VFX', d(35), d(49)),
          ('編集', '音楽・MA', d(45), d(56)),
          ('納品', '試写・修正', d(56), d(63)),
          ('納品', '納品', d(63), d(65)),
        ];
      default:
        return [
          ('企画', '企画・構成', d(0), d(14)),
          ('準備', 'キャスト・スタッフ手配', d(7), d(21)),
          ('準備', '会場・機材手配', d(14), d(28)),
          ('準備', 'リハーサル', d(28), d(34)),
          ('本番', '本番', d(35), d(36)),
          ('後処理', '報告・精算', d(36), d(42)),
        ];
    }
  }
}

class _TaskLabel extends StatelessWidget {
  final GanttTask task;
  final double height;
  final ProjectProvider provider;
  final VoidCallback onTap;
  const _TaskLabel({required this.task, required this.height,
    required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outline, width: 0.5))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(task.name,
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: _catColor(task.category)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(3)),
                  child: Text(task.category,
                    style: TextStyle(
                      fontSize: 9,
                      color: _catColor(task.category)))),
                if (task.owner.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(task.owner,
                      style: TextStyle(
                        fontSize: 9,
                        color: cs.onSurface.withOpacity(0.4)),
                      overflow: TextOverflow.ellipsis)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case '企画': return Colors.purple;
      case '準備': return Colors.blue;
      case '撮影': return glightGreen;
      case '編集': return Colors.orange;
      case '納品': return Colors.red;
      case '本番': return glightGreen;
      case '後処理': return Colors.grey;
      default:    return Colors.teal;
    }
  }
}

class _GanttBar extends StatelessWidget {
  final GanttTask task;
  final List<DateTime> dates;
  final double dayW;
  final double rowH;
  final DateTime today;
  const _GanttBar({required this.task, required this.dates,
    required this.dayW, required this.rowH, required this.today});

  Color _barColor() {
    switch (task.category) {
      case '企画': return Colors.purple.shade400;
      case '準備': return Colors.blue.shade400;
      case '撮影': return glightGreen;
      case '編集': return Colors.orange.shade400;
      case '納品': return Colors.red.shade400;
      case '本番': return glightGreen;
      default:    return Colors.teal.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: rowH,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outline, width: 0.5))),
      child: Stack(
        children: [
          // 日付グリッド線
          Row(
            children: dates.map((d) {
              final isToday = d.year == today.year &&
                d.month == today.month && d.day == today.day;
              final isWeekend = d.weekday >= 6;
              return Container(
                width: dayW,
                decoration: BoxDecoration(
                  color: isToday
                      ? glightGreen.withOpacity(0.06)
                      : isWeekend
                          ? Colors.red.withOpacity(0.03)
                          : null,
                  border: Border(
                    right: BorderSide(
                      color: cs.outline.withOpacity(0.3)))),
              );
            }).toList(),
          ),
          // バー
          Positioned(
            left: _offsetX(),
            top: rowH * 0.28,
            child: Container(
              width: _barWidth(),
              height: rowH * 0.44,
              decoration: BoxDecoration(
                color: _barColor(),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: _barColor().withOpacity(0.3),
                    blurRadius: 4, offset: const Offset(0, 1))
                ],
              ),
              child: task.progress > 0
                  ? Stack(children: [
                      FractionallySizedBox(
                        widthFactor: task.progress / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      Center(
                        child: Text('${task.progress}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700))),
                    ])
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  double _offsetX() {
    for (var i = 0; i < dates.length; i++) {
      if (_sameDay(dates[i], task.startDate)) return i * dayW;
    }
    return 0;
  }

  double _barWidth() {
    int start = 0, end = 0;
    for (var i = 0; i < dates.length; i++) {
      if (_sameDay(dates[i], task.startDate)) start = i;
      if (_sameDay(dates[i], task.endDate)) end = i;
    }
    final days = (end - start + 1).clamp(1, dates.length);
    return days * dayW;
  }

  bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
}

class _GanttEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final GanttTask? task;
  const _GanttEditSheet({required this.projectId,
    required this.provider, this.task});

  @override
  State<_GanttEditSheet> createState() => _GanttEditSheetState();
}

class _GanttEditSheetState extends State<_GanttEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _memoCtrl;
  String _category = '準備';
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 7));
  int _progress = 0;

  static const _categories = [
    '企画','準備','撮影','編集','音声','納品','本番','後処理','その他'
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _nameCtrl  = TextEditingController(text: t?.name ?? '');
    _ownerCtrl = TextEditingController(text: t?.owner ?? '');
    _memoCtrl  = TextEditingController(text: t?.memo ?? '');
    _category  = t?.category ?? '準備';
    _start     = t?.startDate ?? DateTime.now();
    _end       = t?.endDate ??
        DateTime.now().add(const Duration(days: 7));
    _progress  = t?.progress ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _ownerCtrl.dispose(); _memoCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.task != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20))),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(isEdit ? 'タスクを編集' : 'タスクを追加',
                    style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (isEdit)
                    TextButton(
                      onPressed: () {
                        widget.provider.deleteGanttTask(
                          widget.task!.id);
                        Navigator.pop(context);
                      },
                      child: const Text('削除',
                        style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text('カテゴリ',
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
                      labelText: 'タスク名')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ownerCtrl,
                    decoration: const InputDecoration(
                      labelText: '担当者')),
                  const SizedBox(height: 12),
                  // 期間
                  Row(children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('開始日',
                          style: TextStyle(fontSize: 13,
                            color: Colors.grey)),
                        subtitle: Text(_fmtDate(_start),
                          style: const TextStyle(fontSize: 15)),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _start,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030));
                          if (d != null) setState(() => _start = d);
                        },
                      ),
                    ),
                    const Text('〜'),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('終了日',
                          style: TextStyle(fontSize: 13,
                            color: Colors.grey)),
                        subtitle: Text(_fmtDate(_end),
                          style: const TextStyle(fontSize: 15)),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _end,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030));
                          if (d != null) setState(() => _end = d);
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  // 進捗
                  Text('進捗：$_progress%',
                    style: TextStyle(
                      fontSize: 13, color: Colors.grey[600])),
                  Slider(
                    value: _progress.toDouble(),
                    min: 0, max: 100, divisions: 20,
                    activeColor: glightGreen,
                    label: '$_progress%',
                    onChanged: (v) =>
                      setState(() => _progress = v.round()),
                  ),
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
    if (_end.isBefore(_start)) _end = _start;
    final t = GanttTask(
      id: widget.task?.id,
      projectId: widget.projectId,
      category: _category,
      name: _nameCtrl.text.trim(),
      startDate: _start,
      endDate: _end,
      owner: _ownerCtrl.text.trim(),
      progress: _progress,
      memo: _memoCtrl.text.trim(),
    );
    if (widget.task != null) {
      widget.provider.updateGanttTask(t);
    } else {
      widget.provider.addGanttTask(t);
    }
    Navigator.pop(context);
  }
}
