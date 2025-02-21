import 'package:anx_reader/widgets/settings/settings_app_bar.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';

class SettingsPageBuilder extends StatelessWidget {
  const SettingsPageBuilder(
      {super.key,
      required this.isMobile,
      required this.id,
      required this.selectedIndex,
      required this.setDetail,
      required this.icon,
      required this.title,
      required this.sections,
      required this.subTitles});

  final bool isMobile;
  final int id;
  final int selectedIndex;
  final void Function(Widget detail, int id) setDetail;
  final Icon icon;
  final String title;
  final Widget sections;
  final List<String> subTitles;

  @override
  Widget build(BuildContext context) {
    return settingsTitle(
      icon: icon,
      title: title,
      isMobile: isMobile,
      id: id,
      selectedIndex: selectedIndex,
      setDetail: setDetail,
      subPage: SettingsPageBody(
        title: title,
        isMobile: isMobile,
        sections: sections,
      ),
      subtitle: subTitles,
    );
  }
}

class SettingsPageBody extends StatefulWidget {
  const SettingsPageBody({
    super.key,
    required this.title,
    required this.isMobile,
    required this.sections,
  });

  final String title;
  final bool isMobile;
  final Widget sections;

  @override
  State<SettingsPageBody> createState() => _SettingsPageBodyState();
}

class _SettingsPageBodyState extends State<SettingsPageBody> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isMobile ? settingsAppBar(widget.title, context) : null,
      body: widget.sections,
    );
  }
}
