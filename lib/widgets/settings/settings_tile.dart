import 'package:flutter/material.dart';

abstract class AbstractSettingsTile extends StatelessWidget {
  const AbstractSettingsTile({super.key});
}

enum SettingsTileType { simpleTile, switchTile, navigationTile }

class SettingsTile extends AbstractSettingsTile {
  SettingsTile({
    this.leading,
    this.trailing,
    this.value,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    super.key,
  }) {
    onToggle = null;
    initialValue = null;
    activeSwitchColor = null;
    tileType = SettingsTileType.simpleTile;
  }

  SettingsTile.navigation({
    this.leading,
    this.trailing,
    this.value,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    super.key,
  }) {
    onToggle = null;
    initialValue = null;
    activeSwitchColor = null;
    tileType = SettingsTileType.navigationTile;
  }

  SettingsTile.switchTile({
    required this.initialValue,
    required this.onToggle,
    this.activeSwitchColor,
    this.leading,
    this.trailing,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    super.key,
  }) {
    value = null;
    tileType = SettingsTileType.switchTile;
  }

  /// The widget at the beginning of the tile
  final Widget? leading;

  /// The Widget at the end of the tile
  final Widget? trailing;

  /// The widget at the center of the tile
  final Widget title;

  /// The widget at the bottom of the [title]
  final Widget? description;

  /// A function that is called by tap on a tile
  final Function(BuildContext context)? onPressed;

  late final Color? activeSwitchColor;
  late final Widget? value;
  late final Function(bool value)? onToggle;
  late final SettingsTileType tileType;
  late final bool? initialValue;
  late final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AndroidSettingsTile(
      description: description,
      onPressed: onPressed,
      onToggle: onToggle,
      tileType: tileType,
      value: value,
      leading: leading,
      title: title,
      enabled: enabled,
      activeSwitchColor: activeSwitchColor,
      initialValue: initialValue ?? false,
      trailing: trailing,
    );
  }
}

class AndroidSettingsTile extends StatelessWidget {
  const AndroidSettingsTile({
    required this.tileType,
    required this.leading,
    required this.title,
    required this.description,
    required this.onPressed,
    required this.onToggle,
    required this.value,
    required this.initialValue,
    required this.activeSwitchColor,
    required this.enabled,
    required this.trailing,
    super.key,
  });

  final SettingsTileType tileType;
  final Widget? leading;
  final Widget? title;
  final Widget? description;
  final Function(BuildContext context)? onPressed;
  final Function(bool value)? onToggle;
  final Widget? value;
  final bool initialValue;
  final bool enabled;
  final Color? activeSwitchColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const scaleFactor = 0.6;

    final cantShowAnimation = tileType == SettingsTileType.switchTile
        ? onToggle == null && onPressed == null
        : onPressed == null;

    return IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: cantShowAnimation
              ? null
              : () {
                  if (tileType == SettingsTileType.switchTile) {
                    onToggle?.call(!initialValue);
                  } else {
                    onPressed?.call(context);
                  }
                },
          highlightColor: Theme.of(context).listTileTheme.selectedColor,
          child: Row(
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: IconTheme(
                    data: IconTheme.of(context).copyWith(
                      color: enabled
                          ? Theme.of(context).iconTheme.color
                          : Theme.of(context).disabledColor,
                    ),
                    child: leading!,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 10,
                    end: 8,
                    bottom: 19 * scaleFactor,
                    top: 19 * scaleFactor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style: TextStyle(
                          color: enabled
                              ? Theme.of(context).textTheme.bodyLarge!.color!
                              : Theme.of(context).disabledColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                        child: title ?? Container(),
                      ),
                      if (value != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: enabled
                                  ? Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .color!
                                  : Theme.of(context).disabledColor,
                            ),
                            child: value!,
                          ),
                        )
                      else if (description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: enabled
                                  ? Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .color!
                                  : Theme.of(context).disabledColor,
                            ),
                            child: description!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (trailing != null && tileType == SettingsTileType.switchTile)
                Row(
                  children: [
                    trailing!,
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Switch(
                        value: initialValue,
                        onChanged: onToggle,
                        activeColor: enabled
                            ? activeSwitchColor
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                )
              else if (tileType == SettingsTileType.switchTile)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
                  child: Switch(
                    value: initialValue,
                    onChanged: onToggle,
                    activeColor: enabled
                        ? activeSwitchColor
                        : Theme.of(context).disabledColor,
                  ),
                )
              else if (tileType == SettingsTileType.navigationTile)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: trailing ??
                      Icon(
                        Icons.chevron_right_sharp,
                        color: enabled
                            ? Theme.of(context).iconTheme.color
                            : Theme.of(context).disabledColor,
                      ),
                )
              else if (trailing != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: trailing!,
                )
            ],
          ),
        ),
      ),
    );
  }
}

class CustomSettingsTile extends AbstractSettingsTile {
  const CustomSettingsTile({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
