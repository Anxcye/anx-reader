import 'package:anx_reader/theme/anx_colors.dart';
import 'package:anx_reader/theme/anx_theme.dart';
import 'package:flutter/material.dart';

/// Plain grouped surface (no Forui card chrome) for section backgrounds.
class AnxSurface extends StatelessWidget {
  const AnxSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.radius = AnxColors.radiusMd,
    this.bordered = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double radius;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final tokens = AnxTheme.of(context).colors;
    final bg = color ?? tokens.surfaceContainer;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          border: bordered || tokens.eInkMode
              ? Border.all(color: tokens.border)
              : null,
        ),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}
