import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Horizontal list of round, selectable options (filters, backgrounds).
class OptionStrip extends StatelessWidget {
  const OptionStrip({super.key, required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: itemBuilder,
        ),
      );
}

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    this.isPro = false,
  });

  final String label;
  final bool selected;
  final bool isPro;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: isPro ? '$label (Pro)' : label,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 68,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? AppTheme.brand : Colors.white24,
                          width: selected ? 3 : 1.5,
                        ),
                      ),
                      child: ClipOval(child: child),
                    ),
                    if (isPro)
                      const PositionedDirectional(
                        top: -2,
                        end: -2,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: Color(0xFFFFC107),
                          child: Icon(Icons.workspace_premium, size: 14, color: Colors.black),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            const SizedBox(width: 8),
            SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13))),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                label: (value * 100).round().toString(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      );
}
