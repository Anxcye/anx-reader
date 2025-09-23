import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/hint_key.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:flutter/material.dart';

class HintBanner extends StatefulWidget {
  const HintBanner({
    super.key,
    required this.child,
    this.icon,
    this.hintKey,
    this.onClose,
    this.margin,
    this.padding,
  });

  final Widget child;
  final Widget? icon;
  final HintKey? hintKey;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  State<HintBanner> createState() => _HintBannerState();
}

class _HintBannerState extends State<HintBanner> {
  late bool _visible;

  @override
  void initState() {
    super.initState();
    _visible = widget.hintKey == null
        ? true
        : Prefs().shouldShowHint(widget.hintKey!);
  }

  void _handleClose() {
    if (!_visible) return;

    widget.onClose?.call();

    if (widget.hintKey != null) {
      Prefs().setShowHint(widget.hintKey!, false);
    }

    setState(() {
      _visible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.primary;
    final backgroundColor = colorScheme.primary.withAlpha(30);

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withAlpha(200), width: 1.5),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 32, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.icon != null) ...[
                  IconTheme(
                    data: IconTheme.of(context)
                        .copyWith(color: borderColor.withAlpha(220)),
                    child: widget.icon!,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(child: widget.child),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: _handleClose,
              icon: Icon(
                Icons.close,
                size: 18,
                color: borderColor.withAlpha(220),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              splashRadius: 18,
              tooltip: L10n.of(context).close,
            ),
          ),
        ],
      ),
    );
  }
}
