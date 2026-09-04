// 脚本・台本管理画面
// PDFや文章データをプロジェクトに紐づけて保存する
// 映画：脚本、動画：台本として使用
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

class ScriptScreen extends StatelessWidget {
  const ScriptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final scripts = provider.scripts;
    final type = provider.currentProject!.type;
    final label = type == ProjectType.film ? '脚本' : '台本';

    return Scaffold(
      body: scripts.isEmpty
          ? EmptyState(
              icon: Icons.description_outlined,
              title: '$labelがありません',
              subtitle: 'PDF・テキストファイルを読み込むか\n直接入力してください',
              action: OutlinedButton.icon(
                onPressed: () => _showAdd(context, provider, label),
                icon: const Icon(Icons.add, size: 16),
                label: Text('$labelを追加')))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: scripts.length,
              itemBuilder: (_, i) => _ScriptTile(
                script: scripts[i], provider: provider, label: label)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(context, provider, label),
        icon: const Icon(Icons.upload_file_outlined),
        label: Text('$labelを追加')),
    );
  }

  void _showAdd(BuildContext ctx, ProjectProvider provider, String label) {
    showAppSheet(ctx, _ScriptEditSheet(
      projectId: provider.currentProject!.id,
      provider: provider, label: label));
  }
}

class _ScriptTile extends StatelessWidget {
  final ScriptFile script;
  final ProjectProvider provider;
  final String label;
  const _ScriptTile({required this.script, required this.provider, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isPdf = script.fileType == 'pdf';

    return Card(
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isPdf
                ? Colors.red.withOpacity(0.12)
                : glightGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.text_snippet_outlined,
            color: isPdf ? Colors.red : glightGreen, size: 22)),
        title: Text(script.title.isEmpty ? '（タイトル未設定）' : script.title,
          style: tt.titleMedium),
        subtitle: Row(children: [
          Tag(isPdf ? 'PDF' : 'テキスト',
            color: isPdf ? Colors.red : glightGreen),
          const SizedBox(width: 8),
          Text(
            '更新: ${script.updatedAt.month}/${script.updatedAt.day}',
            style: tt.bodySmall),
        ]),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, size: 18),
          onPressed: () => _showOptions(context)),
        onTap: () => _showDetail(context),
      ),
    );
  }

  void _showOptions(BuildContext ctx) {
    showModalBottomSheet(context: ctx, builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.open_in_full_outlined),
          title: const Text('開いて見る'),
          onTap: () { Navigator.pop(ctx); _showDetail(ctx); }),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('編集'),
          onTap: () { Navigator.pop(ctx);
            showAppSheet(ctx, _ScriptEditSheet(
              projectId: script.projectId, provider: provider,
              script: script, label: label));
          }),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('削除', style: TextStyle(color: Colors.red)),
          onTap: () { Navigator.pop(ctx); provider.deleteScript(script.id); }),
      ]),
    ));
  }

  void _showDetail(BuildContext ctx) {
    // PDFはbase64をプレビュー、テキストはそのまま表示
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              SheetHeader(title: script.title.isEmpty ? label : script.title),
              Expanded(
                child: script.fileType == 'pdf'
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_outlined,
                              size: 56, color: Colors.red),
                            const SizedBox(height: 12),
                            Text('PDFファイル',
                              style: Theme.of(ctx).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text('${(script.content.length * 0.75 / 1024).round()} KB',
                              style: Theme.of(ctx).textTheme.bodySmall),
                          ],
                        ))
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.all(20),
                        children: [
                          SelectableText(
                            script.content,
                            style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 13, height: 1.7)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScriptEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final ScriptFile? script;
  final String label;
  const _ScriptEditSheet({required this.projectId, required this.provider,
    this.script, required this.label});

  @override
  State<_ScriptEditSheet> createState() => _ScriptEditSheetState();
}

class _ScriptEditSheetState extends State<_ScriptEditSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _memoCtrl;
  String _fileType = 'text';
  String _fileName = '';

  @override
  void initState() {
    super.initState();
    final s = widget.script;
    _titleCtrl   = TextEditingController(text: s?.title ?? '');
    _contentCtrl = TextEditingController(text: s?.fileType == 'text' ? (s?.content ?? '') : '');
    _memoCtrl    = TextEditingController(text: s?.memo ?? '');
    _fileType    = s?.fileType ?? 'text';
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _contentCtrl.dispose(); _memoCtrl.dispose();
    super.dispose();
  }

  // ファイル選択（PDF or テキスト）
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md', 'fountain', 'fdx', 'stry'],
      withData: true);
    if (result == null) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    final ext = file.extension?.toLowerCase() ?? '';
    if (ext == 'pdf') {
      // PDFはbase64で保存（サイズ制限：3MB程度まで）
      if (bytes.length > 3 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ファイルサイズが大きすぎます（3MB以下にしてください）')));
        return;
      }
      setState(() {
        _fileType = 'pdf';
        _fileName = file.name;
        _contentCtrl.text = base64Encode(bytes);
        if (_titleCtrl.text.isEmpty) _titleCtrl.text = file.name;
      });
    } else {
      final text = utf8.decode(bytes, allowMalformed: true);
      setState(() {
        _fileType = 'text';
        _fileName = file.name;
        _contentCtrl.text = text;
        if (_titleCtrl.text.isEmpty) _titleCtrl.text = file.name;
      });
    }
    _showSnack('${file.name} を読み込みました');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.script != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            SheetHeader(
              title: isEdit ? '${widget.label}を編集' : '${widget.label}を追加',
              trailing: isEdit ? TextButton(
                onPressed: () {
                  widget.provider.deleteScript(widget.script!.id);
                  Navigator.pop(context);
                },
                child: const Text('削除', style: TextStyle(color: Colors.red))) : null),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  TextField(controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: '${widget.label}タイトル・バージョン',
                      hintText: '例：決定稿 v2.0')),
                  const SizedBox(height: 14),
                  // ファイル選択エリア
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: glightGreen.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: glightGreen.withOpacity(0.3))),
                      child: Row(children: [
                        Icon(
                          _fileType == 'pdf'
                              ? Icons.picture_as_pdf_outlined
                              : Icons.upload_file_outlined,
                          color: glightGreen),
                        const SizedBox(width: 12),
                        Expanded(child: Text(
                          _fileName.isEmpty
                              ? 'PDFまたはテキストファイルをタップして選択'
                              : _fileName,
                          style: TextStyle(
                            color: _fileName.isEmpty
                                ? cs.onSurfaceVariant : cs.onSurface))),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_fileType == 'text') ...[
                    // テキストの場合は直接編集可能
                    TextField(
                      controller: _contentCtrl,
                      maxLines: 20,
                      style: const TextStyle(
                        fontSize: 12, fontFamily: 'monospace', height: 1.6),
                      decoration: InputDecoration(
                        labelText: '${widget.label}本文（直接入力も可）',
                        hintText: 'ここにテキストを貼り付けるか、上のボタンからファイルを選んでください'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: _memoCtrl,
                    decoration: const InputDecoration(labelText: 'メモ・備考')),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _save,
                    child: Text(isEdit ? '更新' : '保存')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.isEmpty && _contentCtrl.text.isEmpty) return;
    final s = ScriptFile(
      id: widget.script?.id, projectId: widget.projectId,
      title: _titleCtrl.text.trim(), fileType: _fileType,
      content: _contentCtrl.text, memo: _memoCtrl.text.trim());
    if (widget.script != null) {
      widget.provider.updateScript(s);
    } else {
      widget.provider.addScript(s);
    }
    Navigator.pop(context);
  }
}
