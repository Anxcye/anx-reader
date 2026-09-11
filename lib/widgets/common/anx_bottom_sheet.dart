import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/theme/anx_colors.dart';
import 'package:anx_reader/theme/anx_theme.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Shows a bottom sheet using Forui [showFSheet] when an [FTheme] is present.
///
/// Falls back to a Forui-styled [showModalBottomSheet] if Forui sheet APIs
/// cannot be used (e.g. missing ancestor theme in tests).
Future<T?> showAnxBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = true,
  bool showDragHandle = true,
  Color? backgroundColor,
  double? mainAxisMaxRatio,
  RouteSettings? routeSettings,
}) {
  final tokens = AnxTheme.of(context).colors;
  final eInk = Prefs().eInkMode;

  try {
    return showFSheet<T>(
      context: context,
      side: FLayout.btt,
      useRootNavigator: useRootNavigator,
      barrierDismissible: isDismissible,
      draggable: enableDrag && !eInk,
      mainAxisMaxRatio: isScrollControlled
          ? null
          : (mainAxisMaxRatio ?? 9 / 16),
      routeSettings: routeSettings,
      useSafeArea: useSafeArea,
      builder: (sheetContext) {
        final content = builder(sheetContext);
        return AnxBottomSheet(
          backgroundColor: backgroundColor ?? tokens.groupedBackground,
          showDragHandle: showDragHandle,
          child: content,
        );
      },
    );
  } catch (_) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag && !eInk,
      backgroundColor: backgroundColor ?? tokens.groupedBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AnxColors.radiusLg),
        ),
      ),
      routeSettings: routeSettings,
      builder: (sheetContext) => AnxBottomSheet(
        backgroundColor: backgroundColor ?? tokens.groupedBackground,
        showDragHandle: showDragHandle,
        child: builder(sheetContext),
      ),
    );
  }
}

/// Chrome around bottom-sheet content: drag handle + Forui surface colors.
class AnxBottomSheet extends StatelessWidget {
  const AnxBottomSheet({
    super.key,
    required this.child,
    this.backgroundColor,
    this.showDragHandle = true,
  });

  final Widget child;
  final Color? backgroundColor;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final tokens = AnxTheme.of(context).colors;
    final bg = backgroundColor ?? tokens.groupedBackground;

    return Material(
      color: bg,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AnxColors.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.mutedForeground.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
