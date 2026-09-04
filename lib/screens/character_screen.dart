// 役の詳細画面（映画・ドラマ向け）
// 各キャラクターの設定・衣装・メイクをまとめて管理
// AIアシストで脚本から性格・背景を自動生成できる
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final characters = provider.characters;
    final cast = provider.castMembers;

    return Scaffold(
      body: characters.isEmpty
          ? EmptyState(
              icon: Icons.theater_comedy_outlined,
              title: '役の設定がありません',
              subtitle: '出演者を登録してから役を追加してください',
              action: cast.isEmpty ? null : OutlinedButton(
                onPressed: () => _showAdd(context, provider),
                child: const Text('役を追加する')),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: characters.length,
              itemBuilder: (_, i) => _CharacterTile(
                character: characters[i],
                cast: cast,
                provider: provider),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, provider),
        child: const Icon(Icons.add)),
    );
  }

  void _showAdd(BuildContext ctx, ProjectProvider provider) {
    showAppSheet(ctx, _CharacterEditSheet(
      projectId: provider.currentProject!.id,
      provider: provider));
  }
}

class _CharacterTile extends StatelessWidget {
  final CharacterDetail character;
  final List<CastMember> cast;
  final ProjectProvider provider;
  const _CharacterTile({required this.character,
    required this.cast, required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // 紐づく演者を取得
    final actor = cast.where((c) => c.id == character.castId).firstOrNull;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showAppSheet(context, _CharacterEditSheet(
          projectId: character.projectId,
          provider: provider,
          character: character,
          cast: cast)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 役名バッジ
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: glightGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.theater_comedy_outlined,
                      color: glightGreen, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(character.name.isEmpty ? '（役名未設定）' : character.name,
                          style: tt.titleMedium),
                        if (actor != null)
                          Text('出演：${actor.name}',
                            style: tt.bodySmall),
                      ],
                    ),
                  ),
                  if (character.age.isNotEmpty)
                    Tag(character.age),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () => _showOptions(context)),
                ],
              ),
              if (character.personality.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 6),
                Text(character.personality,
                  style: tt.bodySmall, maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              ],
              // タグ行
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (character.costumeMemo.isNotEmpty)
                  Tag('衣装: ${character.costumeMemo}',
                    color: Colors.purple),
                if (character.makeup.isNotEmpty)
                  Tag('メイク: ${character.makeup}',
                    color: Colors.pink),
                if (character.sceneNos.isNotEmpty)
                  Tag('シーン: ${character.sceneNos}',
                    color: Colors.blue),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext ctx) {
    showModalBottomSheet(context: ctx, builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.edit_outlined),
          title: const Text('編集'),
          onTap: () { Navigator.pop(ctx);
            showAppSheet(ctx, _CharacterEditSheet(
              projectId: character.projectId,
              provider: provider, character: character, cast: cast));
          }),
        ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('削除', style: TextStyle(color: Colors.red)),
          onTap: () { Navigator.pop(ctx); provider.deleteCharacter(character.id); }),
      ]),
    ));
  }
}

class _CharacterEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final CharacterDetail? character;
  final List<CastMember> cast;
  const _CharacterEditSheet({required this.projectId, required this.provider,
    this.character, this.cast = const []});

  @override
  State<_CharacterEditSheet> createState() => _CharacterEditSheetState();
}

class _CharacterEditSheetState extends State<_CharacterEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _personalityCtrl;
  late TextEditingController _costumeCtrl;
  late TextEditingController _makeupCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _sceneNosCtrl;
  String _castId = '';
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.character;
    _nameCtrl        = TextEditingController(text: c?.name ?? '');
    _ageCtrl         = TextEditingController(text: c?.age ?? '');
    _personalityCtrl = TextEditingController(text: c?.personality ?? '');
    _costumeCtrl     = TextEditingController(text: c?.costumeMemo ?? '');
    _makeupCtrl      = TextEditingController(text: c?.makeup ?? '');
    _notesCtrl       = TextEditingController(text: c?.notes ?? '');
    _sceneNosCtrl    = TextEditingController(text: c?.sceneNos ?? '');
    _castId          = c?.castId ?? '';
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _ageCtrl, _personalityCtrl,
        _costumeCtrl, _makeupCtrl, _notesCtrl, _sceneNosCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // AIで役の性格・背景を自動生成
  Future<void> _aiAssist() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('役名を入力してください')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key') ?? '';
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI解析タブでAPIキーを設定してください')));
      return;
    }

    setState(() => _aiLoading = true);
    try {
      final project = widget.provider.currentProject!;
      // プロジェクトの情報と既存の役情報をもとにAIが補完
      final prompt = '''
映画「${project.title}」の登場人物「${_nameCtrl.text}」について、以下のJSON形式で詳細を生成してください。
JSONのみ出力し、前置きは不要です。

{
  "age": "年齢設定（例：30代前半）",
  "personality": "性格・人物背景（3〜5文で詳しく）",
  "costume": "衣装の特徴・イメージ",
  "makeup": "メイクの特徴・ポイント",
  "notes": "演技上の注意点・特記事項"
}

既存情報：
- シーン番号: ${_sceneNosCtrl.text}
- 年齢: ${_ageCtrl.text}
''';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-3.6-flash:generateContent?key=$apiKey');
      final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024},
        }));

      if (response.statusCode != 200) throw Exception('APIエラー');
      final data = jsonDecode(response.body);
      var content = data['candidates'][0]['content']['parts'][0]['text'] as String;
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final sc = content.indexOf('{'), ec = content.lastIndexOf('}');
      final result = jsonDecode(content.substring(sc, ec + 1)) as Map;

      setState(() {
        if ((result['age'] ?? '').toString().isNotEmpty && _ageCtrl.text.isEmpty)
          _ageCtrl.text = result['age'].toString();
        if ((result['personality'] ?? '').toString().isNotEmpty)
          _personalityCtrl.text = result['personality'].toString();
        if ((result['costume'] ?? '').toString().isNotEmpty && _costumeCtrl.text.isEmpty)
          _costumeCtrl.text = result['costume'].toString();
        if ((result['makeup'] ?? '').toString().isNotEmpty && _makeupCtrl.text.isEmpty)
          _makeupCtrl.text = result['makeup'].toString();
        if ((result['notes'] ?? '').toString().isNotEmpty && _notesCtrl.text.isEmpty)
          _notesCtrl.text = result['notes'].toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AIアシストエラー: $e')));
    } finally {
      setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.character != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            SheetHeader(
              title: isEdit ? '役を編集' : '役を追加',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                // AIアシストボタン
                TextButton.icon(
                  onPressed: _aiLoading ? null : _aiAssist,
                  icon: _aiLoading
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_outlined, size: 16),
                  label: Text(_aiLoading ? '生成中...' : 'AI補完')),
                if (isEdit)
                  TextButton(onPressed: () {
                    widget.provider.deleteCharacter(widget.character!.id);
                    Navigator.pop(context);
                  }, child: const Text('削除',
                    style: TextStyle(color: Colors.red))),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // 役名・演者
                  Row(children: [
                    Expanded(child: TextField(controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: '役名'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _ageCtrl,
                      decoration: const InputDecoration(labelText: '年齢設定',
                        hintText: '30代前半'))),
                  ]),
                  const SizedBox(height: 12),
                  // 演者紐づけ
                  if (widget.cast.isNotEmpty) ...[
                    Text('出演者', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 6,
                      children: widget.cast.map((c) => ChoiceChip(
                        label: Text(c.name),
                        selected: _castId == c.id,
                        onSelected: (_) => setState(() =>
                          _castId = _castId == c.id ? '' : c.id),
                      )).toList()),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: _personalityCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '性格・人物背景',
                      hintText: 'AI補完ボタンで自動生成できます')),
                  const SizedBox(height: 12),
                  TextField(controller: _costumeCtrl, maxLines: 2,
                    decoration: const InputDecoration(labelText: '衣装メモ')),
                  const SizedBox(height: 12),
                  TextField(controller: _makeupCtrl,
                    decoration: const InputDecoration(labelText: 'メイク・ヘアメモ')),
                  const SizedBox(height: 12),
                  TextField(controller: _sceneNosCtrl,
                    decoration: const InputDecoration(
                      labelText: '登場シーン番号',
                      hintText: '1, 3, 5-8, 12')),
                  const SizedBox(height: 12),
                  TextField(controller: _notesCtrl, maxLines: 2,
                    decoration: const InputDecoration(labelText: '演技上の注意・特記事項')),
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
    final c = CharacterDetail(
      id: widget.character?.id,
      projectId: widget.projectId,
      name: _nameCtrl.text.trim(),
      castId: _castId,
      age: _ageCtrl.text.trim(),
      personality: _personalityCtrl.text.trim(),
      costumeMemo: _costumeCtrl.text.trim(),
      makeup: _makeupCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      sceneNos: _sceneNosCtrl.text.trim(),
    );
    if (widget.character != null) {
      widget.provider.updateCharacter(c);
    } else {
      widget.provider.addCharacter(c);
    }
    Navigator.pop(context);
  }
}
