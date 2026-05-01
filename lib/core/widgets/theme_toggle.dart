import 'package:flutter/material.dart';

import '../../core/state/app_controller.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final currentMode = controller.themeMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? const Color(0xFF1A2930)
        : const Color(0xFF1E5674).withValues(alpha: 0.12);
    final thumbColor = isDark
        ? const Color(0xFF9EC8D9)
        : const Color(0xFF1E5674);
    final textColor = isDark
        ? const Color(0xFFE8F0F2)
        : const Color(0xFF0F2C3F);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: currentMode == AppThemeMode.system
                  ? Alignment.centerLeft
                  : currentMode == AppThemeMode.light
                      ? Alignment.center
                      : Alignment.centerRight,
              child: Container(
                width: 90,
                height: 32,
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: thumbColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.setThemeMode(AppThemeMode.system),
                        child: _SegmentLabel(
                          icon: Icons.devices,
                          label: 'System',
                          selected: currentMode == AppThemeMode.system,
                          color: textColor,
                        ),
                      ),
                    ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setThemeMode(AppThemeMode.light),
                    child: _SegmentLabel(
                      icon: Icons.light_mode,
                      label: 'Light',
                      selected: currentMode == AppThemeMode.light,
                      color: textColor,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setThemeMode(AppThemeMode.dark),
                    child: _SegmentLabel(
                      icon: Icons.dark_mode,
                      label: 'Dark',
                      selected: currentMode == AppThemeMode.dark,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 14,
            color: selected ? Colors.white : color.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : color.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
