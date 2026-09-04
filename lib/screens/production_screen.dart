// 制作物リスト画面
// カテゴリ別アコーディオン表示 + AI自動リストアップ
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

    // カテゴリ別にグループ化
    final Map<String, List<ProductionItem>> grouped = {};
    for (final cat in ProductionItem.categories) {
      final catItems = items.where((i) => i.category == cat).toList();
      grouped[cat] = catItems;
    }
    // その他カテゴリに含まれない項目も拾う
    final knownCats = ProductionItem.categories.toSet();
    final uncategorized = items.where((i) => !knownCats.contains(i.category)).toList();
    if (uncategorized.isNotEmpty) {
      grouped['その他'] = [...(grouped['その他'] ?? []), ...uncategorized];
    }

    return Scaffold(
      body: Column(
        children: [
          // 進捗サマリー
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$done / ${items.length} 完了',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${items.isEmpty ? 0 : (done / items.length * 100).round()}%',
                        style: const TextStyle(
                          color: glightGreen, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 6),
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
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                    children: grouped.entries
                      .where((e) => e.value.isNotEmpty)
                      .map((e) => _CategoryAccordion(
                        category: e.key,
                        items: e.value,
                        provider: provider,
                        statusColor: _statusColor,
                      )).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
JSONのみ出力してください。カテゴリは以下のいずれかを使用:
書類・台本, 映像, 音声・楽曲, グラフィック・デザイン, 衣装・小道具, その他

[{"category":"カテゴリ名","name":"制作物名","owner":"","deadline":""}]

10〜15件リストアップしてください。
''';

    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('AIが制作物リストを生成中...')));

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-2.0-flash:generateContent?key=$apiKey');
      final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.5, 'maxOutputTokens': 2048},
        }));

      if (response.statusCode != 200) throw Exception('APIエラー: ${response.statusCode}');
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
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('${items.length}件の制作物を追加しました')));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('エラー: $e')));
      }
    }
  }
}

// ===== カテゴリアコーディオン =====
class _CategoryAccordion extends StatefulWidget {
  final String category;
  final List<ProductionItem> items;
  final ProjectProvider provider;
  final Color Function(ProductionStatus) statusColor;

  const _CategoryAccordion({
    required this.category,
    required this.items,
    required this.provider,
    required this.statusColor,
  });

  @override
  State<_CategoryAccordion> createState() => _CategoryAccordionState();
}

class _CategoryAccordionState extends State<_CategoryAccordion> {
  bool _expanded = true; // デフォルトで開いた状態

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final done = widget.items.where((i) => i.status == 'done').length;
    final total = widget.items.length;

    // カテゴリアイコン
    final icon = _categoryIcon(widget.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // カテゴリヘッダー（クリックで展開/折りたたみ）
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Icon(icon, color: glightGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.category,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  // 完了数バッジ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: done == total
                          ? Colors.green.withOpacity(0.15)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(99)),
                    child: Text('$done/$total',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: done == total ? Colors.green : cs.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
          // アイテムリスト（展開時のみ表示）
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.items.map((item) => _ProductionTile(
              item: item,
              provider: widget.provider,
              statusColor: widget.statusColor(item.statusEnum),
            )),
          ],
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case '書類・台本':         return Icons.description_outlined;
      case '映像':              return Icons.videocam_outlined;
      case '音声・楽曲':         return Icons.music_note_outlined;
      case 'グラフィック・デザイン': return Icons.palette_outlined;
      case '衣装・小道具':       return Icons.checkroom_outlined;
      default:                  return Icons.checklist_outlined;
    }
  }
}

// ===== 制作物タイル =====
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

    return InkWell(
      onTap: () => showAppSheet(context, _ProductionEditSheet(
        projectId: item.projectId, provider: provider, item: item)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            // ステータスインジケーター
            Container(width: 3, height: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                  if (item.owner.isNotEmpty || item.deadline.isNotEmpty)
                    Row(children: [
                      if (item.owner.isNotEmpty) ...[
                        Icon(Icons.person_outline, size: 12,
                          color: cs.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(item.owner, style: tt.bodySmall),
                        const SizedBox(width: 8),
                      ],
                      if (item.deadline.isNotEmpty) ...[
                        Icon(Icons.calendar_today_outlined, size: 12,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3))),
                child: Text(item.statusEnum.label,
                  style: TextStyle(fontSize: 11, color: statusColor,
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
    );
  }
}

// ===== 編集シート =====
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
              Text('カテゴリ', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6,
                children: ProductionItem.categories.map((c) => ChoiceChip(
                  label: Text(c, style: const TextStyle(fontSize: 12)),
                  selected: _category == c,
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
              Text('ステータス', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6,
                children: ProductionStatus.values.map((s) => ChoiceChip(
                  label: Text(s.label, style: const TextStyle(fontSize: 12)),
                  selected: _status == s.name,
                  onSelected: (_) => setState(() => _status = s.name))).toList()),
              const SizedBox(height: 12),
              TextField(controller: _memoCtrl,
                decoration: const InputDecoration(labelText: '備考')),
              const SizedBox(height: 20),
              Row(children: [
                if (isEdit) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.provider.deleteProduction(widget.item!.id);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red)),
                      child: const Text('削除')),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
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
