import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import '../widgets/type_card.dart';
import '../widgets/ui_kit.dart';
import 'project_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final projects = provider.projects;
    final user = Supabase.instance.client.auth.currentUser;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: glightGreen,
                borderRadius: BorderRadius.circular(8)),
              child: const Center(
                child: Text('G',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16))),
            ),
            const SizedBox(width: 10),
            const Text('制作スケジュール帳'),
          ],
        ),
        actions: [
          // テーマ切り替えボタン
          IconButton(
            icon: Icon(
              themeProvider.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined),
            tooltip: themeProvider.isDark ? 'ライトモード' : 'ダークモード',
            onPressed: () => themeProvider.toggle(),
          ),
          // ユーザーメニュー
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ログイン中',
                      style: Theme.of(context).textTheme.labelSmall),
                    Text(user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 10),
                  Text('ログアウト'),
                ]),
              ),
            ],
            onSelected: (val) async {
              if (val == 'logout') {
                await Supabase.instance.client.auth.signOut();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: projects.isEmpty
          ? EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'プロジェクトがありません',
              subtitle: '右下のボタンから新規作成してください',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Text('プロジェクト',
                  style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                ...projects.map((p) => _ProjectTile(project: p)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAppSheet(context, const _NewProjectSheet()),
        icon: const Icon(Icons.add),
        label: const Text('新規プロジェクト',
          style: TextStyle(fontWeight: FontWeight.w700)),
      ),
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

  void _confirmDelete(BuildContext ctx) {
    final title = project.title.isEmpty ? '（タイトル未設定）' : project.title;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('プロジェクトを削除'),
        content: Text('「$title」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<ProjectProvider>().deleteProject(project.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final title = project.title.isEmpty ? '（タイトル未設定）' : project.title;
    
    return Card(
      child: InkWell(
        onTap: () async {
          final provider = context.read<ProjectProvider>();
          await provider.openProject(project.id);
          if (context.mounted) {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProjectScreen()));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: glightGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(_icon, color: glightGreen, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.titleMedium?.copyWith(
                        color: project.title.isEmpty
                            ? cs.onSurfaceVariant : cs.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Tag(project.type.label),
                        if (project.director.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(project.director, style: tt.bodySmall),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 削除ボタン
              IconButton(
                icon: Icon(Icons.delete_outline, color: cs.error),
                tooltip: '削除',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
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
  void dispose() { _titleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.9, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            SheetHeader(
              title: '新規プロジェクト',
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  const SectionHeader(title: '制作の種類'),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10, mainAxisSpacing: 10,
                      childAspectRatio: 1.3),
                    itemCount: ProjectType.values.length,
                    itemBuilder: (_, i) {
                      final t = ProjectType.values[i];
                      return TypeCard(type: t, selected: _type == t,
                        onTap: () => setState(() => _type = t));
                    },
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(title: _type.titleLabel),
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      hintText: _type == ProjectType.film
                          ? '例：夏の終わりに' : '例：〇〇フェス2026'),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _creating ? null : _create,
                    child: _creating
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                        : const Text('プロジェクトを作成 →'),
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

  Future<void> _create() async {
    setState(() => _creating = true);
    final provider = context.read<ProjectProvider>();
    await provider.createProject(title: _titleCtrl.text.trim(), type: _type);
    if (mounted) {
      Navigator.pop(context);
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ProjectScreen()));
    }
  }
}
