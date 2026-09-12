# UI design system (Forui + Anx facades)

## Why Forui

After comparing **forui**, **shadcn_flutter**, and staying on raw Material:

- **forui ^0.26** is shadcn-inspired, platform-agnostic, and works **under** `MaterialApp`.
- It ships Button / Scaffold / Sheet / Theme with `toApproximateMaterialTheme()`, so we can refresh visuals overnight without rewriting navigation, Riverpod, SmartDialog, or the reading WebView chrome.
- Mixing Material + Forui is officially supported.

We keep `MaterialApp` + existing navigation. Forui is the **visual system**, not a full app shell rewrite.

## Architecture

```
Prefs (seed / dark / true-black / e-ink)
        │
        ▼
   AnxTheme.fromPrefs  ──► FThemeData (+ AnxColors tokens)
        │
        ├─► MaterialApp.theme / darkTheme via AnxColors → FlexColorScheme
        │     (Forui's toApproximateMaterialTheme returns material_ui ThemeData,
        │      incompatible with flutter/material ThemeData in this app)
        │     (+ e-ink no-splash / no page transitions, Chinese fonts)
        └─► MaterialApp.builder → AnxThemeProvider → FTheme → FToaster / FTooltipGroup
              → FlutterSmartDialog.init()
```

Call sites should depend on **Anx\*** wrappers, not raw Material or raw Forui, so future swaps stay localized.

| Facade | Backed by | Notes |
|--------|-----------|--------|
| `AnxButton` | `FButton` | `filled→primary`, `outlined→outline`, `text/ghost→ghost`, plus `secondary` / `destructive` |
| `AnxScaffold` | Material `Scaffold` by default | Use `AnxScaffold.forui` for leaf pages; home shell keeps Material for `extendBody` / FAB / nested navigators |
| `showAnxBottomSheet` / `AnxBottomSheet` | `showFSheet` | Falls back to styled `showModalBottomSheet` |
| `AnxCard` / `AnxSurface` | `FCard` / decorated box | Grouped settings-style surfaces |

Barrel: `package:anx_reader/widgets/common/anx_ui.dart`.

## Usage snippets

```dart
AnxButton(
  onPressed: () {},
  child: const Text('Save'),
);

AnxButton.outlined(
  onPressed: () {},
  child: const Text('Cancel'),
);

showAnxBottomSheet(
  context: context,
  builder: (_) => const MySheetBody(),
);

AnxScaffold(
  appBar: AppBar(title: const Text('Settings')),
  body: ListView(...),
);
```

## E-ink

When `Prefs().eInkMode` is on:

- Forui colors collapse to high-contrast black / white (no accent seed).
- Material splash / highlight / page transitions are disabled (#986).
- `themeMode` is forced to light for the MaterialApp bridge.
- Sheet drag animations respect e-ink (drag disabled in `showAnxBottomSheet`).

## Migration status (overnight pass)

**Done**

- Theme bridge (`lib/theme/`, `lib/utils/color_scheme.dart`, `lib/main.dart`)
- Common facades under `lib/widgets/common/`
- Home shell (`home_page.dart`) → `AnxScaffold` + rail `AnxSurface`
- Bookshelf book sheet + sync status sheet → `showAnxBottomSheet` / `AnxButton`
- Settings home + `SettingsSection` chrome → `AnxCard`
- Statistics undo control → `AnxButton`

**Next pass (still Material-heavy)**

- Reading page WebView chrome / TTS / selection menus
- Most settings subpages (`appearance`, AI, narrate, storage, fonts, …)
- Remaining raw `ElevatedButton` / `showModalBottomSheet` / `ListTile` density
- Optional: migrate simple leaf pages to `AnxScaffold.forui` and `FBottomNavigationBar`

## Chinese fonts

`useSystemChineseFont` is still applied on the Material `ThemeData` after the Forui approximate theme is built. Do not drop that step.
