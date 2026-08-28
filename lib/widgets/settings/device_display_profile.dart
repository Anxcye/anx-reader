import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/device_display_profile.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/common/anx_segmented_button.dart';
import 'package:flutter/material.dart';

class DeviceDisplayProfileCard extends StatefulWidget {
  const DeviceDisplayProfileCard({super.key, this.compact = false});

  final bool compact;

  @override
  State<DeviceDisplayProfileCard> createState() =>
      _DeviceDisplayProfileCardState();
}

class _DeviceDisplayProfileCardState extends State<DeviceDisplayProfileCard> {
  late DeviceDisplayProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = Prefs().deviceDisplayProfile;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isEInk = _profile == DeviceDisplayProfile.eInk;
    final colorScheme = Theme.of(context).colorScheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compact) ...[
          Row(
            children: [
              Icon(
                isEInk ? Icons.menu_book_outlined : Icons.smartphone_outlined,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEInk
                          ? l10n.deviceDisplayEInk
                          : l10n.deviceDisplayStandard,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      isEInk
                          ? l10n.deviceDisplayEInkDescription
                          : l10n.deviceDisplayStandardDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        AnxSegmentedButton<DeviceDisplayProfile>(
          segments: [
            SegmentButtonItem(
              value: DeviceDisplayProfile.standard,
              label: l10n.deviceDisplayStandard,
              icon: const Icon(Icons.smartphone_outlined),
            ),
            SegmentButtonItem(
              value: DeviceDisplayProfile.eInk,
              label: l10n.deviceDisplayEInk,
              icon: const Icon(Icons.menu_book_outlined),
            ),
          ],
          selected: {_profile},
          onSelectionChanged: (selection) async {
            final next = selection.first;
            await Prefs().saveDeviceDisplayProfile(next);
            if (mounted) setState(() => _profile = next);
          },
        ),
        if (!widget.compact) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.devices, size: 16, color: colorScheme.outline),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.deviceDisplayLocalOnly,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (widget.compact) return content;
    return Semantics(
      container: true,
      label: l10n.settingsDeviceDisplayProfile,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }
}
