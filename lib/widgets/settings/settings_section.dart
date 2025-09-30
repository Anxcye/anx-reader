import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:flutter/material.dart';

abstract class AbstractSettingsSection extends StatelessWidget {
  const AbstractSettingsSection({super.key});
}

class SettingsSection extends AbstractSettingsSection {
  const SettingsSection({
    super.key,
    required this.tiles,
    this.margin,
    this.title,
  });

  final List<AbstractSettingsTile> tiles;
  final EdgeInsetsDirectional? margin;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    return buildSectionBody(context);
  }

  Widget buildSectionBody(BuildContext context) {
    const scaleFactor = 0.5;
    final tileList = buildTileList();

    if (title == null) {
      return tileList;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            top: 24 * scaleFactor,
            bottom: 10 * scaleFactor,
            start: 24,
            end: 24,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Theme.of(context).primaryColor,
            ),
            child: title!,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FilledContainer(
            padding: EdgeInsetsGeometry.zero,
            child: tileList,
          ),
        ),
      ],
    );
  }

  Widget buildTileList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: tiles.length,
      padding: EdgeInsets.zero,
      itemBuilder: (BuildContext context, int index) {
        return tiles[index];
      },
    );
  }
}

class CustomSettingsSection extends AbstractSettingsSection {
  const CustomSettingsSection({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
