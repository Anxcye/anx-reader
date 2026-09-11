import 'package:anx_reader/theme/anx_theme.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Thin scaffold facade.
///
/// Defaults to Material [Scaffold] with Forui-aligned background colors so
/// nested [Navigator]s, [Heroine], and [FlutterSmartDialog] keep working.
/// Use [AnxScaffold.forui] for simpler pages that can host [FScaffold] directly.
///
/// ## Why not FScaffold everywhere?
/// [FScaffold] has a fixed header / sidebar / footer layout and no
/// `floatingActionButton` / `extendBody` equivalents. The home shell and
/// reading chrome still need Material [Scaffold] behavior overnight; migrate
/// leaf pages gradually via [AnxScaffold.forui].
class AnxScaffold extends StatelessWidget {
  const AnxScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
  })  : header = null,
        footer = null,
        sidebar = null,
        child = null,
        _useForui = false,
        childPad = true;

  /// Forui-native scaffold for simple pages (settings-style leaf screens).
  const AnxScaffold.forui({
    super.key,
    required Widget this.child,
    this.header,
    this.footer,
    this.sidebar,
    this.backgroundColor,
    this.childPad = true,
    this.resizeToAvoidBottomInset = true,
  })  : appBar = null,
        body = null,
        floatingActionButton = null,
        floatingActionButtonLocation = null,
        bottomNavigationBar = null,
        drawer = null,
        endDrawer = null,
        extendBody = false,
        extendBodyBehindAppBar = false,
        _useForui = true;

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;

  final Widget? header;
  final Widget? footer;
  final Widget? sidebar;
  final Widget? child;
  final bool childPad;
  final bool _useForui;

  @override
  Widget build(BuildContext context) {
    final tokens = AnxTheme.of(context).colors;
    final bg = backgroundColor ?? tokens.groupedBackground;

    if (_useForui) {
      return FScaffold(
        header: header,
        footer: footer,
        sidebar: sidebar,
        childPad: childPad,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
        scaffoldStyle: FScaffoldStyleDelta.delta(
          backgroundColor: bg,
        ),
        child: child ?? const SizedBox.shrink(),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: bg,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
