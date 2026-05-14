import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AppBottomNavigationItem {
  const AppBottomNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<AppBottomNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 10, offset: Offset(0, -3)),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _BottomNavButton(
                  item: items[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        selected ? AppColors.primary : AppColors.navInactive;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerUp: (_) => onTap(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                tween: ColorTween(end: foregroundColor),
                builder: (context, color, _) {
                  return Icon(
                    selected ? item.activeIcon : item.icon,
                    color: color ?? foregroundColor,
                    size: 21,
                  );
                },
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 11,
                  ),
                  child: Text(item.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
