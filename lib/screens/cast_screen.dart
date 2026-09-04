import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

class CastScreen extends StatelessWidget {
  const CastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.currentProject;
    if (project == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(tabs: [
            Tab(text: '${project.type.castWord}（${provider.castMembers.length}）'),
            Tab(text: 'スタッフ（${provider.crewMembers.length}）'),
          ]),
          Expanded(
            child: TabBarView(children: [
              _CastList(provider: provider),
              _CrewList(provider: provider),
            ]),
          ),
        ],
      ),
    );
  }
}

// ===== 演者リスト =====
class _CastList extends StatelessWidget {
  final ProjectProvider provider;
  const _CastList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cast = provider.castMembers;
    final type = provider.currentProject!.type;
    return Scaffold(
      body: cast.isEmpty
          ? EmptyState(icon: Icons.people_outline,
              title: '${type.castWord}がいません')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: cast.length,
              itemBuilder: (_, i) => _CastTile(member: cast[i], provider: provider),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAppSheet(context,
          _CastEditSheet(projectId: provider.currentProject!.id, provider: provider)),
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }
}

class _CastTile extends StatelessWidget {
  final CastMember member;
  final ProjectProvider provider;
  const _CastTile({required this.member, required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: glightGreen.withOpacity(0.15),
          // 写真があれば表示、なければイニシャル
          backgroundImage: member.photoBase64 != null
              ? MemoryImage(base64Decode(member.photoBase64!))
              : null,
          child: member.photoBase64 == null
              ? Text(member.name.isNotEmpty ? member.name[0] : '?',
                  style: const TextStyle(color: glightGreenDark, fontWeight: FontWeight.w700))
              : null,
        ),
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            if (member.rank.isNotEmpty) Tag(member.rank),
            if (member.role.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(member.role, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ],
        ),
        trailing: IconButton(icon: const Icon(Icons.more_vert, size: 18),
          onPressed: () => _showOptions(context)),
        onTap: () => _showEdit(context),
      ),
    );
  }

  void _showOptions(BuildContext ctx) {
    showModalBottomSheet(context: ctx, builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('編集'),
          onTap: () { Navigator.pop(ctx); _showEdit(ctx); }),
        ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('削除', style: TextStyle(color: Colors.red)),
          onTap: () { Navigator.pop(ctx); provider.deleteCastMember(member.id); }),
      ]),
    ));
  }

  void _showEdit(BuildContext ctx) {
    showAppSheet(ctx, _CastEditSheet(
      projectId: member.projectId, provider: provider, member: member));
  }
}

class _CastEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final CastMember? member;
  const _CastEditSheet({required this.projectId, required this.provider, this.member});

  @override
  State<_CastEditSheet> createState() => _CastEditSheetState();
}

class _CastEditSheetState extends State<_CastEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _roleCtrl;
  late TextEditingController _telCtrl;
  String _rank = '';
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member?.name ?? '');
    _roleCtrl = TextEditingController(text: widget.member?.role ?? '');
    _telCtrl  = TextEditingController(text: widget.member?.tel ?? '');
    _rank     = widget.member?.rank ?? '';
    _photoBase64 = widget.member?.photoBase64;
  }

  @override
  void dispose() { _nameCtrl.dispose(); _roleCtrl.dispose(); _telCtrl.dispose(); super.dispose(); }

  // 写真を選んでbase64に変換する
  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image, withData: true);
    if (result == null) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    // 大きすぎる画像を弾く（500KB程度まで）
    if (bytes.length > 800 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('画像サイズが大きすぎます（800KB以下にしてください）')));
      return;
    }
    setState(() => _photoBase64 = base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final type = widget.provider.currentProject!.type;
    final isEdit = widget.member != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? '${type.castWord}を編集' : '${type.castWord}を追加',
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // 写真選択
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: glightGreen.withOpacity(0.12),
                        backgroundImage: _photoBase64 != null
                            ? MemoryImage(base64Decode(_photoBase64!)) : null,
                        child: _photoBase64 == null
                            ? const Icon(Icons.add_a_photo_outlined, color: glightGreen)
                            : null,
                      ),
                      if (_photoBase64 != null)
                        Positioned(right: 0, bottom: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _photoBase64 = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white)),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '氏名')),
              const SizedBox(height: 12),
              TextField(controller: _roleCtrl,
                decoration: InputDecoration(labelText: type == ProjectType.film ? '役名' : '肩書・役割')),
              const SizedBox(height: 12),
              if (type.castRanks.isNotEmpty) ...[
                Text('区分', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6,
                  children: type.castRanks.map((r) => ChoiceChip(
                    label: Text(r), selected: _rank == r,
                    onSelected: (_) => setState(() => _rank = r))).toList()),
                const SizedBox(height: 12),
              ],
              TextField(controller: _telCtrl,
                decoration: const InputDecoration(labelText: '連絡先'), keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: Text(isEdit ? '更新' : '追加')),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final m = CastMember(
      id: widget.member?.id, projectId: widget.projectId,
      name: _nameCtrl.text.trim(), role: _roleCtrl.text.trim(),
      rank: _rank, tel: _telCtrl.text.trim(),
      availability: widget.member?.availability ?? {},
      photoBase64: _photoBase64,
    );
    if (widget.member != null) {
      widget.provider.updateCastMember(m);
    } else {
      widget.provider.addCastMember(m);
    }
    Navigator.pop(context);
  }
}

// ===== スタッフリスト =====
class _CrewList extends StatelessWidget {
  final ProjectProvider provider;
  const _CrewList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final crew = provider.crewMembers;
    return Scaffold(
      body: Column(
        children: [
          // 書類から取り込みボタン
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () => showAppSheet(context, _CrewImportSheet(provider: provider)),
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('PDF・書類から取り込む（AI）'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            ),
          ),
          Expanded(
            child: crew.isEmpty
                ? const EmptyState(icon: Icons.badge_outlined, title: 'スタッフがいません')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    itemCount: crew.length,
                    itemBuilder: (_, i) {
                      final c = crew[i];
                      Color dc;
                      try {
                        final h = c.deptColor.replaceAll('#', '');
                        dc = Color(int.parse('FF' + h, radix: 16));
                      } catch (_) { dc = glightGreen; }
                      return Card(
                        child: ListTile(
                          onTap: () => _showEditCrew(context, c),
                          leading: CircleAvatar(
                            backgroundColor: dc.withOpacity(0.18),
                            child: Text(c.name.isNotEmpty ? c.name[0] : '?',
                              style: TextStyle(color: dc, fontWeight: FontWeight.w700))),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Row(children: [
                            if (c.dept.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: dc.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: dc.withOpacity(0.3))),
                                child: Text(c.dept,
                                  style: TextStyle(fontSize: 11, color: dc, fontWeight: FontWeight.w700))),
                            Expanded(child: Text(
                              '${c.company.isNotEmpty ? "${c.company}　" : ""}${c.role}',
                              overflow: TextOverflow.ellipsis)),
                          ]),
                          trailing: Text(c.tel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context),
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  void _showEditCrew(BuildContext ctx, CrewMember crew) {
    final nameCtrl    = TextEditingController(text: crew.name);
    final companyCtrl = TextEditingController(text: crew.company);
    final roleCtrl    = TextEditingController(text: crew.role);
    final telCtrl     = TextEditingController(text: crew.tel);
    String dept = crew.dept;
    String deptColor = crew.deptColor;

    showAppSheet(ctx, StatefulBuilder(
      builder: (ctx2, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(color: Theme.of(ctx2).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('スタッフを編集', style: Theme.of(ctx2).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '氏名')),
              const SizedBox(height: 12),
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: '会社・所属')),
              const SizedBox(height: 12),
              TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: '担当')),
              const SizedBox(height: 12),
              TextField(controller: telCtrl, decoration: const InputDecoration(labelText: '連絡先'),
                keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              // 担当カテゴリ・色選択
              Text('担当カテゴリ', style: Theme.of(ctx2).textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8,
                children: CrewMember.deptColors.entries.map((entry) {
                  Color c;
                  try { final h = entry.value.replaceAll('#', ''); c = Color(int.parse('FF' + h, radix: 16)); }
                  catch (_) { c = glightGreen; }
                  final selected = dept == entry.key;
                  return GestureDetector(
                    onTap: () => setSt(() { dept = entry.key; deptColor = entry.value; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? c : c.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: c, width: selected ? 2 : 1)),
                      child: Text(entry.key,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : c))));
                }).toList()),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () {
                    provider.deleteCrewMember(crew.id);
                    Navigator.pop(ctx2);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('削除'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    provider.updateCrewMember(CrewMember(
                      id: crew.id, projectId: crew.projectId,
                      name: nameCtrl.text.trim(), company: companyCtrl.text.trim(),
                      role: roleCtrl.text.trim(), tel: telCtrl.text.trim(),
                      ngDates: crew.ngDates, dept: dept, deptColor: deptColor));
                    Navigator.pop(ctx2);
                  },
                  child: const Text('更新'))),
              ]),
            ]),
          ),
        ),
      ),
    ));
  }

  void _showAdd(BuildContext ctx) {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    showAppSheet(ctx, Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('スタッフを追加', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '氏名')),
          const SizedBox(height: 12),
          TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: '会社・所属')),
          const SizedBox(height: 12),
          TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: '担当')),
          const SizedBox(height: 12),
          TextField(controller: telCtrl, decoration: const InputDecoration(labelText: '連絡先'),
            keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              provider.addCrewMember(CrewMember(
                projectId: provider.currentProject!.id,
                name: nameCtrl.text.trim(), company: companyCtrl.text.trim(),
                role: roleCtrl.text.trim(), tel: telCtrl.text.trim()));
              Navigator.pop(ctx);
            },
            child: const Text('追加')),
        ]),
      ),
    ));
  }
}

// ===== スタッフをPDF/書類からAI取り込み =====
class _CrewImportSheet extends StatefulWidget {
  final ProjectProvider provider;
  const _CrewImportSheet({required this.provider});

  @override
  State<_CrewImportSheet> createState() => _CrewImportSheetState();
}

class _CrewImportSheetState extends State<_CrewImportSheet> {
  final _textCtrl = TextEditingController();
  String _fileName = '';
  var _pdfBytes;
  bool _isLoading = false;
  String _result = '';

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md', 'csv'],
      withData: true);
    if (result == null) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    final ext = file.extension?.toLowerCase() ?? '';
    if (ext == 'pdf') {
      setState(() { _pdfBytes = bytes; _fileName = file.name; _textCtrl.text = ''; });
    } else {
      setState(() {
        _pdfBytes = null; _fileName = file.name;
        _textCtrl.text = utf8.decode(bytes, allowMalformed: true);
      });
    }
  }

  Future<void> _analyze() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key') ?? '';
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('先にAI解析タブでGemini APIキーを設定してください')));
      return;
    }
    if (_textCtrl.text.trim().isEmpty && _pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ファイルを選ぶかテキストを貼り付けてください')));
      return;
    }

    setState(() { _isLoading = true; _result = ''; });
    try {
      const prompt = '以下の書類からスタッフ・キャストの情報をJSON配列で抽出してください。'
          'JSONのみ出力し、説明は不要です。\n'
          '[{"name":"氏名","company":"会社・所属","role":"担当・役割","tel":"連絡先","isCast":false}]\n'
          'isCastはtrue=出演者、false=スタッフ。';

      final parts = <Map<String, dynamic>>[
        if (_pdfBytes != null)
          {'inline_data': {'mime_type': 'application/pdf', 'data': base64Encode(_pdfBytes)}},
        {'text': _pdfBytes != null ? prompt : '$prompt\n\n${_textCtrl.text}'},
      ];

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-3.6-flash:generateContent?key=$apiKey');
      final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': parts}],
          'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 4096},
        }));

      if (response.statusCode != 200) throw Exception('APIエラー: ${response.statusCode}');
      final data = jsonDecode(response.body);
      var content = data['candidates'][0]['content']['parts'][0]['text'] as String;
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final sb = content.indexOf('['), sc = content.lastIndexOf(']');
      final jsonStr = content.substring(sb, sc + 1);

      final people = jsonDecode(jsonStr) as List;
      int c = 0, s = 0;
      final pid = widget.provider.currentProject!.id;
      for (final p in people) {
        final m = p as Map<String, dynamic>;
        if (m['isCast'] as bool? ?? false) {
          await widget.provider.addCastMember(CastMember(projectId: pid,
            name: m['name'] ?? '', role: m['role'] ?? '', tel: m['tel'] ?? ''));
          c++;
        } else {
          await widget.provider.addCrewMember(CrewMember(projectId: pid,
            name: m['name'] ?? '', company: m['company'] ?? '',
            role: m['role'] ?? '', tel: m['tel'] ?? ''));
          s++;
        }
      }
      setState(() => _result = '✓ スタッフ$s名・出演者$c名を登録しました');
    } catch (e) {
      setState(() => _result = 'エラー: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('書類からスタッフを取り込む', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('PDF・テキストの座組表・スタッフリストからAIが自動登録します。',
              style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: _pickFile,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(_fileName.isEmpty ? 'ファイルを選ぶ（PDF/txt/csv）' : _fileName)),
            const SizedBox(height: 12),
            if (_pdfBytes == null)
              TextField(controller: _textCtrl, maxLines: 8,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: const InputDecoration(hintText: 'または直接テキストを貼り付け')),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analyze,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(_isLoading ? '解析中...' : 'AIで取り込む')),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_result,
                style: TextStyle(
                  color: _result.startsWith('✓') ? glightGreen : cs.error, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
