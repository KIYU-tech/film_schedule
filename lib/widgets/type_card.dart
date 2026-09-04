import 'package:flutter/material.dart';
import '../models/project.dart';
import '../theme.dart';

class TypeCard extends StatelessWidget {
  final ProjectType type;
  final bool selected;
  final VoidCallback onTap;

  const TypeCard({super.key, required this.type,
    required this.selected, required this.onTap});

  IconData get _icon {
    switch (type) {
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? glightGreen : cs.surfaceContainerHighest,
          border: Border.all(
            color: selected ? glightGreen : cs.outline,
            width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [BoxShadow(
                  color: glightGreen.withOpacity(0.3),
                  blurRadius: 16, offset: const Offset(0, 6))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.black.withOpacity(0.15)
                    : glightGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(_icon, size: 20,
                color: selected ? Colors.black : glightGreen),
            ),
            const SizedBox(height: 10),
            Text(type.label,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: selected ? Colors.black : cs.onSurface)),
            const SizedBox(height: 4),
            Text(type.description,
              style: TextStyle(
                fontSize: 11, height: 1.5,
                color: selected
                    ? Colors.black.withOpacity(0.7)
                    : cs.onSurfaceVariant),
              maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
