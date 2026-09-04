// 交通費管理画面
// 演者・スタッフの交通費を記録・精算管理する
// AIアシストで出発地・目的地から交通手段・金額を推定できる
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

class TransportScreen extends StatelessWidget {
  const TransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final transports = provider.transports;
    final total = transports.fold(0, (a, b) => a + b.amount);
    final paid = transports.where((t) => t.isPaid).fold(0, (a, b) => a + b.amount);
    final unpaid = total - paid;

    return Scaffold(
      body: Column(
        children: [
          // サマリー
          if (transports.isNotEmpty)
            SummaryBar(children: [
              StatChip(label: '合計', value: _fmt(total)),
              StatChip(label: '精算済', value: _fmt(paid), color: Colors.green),
              StatChip(label: '未精算', value: _fmt(unpaid), color: Colors.orange),
            ]),
          Expanded(
            child: transports.isEmpty
                ? EmptyState(
                    icon: Icons.directions_car_outlined,
                    title: '交通費がありません',
                    action: OutlinedButton(
                      onPressed: () => _showAdd(context, provider),
                      child: const Text('追加する')))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: transports.length,
                    itemBuilder: (_, i) => _TransportTile(
                      transport: transports[i], provider: provider)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, provider),
        child: const Icon(Icons.add)),
    );
  }

  String _fmt(int v) {
    if (v == 0) return '¥0';
    final s = v.toString();
    final buf = StringBuffer('¥');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _showAdd(BuildContext ctx, ProjectProvider provider) {
    showAppSheet(ctx, _TransportEditSheet(
      projectId: provider.currentProject!.id, provider: provider));
  }
}

class _TransportTile extends StatelessWidget {
  final TransportCost transport;
  final ProjectProvider provider;
  const _TransportTile({required this.transport, required this.provider});

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer('¥');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showAppSheet(context, _TransportEditSheet(
          projectId: transport.projectId,
          provider: provider, transport: transport)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 精算チェック
              GestureDetector(
                onTap: () => provider.updateTransport(
                  TransportCost(
                    id: transport.id, projectId: transport.projectId,
                    personName: transport.personName, personType: transport.personType,
                    date: transport.date, from: transport.from, to: transport.to,
                    method: transport.method, amount: transport.amount,
                    isPaid: !transport.isPaid, memo: transport.memo)),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: transport.isPaid
                        ? Colors.green : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: transport.isPaid ? Colors.green : cs.outline)),
                  child: transport.isPaid
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(transport.personName,
                        style: tt.titleMedium),
                      const SizedBox(width: 8),
                      Tag(transport.personType == 'cast' ? '出演者' : 'スタッフ',
                        color: transport.personType == 'cast'
                            ? glightGreen : Colors.blue),
                    ]),
                    const SizedBox(height: 4),
                    Text('${transport.from} → ${transport.to}',
                      style: tt.bodySmall),
                    if (transport.method.isNotEmpty || transport.date.isNotEmpty)
                      Text(
                        [transport.date, transport.method]
                          .where((s) => s.isNotEmpty).join('　'),
                        style: tt.labelSmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmt(transport.amount),
                    style: tt.titleMedium?.copyWith(color: glightGreen)),
                  Text(transport.isPaid ? '精算済' : '未精算',
                    style: TextStyle(fontSize: 11,
                      color: transport.isPaid ? Colors.green : Colors.orange)),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(icon: const Icon(Icons.more_vert, size: 18),
                onPressed: () => _showOptions(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext ctx) {
    showModalBottomSheet(context: ctx, builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('編集'),
          onTap: () { Navigator.pop(ctx);
            showAppSheet(ctx, _TransportEditSheet(
              projectId: transport.projectId,
              provider: provider, transport: transport));
          }),
        ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('削除', style: TextStyle(color: Colors.red)),
          onTap: () { Navigator.pop(ctx); provider.deleteTransport(transport.id); }),
      ]),
    ));
  }
}

class _TransportEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final TransportCost? transport;
  const _TransportEditSheet({required this.projectId, required this.provider,
    this.transport});

  @override
  State<_TransportEditSheet> createState() => _TransportEditSheetState();
}

class _TransportEditSheetState extends State<_TransportEditSheet> {
  late TextEditingController _personCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _fromCtrl;
  late TextEditingController _toCtrl;
  late TextEditingController _methodCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _memoCtrl;
  String _personType = 'cast';
  bool _isPaid = false;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transport;
    _personCtrl = TextEditingController(text: t?.personName ?? '');
    _dateCtrl   = TextEditingController(text: t?.date ?? '');
    _fromCtrl   = TextEditingController(text: t?.from ?? '');
    _toCtrl     = TextEditingController(text: t?.to ?? '');
    _methodCtrl = TextEditingController(text: t?.method ?? '');
    _amountCtrl = TextEditingController(
      text: t != null && t.amount > 0 ? '${t.amount}' : '');
    _memoCtrl   = TextEditingController(text: t?.memo ?? '');
    _personType = t?.personType ?? 'cast';
    _isPaid     = t?.isPaid ?? false;
  }

  @override
  void dispose() {
    for (final c in [_personCtrl, _dateCtrl, _fromCtrl, _toCtrl,
        _methodCtrl, _amountCtrl, _memoCtrl]) c.dispose();
    super.dispose();
  }

  // AIで交通手段・金額を推定
  Future<void> _aiAssist() async {
    if (_fromCtrl.text.isEmpty || _toCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('出発地と目的地を入力してください')));
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
      final prompt = '出発地「${_fromCtrl.text}」から目的地「${_toCtrl.text}」への'
          '一般的な交通手段と片道の概算費用をJSONで答えてください。'
          'JSONのみ出力してください。\n'
          '{"method":"交通手段（例：電車・バス）","amount":概算金額の数値のみ,"notes":"備考"}';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-3.6-flash:generateContent?key=$apiKey');
      final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 256},
        }));

      if (response.statusCode != 200) throw Exception('APIエラー');
      final data = jsonDecode(response.body);
      var content = data['candidates'][0]['content']['parts'][0]['text'] as String;
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final sc = content.indexOf('{'), ec = content.lastIndexOf('}');
      final result = jsonDecode(content.substring(sc, ec + 1)) as Map;

      setState(() {
        if (_methodCtrl.text.isEmpty)
          _methodCtrl.text = result['method']?.toString() ?? '';
        if (_amountCtrl.text.isEmpty && result['amount'] != null)
          _amountCtrl.text = result['amount'].toString();
        if ((result['notes'] ?? '').toString().isNotEmpty && _memoCtrl.text.isEmpty)
          _memoCtrl.text = result['notes'].toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AIエラー: $e')));
    } finally {
      setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.transport != null;

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
              Row(children: [
                Text(isEdit ? '交通費を編集' : '交通費を追加',
                  style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: _aiLoading ? null : _aiAssist,
                  icon: _aiLoading
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_outlined, size: 16),
                  label: Text(_aiLoading ? '推定中...' : 'AI推定')),
              ]),
              const SizedBox(height: 14),
              // 対象者・区分
              Row(children: [
                Expanded(child: TextField(controller: _personCtrl,
                  decoration: const InputDecoration(labelText: '対象者名'))),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<String>(
                  value: _personType,
                  decoration: const InputDecoration(labelText: '区分'),
                  dropdownColor: cs.surface,
                  items: const [
                    DropdownMenuItem(value: 'cast', child: Text('出演者')),
                    DropdownMenuItem(value: 'crew', child: Text('スタッフ')),
                  ],
                  onChanged: (v) => setState(() => _personType = v ?? 'cast'))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _dateCtrl,
                decoration: const InputDecoration(labelText: '日付', hintText: '9/15')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _fromCtrl,
                  decoration: const InputDecoration(labelText: '出発地'))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 18)),
                Expanded(child: TextField(controller: _toCtrl,
                  decoration: const InputDecoration(labelText: '目的地'))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _methodCtrl,
                  decoration: const InputDecoration(labelText: '交通手段',
                    hintText: '電車・バス'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _amountCtrl,
                  decoration: const InputDecoration(labelText: '金額（円）'),
                  keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _memoCtrl,
                decoration: const InputDecoration(labelText: '備考')),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isPaid,
                onChanged: (v) => setState(() => _isPaid = v),
                title: const Text('精算済み'),
                activeColor: glightGreen,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _save,
                child: Text(isEdit ? '更新' : '追加')),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final t = TransportCost(
      id: widget.transport?.id, projectId: widget.projectId,
      personName: _personCtrl.text.trim(), personType: _personType,
      date: _dateCtrl.text.trim(), from: _fromCtrl.text.trim(),
      to: _toCtrl.text.trim(), method: _methodCtrl.text.trim(),
      amount: int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0,
      isPaid: _isPaid, memo: _memoCtrl.text.trim(),
    );
    if (widget.transport != null) {
      widget.provider.updateTransport(t);
    } else {
      widget.provider.addTransport(t);
    }
    Navigator.pop(context);
  }
}
