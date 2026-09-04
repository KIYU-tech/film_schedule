// 共通UIパーツ集
// 各画面で同じ見た目を保つため、ここにまとめる
import 'package:flutter/material.dart';
import '../theme.dart';

// ===== セクションヘッダー =====
// 左に緑の縦線 + タイトル
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4, height: 20,
            decoration: BoxDecoration(
              color: glightGreen,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

// ===== タグ（小さいラベル） =====
class Tag extends StatelessWidget {
  final String label;
  final Color? color;
  final bool filled;
  const Tag(this.label, {super.key, this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? glightGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? c : c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: filled ? null : Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(label,
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: filled ? Colors.black : c)),
    );
  }
}

// ===== 空状態 =====
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title,
    this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, size: 32, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ===== 統計チップ（数値表示） =====
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const StatChip({super.key, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? glightGreen;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: TextStyle(fontSize: 11, color: c.withOpacity(0.8),
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value,
              style: TextStyle(fontSize: 16, color: c,
                fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ],
        ),
      ),
    );
  }
}

// ===== ボトムシートの共通ハンドル+ヘッダー =====
class SheetHeader extends StatelessWidget {
  final String title;
  final Widget? badge;
  final Widget? trailing;
  const SheetHeader({super.key, required this.title, this.badge, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: cs.outline,
            borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (badge != null) ...[const SizedBox(width: 8), badge!],
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

// ===== 統計サマリーバー =====
class SummaryBar extends StatelessWidget {
  final List<Widget> children;
  const SummaryBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outline))),
      child: Row(
        children: children
          .expand((w) => [w, const SizedBox(width: 8)])
          .toList()..removeLast(),
      ),
    );
  }
}

// ===== ボトムシートを開くヘルパー =====
Future<T?> showAppSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => child,
  );
}

// ===== 選択ボタン（屋内/屋外などの2〜3択） =====
class SelectButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SelectButton({super.key, required this.label,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? glightGreen : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? glightGreen : cs.outline)),
        child: Text(label,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? Colors.black : cs.onSurfaceVariant)),
      ),
    );
  }
}


// ===== スマホ向け 横スクロール可能なボトムナビ =====
// 通常のNavigationBarはタブ数が多いと窮屈で押しにくいため、
// 画面が狭い時はこちらの横スクロール版に切り替える
class ScrollableBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<({IconData icon, String label})> items;
  const ScrollableBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outline)),
      ),
      child: SafeArea(
        top: false,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final selected = i == selectedIndex;
            final item = items[i];
            return GestureDetector(
              onTap: () => onSelected(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected ? glightGreen.withOpacity(0.16) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      // アイコンを一回り大きくして押しやすく
                      child: Icon(item.icon, size: 26,
                        color: selected ? glightGreen : cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? glightGreen : cs.onSurfaceVariant),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
