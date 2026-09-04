// 制作物リスト画面
// 映像・音声・グラフィックなど制作物の進捗を管理する
// AIアシストでプロジェクト内容から制作物を自動リストアップできる
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

class ProductionScreen extends StatelessWidget {
  const ProductionScreen({super.key});

  // ステータスごとの色
  Color _statusColor(ProductionStatus s) {
    switch (s) {
      case ProductionStatus.notStarted: return Colors.grey;
      case ProductionStatus.inProgress: return Colors.blue;
      case ProductionStatus.review:     return Colors.orange;
      case ProductionStatus.done:       return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final items = provider.productions;
    final done = items.where((p) => p.status == 'done').length;

    return Scaffold(
      body: Column(
        children: [
          // 進捗サマリー
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$done / ${items.length} 完了',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${(done / items.length * 100).round()}%',
                        style: const TextStyle(
                          color: glightGreen, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 進捗バー
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: items.isEmpty ? 0 : done / items.length,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation(glightGreen),
                      minHeight: 6)),
                ],
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.checklist_outlined,
                    title: '制作物がありません',
                    action: OutlinedButton.icon(
                      onPressed: () => _aiSuggest(context, provider),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                      label: const Text('AIでリストを生成')))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ProductionTile(
                      item: items[i], provider: provider,
                      statusColor: _statusColor(items[i].statusEnum))),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AIで一括生成
          FloatingActionButton.small(
            heroTag: 'ai',
            onPressed: () => _aiSuggest(context, provider),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: glightGreen,
            child: const Icon(Icons.auto_awesome_outlined)),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAdd(context, provider),
            child: const Icon(Icons.add)),
        ],
      ),
    );
  }

  void _showAdd(BuildContext ctx, ProjectProvider provider) {
    showAppSheet(ctx, _ProductionEditSheet(
      projectId: provider.currentProject!.id, provider: provider));
  }

  // AIでプロジェクト内容から制作物をリストアップ
  Future<void> _aiSuggest(BuildContext ctx, ProjectProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key') ?? '';
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('AI解析タブでAPIキーを設定してください')));
      return;
    }

    final project = provider.currentProject!;
    final prompt = '''
${project.type.label}「${project.title}」の制作物リストを提案してください。
JSONのみ出力してください。

[{"category":"映像/音声/グラフィック/書類/衣装・小道具/その他のいずれか","name":"制作物名","owner":"担当（空でよい）","deadline":"期日（空でよい）"}]

映像制作に必要な一般的な制作物を10〜15件リストアップしてください。
''';

    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('AIが制作物リストを生成中...')));

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-3.6-flash:generateContent?key=$apiKey');
      final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.5, 'maxOutputTokens': 2048},
        }));

      if (response.statusCode != 200) throw Exception('APIエラー');
      final data = jsonDecode(response.body);
      var content = data['candidates'][0]['content']['parts'][0]['text'] as String;
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final sb = content.indexOf('['), eb = content.lastIndexOf(']');
      final items = jsonDecode(content.substring(sb, eb + 1)) as List;

      for (final item in items) {
        final m = item as Map<String, dynamic>;
        await provider.addProduction(ProductionItem(
          projectId: project.id,
          category: m['category'] ?? 'その他',
          name: m['name'] ?? '',
          owner: m['owner'] ?? '',
          deadline: m['deadline'] ?? '',
        ));
      }
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('${items.length}件の制作物を追加しました')));
    } catch (e) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('エラー: $e')));
    }
  }
}

class _ProductionTile extends StatelessWidget {
  final ProductionItem item;
  final ProjectProvider provider;
  final Color statusColor;
  const _ProductionTile({required this.item, required this.provider,
    required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showAppSheet(context, _ProductionEditSheet(
          projectId: item.projectId, provider: provider, item: item)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              // ステータスインジケーター
              Container(width: 4, height: 44,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Tag(item.category, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.name,
                        style: tt.titleMedium, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (item.owner.isNotEmpty) ...[
                        Icon(Icons.person_outline, size: 13,
                          color: cs.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(item.owner, style: tt.bodySmall),
                        const SizedBox(width: 10),
                      ],
                      if (item.deadline.isNotEmpty) ...[
                        Icon(Icons.calendar_today_outlined, size: 13,
                          color: cs.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(item.deadline, style: tt.bodySmall),
                      ],
                    ]),
                  ],
                ),
              ),
              // ステータス選択
              PopupMenuButton<String>(
                initialValue: item.status,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3))),
                  child: Text(item.statusEnum.label,
                    style: TextStyle(fontSize: 12, color: statusColor,
                      fontWeight: FontWeight.w700))),
                itemBuilder: (_) => ProductionStatus.values.map((s) =>
                  PopupMenuItem(value: s.name, child: Text(s.label))).toList(),
                onSelected: (v) => provider.updateProduction(ProductionItem(
                  id: item.id, projectId: item.projectId,
                  category: item.category, name: item.name,
                  owner: item.owner, deadline: item.deadline,
                  status: v, memo: item.memo, sortKey: item.sortKey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductionEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final ProductionItem? item;
  const _ProductionEditSheet({required this.projectId, required this.provider, this.item});

  @override
  State<_ProductionEditSheet> createState() => _ProductionEditSheetState();
}

class _ProductionEditSheetState extends State<_ProductionEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _deadlineCtrl;
  late TextEditingController _memoCtrl;
  String _category = 'その他';
  String _status = 'notStarted';

  @override
  void initState() {
    super.initState();
    final p = widget.item;
    _nameCtrl     = TextEditingController(text: p?.name ?? '');
    _ownerCtrl    = TextEditingController(text: p?.owner ?? '');
    _deadlineCtrl = TextEditingController(text: p?.deadline ?? '');
    _memoCtrl     = TextEditingController(text: p?.memo ?? '');
    _category     = p?.category ?? 'その他';
    _status       = p?.status ?? 'notStarted';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _ownerCtrl.dispose();
    _deadlineCtrl.dispose(); _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.item != null;

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
              Text(isEdit ? '制作物を編集' : '制作物を追加',
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              // カテゴリ
              Text('カテゴリ', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6,
                children: ProductionItem.categories.map((c) => ChoiceChip(
                  label: Text(c), selected: _category == c,
                  onSelected: (_) => setState(() => _category = c))).toList()),
              const SizedBox(height: 12),
              TextField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '制作物名')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _ownerCtrl,
                  decoration: const InputDecoration(labelText: '担当'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _deadlineCtrl,
                  decoration: const InputDecoration(
                    labelText: '期日', hintText: '9/30'))),
              ]),
              const SizedBox(height: 12),
              // ステータス
              Text('ステータス', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6,
                children: ProductionStatus.values.map((s) => ChoiceChip(
                  label: Text(s.label), selected: _status == s.name,
                  onSelected: (_) => setState(() => _status = s.name))).toList()),
              const SizedBox(height: 12),
              TextField(controller: _memoCtrl,
                decoration: const InputDecoration(labelText: '備考')),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save,
                child: Text(isEdit ? '更新' : '追加')),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final p = ProductionItem(
      id: widget.item?.id, projectId: widget.projectId,
      category: _category, name: _nameCtrl.text.trim(),
      owner: _ownerCtrl.text.trim(), deadline: _deadlineCtrl.text.trim(),
      status: _status, memo: _memoCtrl.text.trim(),
      sortKey: widget.item?.sortKey ?? widget.provider.productions.length,
    );
    if (widget.item != null) {
      widget.provider.updateProduction(p);
    } else {
      widget.provider.addProduction(p);
    }
    Navigator.pop(context);
  }
}
