import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme.dart';
import '../widgets/type_card.dart';
import 'project_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final projects = provider.projects;
    // Supabase.instance.client.auth.currentUser → 現在ログイン中のユーザー
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: glightGreen,
                borderRadius: BorderRadius.circular(6)),
              child: const Center(
                child: Text('G',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16))),
            ),
            const SizedBox(width: 10),
            const Text('制作スケジュール帳',
              style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          // ユーザーメニュー
          PopupMenuButton(
            icon: const Icon(Icons.account_circle_outlined),
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                enabled: false,
                child: Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 12, color: Colors.grey[500]))),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('ログアウト'),
                ])),
            ],
            onSelected: (val) async {
              if (val == 'logout') {
                // ログアウト → AuthScreenに自動遷移（StreamBuilderが検知）
                await Supabase.instance.client.auth.signOut();
              }
            },
          ),
        ],
      ),
      body: projects.isEmpty
          ? _buildEmpty(context)
          : _buildList(context, projects),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewSheet(context),
        backgroundColor: glightGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('新規プロジェクト',
          style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined,
            size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text('プロジェクトがありません',
            style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 8),
          Text('右下のボタンから新規作成してください',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Project> projects) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (_, i) => _ProjectTile(project: projects[i]),
    );
  }

  void _showNewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewProjectSheet(),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  const _ProjectTile({required this.project});

  IconData get _icon {
    switch (project.type) {
      case ProjectType.film:       return Icons.movie_outlined;
      case ProjectType.broadcast:  return Icons.cast_outlined;
      case ProjectType.live:       return Icons.music_note_outlined;
      case ProjectType.event:      return Icons.event_outlined;
      case ProjectType.conference: return Icons.groups_outlined;
      case ProjectType.video:      return Icons.videocam_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: glightGreenLight,
            borderRadius: BorderRadius.circular(10)),
          child: Icon(_icon, color: glightGreenDark, size: 22),
        ),
        title: Text(
          project.title.isEmpty ? '（タイトル未設定）' : project.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: project.title.isEmpty
                ? cs.onSurface.withOpacity(0.4) : cs.onSurface)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: glightGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4)),
              child: Text(project.type.label,
                style: const TextStyle(
                  fontSize: 11, color: glightGreen,
                  fontWeight: FontWeight.w700)),
            ),
            if (project.director.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(project.director,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5))),
            ],
          ],
        ),
        trailing: Icon(Icons.chevron_right,
          color: cs.onSurface.withOpacity(0.3)),
        onTap: () async {
          final provider = context.read<ProjectProvider>();
          await provider.openProject(project.id);
          if (context.mounted) {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProjectScreen()));
          }
        },
      ),
    );
  }
}

class _NewProjectSheet extends StatefulWidget {
  const _NewProjectSheet();

  @override
  State<_NewProjectSheet> createState() => _NewProjectSheetState();
}

class _NewProjectSheetState extends State<_NewProjectSheet> {
  final _titleCtrl = TextEditingController();
  ProjectType _type = ProjectType.film;
  bool _creating = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20))),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text('新規プロジェクト',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _stepLabel('01', '制作の種類'),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10, mainAxisSpacing: 10,
                        childAspectRatio: 1.3),
                    itemCount: ProjectType.values.length,
                    itemBuilder: (_, i) {
                      final t = ProjectType.values[i];
                      return TypeCard(
                        type: t, selected: _type == t,
                        onTap: () => setState(() => _type = t));
                    },
                  ),
                  const SizedBox(height: 24),
                  _stepLabel('02', _type.titleLabel),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      hintText: _type == ProjectType.film
                          ? '例：夏の終わりに' : '例：〇〇フェス2024'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _creating ? null : _create,
                      child: _creating
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                          : const Text('プロジェクトを作成 →'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepLabel(String num, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: glightGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6)),
          child: Text('STEP $num',
            style: const TextStyle(
              fontSize: 11, color: glightGreen,
              fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Text(label,
          style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    final provider = context.read<ProjectProvider>();
    await provider.createProject(
      title: _titleCtrl.text.trim(), type: _type);
    if (mounted) {
      Navigator.pop(context);
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ProjectScreen()));
    }
  }
}
