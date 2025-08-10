import 'package:anx_reader/page/settings_page/appearance.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
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
        L10n.of(context).onboardingDone,
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
        L10n.of(context).onboardingSkip,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  PageViewModel _buildWelcomePage() {
    return PageViewModel(
      title: L10n.of(context).onboardingWelcomeTitle,
      body: L10n.of(context).onboardingWelcomeBody,
      image: _buildIconPage(Icons.book_outlined),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildAppearancePage() {
    return PageViewModel(
      title: '',
      bodyWidget: _buildAppearanceSettings(),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildSyncPage() {
    return PageViewModel(
      title: L10n.of(context).onboardingSyncTitle,
      bodyWidget: _buildPageWithTip(
        L10n.of(context).onboardingSyncBody,
        L10n.of(context).onboardingSyncTip,
      ),
      image: _buildIconPage(Icons.sync_outlined),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildAIPage() {
    return PageViewModel(
      title: L10n.of(context).onboardingAiTitle,
      bodyWidget: _buildPageWithTip(
        L10n.of(context).onboardingAiBody,
        L10n.of(context).onboardingAiTip,
      ),
      image: _buildIconPage(Icons.auto_awesome_outlined),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildCompletePage() {
    return PageViewModel(
      title: L10n.of(context).onboardingCompleteTitle,
      body: L10n.of(context).onboardingCompleteBody,
      image: _buildIconPage(Icons.check_circle_outline),
      decoration: _getPageDecoration(),
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
    Widget buildLanguageSelector() {
      final currentLocale = Prefs().locale;
      final currentLanguageCode = currentLocale?.languageCode ?? 'System';
      final currentCountryCode = currentLocale?.countryCode ?? '';
      final currentLanguageTag = currentLanguageCode +
          (currentCountryCode.isNotEmpty ? '-$currentCountryCode' : '');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                L10n.of(context).settingsAppearanceLanguage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(100),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              underline: const SizedBox(),
              value: languageOptions.any(
                      (option) => option.values.first == currentLanguageTag)
                  ? currentLanguageTag
                  : 'system',
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    Prefs().saveLocaleToPrefs(newValue);
                  });
                }
              },
              items: languageOptions
                  .map<DropdownMenuItem<String>>((Map<String, String> option) {
                final displayName = option.keys.first;
                final languageCode = option.values.first;
                return DropdownMenuItem<String>(
                  value: languageCode,
                  child: Text(displayName),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    Widget buildThemeColorSelector() {
      final List<Color> themeColors = [
        Colors.purple,
        Colors.indigo,
        Colors.blue,
        Colors.cyan,
        Colors.teal,
        Colors.green,
        Colors.lime,
        Colors.amber,
        Colors.orange,
        Colors.deepOrange,
        Colors.pink,
        Colors.red,
      ]..reversed.toList();

      final currentThemeColor = Prefs().themeColor;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                L10n.of(context).settingsAppearanceThemeColor,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: themeColors.length,
            itemBuilder: (context, index) {
              final color = themeColors[index];
              final isSelected =
                  color.toARGB32() == currentThemeColor.toARGB32();

              return GestureDetector(
                onTap: () {
                  setState(() {
                    Prefs().saveThemeToPrefs(color.toARGB32());
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                      if (isSelected)
                        BoxShadow(
                          color: color.withAlpha(100),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      );
    }

    return Consumer<Prefs>(
      builder: (context, prefs, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    L10n.of(context).settingsAppearance,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    L10n.of(context).customizeYourExperience,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(150),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              buildLanguageSelector(),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.contrast,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          L10n.of(context).eInkMode,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          L10n.of(context).optimizedForEInkDisplays,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
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
                ],
              ),

              const SizedBox(height: 24),

              buildThemeColorSelector(),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        L10n.of(context).moreDisplayOptionsTip,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(150),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageWithTip(String bodyText, String tipText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          bodyText,
          style: TextStyle(
            fontSize: 19.0,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha(50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(50),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tipText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(150),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onIntroEnd() async {
    widget.onComplete();
  }
}
