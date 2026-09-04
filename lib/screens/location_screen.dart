import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final locations = provider.locations;

    return Scaffold(
      body: locations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined,
                    size: 56, color: Colors.grey[700]),
                  const SizedBox(height: 12),
                  Text('ロケ地がありません',
                    style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  Text('右下のボタンで追加してください',
                    style: TextStyle(
                      color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: locations.length,
              itemBuilder: (_, i) => _LocationTile(
                location: locations[i],
                provider: provider,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, provider),
        backgroundColor: glightGreen,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_location_alt_outlined),
      ),
    );
  }

  void _showAdd(BuildContext ctx, ProjectProvider provider) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationEditSheet(
        projectId: provider.currentProject!.id,
        provider: provider,
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final LocationItem location;
  final ProjectProvider provider;

  const _LocationTile({
    required this.location,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showEdit(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: glightGreenLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on,
                      color: glightGreenDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(location.name.isEmpty
                            ? '（名称未設定）' : location.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                        if (location.address.isNotEmpty)
                          Text(location.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.5)),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert,
                      size: 18,
                      color: cs.onSurface.withOpacity(0.4)),
                    onPressed: () => _showOptions(context),
                  ),
                ],
              ),
              // タグ行
              if (location.permitRequired ||
                  location.hasParking ||
                  location.indoor != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: [
                    if (location.indoor != null)
                      _tag(location.indoor! ? '屋内' : '屋外',
                        location.indoor!
                            ? Colors.orange : Colors.blue),
                    if (location.permitRequired)
                      _tag('許可申請必要', Colors.red),
                    if (location.hasParking)
                      _tag('駐車場あり', Colors.green),
                  ],
                ),
              ],
              // アクセス・備考
              if (location.access.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions_outlined,
                      size: 13,
                      color: cs.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(location.access,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
              if (location.memo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.notes_outlined,
                      size: 13,
                      color: cs.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(location.memo,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
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
        color: color.withOpacity(0.12),
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
                provider.deleteLocation(location.id);
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
      builder: (_) => _LocationEditSheet(
        projectId: location.projectId,
        provider: provider,
        location: location,
      ),
    );
  }
}

class _LocationEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final LocationItem? location;

  const _LocationEditSheet({
    required this.projectId,
    required this.provider,
    this.location,
  });

  @override
  State<_LocationEditSheet> createState() =>
    _LocationEditSheetState();
}

class _LocationEditSheetState
    extends State<_LocationEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _accessCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _hoursCtrl;
  late TextEditingController _memoCtrl;
  bool? _indoor;
  bool _permitRequired = false;
  bool _hasParking = false;

  @override
  void initState() {
    super.initState();
    final l = widget.location;
    _nameCtrl    = TextEditingController(text: l?.name ?? '');
    _addressCtrl = TextEditingController(text: l?.address ?? '');
    _accessCtrl  = TextEditingController(text: l?.access ?? '');
    _contactCtrl = TextEditingController(text: l?.contact ?? '');
    _hoursCtrl   = TextEditingController(text: l?.hours ?? '');
    _memoCtrl    = TextEditingController(text: l?.memo ?? '');
    _indoor        = l?.indoor;
    _permitRequired = l?.permitRequired ?? false;
    _hasParking    = l?.hasParking ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose();
    _accessCtrl.dispose(); _contactCtrl.dispose();
    _hoursCtrl.dispose(); _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.location != null;

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
                  Text(isEdit ? 'ロケ地を編集' : 'ロケ地を追加',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (isEdit)
                    TextButton(
                      onPressed: () {
                        widget.provider.deleteLocation(
                          widget.location!.id);
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
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ロケ地名・場所名',
                      hintText: '例：渋谷公園通り'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: '住所',
                      hintText: '例：東京都渋谷区宇田川町'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accessCtrl,
                    decoration: const InputDecoration(
                      labelText: 'アクセス',
                      hintText: '例：渋谷駅から徒歩5分'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hoursCtrl,
                    decoration: const InputDecoration(
                      labelText: '使用可能時間',
                      hintText: '例：9:00〜18:00'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contactCtrl,
                    decoration: const InputDecoration(
                      labelText: '連絡先・担当者',
                      hintText: '例：〇〇管理事務所 03-xxxx-xxxx'),
                  ),
                  const SizedBox(height: 14),
                  // 屋内/屋外
                  Text('屋内 / 屋外',
                    style: TextStyle(
                      fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Row(children: [
                    _selectBtn('屋内', _indoor == true,
                      () => setState(() => _indoor = true)),
                    const SizedBox(width: 8),
                    _selectBtn('屋外', _indoor == false,
                      () => setState(() => _indoor = false)),
                    const SizedBox(width: 8),
                    _selectBtn('両方', _indoor == null,
                      () => setState(() => _indoor = null)),
                  ]),
                  const SizedBox(height: 14),
                  // チェックボックス
                  CheckboxListTile(
                    value: _permitRequired,
                    onChanged: (v) =>
                      setState(() => _permitRequired = v ?? false),
                    title: const Text('許可申請が必要'),
                    activeColor: glightGreen,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _hasParking,
                    onChanged: (v) =>
                      setState(() => _hasParking = v ?? false),
                    title: const Text('駐車場あり'),
                    activeColor: glightGreen,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _memoCtrl,
                    decoration: const InputDecoration(
                      labelText: '備考・注意点',
                      hintText: '例：雨天時は使用不可、トイレなし'),
                    maxLines: 3,
                  ),
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

  Widget _selectBtn(String label, bool selected,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? glightGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? glightGreen : Colors.grey.shade600),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : Colors.grey.shade400)),
      ),
    );
  }

  void _save() {
    final l = LocationItem(
      id: widget.location?.id,
      projectId: widget.projectId,
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      access: _accessCtrl.text.trim(),
      hours: _hoursCtrl.text.trim(),
      contact: _contactCtrl.text.trim(),
      memo: _memoCtrl.text.trim(),
      indoor: _indoor,
      permitRequired: _permitRequired,
      hasParking: _hasParking,
    );
    if (widget.location != null) {
      widget.provider.updateLocation(l);
    } else {
      widget.provider.addLocation(l);
    }
    Navigator.pop(context);
  }
}
