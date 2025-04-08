import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/tts.dart';
import 'package:anx_reader/service/tts/edge_tts_api.dart';
import 'package:anx_reader/utils/tts_model_list.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NarrateSettings extends ConsumerStatefulWidget {
  const NarrateSettings({super.key});

  @override
  ConsumerState<NarrateSettings> createState() => _NarrateSettingsState();
}

class _NarrateSettingsState extends ConsumerState<NarrateSettings>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> data = ttsModelList;
  String? selectedVoiceModel;
  Map<String, List<Map<String, dynamic>>> groupedVoices = {};
  Set<String> expandedGroups = {};
  final ScrollController _scrollController = ScrollController();
  String? _highlightedModel;
  late AnimationController _highlightAnimationController;
  late Animation<Color?> _highlightAnimation;
  Map<String, dynamic>? _currentModelDetails;
  String? _currentModelLanguageGroup;

  @override
  void initState() {
    super.initState();

    _highlightAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    selectedVoiceModel = Prefs().ttsVoiceModel;

    _groupVoicesByLanguage();
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

    _updateCurrentModelDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _highlightAnimationController.dispose();
    super.dispose();
  }

  void _updateCurrentModelDetails() {
    if (selectedVoiceModel != null) {
      for (var voice in data) {
        if (voice['ShortName'] == selectedVoiceModel) {
          _currentModelDetails = voice;
          break;
        }
      }

      for (var entry in groupedVoices.entries) {
        for (var voice in entry.value) {
          if (voice['ShortName'] == selectedVoiceModel) {
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

    Future.delayed(const Duration(milliseconds: 300), () {
      List<String> languageGroups = groupedVoices.keys.toList();
      int groupIndex = languageGroups.indexOf(_currentModelLanguageGroup!);

      if (groupIndex == -1) return;

      double scrollPosition = 0;

      for (int i = 0; i < groupIndex; i++) {
        String lang = languageGroups[i];
        scrollPosition += 50;

        if (expandedGroups.contains(lang)) {
          scrollPosition += groupedVoices[lang]!.length * 80;
        }
      }

      List<Map<String, dynamic>> voicesInGroup =
          groupedVoices[_currentModelLanguageGroup]!;
      int modelIndex = voicesInGroup
          .indexWhere((voice) => voice['ShortName'] == selectedVoiceModel);

      if (modelIndex != -1) {
        scrollPosition += modelIndex * 80;
      }

      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      setState(() {
        _highlightedModel = selectedVoiceModel;
      });
      _highlightAnimationController.reset();
      _highlightAnimationController.forward();
    });
  }

  void _groupVoicesByLanguage() {
    groupedVoices.clear();

    for (var voice in data) {
      String locale = voice['Locale'] as String;
      String languageName = _getLanguageNameFromLocale(locale);

      if (!groupedVoices.containsKey(languageName)) {
        groupedVoices[languageName] = [];
      }

      groupedVoices[languageName]!.add(voice);
    }
  }

  String _getLanguageNameFromLocale(String locale) {
    Map<String, String> languageMap = {
      'af': 'Afrikaans (Afrikaans)',
      'am': 'አማርኛ (Amharic)',
      'ar': 'العربية (Arabic)',
      'az': 'Azərbaycan (Azerbaijani)',
      'bg': 'Български (Bulgarian)',
      'bs': 'Bosanski (Bosnian)',
      'iu': 'ᐃᓄᒃᑎᑐᑦ (Inuktitut)',
      'zu': 'IsiZulu (Zulu)',
      'bn': 'বাংলা (Bengali)',
      'ca': 'Català (Catalan)',
      'cs': 'Čeština (Czech)',
      'cy': 'Cymraeg (Welsh)',
      'da': 'Dansk (Danish)',
      'de': 'Deutsch (German)',
      'el': 'Ελληνικά (Greek)',
      'en': 'English (English)',
      'es': 'Español (Spanish)',
      'et': 'Eesti (Estonian)',
      'eu': 'Euskara (Basque)',
      'fa': 'فارسی (Persian)',
      'fi': 'Suomi (Finnish)',
      'fil': 'Filipino (Filipino)',
      'fr': 'Français (French)',
      'ga': 'Gaeilge (Irish)',
      'gl': 'Galego (Galician)',
      'gu': 'ગુજરાતી (Gujarati)',
      'he': 'עברית (Hebrew)',
      'hi': 'हिन्दी (Hindi)',
      'hr': 'Hrvatski (Croatian)',
      'hu': 'Magyar (Hungarian)',
      'hy': 'Հայերեն (Armenian)',
      'id': 'Indonesia (Indonesian)',
      'is': 'Íslenska (Icelandic)',
      'it': 'Italiano (Italian)',
      'ja': '日本語 (Japanese)',
      'jv': 'Basa Jawa (Javanese)',
      'ka': 'ქართული (Georgian)',
      'kk': 'Қазақ (Kazakh)',
      'km': 'ខ្មែរ (Khmer)',
      'kn': 'ಕನ್ನಡ (Kannada)',
      'ko': '한국어 (Korean)',
      'lo': 'ລາວ (Lao)',
      'lt': 'Lietuvių (Lithuanian)',
      'lv': 'Latviešu (Latvian)',
      'mk': 'Македонски (Macedonian)',
      'ml': 'മലയാളം (Malayalam)',
      'mn': 'Монгол (Mongolian)',
      'mr': 'मराठी (Marathi)',
      'ms': 'Melayu (Malay)',
      'mt': 'Malti (Maltese)',
      'my': 'မြန်မာ (Burmese)',
      'nb': 'Norsk Bokmål (Norwegian Bokmål)',
      'ne': 'नेपाली (Nepali)',
      'nl': 'Nederlands (Dutch)',
      'nn': 'Nynorsk (Norwegian Nynorsk)',
      'or': 'ଓଡ଼ିଆ (Odia)',
      'pa': 'ਪੰਜਾਬੀ (Punjabi)',
      'pl': 'Polski (Polish)',
      'ps': 'پښتو (Pashto)',
      'pt': 'Português (Portuguese)',
      'ro': 'Română (Romanian)',
      'ru': 'Русский (Russian)',
      'si': 'සිංහල (Sinhala)',
      'sk': 'Slovenčina (Slovak)',
      'sl': 'Slovenščina (Slovenian)',
      'so': 'Soomaali (Somali)',
      'sq': 'Shqip (Albanian)',
      'sr': 'Српски (Serbian)',
      'su': 'Basa Sunda (Sundanese)',
      'sv': 'Svenska (Swedish)',
      'sw': 'Kiswahili (Swahili)',
      'ta': 'தமிழ் (Tamil)',
      'te': 'తెలుగు (Telugu)',
      'th': 'ไทย (Thai)',
      'tr': 'Türkçe (Turkish)',
      'uk': 'Українська (Ukrainian)',
      'ur': 'اردو (Urdu)',
      'uz': "O'zbek (Uzbek)",
      'vi': 'Tiếng Việt (Vietnamese)',
      'yue': '粵語 (Cantonese)',
      'zh': '中文 (Chinese)',
    };

    String langCode = locale.split('-')[0];
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
    setState(() {
      selectedVoiceModel = shortName;
      Prefs().ttsVoiceModel = shortName;
      EdgeTTSApi.voice = shortName;
      _updateCurrentModelDetails();
    });
  }

  IconData _getGenderIcon(String gender) {
    switch (gender) {
      case 'Female':
        return Icons.female;
      case 'Male':
        return Icons.male;
      default:
        return Icons.person;
    }
  }

  String _getCurrentModelDisplayName() {
    if (_currentModelDetails == null) {
      return L10n.of(context).settings_narrate_voice_model_not_selected;
    }

    String shortName = _currentModelDetails!['ShortName'] as String;
    String personName = shortName.split('-').last;
    if (personName.endsWith('Neural')) {
      personName = personName.substring(0, personName.length - 6);
    }

    return personName;
  }

  String _getCurrentModelLanguageName() {
    if (_currentModelDetails == null) return '';

    String locale = _currentModelDetails!['Locale'] as String;
    return _getLanguageNameFromLocale(locale);
  }

  String _getCurrentModelGender() {
    if (_currentModelDetails == null) return '';

    return _currentModelDetails!['Gender'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(title: Text("TTS类型"), tiles: [
          SettingsTile.switchTile(
              title: Text("使用系统TTS"),
              initialValue: Prefs().isSystemTts,
              onToggle: (value) async {
                await getTtsFactory().switchTtsType(value);
                setState(() {});
              }),
        ]),
        Visibility(
          visible: !Prefs().isSystemTts,
          child: Expanded(
            child: _buildVoiceModelSelector(),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceModelSelector() {
    return ListView(
      controller: _scrollController,
      children: [
        _buildCurrentModelSection(),
        const Divider(),
        ..._buildVoiceModelList(),
      ],
    );
  }

  Widget _buildCurrentModelSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
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
                      L10n.of(context)
                          .settings_narrate_voice_model_current_model,
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
                      L10n.of(context)
                          .settings_narrate_voice_model_click_to_view,
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

    for (var language in groupedVoices.entries) {
      String languageName = language.key;
      List<Map<String, dynamic>> voicesInLanguage = language.value;

      voiceModelList.add(
        Column(
          children: [
            Container(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withAlpha(100),
              child: ListTile(
                title: Text(
                  languageName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                String shortName = voice['ShortName'] as String;
                String friendlyName = voice['FriendlyName'] as String;
                String gender = voice['Gender'] as String;

                String displayName = friendlyName.split(' - ').last;
                if (displayName.contains('(')) {
                  displayName = displayName.split('(')[0].trim();
                }

                String personName = shortName.split('-').last;
                if (personName.endsWith('Neural')) {
                  personName = personName.substring(0, personName.length - 6);
                }

                bool isHighlighted = _highlightedModel == shortName;

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
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        _getGenderIcon(gender),
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      personName,
                      style: TextStyle(
                        fontWeight: selectedVoiceModel == shortName
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(gender == 'Male'
                        ? L10n.of(context).settings_narrate_voice_model_male
                        : L10n.of(context).settings_narrate_voice_model_female),
                    trailing: Radio<String>(
                      value: shortName,
                      groupValue: selectedVoiceModel,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) {
                        if (value != null) {
                          _selectVoiceModel(value);
                        }
                      },
                    ),
                    onTap: () => _selectVoiceModel(shortName),
                  ),
                );
              }),
            const Divider(height: 1),
          ],
        ),
      );
    }

    return voiceModelList;
  }
}
