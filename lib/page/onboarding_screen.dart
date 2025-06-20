import 'package:anx_reader/page/settings_page/appearance.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/widgets/settings/theme_mode.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

/// Onboarding screen for first-time users
/// Shows introduction pages covering key features and settings
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final GlobalKey<IntroductionScreenState> _introKey =
      GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: _introKey,
      globalBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      allowImplicitScrolling: true,
      infiniteAutoScroll: false,
      globalHeader: Align(
        alignment: Alignment.topRight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16),
            child: _buildSkipButton(),
          ),
        ),
      ),
      pages: [
        _buildWelcomePage(),
        _buildAppearancePage(),
        _buildSyncPage(),
        _buildAIPage(),
        _buildCompletePage(),
      ],
      onDone: _onIntroEnd,
      onSkip: _onIntroEnd,
      showSkipButton: false, // We handle skip in globalHeader
      showBackButton: true,
      showNextButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBottomPart: true,
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        activeSize: const Size(22.0, 10.0),
        activeColor: Theme.of(context).colorScheme.primary,
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      next: Icon(
        Icons.arrow_forward,
        color: Theme.of(context).colorScheme.primary,
      ),
      back: Icon(
        Icons.arrow_back,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
      ),
      done: Text(
        L10n.of(context).onboarding_done,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _onIntroEnd,
      child: Text(
        L10n.of(context).onboarding_skip,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  PageViewModel _buildWelcomePage() {
    return PageViewModel(
      title: L10n.of(context).onboarding_welcome_title,
      body: L10n.of(context).onboarding_welcome_body,
      image: _buildImage('assets/images/app_icon.png'),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildAppearancePage() {
    return PageViewModel(
      title: L10n.of(context).onboarding_appearance_title,
      bodyWidget: _buildAppearanceSettings(),
      // image: _buildIconPage(Icons.palette_outlined),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildSyncPage() {
    return PageViewModel(
      title: L10n.of(context).onboarding_sync_title,
      body: L10n.of(context).onboarding_sync_body,
      image: _buildIconPage(Icons.sync_outlined),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildAIPage() {
    return PageViewModel(
      title: L10n.of(context).onboarding_ai_title,
      body: L10n.of(context).onboarding_ai_body,
      image: _buildIconPage(Icons.auto_awesome_outlined),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildCompletePage() {
    return PageViewModel(
      title: L10n.of(context).onboarding_complete_title,
      body: L10n.of(context).onboarding_complete_body,
      image: _buildIconPage(Icons.check_circle_outline),
      decoration: _getPageDecoration(),
    );
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    return Image.asset(
      assetName,
      width: width,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if image asset doesn't exist
        return _buildIconPage(Icons.menu_book_outlined);
      },
    );
  }

  Widget _buildIconPage(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(40),
      child: Icon(
        icon,
        size: 120,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  PageDecoration _getPageDecoration() {
    return PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      bodyTextStyle: TextStyle(
        fontSize: 19.0,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Theme.of(context).scaffoldBackgroundColor,
      imagePadding: const EdgeInsets.symmetric(vertical: 40.0),
    );
  }

  Widget _buildAppearanceSettings() {
    return Consumer<Prefs>(
      builder: (context, prefs, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              L10n.of(context).onboarding_appearance_body,
              style: TextStyle(
                fontSize: 16.0,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
              ),
            ),
            const SizedBox(height: 24),
            
            // Language Selection
            _buildSettingCard(
              icon: Icons.language,
              title: L10n.of(context).settings_appearance_language,
              child: _buildLanguageSelector(),
            ),
            
            const SizedBox(height: 16),
            
            // Theme Mode Selection
            _buildSettingCard(
              icon: Icons.brightness_6,
              title: L10n.of(context).settings_appearance_theme,
              child: const ChangeThemeMode(),
            ),
            
            const SizedBox(height: 16),
            
            // Theme Color Selection
            _buildSettingCard(
              icon: Icons.color_lens,
              title: L10n.of(context).settings_appearance_themeColor,
              child: _buildThemeColorSelector(),
            ),
            
            const SizedBox(height: 16),
            
            // E-ink Mode Toggle
            _buildSettingCard(
              icon: Icons.contrast,
              title: L10n.of(context).e_ink_mode,
              child: Switch(
                value: prefs.eInkMode,
                onChanged: (value) {
                  setState(() {
                    if (value) {
                      prefs.saveThemeModeToPrefs('light');
                    }
                    prefs.eInkMode = value;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'You can configure more display options in Settings → Appearance',
              style: TextStyle(
                fontSize: 14.0,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final currentLocale = Prefs().locale;
    final currentLanguageCode = currentLocale?.languageCode ?? 'system';
    final currentCountryCode = currentLocale?.countryCode ?? '';
    final currentLanguageTag = currentLanguageCode + 
        (currentCountryCode.isNotEmpty ? '-$currentCountryCode' : '');
    
    return DropdownButton<String>(
      isExpanded: true,
      value: languageOptions.any((option) => option.values.first == currentLanguageTag)
          ? currentLanguageTag
          : 'system',
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            Prefs().saveLocaleToPrefs(newValue);
          });
        }
      },
      items: languageOptions.map<DropdownMenuItem<String>>((Map<String, String> option) {
        final displayName = option.keys.first;
        final languageCode = option.values.first;
        return DropdownMenuItem<String>(
          value: languageCode,
          child: Text(displayName),
        );
      }).toList(),
    );
  }

  Widget _buildThemeColorSelector() {
    return GestureDetector(
      onTap: () => _showColorPickerDialog(),
      child: Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Prefs().themeColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(150),
          ),
        ),
        child: Center(
          child: Text(
            'Tap to change',
            style: TextStyle(
              color: Prefs().themeColor.computeLuminance() > 0.5 
                  ? Colors.black 
                  : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showColorPickerDialog() async {
    Color pickedColor = Prefs().themeColor;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(L10n.of(context).settings_appearance_themeColor),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickedColor,
              onColorChanged: (color) {
                pickedColor = color;
              },
              enableAlpha: false,
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(L10n.of(context).common_cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(L10n.of(context).common_ok),
              onPressed: () {
                setState(() {
                  Prefs().saveThemeToPrefs(pickedColor.toARGB32());
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onIntroEnd() async {
    try {
      // Mark first launch as completed
      // await AppVersionManager.markFirstLaunchCompleted();
      AnxLog.info('Onboarding completed, first launch marked');
      
      // Call the completion callback
      widget.onComplete();
    } catch (e) {
      AnxLog.severe('Failed to complete onboarding: $e');
      // Still proceed to complete onboarding even if there's an error
      widget.onComplete();
    }
  }
}