import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _textCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showApiKey = false;
  String _result = '';
  String _selectedMode = 'auto';

  final _modes = [
    ('自動判定', 'auto'),
    ('台本・脚本', 'script'),
    ('座組表', 'cast'),
    ('進行表', 'rundown'),
    ('企画書', 'plan'),
    ('ロケ地リスト', 'location'),
  ];

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('gemini_api_key') ?? '';
    setState(() => _apiKeyCtrl.text = key);
  }

  Future<void> _saveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKeyCtrl.text.trim());
    setState(() => _showApiKey = false);
    _showSnack('APIキーを保存しました');
  }

  Future<void> _analyze(ProjectProvider provider) async {
    final apiKey = _apiKeyCtrl.text.trim();
    final text = _textCtrl.text.trim();

    if (apiKey.isEmpty) {
      _showSnack('APIキーを入力してください');
      setState(() => _showApiKey = true);
      return;
    }
    if (text.isEmpty) {
      _showSnack('テキストを入力してください');
      return;
    }

    setState(() { _isLoading = true; _result = ''; });

    try {
      final mode = _selectedMode == 'auto'
          ? _detectMode(text)
          : _selectedMode;

      final prompt = _buildPrompt(mode, text, provider.currentProject!);

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-1.5-flash:generateContent?key=$apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 4096,
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('APIエラー: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final content = data['candidates'][0]['content']['parts'][0]['text'] as String;

      await _applyResult(mode, content, provider);

    } catch (e) {
      setState(() => _result = 'エラー: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _detectMode(String text) {
    if (text.contains('シーン') || text.contains('ト書き') ||
        text.contains('柱')) return 'script';
    if (text.contains('氏名') || text.contains('キャスト') ||
        text.contains('座組')) return 'cast';
    if (text.contains('進行') || text.contains('タイムテーブル')) return 'rundown';
    if (text.contains('ロケ') || text.contains('住所')) return 'location';
    return 'plan';
  }

  String _buildPrompt(String mode, String text, Project project) {
    const base = '以下の内容を解析してください。JSONのみ出力し、前置きや説明は不要です。';
    switch (mode) {
      case 'script':
        return '$base\n\n脚本からシーンをJSON配列で抽出してください。\n'
            '[{"no":"","location":"","io":"屋内","timeOfDay":"昼","description":"","cast":[],"props":""}]\n\n$text';
      case 'cast':
        return '$base\n\n座組表から人物をJSON配列で抽出してください。\n'
            '[{"name":"","role":"","rank":"","tel":"","company":"","isCast":true}]\n\n$text';
      case 'rundown':
        return '$base\n\n進行表から項目をJSON配列で抽出してください。\n'
            '[{"kind":"本番","name":"","minutes":0,"owner":"","memo":""}]\n\n$text';
      case 'location':
        return '$base\n\nロケ地リストからJSON配列で抽出してください。\n'
            '[{"name":"","address":"","access":"","hours":"","contact":"","memo":""}]\n\n$text';
      default:
        return '$base\n\n企画書からJSON形式で抽出してください。\n'
            '{"title":"","summary":"","cast":[],"rundown":[]}\n\n$text';
    }
  }

  Future<void> _applyResult(String mode, String content,
      ProjectProvider provider) async {
    try {
      final jsonStr = _extractJson(content);
      switch (mode) {
        case 'script':
          final scenes = jsonDecode(jsonStr) as List;
          for (final s in scenes) {
            final m = s as Map<String, dynamic>;
            await provider.addSceneItem(SceneItem(
              projectId: provider.currentProject!.id,
              no: m['no']?.toString() ?? '',
              location: m['location'] ?? '',
              io: m['io'] ?? '屋内',
              timeOfDay: m['timeOfDay'] ?? '昼',
              description: m['description'] ?? '',
              props: m['props'] ?? '',
            ));
          }
          setState(() => _result = '✓ ${scenes.length}件のシーンを追加しました');
          break;

        case 'cast':
          final people = jsonDecode(jsonStr) as List;
          int c = 0, s = 0;
          for (final p in people) {
            final m = p as Map<String, dynamic>;
            if (m['isCast'] as bool? ?? true) {
              await provider.addCastMember(CastMember(
                projectId: provider.currentProject!.id,
                name: m['name'] ?? '', role: m['role'] ?? '',
                rank: m['rank'] ?? '', tel: m['tel'] ?? '',
              ));
              c++;
            } else {
              await provider.addCrewMember(CrewMember(
                projectId: provider.currentProject!.id,
                name: m['name'] ?? '', company: m['company'] ?? '',
                role: m['role'] ?? '', tel: m['tel'] ?? '',
              ));
              s++;
            }
          }
          setState(() => _result = '✓ 出演者$c名・スタッフ$s名を登録しました');
          break;

        case 'rundown':
          final items = jsonDecode(jsonStr) as List;
          for (final item in items) {
            final m = item as Map<String, dynamic>;
            await provider.addRundownItem(RundownItem(
              projectId: provider.currentProject!.id,
              kind: m['kind'] ?? '本番', name: m['name'] ?? '',
              minutes: (m['minutes'] as num?)?.toInt() ?? 0,
              owner: m['owner'] ?? '', memo: m['memo'] ?? '',
            ));
          }
          setState(() => _result = '✓ ${items.length}件の進行項目を追加しました');
          break;

        case 'location':
          final locs = jsonDecode(jsonStr) as List;
          for (final l in locs) {
            final m = l as Map<String, dynamic>;
            await provider.addLocation(LocationItem(
              projectId: provider.currentProject!.id,
              name: m['name'] ?? '', address: m['address'] ?? '',
              access: m['access'] ?? '', hours: m['hours'] ?? '',
              contact: m['contact'] ?? '', memo: m['memo'] ?? '',
            ));
          }
          setState(() => _result = '✓ ${locs.length}件のロケ地を追加しました');
          break;

        default:
          setState(() => _result = '✓ 解析完了。内容を確認してください。\n\n$content');
          break;
      }
    } catch (e) {
      setState(() => _result = '適用エラー: $e\n\n生の出力:\n$content');
    }
  }

  String _extractJson(String text) {
    var s = text.trim()
        .replaceAll('```json', '').replaceAll('```', '').trim();
    final startB = s.indexOf('[');
    final startC = s.indexOf('{');
    if (startB >= 0 && (startC < 0 || startB < startC)) {
      s = s.substring(startB, s.lastIndexOf(']') + 1);
    } else if (startC >= 0) {
      s = s.substring(startC, s.lastIndexOf('}') + 1);
    }
    return s;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // APIキー設定
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key_outlined,
                      color: glightGreen, size: 20),
                    const SizedBox(width: 8),
                    const Text('Gemini APIキー',
                      style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                        setState(() => _showApiKey = !_showApiKey),
                      child: Text(_showApiKey ? '閉じる' : '設定'),
                    ),
                  ],
                ),
                if (_showApiKey) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _apiKeyCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'APIキーを入力',
                      hintText: 'AIza...',
                      isDense: true),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveApiKey,
                      child: const Text('保存')),
                  ),
                  const SizedBox(height: 6),
                  Text('aistudio.google.com から無料で取得できます',
                    style: TextStyle(
                      fontSize: 11, color: Colors.grey[500])),
                ],
                if (!_showApiKey)
                  Text(
                    _apiKeyCtrl.text.isEmpty
                        ? '未設定（タップして設定）'
                        : 'APIキー設定済み ✓',
                    style: TextStyle(
                      fontSize: 12,
                      color: _apiKeyCtrl.text.isEmpty
                          ? Colors.orange : glightGreen)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // モード選択
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('解析モード',
                  style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: _modes.map((m) => ChoiceChip(
                    label: Text(m.$1,
                      style: const TextStyle(fontSize: 12)),
                    selected: _selectedMode == m.$2,
                    onSelected: (_) =>
                      setState(() => _selectedMode = m.$2),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // テキスト入力
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('書類テキスト',
                  style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: _textCtrl,
                  maxLines: 12,
                  style: const TextStyle(
                    fontSize: 12, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    hintText:
                      '台本・座組表・進行表・企画書・ロケ地リストなどを\n'
                      'ここにコピー＆ペーストしてください。',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null : () => _analyze(provider),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.auto_awesome_outlined,
                            size: 18),
                    label: Text(
                      _isLoading ? '解析中...' : 'AIで解析する'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 結果
        if (_result.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result.startsWith('✓')
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: _result.startsWith('✓')
                            ? glightGreen : Colors.orange,
                        size: 20),
                      const SizedBox(width: 8),
                      const Text('結果',
                        style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_result,
                    style: TextStyle(
                      fontSize: 13,
                      color: _result.startsWith('✓')
                          ? glightGreen : cs.onSurface,
                      height: 1.6)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
