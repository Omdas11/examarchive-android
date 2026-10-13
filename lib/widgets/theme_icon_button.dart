import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';

/// Theme switcher as a header icon: opens a bottom sheet with icon options.
class ThemeIconButton extends StatelessWidget {
  const ThemeIconButton({super.key});

  static const _icons = {
    AppThemeName.system: Icons.smartphone_outlined,
    AppThemeName.light: Icons.light_mode_outlined,
    AppThemeName.dark: Icons.dark_mode_outlined,
    AppThemeName.amoled: Icons.contrast_outlined,
    AppThemeName.emerald: Icons.eco_outlined,
  };

  static const _shortLabels = {
    AppThemeName.system: 'System',
    AppThemeName.light: 'Light',
    AppThemeName.dark: 'Dark',
    AppThemeName.amoled: 'AMOLED',
    AppThemeName.emerald: 'Emerald',
  };

  void _showPicker(BuildContext context) {
    final provider = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: AppThemeName.values.map((t) {
              final selected = provider.theme == t;
              final color = selected
                  ? Theme.of(ctx).colorScheme.primary
                  : Theme.of(ctx).colorScheme.onSurfaceVariant;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  provider.setTheme(t);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(ctx)
                                  .colorScheme
                                  .primaryContainer
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Theme.of(ctx).colorScheme.primary
                                : Theme.of(ctx).dividerColor,
                          ),
                        ),
                        child: Icon(_icons[t], color: color, size: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _shortLabels[t]!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.palette_outlined),
      tooltip: 'Theme',
      onPressed: () => _showPicker(context),
    );
  }
}
