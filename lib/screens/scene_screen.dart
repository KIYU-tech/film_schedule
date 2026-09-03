import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

class SceneScreen extends StatelessWidget {
  const SceneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final scenes = provider.sceneItems;
    final totalMin = scenes.fold(0, (a, b) => a + b.minutes);

    return Scaffold(
      body: Column(
        children: [
          if (scenes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Text('${scenes.length}シーン',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  Text('推定合計 $totalMin分',
                    style: TextStyle(
                      color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            ),
          Expanded(
            child: scenes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grid_view_outlined,
                          size: 56, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text('シーンがありません',
                          style: TextStyle(
                            color: Colors.grey[500])),
                        const SizedBox(height: 8),
                        Text('右下のボタンで追加してください',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: scenes.length,
                    itemBuilder: (_, i) {
                      final s = scenes[i];
                      final cast = provider.castMembers
                          .where((c) => s.castIds.contains(c.id))
                          .toList();
                      return _SceneTile(
                        scene: s,
                        castNames: cast.map((c) => c.name).toList(),
                        provider: provider,
                      );
                    },
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
      builder: (_) => _SceneEditSheet(
        projectId: provider.currentProject!.id,
        provider: provider,
      ),
    );
  }
}

class _SceneTile extends StatelessWidget {
  final SceneItem scene;
  final List<String> castNames;
  final ProjectProvider provider;

  const _SceneTile({
    required this.scene,
    required this.castNames,
    required this.provider,
  });

  Color _ioColor() {
    return scene.io == '屋外'
        ? Colors.blue.shade400
        : Colors.orange.shade400;
  }

  Color _todColor() {
    switch (scene.timeOfDay) {
      case '朝': return Colors.orange.shade300;
      case '昼': return Colors.yellow.shade700;
      case '夕': return Colors.deepOrange.shade400;
      case '夜': return Colors.indigo.shade400;
      default:   return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showEdit(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // シーン番号
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: glightGreenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(scene.no,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: glightGreenDark)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 場所
                    Text(scene.location.isEmpty
                        ? '（場所未設定）' : scene.location,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                    const SizedBox(height: 6),
                    // タグ行
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: [
                        _tag(scene.io, _ioColor()),
                        _tag(scene.timeOfDay, _todColor()),
                        if (scene.minutes > 0)
                          _tag('${scene.minutes}分',
                            Colors.grey.shade600),
                        if (scene.date.isNotEmpty)
                          _tag(scene.date,
                            glightGreenDark),
                      ],
                    ),
                    // 内容
                    if (scene.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(scene.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.6)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    ],
                    // 出演者
                    if (castNames.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.people_outline,
                            size: 13, color: glightGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(castNames.join('・'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: glightGreen),
                              overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                    // 小道具
                    if (scene.props.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                            size: 13,
                            color: cs.onSurface.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(scene.props,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface
                                    .withOpacity(0.4)),
                              overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // 削除ボタン
              IconButton(
                icon: Icon(Icons.more_vert,
                  size: 18,
                  color: cs.onSurface.withOpacity(0.4)),
                onPressed: () => _showOptions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600)),
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
                provider.deleteSceneItem(scene.id);
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
      builder: (_) => _SceneEditSheet(
        projectId: scene.projectId,
        provider: provider,
        scene: scene,
      ),
    );
  }
}

class _SceneEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final SceneItem? scene;
  const _SceneEditSheet({
    required this.projectId,
    required this.provider,
    this.scene,
  });

  @override
  State<_SceneEditSheet> createState() => _SceneEditSheetState();
}

class _SceneEditSheetState extends State<_SceneEditSheet> {
  late TextEditingController _noCtrl;
  late TextEditingController _locCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _propsCtrl;
  late TextEditingController _costumeCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _memoCtrl;
  String _io = '屋内';
  String _tod = '昼';
  List<String> _selectedCastIds = [];

  @override
  void initState() {
    super.initState();
    final s = widget.scene;
    _noCtrl      = TextEditingController(text: s?.no ?? '');
    _locCtrl     = TextEditingController(text: s?.location ?? '');
    _descCtrl    = TextEditingController(text: s?.description ?? '');
    _propsCtrl   = TextEditingController(text: s?.props ?? '');
    _costumeCtrl = TextEditingController(text: s?.costume ?? '');
    _minCtrl     = TextEditingController(
      text: s != null && s.minutes > 0 ? '${s.minutes}' : '');
    _dateCtrl    = TextEditingController(text: s?.date ?? '');
    _memoCtrl    = TextEditingController(text: s?.memo ?? '');
    _io  = s?.io ?? '屋内';
    _tod = s?.timeOfDay ?? '昼';
    _selectedCastIds = List.from(s?.castIds ?? []);
  }

  @override
  void dispose() {
    _noCtrl.dispose(); _locCtrl.dispose();
    _descCtrl.dispose(); _propsCtrl.dispose();
    _costumeCtrl.dispose(); _minCtrl.dispose();
    _dateCtrl.dispose(); _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.scene != null;
    final castMembers = widget.provider.castMembers;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(isEdit ? 'シーンを編集' : 'シーンを追加',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (isEdit)
                    TextButton(
                      onPressed: () {
                        widget.provider.deleteSceneItem(
                          widget.scene!.id);
                        Navigator.pop(context);
                      },
                      child: const Text('削除',
                        style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20),
                children: [
                  // No. と場所
                  Row(children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _noCtrl,
                        decoration: const InputDecoration(
                          labelText: 'No.'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _locCtrl,
                        decoration: const InputDecoration(
                          labelText: '場所'))),
                  ]),
                  const SizedBox(height: 12),
                  // 内外・時間帯
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _io,
                        decoration: const InputDecoration(
                          labelText: '内/外'),
                        dropdownColor: cs.surface,
                        items: const [
                          DropdownMenuItem(
                            value: '屋内', child: Text('屋内')),
                          DropdownMenuItem(
                            value: '屋外', child: Text('屋外')),
                        ],
                        onChanged: (v) =>
                          setState(() => _io = v ?? '屋内')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _tod,
                        decoration: const InputDecoration(
                          labelText: '時間帯'),
                        dropdownColor: cs.surface,
                        items: const [
                          DropdownMenuItem(
                            value: '朝', child: Text('朝')),
                          DropdownMenuItem(
                            value: '昼', child: Text('昼')),
                          DropdownMenuItem(
                            value: '夕', child: Text('夕')),
                          DropdownMenuItem(
                            value: '夜', child: Text('夜')),
                        ],
                        onChanged: (v) =>
                          setState(() => _tod = v ?? '昼')),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  // 内容
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: '内容・ト書き'),
                    maxLines: 3),
                  const SizedBox(height: 12),
                  // 出演者選択
                  if (castMembers.isNotEmpty) ...[
                    Text('出演者',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: castMembers.map((c) {
                        final selected =
                          _selectedCastIds.contains(c.id);
                        return FilterChip(
                          label: Text(c.name,
                            style: const TextStyle(
                              fontSize: 12)),
                          selected: selected,
                          selectedColor:
                            glightGreen.withOpacity(0.2),
                          checkmarkColor: glightGreen,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _selectedCastIds.add(c.id);
                            } else {
                              _selectedCastIds.remove(c.id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // 小道具・衣装
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _propsCtrl,
                        decoration: const InputDecoration(
                          labelText: '小道具'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _costumeCtrl,
                        decoration: const InputDecoration(
                          labelText: '衣装'))),
                  ]),
                  const SizedBox(height: 12),
                  // 推定時間・撮影日
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _minCtrl,
                        decoration: const InputDecoration(
                          labelText: '推定（分）'),
                        keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _dateCtrl,
                        decoration: const InputDecoration(
                          labelText: '撮影日',
                          hintText: '9/15'),
                      )),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _memoCtrl,
                    decoration: const InputDecoration(
                      labelText: '備考・注意点'),
                    maxLines: 2),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? '更新' : '追加')),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final s = SceneItem(
      id: widget.scene?.id,
      projectId: widget.projectId,
      no: _noCtrl.text.trim(),
      location: _locCtrl.text.trim(),
      io: _io,
      timeOfDay: _tod,
      description: _descCtrl.text.trim(),
      castIds: _selectedCastIds,
      props: _propsCtrl.text.trim(),
      costume: _costumeCtrl.text.trim(),
      minutes: int.tryParse(_minCtrl.text) ?? 0,
      date: _dateCtrl.text.trim(),
      memo: _memoCtrl.text.trim(),
      sortKey: widget.scene?.sortKey
          ?? widget.provider.sceneItems.length,
    );
    if (widget.scene != null) {
      widget.provider.updateSceneItem(s);
    } else {
      widget.provider.addSceneItem(s);
    }
    Navigator.pop(context);
  }
}