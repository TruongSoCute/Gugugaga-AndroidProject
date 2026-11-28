import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme_widgets.dart';

/// Một mục trên thanh điều hướng nổi dạng viên thuốc.
class FloatingNavigationItem {
  const FloatingNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Thanh điều hướng nổi dạng viên thuốc tối giản (Floating Capsule Dock),
/// tham khảo phong cách Material 3 Expressive / Shop / Stripe và đồng bộ với app Admin.
class FloatingNavigationBar extends StatelessWidget {
  const FloatingNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<FloatingNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OcopColors.nenManHinh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: OcopColors.nenThe,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18111827),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x0A111827),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _FloatingTabButton(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingTabButton extends StatelessWidget {
  const _FloatingTabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mau = selected ? OcopColors.xanhOcop : OcopColors.chuPhu;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          splashColor: OcopColors.xanhNhat,
          highlightColor: OcopColors.xanhNhat.withValues(alpha: 0.5),
          onTap: () {
            if (!selected) HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? OcopColors.xanhNhat : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Icon(selected ? item.selectedIcon : item.icon, size: 21, color: mau),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: mau,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
