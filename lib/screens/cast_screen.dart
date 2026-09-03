import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

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
            Tab(text:
              '${project.type.castWord}（${provider.castMembers.length}）'),
            Tab(text:
              'スタッフ（${provider.crewMembers.length}）'),
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
          ? Center(
              child: Text('${type.castWord}がいません',
                style: const TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cast.length,
              itemBuilder: (_, i) =>
                _CastTile(member: cast[i], provider: provider),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEdit(context, provider),
        backgroundColor: glightGreen,
        foregroundColor: Colors.black,
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  void _showEdit(BuildContext ctx, ProjectProvider provider) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CastEditSheet(
        projectId: provider.currentProject!.id,
        provider: provider,
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
          backgroundColor: glightGreen.withOpacity(0.15),
          child: Text(
            member.name.isNotEmpty ? member.name[0] : '?',
            style: const TextStyle(
              color: glightGreenDark,
              fontWeight: FontWeight.w700,
            )),
        ),
        title: Text(member.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            if (member.rank.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: glightGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(member.rank,
                  style: const TextStyle(
                    fontSize: 11, color: glightGreen)),
              ),
            if (member.role.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(member.role,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5))),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, size: 18),
          onPressed: () => _showOptions(context),
        ),
        onTap: () => _showEdit(context),
      ),
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
              onTap: () {
                Navigator.pop(ctx);
                _showEdit(ctx);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline, color: Colors.red),
              title: const Text('削除',
                style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                provider.deleteCastMember(member.id);
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
      builder: (_) => _CastEditSheet(
        projectId: member.projectId,
        provider: provider,
        member: member,
      ),
    );
  }
}

class _CastEditSheet extends StatefulWidget {
  final String projectId;
  final ProjectProvider provider;
  final CastMember? member;
  const _CastEditSheet({
    required this.projectId,
    required this.provider,
    this.member,
  });

  @override
  State<_CastEditSheet> createState() => _CastEditSheetState();
}

class _CastEditSheetState extends State<_CastEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _roleCtrl;
  late TextEditingController _telCtrl;
  String _rank = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member?.name ?? '');
    _roleCtrl = TextEditingController(text: widget.member?.role ?? '');
    _telCtrl  = TextEditingController(text: widget.member?.tel ?? '');
    _rank     = widget.member?.rank ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final type = widget.provider.currentProject!.type;
    final isEdit = widget.member != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit
                ? '${type.castWord}を編集'
                : '${type.castWord}を追加',
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '氏名')),
            const SizedBox(height: 12),
            TextField(
              controller: _roleCtrl,
              decoration: InputDecoration(
                labelText: type == ProjectType.film
                    ? '役名' : '肩書・役割')),
            const SizedBox(height: 12),
            if (type.castRanks.isNotEmpty) ...[
              Text('区分',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: type.castRanks.map((r) =>
                  ChoiceChip(
                    label: Text(r,
                      style: const TextStyle(fontSize: 12)),
                    selected: _rank == r,
                    onSelected: (_) =>
                      setState(() => _rank = r),
                  )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _telCtrl,
              decoration:
                const InputDecoration(labelText: '連絡先'),
              keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? '更新' : '追加')),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final m = CastMember(
      id: widget.member?.id,
      projectId: widget.projectId,
      name: _nameCtrl.text.trim(),
      role: _roleCtrl.text.trim(),
      rank: _rank,
      tel: _telCtrl.text.trim(),
      availability: widget.member?.availability ?? {},
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
      body: crew.isEmpty
          ? const Center(
              child: Text('スタッフがいません',
                style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: crew.length,
              itemBuilder: (_, i) {
                final c = crew[i];
                return Card(
                  child: ListTile(
                    title: Text(c.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${c.company.isNotEmpty ? c.company + "　" : ""}${c.role}'),
                    trailing: Text(c.tel,
                      style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context),
        backgroundColor: glightGreen,
        foregroundColor: Colors.black,
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  void _showAdd(BuildContext ctx) {
    final nameCtrl    = TextEditingController();
    final companyCtrl = TextEditingController();
    final roleCtrl    = TextEditingController();
    final telCtrl     = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('スタッフを追加',
                style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl,
                decoration:
                  const InputDecoration(labelText: '氏名')),
              const SizedBox(height: 12),
              TextField(controller: companyCtrl,
                decoration:
                  const InputDecoration(labelText: '会社・所属')),
              const SizedBox(height: 12),
              TextField(controller: roleCtrl,
                decoration:
                  const InputDecoration(labelText: '担当')),
              const SizedBox(height: 12),
              TextField(controller: telCtrl,
                decoration:
                  const InputDecoration(labelText: '連絡先'),
                keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    provider.addCrewMember(CrewMember(
                      projectId: provider.currentProject!.id,
                      name: nameCtrl.text.trim(),
                      company: companyCtrl.text.trim(),
                      role: roleCtrl.text.trim(),
                      tel: telCtrl.text.trim(),
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('追加')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}