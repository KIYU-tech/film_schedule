import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

// Web専用：dart:htmlを条件付きでimport
import 'ai_screen_web.dart' if (dart.library.io) 'ai_screen_stub.dart';

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

  Uint8List? _pdfBytes;
  String _fileName = '';

  final _modes = [
    ('自動判定', 'auto'),
    ('台本・脚本', 'script'),
    ('座組表', 'cast'),
    ('進行表', 'rundown'),
    ('企画書', 'plan'),
    ('ロケ地リスト', 'location'),
    ('制作物リスト', 'production'),
    ('機材リスト', 'equipment'),
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
    setState(() => _apiKeyCtrl.text = prefs.getString('gemini_api_key') ?? '');
  }

  Future<void> _saveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKeyCtrl.text.trim());
    setState(() => _showApiKey = false);
    _showSnack('APIキーを保存しました');
  }

  // ファイル選択（Web対応）
  Future<void> _pickFile() async {
    final result = await pickFileForAi();
    if (result == null) return;

    if (result.isPdf) {
      setState(() {
        _pdfBytes = result.bytes;
        _fileName = result.name;
        _textCtrl.text = '';
      });
      _showSnack('${result.name} を読み込みました（PDF）');
    } else {
      final text = utf8.decode(result.bytes, allowMalformed: true);
      setState(() {
        _pdfBytes = null;
        _fileName = result.name;
        _textCtrl.text = text;
      });
      _showSnack('${result.name} を読み込みました');
    }
  }

  void _clearFile() {
    setState(() { _pdfBytes = null; _fileName = ''; _textCtrl.text = ''; });
  }

  Future<void> _analyze(ProjectProvider provider) async {
    final apiKey = _apiKeyCtrl.text.trim();
    final text = _textCtrl.text.trim();
    final hasPdf = _pdfBytes != null;

    if (apiKey.isEmpty) {
      _showSnack('APIキーを入力してください');
      setState(() => _showApiKey = true);
      return;
    }
    if (text.isEmpty && !hasPdf) {
      _showSnack('テキストを入力またはファイルを選んでください');
      return;
    }

    setState(() { _isLoading = true; _result = ''; });

    try {
      final mode = _selectedMode == 'auto'
          ? (hasPdf ? 'plan' : _detectMode(text))
          : _selectedMode;

      final prompt = _buildPrompt(mode, hasPdf ? '' : text);

      final parts = <Map<String, dynamic>>[
        if (hasPdf)
          {
            'inline_data': {
              'mime_type': 'application/pdf',
              'data': base64Encode(_pdfBytes!),
            }
          },
        {'text': prompt},
      ];

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-2.0-flash:generateContent?key=$apiKey');

      final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': parts}],
          'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 8192},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('APIエラー: ${response.statusCode}\n${response.body}');
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
    if (text.contains('シーン') || text.contains('ト書き') || text.contains('柱')) return 'script';
    if (text.contains('氏名') || text.contains('キャスト') || text.contains('座組')) return 'cast';
    if (text.contains('進行') || text.contains('タイムテーブル')) return 'rundown';
    if (text.contains('ロケ') || text.contains('住所')) return 'location';
    if (text.contains('制作物') || text.contains('納品')) return 'production';
    if (text.contains('機材') || text.contains('カメラ') || text.contains('機器')) return 'equipment';
    return 'plan';
  }

  String _buildPrompt(String mode, String text) {
    const base = '以下の内容を解析してください。JSONのみ出力し、前置きや説明は不要です。';
    final body = text.isEmpty ? '（添付のPDFを読んでください）' : text;
    switch (mode) {
      case 'script':
        return '$base\n\n脚本からシーンをJSON配列で抽出してください。\n'
            '[{"no":"","location":"","io":"屋内","timeOfDay":"昼","description":"","cast":[],"props":""}]\n\n$body';
      case 'cast':
        return '$base\n\n座組表から人物をJSON配列で抽出してください。\n'
            '[{"name":"","role":"","rank":"","tel":"","company":"","isCast":true}]\n\n$body';
      case 'rundown':
        return '$base\n\n進行表から項目をJSON配列で抽出してください。\n'
            '[{"kind":"本番","name":"","minutes":0,"owner":"","memo":""}]\n\n$body';
      case 'location':
        return '$base\n\nロケ地リストからJSON配列で抽出してください。\n'
            '[{"name":"","address":"","access":"","hours":"","contact":"","memo":""}]\n\n$body';
      case 'production':
        return '$base\n\n書類から制作物リストをJSON配列で抽出してください。\n'
            'カテゴリは「書類・台本」「映像」「音声・楽曲」「グラフィック・デザイン」「衣装・小道具」「その他」のいずれか。\n'
            '[{"category":"","name":"","owner":"","deadline":""}]\n\n$body';
      case 'equipment':
        return '$base\n\n書類から機材リストをJSON配列で抽出してください。\n'
            'カテゴリは「カメラ」「スイッチャー」「音声」「照明」「PC・配信」「回線」「ケーブル」「電源」「その他」のいずれか。\n'
            '[{"category":"","name":"","qty":1,"owner":"","memo":""}]\n\n$body';
      default:
        return '$base\n\n企画書・書類から情報を抽出してください。\n'
            '{"title":"","summary":"","cast":[{"name":"","role":""}],"rundown":[{"kind":"本番","name":"","minutes":0}],'
            '"locations":[{"name":"","address":""}],"productions":[{"category":"","name":""}],"equipment":[{"category":"","name":"","qty":1}]}\n\n$body';
    }
  }

  Future<void> _applyResult(String mode, String content, ProjectProvider provider) async {
    try {
      final jsonStr = _extractJson(content);
      final pid = provider.currentProject!.id;

      switch (mode) {
        case 'script':
          final scenes = jsonDecode(jsonStr) as List;
          for (final s in scenes) {
            final m = s as Map<String, dynamic>;
            await provider.addSceneItem(SceneItem(projectId: pid,
              no: m['no']?.toString() ?? '', location: m['location'] ?? '',
              io: m['io'] ?? '屋内', timeOfDay: m['timeOfDay'] ?? '昼',
              description: m['description'] ?? '', props: m['props'] ?? ''));
          }
          setState(() => _result = '✓ ${scenes.length}件のシーンを香盤表に追加しました');
          break;

        case 'cast':
          final people = jsonDecode(jsonStr) as List;
          int c = 0, s = 0;
          for (final p in people) {
            final m = p as Map<String, dynamic>;
            if (m['isCast'] as bool? ?? true) {
              await provider.addCastMember(CastMember(projectId: pid,
                name: m['name'] ?? '', role: m['role'] ?? '',
                rank: m['rank'] ?? '', tel: m['tel'] ?? ''));
              c++;
            } else {
              await provider.addCrewMember(CrewMember(projectId: pid,
                name: m['name'] ?? '', company: m['company'] ?? '',
                role: m['role'] ?? '', tel: m['tel'] ?? ''));
              s++;
            }
          }
          setState(() => _result = '✓ 出演者$c名・スタッフ$s名を登録しました');
          break;

        case 'rundown':
          final items = jsonDecode(jsonStr) as List;
          for (final item in items) {
            final m = item as Map<String, dynamic>;
            await provider.addRundownItem(RundownItem(projectId: pid,
              kind: m['kind'] ?? '本番', name: m['name'] ?? '',
              minutes: (m['minutes'] as num?)?.toInt() ?? 0,
              owner: m['owner'] ?? '', memo: m['memo'] ?? ''));
          }
          setState(() => _result = '✓ ${items.length}件の進行項目を追加しました');
          break;

        case 'location':
          final locs = jsonDecode(jsonStr) as List;
          for (final l in locs) {
            final m = l as Map<String, dynamic>;
            await provider.addLocation(LocationItem(projectId: pid,
              name: m['name'] ?? '', address: m['address'] ?? '',
              access: m['access'] ?? '', hours: m['hours'] ?? '',
              contact: m['contact'] ?? '', memo: m['memo'] ?? ''));
          }
          setState(() => _result = '✓ ${locs.length}件のロケ地を追加しました');
          break;

        case 'production':
          final prods = jsonDecode(jsonStr) as List;
          for (final p in prods) {
            final m = p as Map<String, dynamic>;
            await provider.addProduction(ProductionItem(projectId: pid,
              category: m['category'] ?? 'その他', name: m['name'] ?? '',
              owner: m['owner'] ?? '', deadline: m['deadline'] ?? ''));
          }
          setState(() => _result = '✓ ${prods.length}件の制作物を追加しました');
          break;

        case 'equipment':
          final equips = jsonDecode(jsonStr) as List;
          for (final e in equips) {
            final m = e as Map<String, dynamic>;
            await provider.addEquipment(EquipmentItem(projectId: pid,
              category: m['category'] ?? 'その他', name: m['name'] ?? '',
              qty: (m['qty'] as num?)?.toInt() ?? 1,
              owner: m['owner'] ?? '', memo: m['memo'] ?? ''));
          }
          setState(() => _result = '✓ ${equips.length}件の機材を追加しました');
          break;

        default:
          final plan = jsonDecode(jsonStr) as Map<String, dynamic>;
          final project = provider.currentProject!;
          final sb = StringBuffer('✓ 企画書を解析しました\n');
          if (plan['title'] != null && (plan['title'] as String).isNotEmpty && project.title.isEmpty) {
            await provider.updateProject(project.copyWith(title: plan['title']));
            sb.writeln('・タイトル：${plan['title']}');
          }
          final castList = plan['cast'] as List? ?? [];
          for (final c in castList) {
            final m = c as Map<String, dynamic>;
            if ((m['name'] ?? '').toString().isNotEmpty) {
              await provider.addCastMember(CastMember(projectId: pid, name: m['name'], role: m['role'] ?? ''));
            }
          }
          if (castList.isNotEmpty) sb.writeln('・出演者：${castList.length}名');
          final rdList = plan['rundown'] as List? ?? [];
          for (final r in rdList) {
            final m = r as Map<String, dynamic>;
            await provider.addRundownItem(RundownItem(projectId: pid,
              kind: m['kind'] ?? '本番', name: m['name'] ?? '',
              minutes: (m['minutes'] as num?)?.toInt() ?? 0));
          }
          if (rdList.isNotEmpty) sb.writeln('・進行項目：${rdList.length}件');
          final locList = plan['locations'] as List? ?? [];
          for (final l in locList) {
            final m = l as Map<String, dynamic>;
            if ((m['name'] ?? '').toString().isNotEmpty) {
              await provider.addLocation(LocationItem(projectId: pid, name: m['name'], address: m['address'] ?? ''));
            }
          }
          if (locList.isNotEmpty) sb.writeln('・ロケ地：${locList.length}件');
          final prodList = plan['productions'] as List? ?? [];
          for (final p in prodList) {
            final m = p as Map<String, dynamic>;
            if ((m['name'] ?? '').toString().isNotEmpty) {
              await provider.addProduction(ProductionItem(projectId: pid,
                category: m['category'] ?? 'その他', name: m['name']));
            }
          }
          if (prodList.isNotEmpty) sb.writeln('・制作物：${prodList.length}件');
          final equipList = plan['equipment'] as List? ?? [];
          for (final e in equipList) {
            final m = e as Map<String, dynamic>;
            if ((m['name'] ?? '').toString().isNotEmpty) {
              await provider.addEquipment(EquipmentItem(projectId: pid,
                category: m['category'] ?? 'その他', name: m['name'],
                qty: (m['qty'] as num?)?.toInt() ?? 1));
            }
          }
          if (equipList.isNotEmpty) sb.writeln('・機材：${equipList.length}件');
          if (plan['summary'] != null) sb.writeln('\n概要：${plan['summary']}');
          setState(() => _result = sb.toString());
          break;
      }
    } catch (e) {
      setState(() => _result = '適用エラー: $e\n\n生の出力:\n$content');
    }
  }

  String _extractJson(String text) {
    var s = text.trim().replaceAll('```json', '').replaceAll('```', '').trim();
    final sb = s.indexOf('['), sc = s.indexOf('{');
    if (sb >= 0 && (sc < 0 || sb < sc)) {
      s = s.substring(sb, s.lastIndexOf(']') + 1);
    } else if (sc >= 0) {
      s = s.substring(sc, s.lastIndexOf('}') + 1);
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
    final tt = Theme.of(context).textTheme;
    final hasFile = _fileName.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // APIキー
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.key_outlined, color: glightGreen, size: 20),
                  const SizedBox(width: 8),
                  Text('Gemini APIキー', style: tt.titleMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _showApiKey = !_showApiKey),
                    child: Text(_showApiKey ? '閉じる' : '設定')),
                ]),
                if (_showApiKey) ...[
                  const SizedBox(height: 10),
                  TextField(controller: _apiKeyCtrl, obscureText: true,
                    decoration: const InputDecoration(labelText: 'APIキー', hintText: 'AIza...')),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _saveApiKey, child: const Text('保存')),
                  const SizedBox(height: 6),
                  Text('aistudio.google.com から無料で取得できます', style: tt.bodySmall),
                ] else
                  Text(_apiKeyCtrl.text.isEmpty ? '未設定' : '設定済み ✓',
                    style: TextStyle(fontSize: 12,
                      color: _apiKeyCtrl.text.isEmpty ? Colors.orange : glightGreen)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 解析モード
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('解析モード', style: tt.titleMedium),
                const SizedBox(height: 4),
                Text('※ 企画書モードは制作物・機材も一括で取り込みます',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6,
                  children: _modes.map((m) => ChoiceChip(
                    label: Text(m.$1, style: const TextStyle(fontSize: 12)),
                    selected: _selectedMode == m.$2,
                    onSelected: (_) => setState(() => _selectedMode = m.$2),
                  )).toList()),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 書類・テキスト
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('書類', style: tt.titleMedium),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file_outlined, size: 16),
                    label: const Text('ファイルを開く')),
                ]),
                const SizedBox(height: 12),

                // ファイル読み込み済み表示
                if (hasFile)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: glightGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: glightGreen.withOpacity(0.3))),
                    child: Row(children: [
                      Icon(_pdfBytes != null
                          ? Icons.picture_as_pdf_outlined
                          : Icons.description_outlined,
                        color: glightGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _clearFile, tooltip: 'クリア'),
                    ]),
                  ),

                // テキスト欄（PDFのときは非表示）
                if (_pdfBytes == null)
                  TextField(
                    controller: _textCtrl,
                    maxLines: 10,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: '台本・座組表・進行表・企画書・機材リストなどのテキストを貼り付けてください。\n'
                        '自動判定モードで書類の種類を自動認識します。'),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('PDFをGeminiに直接送って解析します。', style: tt.bodySmall)),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _analyze(provider),
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: Text(_isLoading ? '解析中...' : 'AIで解析して取り込む')),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 結果
        if (_result.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(_result.startsWith('✓')
                        ? Icons.check_circle_outline : Icons.error_outline,
                      color: _result.startsWith('✓') ? glightGreen : Colors.orange,
                      size: 20),
                    const SizedBox(width: 8),
                    Text('結果', style: tt.titleMedium),
                  ]),
                  const SizedBox(height: 8),
                  SelectableText(_result,
                    style: TextStyle(fontSize: 13, height: 1.6,
                      color: _result.startsWith('✓') ? glightGreen : cs.onSurface)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
