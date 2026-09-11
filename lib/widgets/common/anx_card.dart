import 'package:anx_reader/theme/anx_colors.dart';
import 'package:anx_reader/theme/anx_theme.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Grouped settings-style card backed by Forui [FCard].
class AnxCard extends StatelessWidget {
  const AnxCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final tokens = AnxTheme.of(context).colors;
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    Widget card = FCard(
      clipBehavior: clipBehavior,
      style: FCardStyleDelta.delta(
        decoration: DecorationDelta.shapeDelta(
          color: tokens.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AnxColors.radiusMd),
            side: BorderSide(
              color: tokens.eInkMode
                  ? tokens.border
                  : tokens.border.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
      child: content,
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }
    return card;
  }
}
