import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

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

  // 読み込んだPDFのバイト列（PDFの場合はここに入る）
  // Uint8List → バイトの配列型（ファイルの中身）
  Uint8List? _pdfBytes;
  String _fileName = '';

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
    // Web環境でのファイルドロップイベントを監視
    if (kIsWeb) {
      html.window.addEventListener('fileDropped', _onFileDrop);
    }
  }

  void _onFileDrop(html.Event e) {
    final customEvent = e as html.CustomEvent;
    final detail = customEvent.detail as Map;
    final name = detail['name'] as String? ?? '';
    final type = detail['type'] as String? ?? '';
    final data = html.window.localStorage['dropped_file_data'] ?? '';
    final ready = html.window.localStorage['dropped_file_ready'] ?? '';
    if (ready != 'true' || data.isEmpty) return;

    // 読み取り後はクリア
    html.window.localStorage.remove('dropped_file_ready');

    if (type == 'pdf') {
      try {
        final bytes = base64Decode(data);
        setState(() {
          _pdfBytes = bytes;
          _fileName = name;
          _textCtrl.text = '';
        });
        _showSnack('$name を読み込みました（PDF）');
      } catch (e) {
        _showSnack('PDFの読み込みに失敗しました');
      }
    } else {
      setState(() {
        _pdfBytes = null;
        _fileName = name;
        _textCtrl.text = data;
      });
      _showSnack('$name を読み込みました');
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      html.window.removeEventListener('fileDropped', _onFileDrop);
    }
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

  // ファイルを選ぶ
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md', 'fountain', 'fdx', 'stry'],
      withData: true, // Web対応：ファイルの中身をメモリに読む
    );
    if (result == null) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) { _showSnack('ファイルを読み込めませんでした'); return; }

    final ext = file.extension?.toLowerCase() ?? '';

    if (ext == 'pdf') {
      // PDFはバイト列のまま保持してGeminiに送る
      setState(() {
        _pdfBytes = bytes;
        _fileName = file.name;
        _textCtrl.text = '';
      });
      _showSnack('${file.name} を読み込みました（PDF）');
    } else {
      // テキストファイルはデコードしてテキスト欄に入れる
      final text = utf8.decode(bytes, allowMalformed: true);
      setState(() {
        _pdfBytes = null;
        _fileName = file.name;
        _textCtrl.text = text;
      });
      _showSnack('${file.name} を読み込みました');
    }
  }

  // ファイルをクリア
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

      // Geminiへ送る parts を作る
      // PDFがあれば inline_data として base64 で送る
      final parts = <Map<String, dynamic>>[
        if (hasPdf)
          {
            'inline_data': {
              'mime_type': 'application/pdf',
              // base64Encode → バイト列を文字列に変換（通信用）
              'data': base64Encode(_pdfBytes!),
            }
          },
        {'text': prompt},
      ];

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-3.6-flash:generateContent?key=$apiKey');

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
      default:
        return '$base\n\n企画書・書類から情報を抽出してください。\n'
            '{"title":"","summary":"","cast":[{"name":"","role":""}],"rundown":[{"kind":"本番","name":"","minutes":0}],"locations":[{"name":"","address":""}]}\n\n$body';
    }
  }

  Future<void> _applyResult(String mode, String content,
      ProjectProvider provider) async {
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
        default:
          // 企画書：一括で複数の項目を反映
          final plan = jsonDecode(jsonStr) as Map<String, dynamic>;
          final project = provider.currentProject!;
          final sb = StringBuffer('✓ 企画書を解析しました\n');
          if (plan['title'] != null && (plan['title'] as String).isNotEmpty
              && project.title.isEmpty) {
            await provider.updateProject(project.copyWith(title: plan['title']));
            sb.writeln('・タイトル：${plan['title']}');
          }
          final castList = plan['cast'] as List? ?? [];
          for (final c in castList) {
            final m = c as Map<String, dynamic>;
            if ((m['name'] ?? '').toString().isNotEmpty) {
              await provider.addCastMember(CastMember(projectId: pid,
                name: m['name'], role: m['role'] ?? ''));
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
              await provider.addLocation(LocationItem(projectId: pid,
                name: m['name'], address: m['address'] ?? ''));
            }
          }
          if (locList.isNotEmpty) sb.writeln('・ロケ地：${locList.length}件');
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
        // ===== APIキー =====
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
                    decoration: const InputDecoration(
                      labelText: 'APIキー', hintText: 'AIza...')),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _saveApiKey, child: const Text('保存')),
                  const SizedBox(height: 6),
                  Text('aistudio.google.com から無料で取得できます',
                    style: tt.bodySmall),
                ] else
                  Text(
                    _apiKeyCtrl.text.isEmpty ? '未設定' : '設定済み ✓',
                    style: TextStyle(fontSize: 12,
                      color: _apiKeyCtrl.text.isEmpty
                          ? Colors.orange : glightGreen)),
              ],
            ),
          ),
        ),

        // ===== モード =====
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('解析モード', style: tt.titleMedium),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6,
                  children: _modes.map((m) => ChoiceChip(
                    label: Text(m.$1),
                    selected: _selectedMode == m.$2,
                    onSelected: (_) => setState(() => _selectedMode = m.$2),
                  )).toList()),
              ],
            ),
          ),
        ),

        // ===== ファイル・テキスト =====
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
                // ドロップゾーン（ファイルをここにドラッグ）
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: glightGreen.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: glightGreen.withOpacity(0.3),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                          size: 36, color: glightGreen.withOpacity(0.6)),
                        const SizedBox(height: 8),
                        Text('ここにファイルをドラッグ、またはタップして選択',
                          style: TextStyle(fontSize: 13,
                            color: cs.onSurfaceVariant),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text('PDF / TXT / MD / STRY 対応',
                          style: TextStyle(fontSize: 11,
                            color: cs.onSurfaceVariant.withOpacity(0.6))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 読み込んだファイル表示
                if (hasFile)
                  Container(
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

                // PDFのときはテキスト欄を隠す
                if (_pdfBytes == null) ...[
                  if (hasFile) const SizedBox(height: 10),
                  TextField(
                    controller: _textCtrl,
                    maxLines: 10,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: 'テキストを貼り付け、またはPDF・テキストファイルを開いてください。\n'
                        '台本・座組表・進行表・企画書・ロケ地リストに対応。'),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('PDFをGeminiに直接送って解析します。',
                      style: tt.bodySmall)),

                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _analyze(provider),
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: Text(_isLoading ? '解析中...' : 'AIで解析する')),
              ],
            ),
          ),
        ),

        // ===== 結果 =====
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
