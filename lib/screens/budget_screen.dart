import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final items = provider.budgetItems;

    final totalBudget = items.fold(0, (a, b) => a + b.budget);
    final totalActual = items.fold(0, (a, b) => a + b.actual);
    final balance = totalBudget - totalActual;

    return Scaffold(
      body: Column(
        children: [
          // サマリーカード
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                _SummaryChip(label: '予算合計',
                  value: totalBudget, color: Colors.blue),
                const SizedBox(width: 12),
                _SummaryChip(label: '実績合計',
                  value: totalActual, color: Colors.orange),
                const SizedBox(width: 12),
                _SummaryChip(label: '残高',
                  value: balance,
                  color: balance >= 0 ? glightGreen : Colors.red),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                          size: 56, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text('予算項目がありません',
                          style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => _addPreset(provider),
                          child: const Text('標準項目を入れる'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _BudgetTile(
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
      builder: (_) => _BudgetEditSheet(
        projectId: provider.currentProject!.id,
        provider: provider,
      ),
    );
  }

  Future<void> _addPreset(ProjectProvider provider) async {
    final type = provider.currentProject!.type;
    final presets = _getPresets(type);
    for (final p in presets) {
      await provider.addBudgetItem(BudgetItem(
        projectId: provider.currentProject!.id,
        category: p.$1, name: p.$2, budget: p.$3,
      ));
    }
  }

  List<(String, String, int)> _getPresets(ProjectType type) {
    switch (type) {
      case ProjectType.film:
      case ProjectType.video:
        return [
          ('制作費', 'スタッフ人件費', 0),
          ('制作費', 'キャスト出演料', 0),
          ('機材費', 'カメラ・レンズレンタル', 0),
          ('機材費', '照明機材', 0),
          ('ロケ費', 'ロケ地使用料', 0),
          ('交通費', '車両・移動費', 0),
          ('食費', 'ケータリング', 0),
          ('編集費', '編集・MA・カラグレ', 0),
          ('その他', '雑費・予備費', 0),
        ];
      case ProjectType.broadcast:
      case ProjectType.live:
      case ProjectType.event:
      case ProjectType.conference:
        return [
          ('会場費', '会場使用料', 0),
          ('技術費', '配信・音響・映像機材', 0),
          ('人件費', 'スタッフ人件費', 0),
          ('出演費', '出演者・ゲスト', 0),
          ('制作費', 'グラフィック・印刷物', 0),
          ('交通費', '交通・宿泊費', 0),
          ('食費', 'ケータリング', 0),
          ('その他', '雑費・予備費', 0),
        ];
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SummaryChip({
    required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: TextStyle(
                fontSize: 11, color: color,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_fmt(value),
              style: TextStyle(
                fontSize: 15, color: color,
                fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  String _fmt(int v) {
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${v < 0 ? '-' : ''}¥$buf';
  }
}

class _BudgetTile extends StatelessWidget {
  final BudgetItem item;
  final ProjectProvider provider;
  const _BudgetTile({required this.item, required this.provider});

  Color _statusColor() {
    if (item.budget == 0) return Colors.grey;
    if (item.actual > item.budget) return Colors.red;
    if (item.actual == item.budget) return Colors.orange;
    return glightGreen;
  }

  String _fmt(int v) {
    if (v == 0) return '—';
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '¥$buf';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final diff = item.budget - item.actual;

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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15))),
                  IconButton(
                    icon: Icon(Icons.more_vert, size: 18,
                      color: cs.onSurface.withOpacity(0.4)),
                    onPressed: () => _showOptions(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _amountCell('予算', item.budget, Colors.blue),
                  const SizedBox(width: 8),
                  _amountCell('実績', item.actual, Colors.orange),
                  const SizedBox(width: 8),
                  _amountCell('差額',
                    diff, diff >= 0 ? glightGreen : Colors.red),
                ],
              ),
              if (item.budget > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.actual / item.budget,
                    backgroundColor: cs.outline,
                    valueColor: AlwaysStoppedAnimation(
                      _statusColor()),
                    minHeight: 5,
                  ),
                ),
              ],
              if (item.memo.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(item.memo,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountCell(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: TextStyle(
                fontSize: 10, color: color.withOpacity(0.7))),
            Text(_fmt(value),
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: color)),
          ],
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
              onTap: () { Navigator.pop(ctx); _showEdit(ctx); },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline, color: Colors.red),
              title: const Text('削除',
                style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                provider.deleteBudgetItem(item.id);
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
      builder: (_) => _BudgetEditSheet(
        projectId: item.projectId,
        provider: provider,
        item: item,
      ),
    );
  }
}

class _BudgetEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final BudgetItem? item;
  const _BudgetEditSheet({
    required this.projectId, required this.provider, this.item});

  @override
  State<_BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends State<_BudgetEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _budgetCtrl;
  late TextEditingController _actualCtrl;
  late TextEditingController _memoCtrl;
  String _category = 'その他';

  static const _categories = [
    '制作費','人件費','出演費','機材費','会場費',
    'ロケ費','技術費','交通費','食費','その他'
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.item;
    _nameCtrl   = TextEditingController(text: b?.name ?? '');
    _budgetCtrl = TextEditingController(
      text: b != null && b.budget > 0 ? '${b.budget}' : '');
    _actualCtrl = TextEditingController(
      text: b != null && b.actual > 0 ? '${b.actual}' : '');
    _memoCtrl   = TextEditingController(text: b?.memo ?? '');
    _category   = b?.category ?? 'その他';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _budgetCtrl.dispose();
    _actualCtrl.dispose(); _memoCtrl.dispose();
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
            Text(isEdit ? '予算項目を編集' : '予算項目を追加',
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
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
                labelText: '項目名')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _budgetCtrl,
                  decoration: const InputDecoration(
                    labelText: '予算（円）',
                    hintText: '100000'),
                  keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _actualCtrl,
                  decoration: const InputDecoration(
                    labelText: '実績（円）',
                    hintText: '0'),
                  keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _memoCtrl,
              decoration: const InputDecoration(
                labelText: '備考・メモ')),
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
    final b = BudgetItem(
      id: widget.item?.id,
      projectId: widget.projectId,
      category: _category,
      name: _nameCtrl.text.trim(),
      budget: int.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 0,
      actual: int.tryParse(_actualCtrl.text.replaceAll(',', '')) ?? 0,
      memo: _memoCtrl.text.trim(),
    );
    if (widget.item != null) {
      widget.provider.updateBudgetItem(b);
    } else {
      widget.provider.addBudgetItem(b);
    }
    Navigator.pop(context);
  }
}
