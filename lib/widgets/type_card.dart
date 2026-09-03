import 'package:flutter/material.dart';
import '../models/project.dart';
import '../theme.dart';

class TypeCard extends StatelessWidget {
  final ProjectType type;
  final bool selected;
  final VoidCallback onTap;

  const TypeCard({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? glightGreen : cs.surface,
          border: Border.all(
            color: selected ? glightGreen : cs.outline,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [BoxShadow(
                  color: glightGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _icon,
              size: 26,
              color: selected ? Colors.black : glightGreen,
            ),
            const SizedBox(height: 10),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.black : cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type.description,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? Colors.black87
                    : cs.onSurface.withOpacity(0.5),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}