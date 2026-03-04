import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/providers/tts_providers.dart';
import 'package:anx_reader/service/tts/models/tts_voice.dart';
import 'package:anx_reader/service/tts/online_tts.dart';
import 'package:anx_reader/service/tts/system_tts.dart';
import 'package:anx_reader/service/tts/tts_factory.dart';
import 'package:anx_reader/service/tts/tts_handler.dart';
import 'package:anx_reader/service/tts/tts_service.dart' as tts_svc;
import 'package:anx_reader/utils/get_current_language_code.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/widgets/common/anx_button.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:anx_reader/widgets/settings/service_config_form.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NarrateSettings extends ConsumerStatefulWidget {
  const NarrateSettings({super.key});

  @override
  ConsumerState<NarrateSettings> createState() => _NarrateSettingsState();
}

class _NarrateSettingsState extends ConsumerState<NarrateSettings>
    with SingleTickerProviderStateMixin {
  String? selectedVoiceModel;
  Map<String, List<TtsVoice>> groupedVoices = {};
  Set<String> expandedGroups = {};
  final ScrollController _scrollController = ScrollController();
  String? _highlightedModel;
  late AnimationController _highlightAnimationController;
  late Animation<Color?> _highlightAnimation;
  TtsVoice? _currentModelDetails;
  String? _currentModelLanguageGroup;

  final Map<String, GlobalKey> _languageKeys = {};
  final TextEditingController _testTextController = TextEditingController();
  bool _showVoiceList = false;

  final Map<String, bool> _modelLoadingStates = {};
  bool _mainTestLoading = false;

  Future<void> _testSpeak(String text, String? voiceShortName,
      {bool isMainButton = false}) async {
    if (isMainButton) {
      if (_mainTestLoading) return;
      setState(() {
        _mainTestLoading = true;
      });
    } else if (voiceShortName != null) {
      if (_modelLoadingStates[voiceShortName] == true) return;
      setState(() {
        _modelLoadingStates[voiceShortName] = true;
      });
    }

    try {
      final tts = TtsFactory().current;
      await tts.stop();
      if (tts is OnlineTts) {
        if (voiceShortName != null) {
          await tts.speakWithVoice(text, voiceShortName);
        } else {
          await tts.speak(content: text);
        }
      } else if (tts is SystemTts) {
        if (voiceShortName != null) {
          await tts.speakWithVoice(text, voiceShortName);
        } else {
          await tts.speak(content: text);
        }
      }
    } catch (e) {
      AnxLog.severe('TTS Test Speak Error: $e');
      if (mounted) {
        final errorColor = Theme.of(context).colorScheme.error;
        SmartDialog.show(
          useSystem: true,
          animationType: SmartAnimationType.centerFade_otherSlide,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: errorColor),
                const SizedBox(width: 8),
                Text(L10n.of(dialogContext).commonError),
              ],
            ),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => SmartDialog.dismiss(),
                child: Text(L10n.of(dialogContext).commonOk),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isMainButton) {
            _mainTestLoading = false;
          } else if (voiceShortName != null) {
            _modelLoadingStates[voiceShortName] = false;
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _highlightAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final serviceId = Prefs().ttsService;
    selectedVoiceModel =
        tts_svc.getTtsService(serviceId).provider.getSelectedVoice();
    _testTextController.text = "Hello, this is a test.";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _highlightAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
      end: Colors.transparent,
    ).animate(_highlightAnimationController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _highlightedModel = null;
          });
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _highlightAnimationController.dispose();
    _testTextController.dispose();
    super.dispose();
  }

  void _updateCurrentModelDetails(List<TtsVoice> voices) {
    if (selectedVoiceModel != null) {
      for (var voice in voices) {
        if (voice.shortName == selectedVoiceModel) {
          _currentModelDetails = voice;
          break;
        }
      }

      for (var entry in groupedVoices.entries) {
        for (var voice in entry.value) {
          if (voice.shortName == selectedVoiceModel) {
            _currentModelLanguageGroup = entry.key;
            break;
          }
        }
        if (_currentModelLanguageGroup != null) break;
      }
    }
  }

  void _scrollToSelectedModel() {
    if (selectedVoiceModel == null || _currentModelLanguageGroup == null) {
      return;
    }

    if (!expandedGroups.contains(_currentModelLanguageGroup)) {
      setState(() {
        expandedGroups.add(_currentModelLanguageGroup!);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _languageKeys[_currentModelLanguageGroup];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1, // Align near top
        );
      }

      setState(() {
        _highlightedModel = selectedVoiceModel;
      });
      _highlightAnimationController.reset();
      _highlightAnimationController.forward();
    });
  }

  void _groupVoicesByLanguage(List<TtsVoice> voices) {
    groupedVoices.clear();

    for (var voice in voices) {
      String locale = voice.locale; // TtsVoice ensures non-null
      String languageName = _getLanguageNameFromLocale(locale);

      if (!groupedVoices.containsKey(languageName)) {
        groupedVoices[languageName] = [];
      }

      groupedVoices[languageName]!.add(voice);
    }
  }

  String _getLanguageNameFromLocale(String locale) {
    if (locale.isEmpty) return 'Unknown';
    String langCode = locale.split('-')[0].toLowerCase();

    const Map<String, String> languageMap = {
      'ar': 'العربية', // Arabic
      'bg': 'Български', // Bulgarian
      'ca': 'Català', // Catalan
      'cs': 'Čeština', // Czech
      'da': 'Dansk', // Danish
      'de': 'Deutsch', // German
      'el': 'Ελληνικά', // Greek
      'en': 'English', // English
      'es': 'Español', // Spanish
      'et': 'Eesti', // Estonian
      'fi': 'Suomi', // Finnish
      'fr': 'Français', // French
      'gl': 'Galego', // Galician
      'gu': 'ગુજરાતી', // Gujarati
      'he': 'עברית', // Hebrew
      'hi': 'हिन्दी', // Hindi
      'hr': 'Hrvatski', // Croatian
      'hu': 'Magyar', // Hungarian
      'id': 'Bahasa Indonesia', // Indonesian
      'it': 'Italiano', // Italian
      'ja': '日本語', // Japanese
      'ko': '한국어', // Korean
      'lt': 'Lietuvių', // Lithuanian
      'lv': 'Latviešu', // Latvian
      'ms': 'Bahasa Melayu', // Malay
      'mt': 'Malti', // Maltese
      'nb': 'Norsk bokmål', // Norwegian Bokmål
      'nl': 'Nederlands', // Dutch
      'pl': 'Polski', // Polish
      'pt': 'Português', // Portuguese
      'ro': 'Română', // Romanian
      'ru': 'Русский', // Russian
      'sk': 'Slovenčina', // Slovak
      'sl': 'Slovenščina', // Slovenian
      'sv': 'Svenska', // Swedish
      'ta': 'தமிழ்', // Tamil
      'te': 'తెలుగు', // Telugu
      'th': 'ไทย', // Thai
      'tr': 'Türkçe', // Turkish
      'uk': 'Українська', // Ukrainian
      'ur': 'اردو', // Urdu
      'vi': 'Tiếng Việt', // Vietnamese
      'zh': '中文', // Chinese
      'yue': '粵語', // Cantonese
      'wuu': '吳語', // Wu Chinese
    };

    return languageMap[langCode] ?? locale;
  }

  void _toggleGroup(String languageName) {
    setState(() {
      if (expandedGroups.contains(languageName)) {
        expandedGroups.remove(languageName);
      } else {
        expandedGroups.add(languageName);
      }
    });
  }

  void _selectVoiceModel(String shortName) {
    final serviceId = ref.read(ttsServiceProvider);
    final provider = tts_svc.getTtsService(serviceId).provider;
    final hasVoiceField = provider.getConfig().containsKey('voice');
    if (hasVoiceField) {
      ref
          .read(onlineTtsConfigProvider(serviceId).notifier)
          .updateConfig('voice', shortName);
    }
    setState(() {
      selectedVoiceModel = shortName;
      provider.setSelectedVoice(shortName);
    });
  }

  IconData _getGenderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'female':
        return Icons.female;
      case 'male':
        return Icons.male;
      default:
        return Icons.person;
    }
  }

  String _getCurrentModelDisplayName() {
    if (_currentModelDetails == null) {
      return L10n.of(context).settingsNarrateVoiceModelNotSelected;
    }
    return _currentModelDetails!.name;
  }

  String _getCurrentModelLanguageName() {
    if (_currentModelDetails == null) return '';
    return _currentModelDetails!.locale;
  }

  String _getCurrentModelGender() {
    if (_currentModelDetails == null) return '';
    return _currentModelDetails!.gender;
  }

  @override
  Widget build(BuildContext context) {
    final ttsServiceId = ref.watch(ttsServiceProvider);
    final currentProvider = tts_svc.getTtsService(ttsServiceId).provider;

    // Listen to config changes to hide voice list
    ref.listen(onlineTtsConfigProvider(ttsServiceId), (prev, next) {
      if (prev != next) {
        setState(() {
          _showVoiceList = false;
          selectedVoiceModel = currentProvider.getSelectedVoice();
        });
      }
    });

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 50.0), // Add padding for bottom
      children: [
        SettingsSection(
          title: Text(L10n.of(context).settingsNarrateTtsService),
          tiles: [
            SettingsTile.switchTile(
                title: Text(L10n.of(context).allowMixing),
                description: Text(L10n.of(context).enableMixTip),
                initialValue: Prefs().allowMixWithOtherAudio,
                onToggle: (value) {
                  Prefs().allowMixWithOtherAudio = value;
                  setState(() {});
                }),
          ],
        ),
        SettingsSection(
          title: Text(L10n.of(context).ttsType),
          tiles: [
            CustomSettingsTile(child: _buildServiceSelection(ttsServiceId)),
            if (ttsServiceId != 'system')
              CustomSettingsTile(child: _buildConfigSection(ttsServiceId)),
          ],
        ),

        // Voice List Section - Inlined
        SettingsSection(
          title: Text(L10n.of(context).settingsNarrateTtsVoiceModels),
          tiles: [
            CustomSettingsTile(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _showVoiceList
                    ? Column(
                        children: [..._buildVoiceListContent()],
                      )
                    : Center(
                        child: AnxButton(
                          onPressed: () async {
                            setState(() {
                              _showVoiceList = true;
                            });
                            final voices =
                                await ref.refresh(ttsVoicesProvider.future);
                            if (selectedVoiceModel == null &&
                                voices.isNotEmpty) {
                              final currentLocale =
                                  Localizations.localeOf(context);
                              final currentLangCode =
                                  currentLocale.languageCode;

                              // Try to find a voice matching current language
                              TtsVoice? match = voices.firstWhere(
                                (v) => v.locale
                                    .toLowerCase()
                                    .startsWith(currentLangCode.toLowerCase()),
                                orElse: () => voices.firstWhere(
                                  // Fallback to English
                                  (v) =>
                                      v.locale.toLowerCase().startsWith('en'),
                                  // Fallback to first available
                                  orElse: () => voices.first,
                                ),
                              );

                              _selectVoiceModel(match.shortName);
                            }
                          },
                          child: Text(
                              L10n.of(context).settingsNarrateGetVoiceList),
                        ),
                      ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildServiceSelection(String currentServiceId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButtonFormField<String>(
        initialValue: currentServiceId,
        decoration: InputDecoration(
          labelText: L10n.of(context).settingsNarrateTtsService,
          border: OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(
              value: 'system',
              child: Text(L10n.of(context).settingsNarrateSystemTts)),
          DropdownMenuItem(
              value: 'aliyun',
              child: Text(L10n.of(context).settingsNarrateAliyunTts)),
          DropdownMenuItem(
              value: 'azure',
              child: Text(L10n.of(context).settingsNarrateAzureTts)),
          DropdownMenuItem(
              value: 'openai',
              child: Text(L10n.of(context).settingsNarrateOpenAiTts)),
        ],
        onChanged: (value) async {
          if (value != null && value != currentServiceId) {
            await TtsHandler().switchTtsType(value);
            ref.read(ttsServiceProvider.notifier).setService(value);

            // Hide voice list when switching services, require manual fetch
            _showVoiceList = false;

            // Sync selected voice model for the new service
            selectedVoiceModel =
                tts_svc.getTtsService(value).provider.getSelectedVoice();

            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildConfigSection(String serviceId) {
    final service = tts_svc.getTtsService(serviceId);
    if (service == tts_svc.TtsService.system) return const SizedBox.shrink();

    final provider = service.provider;
    final configItems = provider.getConfigItems(context);
    if (configItems.isEmpty) return const SizedBox.shrink();

    final config = ref.watch(onlineTtsConfigProvider(serviceId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: ServiceConfigForm(
        configItems: configItems,
        initialConfig: config,
        onConfigChanged: (newConfig) {
          // Update config for each changed field
          for (var entry in newConfig.entries) {
            ref
                .read(onlineTtsConfigProvider(serviceId).notifier)
                .updateConfig(entry.key, entry.value);
          }
        },
      ),
    );
  }

  List<Widget> _buildVoiceListContent() {
    final voicesAsync = ref.watch(ttsVoicesProvider);

    return voicesAsync.when(
      data: (voices) {
        if (voices.isEmpty) {
          return [
            Center(child: Text(L10n.of(context).settingsNarrateNoVoicesFound))
          ];
        }

        _groupVoicesByLanguage(voices);
        _updateCurrentModelDetails(voices);

        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _testTextController,
              decoration: InputDecoration(
                labelText: L10n.of(context).settingsNarrateTestText,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: AnxButton.icon(
                    type: AnxButtonType.text,
                    isLoading: _mainTestLoading,
                    icon: Icon(Icons.play_arrow),
                    label: Text(L10n.of(context).commonTest),
                    onPressed: () => _testSpeak(
                        _testTextController.text, selectedVoiceModel,
                        isMainButton: true),
                  ),
                ),
              ),
            ),
          ),
          _buildCurrentModelSection(),
          Divider(thickness: 4, color: Theme.of(context).colorScheme.surface),
          ..._buildVoiceModelList(),
        ];
      },
      loading: () => [const Center(child: CircularProgressIndicator())],
      error: (err, stack) => [Center(child: Text('Error: $err'))],
    );
  }

  Widget _buildCurrentModelSection() {
    // Reuse existing UI logic
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FilledContainer(
        child: InkWell(
          onTap: _scrollToSelectedModel,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      L10n.of(context).settingsNarrateVoiceModelCurrentModel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Icon(
                      _getGenderIcon(_getCurrentModelGender()),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      radius: 24,
                      child: Icon(
                        _getGenderIcon(_getCurrentModelGender()),
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCurrentModelDisplayName(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCurrentModelLanguageName(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      L10n.of(context).settingsNarrateVoiceModelClickToView,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVoiceModelList() {
    List<Widget> voiceModelList = [];

    String currentLangCode = getCurrentLanguageCode();
    String currentLangName = _getLanguageNameFromLocale(currentLangCode);

    var sortedEntries = groupedVoices.entries.toList()
      ..sort((a, b) {
        if (a.key == currentLangName) return -1;
        if (b.key == currentLangName) return 1;
        return a.key.compareTo(b.key);
      });

    for (var language in sortedEntries) {
      String languageName = language.key;
      List<TtsVoice> voicesInLanguage = language.value;

      // Assign key for auto-scroll
      final GlobalKey key =
          _languageKeys.putIfAbsent(languageName, () => GlobalKey());

      voiceModelList.add(
        Column(
          children: [
            FilledContainer(
              radius: 5,
              key: key,
              child: ListTile(
                title: Text(
                  languageName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: Icon(
                  expandedGroups.contains(languageName)
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: () => _toggleGroup(languageName),
              ),
            ),
            if (expandedGroups.contains(languageName))
              ...voicesInLanguage.map((voice) {
                String shortName = voice.shortName;
                String friendlyName = voice.name;
                String gender = voice.gender;
                String displayName = friendlyName;

                bool isHighlighted = _highlightedModel == shortName;
                bool isSelected = selectedVoiceModel == shortName;
                String localizationedGender = gender.toLowerCase() == 'female'
                    ? L10n.of(context).settingsNarrateVoiceModelFemale
                    : gender.toLowerCase() == 'male'
                        ? L10n.of(context).settingsNarrateVoiceModelMale
                        : gender;

                final description = voice.description;
                final subtitle = description.isNotEmpty
                    ? '$localizationedGender · ${voice.locale} · $description'
                    : '$localizationedGender · ${voice.locale}';

                return AnimatedBuilder(
                  animation: _highlightAnimation,
                  builder: (context, child) {
                    return Container(
                      color: isHighlighted
                          ? _highlightAnimation.value
                          : Colors.transparent,
                      child: child,
                    );
                  },
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        _getGenderIcon(gender),
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(subtitle),
                    trailing: isSelected
                        ? Icon(Icons.check,
                            color: Theme.of(context).primaryColor)
                        : null,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnxButton.icon(
                            type: AnxButtonType.text,
                            isLoading: _modelLoadingStates[shortName] ?? false,
                            icon: Icon(Icons.play_arrow),
                            label: Text(L10n.of(context).commonTest),
                            onPressed: () =>
                                _testSpeak(_testTextController.text, shortName),
                          ),
                          AnxButton(
                            type: AnxButtonType.outlined,
                            child:
                                Text(L10n.of(context).settingsNarrateUseVoice),
                            onPressed: () {
                              _selectVoiceModel(shortName);
                            },
                          )
                        ],
                      )
                    ],
                  ),
                );
              }),
            if (language != sortedEntries.last)
              Divider(
                height: 1,
                thickness: 4,
                color: Theme.of(context).colorScheme.surface,
              ),
          ],
        ),
      );
    }

    return voiceModelList;
  }
}
