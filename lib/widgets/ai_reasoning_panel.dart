import 'package:flutter/material.dart';

class ReasoningPanel extends StatelessWidget {
  const ReasoningPanel({
    super.key,
    required this.think,
    required this.expanded,
    required this.onToggle,
    this.streaming = false,
    this.margin = const EdgeInsets.only(bottom: 8.0),
  });

  final String think;
  final bool expanded;
  final bool streaming;
  final VoidCallback onToggle;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      streaming ? 'Thinking...' : 'Reasoning',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SelectableText(
                think,
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}
