import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/other_settings.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/reading_settings.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/style_settings.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class NarrateSettings extends ConsumerStatefulWidget {
  const NarrateSettings({super.key});

  @override
  ConsumerState<NarrateSettings> createState() => _NarrateSettingsState();
}

class _NarrateSettingsState extends ConsumerState<NarrateSettings> {
  List<Map<String, dynamic>> data = [
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (af-ZA, AdriNeural)",
        "ShortName": "af-ZA-AdriNeural",
        "Gender": "Female",
        "Locale": "af-ZA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Adri Online (Natural) - Afrikaans (South Africa)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (af-ZA, WillemNeural)",
        "ShortName": "af-ZA-WillemNeural",
        "Gender": "Male",
        "Locale": "af-ZA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Willem Online (Natural) - Afrikaans (South Africa)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sq-AL, AnilaNeural)",
        "ShortName": "sq-AL-AnilaNeural",
        "Gender": "Female",
        "Locale": "sq-AL",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Anila Online (Natural) - Albanian (Albania)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sq-AL, IlirNeural)",
        "ShortName": "sq-AL-IlirNeural",
        "Gender": "Male",
        "Locale": "sq-AL",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ilir Online (Natural) - Albanian (Albania)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (am-ET, AmehaNeural)",
        "ShortName": "am-ET-AmehaNeural",
        "Gender": "Male",
        "Locale": "am-ET",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ameha Online (Natural) - Amharic (Ethiopia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (am-ET, MekdesNeural)",
        "ShortName": "am-ET-MekdesNeural",
        "Gender": "Female",
        "Locale": "am-ET",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Mekdes Online (Natural) - Amharic (Ethiopia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-DZ, AminaNeural)",
        "ShortName": "ar-DZ-AminaNeural",
        "Gender": "Female",
        "Locale": "ar-DZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Amina Online (Natural) - Arabic (Algeria)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-DZ, IsmaelNeural)",
        "ShortName": "ar-DZ-IsmaelNeural",
        "Gender": "Male",
        "Locale": "ar-DZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ismael Online (Natural) - Arabic (Algeria)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-BH, AliNeural)",
        "ShortName": "ar-BH-AliNeural",
        "Gender": "Male",
        "Locale": "ar-BH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ali Online (Natural) - Arabic (Bahrain)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-BH, LailaNeural)",
        "ShortName": "ar-BH-LailaNeural",
        "Gender": "Female",
        "Locale": "ar-BH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Laila Online (Natural) - Arabic (Bahrain)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-EG, SalmaNeural)",
        "ShortName": "ar-EG-SalmaNeural",
        "Gender": "Female",
        "Locale": "ar-EG",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Salma Online (Natural) - Arabic (Egypt)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-EG, ShakirNeural)",
        "ShortName": "ar-EG-ShakirNeural",
        "Gender": "Male",
        "Locale": "ar-EG",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Shakir Online (Natural) - Arabic (Egypt)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-IQ, BasselNeural)",
        "ShortName": "ar-IQ-BasselNeural",
        "Gender": "Male",
        "Locale": "ar-IQ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Bassel Online (Natural) - Arabic (Iraq)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-IQ, RanaNeural)",
        "ShortName": "ar-IQ-RanaNeural",
        "Gender": "Female",
        "Locale": "ar-IQ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Rana Online (Natural) - Arabic (Iraq)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-JO, SanaNeural)",
        "ShortName": "ar-JO-SanaNeural",
        "Gender": "Female",
        "Locale": "ar-JO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sana Online (Natural) - Arabic (Jordan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-JO, TaimNeural)",
        "ShortName": "ar-JO-TaimNeural",
        "Gender": "Male",
        "Locale": "ar-JO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Taim Online (Natural) - Arabic (Jordan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-KW, FahedNeural)",
        "ShortName": "ar-KW-FahedNeural",
        "Gender": "Male",
        "Locale": "ar-KW",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Fahed Online (Natural) - Arabic (Kuwait)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-KW, NouraNeural)",
        "ShortName": "ar-KW-NouraNeural",
        "Gender": "Female",
        "Locale": "ar-KW",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Noura Online (Natural) - Arabic (Kuwait)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-LB, LaylaNeural)",
        "ShortName": "ar-LB-LaylaNeural",
        "Gender": "Female",
        "Locale": "ar-LB",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Layla Online (Natural) - Arabic (Lebanon)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-LB, RamiNeural)",
        "ShortName": "ar-LB-RamiNeural",
        "Gender": "Male",
        "Locale": "ar-LB",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Rami Online (Natural) - Arabic (Lebanon)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-LY, ImanNeural)",
        "ShortName": "ar-LY-ImanNeural",
        "Gender": "Female",
        "Locale": "ar-LY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Iman Online (Natural) - Arabic (Libya)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-LY, OmarNeural)",
        "ShortName": "ar-LY-OmarNeural",
        "Gender": "Male",
        "Locale": "ar-LY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Omar Online (Natural) - Arabic (Libya)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-MA, JamalNeural)",
        "ShortName": "ar-MA-JamalNeural",
        "Gender": "Male",
        "Locale": "ar-MA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Jamal Online (Natural) - Arabic (Morocco)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-MA, MounaNeural)",
        "ShortName": "ar-MA-MounaNeural",
        "Gender": "Female",
        "Locale": "ar-MA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Mouna Online (Natural) - Arabic (Morocco)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-OM, AbdullahNeural)",
        "ShortName": "ar-OM-AbdullahNeural",
        "Gender": "Male",
        "Locale": "ar-OM",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Abdullah Online (Natural) - Arabic (Oman)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-OM, AyshaNeural)",
        "ShortName": "ar-OM-AyshaNeural",
        "Gender": "Female",
        "Locale": "ar-OM",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Aysha Online (Natural) - Arabic (Oman)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-QA, AmalNeural)",
        "ShortName": "ar-QA-AmalNeural",
        "Gender": "Female",
        "Locale": "ar-QA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Amal Online (Natural) - Arabic (Qatar)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-QA, MoazNeural)",
        "ShortName": "ar-QA-MoazNeural",
        "Gender": "Male",
        "Locale": "ar-QA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Moaz Online (Natural) - Arabic (Qatar)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-SA, HamedNeural)",
        "ShortName": "ar-SA-HamedNeural",
        "Gender": "Male",
        "Locale": "ar-SA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Hamed Online (Natural) - Arabic (Saudi Arabia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-SA, ZariyahNeural)",
        "ShortName": "ar-SA-ZariyahNeural",
        "Gender": "Female",
        "Locale": "ar-SA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Zariyah Online (Natural) - Arabic (Saudi Arabia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-SY, AmanyNeural)",
        "ShortName": "ar-SY-AmanyNeural",
        "Gender": "Female",
        "Locale": "ar-SY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Amany Online (Natural) - Arabic (Syria)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-SY, LaithNeural)",
        "ShortName": "ar-SY-LaithNeural",
        "Gender": "Male",
        "Locale": "ar-SY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Laith Online (Natural) - Arabic (Syria)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-TN, HediNeural)",
        "ShortName": "ar-TN-HediNeural",
        "Gender": "Male",
        "Locale": "ar-TN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Hedi Online (Natural) - Arabic (Tunisia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-TN, ReemNeural)",
        "ShortName": "ar-TN-ReemNeural",
        "Gender": "Female",
        "Locale": "ar-TN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Reem Online (Natural) - Arabic (Tunisia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-AE, FatimaNeural)",
        "ShortName": "ar-AE-FatimaNeural",
        "Gender": "Female",
        "Locale": "ar-AE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Fatima Online (Natural) - Arabic (United Arab Emirates)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-AE, HamdanNeural)",
        "ShortName": "ar-AE-HamdanNeural",
        "Gender": "Male",
        "Locale": "ar-AE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Hamdan Online (Natural) - Arabic (United Arab Emirates)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-YE, MaryamNeural)",
        "ShortName": "ar-YE-MaryamNeural",
        "Gender": "Female",
        "Locale": "ar-YE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Maryam Online (Natural) - Arabic (Yemen)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ar-YE, SalehNeural)",
        "ShortName": "ar-YE-SalehNeural",
        "Gender": "Male",
        "Locale": "ar-YE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Saleh Online (Natural) - Arabic (Yemen)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (az-AZ, BabekNeural)",
        "ShortName": "az-AZ-BabekNeural",
        "Gender": "Male",
        "Locale": "az-AZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Babek Online (Natural) - Azerbaijani (Azerbaijan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (az-AZ, BanuNeural)",
        "ShortName": "az-AZ-BanuNeural",
        "Gender": "Female",
        "Locale": "az-AZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Banu Online (Natural) - Azerbaijani (Azerbaijan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (bn-BD, NabanitaNeural)",
        "ShortName": "bn-BD-NabanitaNeural",
        "Gender": "Female",
        "Locale": "bn-BD",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Nabanita Online (Natural) - Bangla (Bangladesh)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (bn-BD, PradeepNeural)",
        "ShortName": "bn-BD-PradeepNeural",
        "Gender": "Male",
        "Locale": "bn-BD",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Pradeep Online (Natural) - Bangla (Bangladesh)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (bn-IN, BashkarNeural)",
        "ShortName": "bn-IN-BashkarNeural",
        "Gender": "Male",
        "Locale": "bn-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Bashkar Online (Natural) - Bangla (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (bn-IN, TanishaaNeural)",
        "ShortName": "bn-IN-TanishaaNeural",
        "Gender": "Female",
        "Locale": "bn-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Tanishaa Online (Natural) - Bengali (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (bs-BA, VesnaNeural)",
        "ShortName": "bs-BA-VesnaNeural",
        "Gender": "Female",
        "Locale": "bs-BA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Vesna Online (Natural) - Bosnian (Bosnia and Herzegovina)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (bs-BA, GoranNeural)",
        "ShortName": "bs-BA-GoranNeural",
        "Gender": "Male",
        "Locale": "bs-BA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Goran Online (Natural) - Bosnian (Bosnia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (bg-BG, BorislavNeural)",
        "ShortName": "bg-BG-BorislavNeural",
        "Gender": "Male",
        "Locale": "bg-BG",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Borislav Online (Natural) - Bulgarian (Bulgaria)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (bg-BG, KalinaNeural)",
        "ShortName": "bg-BG-KalinaNeural",
        "Gender": "Female",
        "Locale": "bg-BG",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Kalina Online (Natural) - Bulgarian (Bulgaria)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (my-MM, NilarNeural)",
        "ShortName": "my-MM-NilarNeural",
        "Gender": "Female",
        "Locale": "my-MM",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Nilar Online (Natural) - Burmese (Myanmar)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (my-MM, ThihaNeural)",
        "ShortName": "my-MM-ThihaNeural",
        "Gender": "Male",
        "Locale": "my-MM",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Thiha Online (Natural) - Burmese (Myanmar)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ca-ES, EnricNeural)",
        "ShortName": "ca-ES-EnricNeural",
        "Gender": "Male",
        "Locale": "ca-ES",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Enric Online (Natural) - Catalan",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ca-ES, JoanaNeural)",
        "ShortName": "ca-ES-JoanaNeural",
        "Gender": "Female",
        "Locale": "ca-ES",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Joana Online (Natural) - Catalan",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-HK, HiuGaaiNeural)",
        "ShortName": "zh-HK-HiuGaaiNeural",
        "Gender": "Female",
        "Locale": "zh-HK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft HiuGaai Online (Natural) - Chinese (Cantonese Traditional)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-HK, HiuMaanNeural)",
        "ShortName": "zh-HK-HiuMaanNeural",
        "Gender": "Female",
        "Locale": "zh-HK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft HiuMaan Online (Natural) - Chinese (Hong Kong SAR)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-HK, WanLungNeural)",
        "ShortName": "zh-HK-WanLungNeural",
        "Gender": "Male",
        "Locale": "zh-HK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft WanLung Online (Natural) - Chinese (Hong Kong SAR)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-CN, XiaoxiaoNeural)",
        "ShortName": "zh-CN-XiaoxiaoNeural",
        "Gender": "Female",
        "Locale": "zh-CN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Xiaoxiao Online (Natural) - Chinese (Mainland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "News",
                "Novel"
            ],
            "VoicePersonalities": [
                "Warm"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-CN, XiaoyiNeural)",
        "ShortName": "zh-CN-XiaoyiNeural",
        "Gender": "Female",
        "Locale": "zh-CN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Xiaoyi Online (Natural) - Chinese (Mainland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Cartoon",
                "Novel"
            ],
            "VoicePersonalities": [
                "Lively"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-CN, YunjianNeural)",
        "ShortName": "zh-CN-YunjianNeural",
        "Gender": "Male",
        "Locale": "zh-CN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Yunjian Online (Natural) - Chinese (Mainland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Sports",
                " Novel"
            ],
            "VoicePersonalities": [
                "Passion"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-CN, YunxiNeural)",
        "ShortName": "zh-CN-YunxiNeural",
        "Gender": "Male",
        "Locale": "zh-CN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Yunxi Online (Natural) - Chinese (Mainland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Novel"
            ],
            "VoicePersonalities": [
                "Lively",
                "Sunshine"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-CN, YunxiaNeural)",
        "ShortName": "zh-CN-YunxiaNeural",
        "Gender": "Male",
        "Locale": "zh-CN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Yunxia Online (Natural) - Chinese (Mainland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Cartoon",
                "Novel"
            ],
            "VoicePersonalities": [
                "Cute"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-CN, YunyangNeural)",
        "ShortName": "zh-CN-YunyangNeural",
        "Gender": "Male",
        "Locale": "zh-CN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Yunyang Online (Natural) - Chinese (Mainland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "News"
            ],
            "VoicePersonalities": [
                "Professional",
                "Reliable"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-CN-liaoning, XiaobeiNeural)",
        "ShortName": "zh-CN-liaoning-XiaobeiNeural",
        "Gender": "Female",
        "Locale": "zh-CN-liaoning",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Xiaobei Online (Natural) - Chinese (Northeastern Mandarin)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Dialect"
            ],
            "VoicePersonalities": [
                "Humorous"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-TW, HsiaoChenNeural)",
        "ShortName": "zh-TW-HsiaoChenNeural",
        "Gender": "Female",
        "Locale": "zh-TW",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft HsiaoChen Online (Natural) - Chinese (Taiwan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-TW, YunJheNeural)",
        "ShortName": "zh-TW-YunJheNeural",
        "Gender": "Male",
        "Locale": "zh-TW",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft YunJhe Online (Natural) - Chinese (Taiwan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-TW, HsiaoYuNeural)",
        "ShortName": "zh-TW-HsiaoYuNeural",
        "Gender": "Female",
        "Locale": "zh-TW",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft HsiaoYu Online (Natural) - Chinese (Taiwanese Mandarin)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zh-CN-shaanxi, XiaoniNeural)",
        "ShortName": "zh-CN-shaanxi-XiaoniNeural",
        "Gender": "Female",
        "Locale": "zh-CN-shaanxi",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Xiaoni Online (Natural) - Chinese (Zhongyuan Mandarin Shaanxi)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Dialect"
            ],
            "VoicePersonalities": [
                "Bright"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (hr-HR, GabrijelaNeural)",
        "ShortName": "hr-HR-GabrijelaNeural",
        "Gender": "Female",
        "Locale": "hr-HR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Gabrijela Online (Natural) - Croatian (Croatia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (hr-HR, SreckoNeural)",
        "ShortName": "hr-HR-SreckoNeural",
        "Gender": "Male",
        "Locale": "hr-HR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Srecko Online (Natural) - Croatian (Croatia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (cs-CZ, AntoninNeural)",
        "ShortName": "cs-CZ-AntoninNeural",
        "Gender": "Male",
        "Locale": "cs-CZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Antonin Online (Natural) - Czech (Czech)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (cs-CZ, VlastaNeural)",
        "ShortName": "cs-CZ-VlastaNeural",
        "Gender": "Female",
        "Locale": "cs-CZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Vlasta Online (Natural) - Czech (Czech)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (da-DK, ChristelNeural)",
        "ShortName": "da-DK-ChristelNeural",
        "Gender": "Female",
        "Locale": "da-DK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Christel Online (Natural) - Danish (Denmark)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (da-DK, JeppeNeural)",
        "ShortName": "da-DK-JeppeNeural",
        "Gender": "Male",
        "Locale": "da-DK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Jeppe Online (Natural) - Danish (Denmark)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (nl-BE, ArnaudNeural)",
        "ShortName": "nl-BE-ArnaudNeural",
        "Gender": "Male",
        "Locale": "nl-BE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Arnaud Online (Natural) - Dutch (Belgium)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (nl-BE, DenaNeural)",
        "ShortName": "nl-BE-DenaNeural",
        "Gender": "Female",
        "Locale": "nl-BE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Dena Online (Natural) - Dutch (Belgium)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (nl-NL, ColetteNeural)",
        "ShortName": "nl-NL-ColetteNeural",
        "Gender": "Female",
        "Locale": "nl-NL",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Colette Online (Natural) - Dutch (Netherlands)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (nl-NL, FennaNeural)",
        "ShortName": "nl-NL-FennaNeural",
        "Gender": "Female",
        "Locale": "nl-NL",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Fenna Online (Natural) - Dutch (Netherlands)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (nl-NL, MaartenNeural)",
        "ShortName": "nl-NL-MaartenNeural",
        "Gender": "Male",
        "Locale": "nl-NL",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Maarten Online (Natural) - Dutch (Netherlands)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-AU, NatashaNeural)",
        "ShortName": "en-AU-NatashaNeural",
        "Gender": "Female",
        "Locale": "en-AU",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Natasha Online (Natural) - English (Australia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-AU, WilliamNeural)",
        "ShortName": "en-AU-WilliamNeural",
        "Gender": "Male",
        "Locale": "en-AU",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft William Online (Natural) - English (Australia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-CA, ClaraNeural)",
        "ShortName": "en-CA-ClaraNeural",
        "Gender": "Female",
        "Locale": "en-CA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Clara Online (Natural) - English (Canada)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-CA, LiamNeural)",
        "ShortName": "en-CA-LiamNeural",
        "Gender": "Male",
        "Locale": "en-CA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Liam Online (Natural) - English (Canada)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-HK, YanNeural)",
        "ShortName": "en-HK-YanNeural",
        "Gender": "Female",
        "Locale": "en-HK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Yan Online (Natural) - English (Hong Kong SAR)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-HK, SamNeural)",
        "ShortName": "en-HK-SamNeural",
        "Gender": "Male",
        "Locale": "en-HK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sam Online (Natural) - English (Hongkong)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-IN, NeerjaExpressiveNeural)",
        "ShortName": "en-IN-NeerjaExpressiveNeural",
        "Gender": "Female",
        "Locale": "en-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Neerja Online (Natural) - English (India) (Preview)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-IN, NeerjaNeural)",
        "ShortName": "en-IN-NeerjaNeural",
        "Gender": "Female",
        "Locale": "en-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Neerja Online (Natural) - English (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-IN, PrabhatNeural)",
        "ShortName": "en-IN-PrabhatNeural",
        "Gender": "Male",
        "Locale": "en-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Prabhat Online (Natural) - English (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-IE, ConnorNeural)",
        "ShortName": "en-IE-ConnorNeural",
        "Gender": "Male",
        "Locale": "en-IE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Connor Online (Natural) - English (Ireland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-IE, EmilyNeural)",
        "ShortName": "en-IE-EmilyNeural",
        "Gender": "Female",
        "Locale": "en-IE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Emily Online (Natural) - English (Ireland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-KE, AsiliaNeural)",
        "ShortName": "en-KE-AsiliaNeural",
        "Gender": "Female",
        "Locale": "en-KE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Asilia Online (Natural) - English (Kenya)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-KE, ChilembaNeural)",
        "ShortName": "en-KE-ChilembaNeural",
        "Gender": "Male",
        "Locale": "en-KE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Chilemba Online (Natural) - English (Kenya)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-NZ, MitchellNeural)",
        "ShortName": "en-NZ-MitchellNeural",
        "Gender": "Male",
        "Locale": "en-NZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Mitchell Online (Natural) - English (New Zealand)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-NZ, MollyNeural)",
        "ShortName": "en-NZ-MollyNeural",
        "Gender": "Female",
        "Locale": "en-NZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Molly Online (Natural) - English (New Zealand)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-NG, AbeoNeural)",
        "ShortName": "en-NG-AbeoNeural",
        "Gender": "Male",
        "Locale": "en-NG",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Abeo Online (Natural) - English (Nigeria)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-NG, EzinneNeural)",
        "ShortName": "en-NG-EzinneNeural",
        "Gender": "Female",
        "Locale": "en-NG",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ezinne Online (Natural) - English (Nigeria)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-PH, JamesNeural)",
        "ShortName": "en-PH-JamesNeural",
        "Gender": "Male",
        "Locale": "en-PH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft James Online (Natural) - English (Philippines)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-PH, RosaNeural)",
        "ShortName": "en-PH-RosaNeural",
        "Gender": "Female",
        "Locale": "en-PH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Rosa Online (Natural) - English (Philippines)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, AvaNeural)",
        "ShortName": "en-US-AvaNeural",
        "Gender": "Female",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ava Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Conversation",
                "Copilot"
            ],
            "VoicePersonalities": [
                "Expressive",
                "Caring",
                "Pleasant",
                "Friendly"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, AndrewNeural)",
        "ShortName": "en-US-AndrewNeural",
        "Gender": "Male",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Andrew Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Conversation",
                "Copilot"
            ],
            "VoicePersonalities": [
                "Warm",
                "Confident",
                "Authentic",
                "Honest"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, EmmaNeural)",
        "ShortName": "en-US-EmmaNeural",
        "Gender": "Female",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Emma Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Conversation",
                "Copilot"
            ],
            "VoicePersonalities": [
                "Cheerful",
                "Clear",
                "Conversational"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, BrianNeural)",
        "ShortName": "en-US-BrianNeural",
        "Gender": "Male",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Brian Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Conversation",
                "Copilot"
            ],
            "VoicePersonalities": [
                "Approachable",
                "Casual",
                "Sincere"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-SG, LunaNeural)",
        "ShortName": "en-SG-LunaNeural",
        "Gender": "Female",
        "Locale": "en-SG",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Luna Online (Natural) - English (Singapore)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-SG, WayneNeural)",
        "ShortName": "en-SG-WayneNeural",
        "Gender": "Male",
        "Locale": "en-SG",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Wayne Online (Natural) - English (Singapore)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-ZA, LeahNeural)",
        "ShortName": "en-ZA-LeahNeural",
        "Gender": "Female",
        "Locale": "en-ZA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Leah Online (Natural) - English (South Africa)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-ZA, LukeNeural)",
        "ShortName": "en-ZA-LukeNeural",
        "Gender": "Male",
        "Locale": "en-ZA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Luke Online (Natural) - English (South Africa)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-TZ, ElimuNeural)",
        "ShortName": "en-TZ-ElimuNeural",
        "Gender": "Male",
        "Locale": "en-TZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Elimu Online (Natural) - English (Tanzania)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-TZ, ImaniNeural)",
        "ShortName": "en-TZ-ImaniNeural",
        "Gender": "Female",
        "Locale": "en-TZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Imani Online (Natural) - English (Tanzania)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-GB, LibbyNeural)",
        "ShortName": "en-GB-LibbyNeural",
        "Gender": "Female",
        "Locale": "en-GB",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Libby Online (Natural) - English (United Kingdom)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-GB, MaisieNeural)",
        "ShortName": "en-GB-MaisieNeural",
        "Gender": "Female",
        "Locale": "en-GB",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Maisie Online (Natural) - English (United Kingdom)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-GB, RyanNeural)",
        "ShortName": "en-GB-RyanNeural",
        "Gender": "Male",
        "Locale": "en-GB",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ryan Online (Natural) - English (United Kingdom)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-GB, SoniaNeural)",
        "ShortName": "en-GB-SoniaNeural",
        "Gender": "Female",
        "Locale": "en-GB",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sonia Online (Natural) - English (United Kingdom)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-GB, ThomasNeural)",
        "ShortName": "en-GB-ThomasNeural",
        "Gender": "Male",
        "Locale": "en-GB",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Thomas Online (Natural) - English (United Kingdom)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, AnaNeural)",
        "ShortName": "en-US-AnaNeural",
        "Gender": "Female",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ana Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Cartoon",
                "Conversation"
            ],
            "VoicePersonalities": [
                "Cute"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, AndrewMultilingualNeural)",
        "ShortName": "en-US-AndrewMultilingualNeural",
        "Gender": "Male",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft AndrewMultilingual Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Conversation",
                "Copilot"
            ],
            "VoicePersonalities": [
                "Warm",
                "Confident",
                "Authentic",
                "Honest"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, AriaNeural)",
        "ShortName": "en-US-AriaNeural",
        "Gender": "Female",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Aria Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "News",
                "Novel"
            ],
            "VoicePersonalities": [
                "Positive",
                "Confident"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, AvaMultilingualNeural)",
        "ShortName": "en-US-AvaMultilingualNeural",
        "Gender": "Female",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft AvaMultilingual Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Conversation",
                "Copilot"
            ],
            "VoicePersonalities": [
                "Expressive",
                "Caring",
                "Pleasant",
                "Friendly"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, BrianMultilingualNeural)",
        "ShortName": "en-US-BrianMultilingualNeural",
        "Gender": "Male",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft BrianMultilingual Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Conversation",
                "Copilot"
            ],
            "VoicePersonalities": [
                "Approachable",
                "Casual",
                "Sincere"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, ChristopherNeural)",
        "ShortName": "en-US-ChristopherNeural",
        "Gender": "Male",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Christopher Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "News",
                "Novel"
            ],
            "VoicePersonalities": [
                "Reliable",
                "Authority"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, EmmaMultilingualNeural)",
        "ShortName": "en-US-EmmaMultilingualNeural",
        "Gender": "Female",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft EmmaMultilingual Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "Conversation",
                "Copilot"
            ],
            "VoicePersonalities": [
                "Cheerful",
                "Clear",
                "Conversational"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, EricNeural)",
        "ShortName": "en-US-EricNeural",
        "Gender": "Male",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Eric Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "News",
                "Novel"
            ],
            "VoicePersonalities": [
                "Rational"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, GuyNeural)",
        "ShortName": "en-US-GuyNeural",
        "Gender": "Male",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Guy Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "News",
                "Novel"
            ],
            "VoicePersonalities": [
                "Passion"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, JennyNeural)",
        "ShortName": "en-US-JennyNeural",
        "Gender": "Female",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Jenny Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Considerate",
                "Comfort"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, MichelleNeural)",
        "ShortName": "en-US-MichelleNeural",
        "Gender": "Female",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Michelle Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "News",
                "Novel"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Pleasant"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, RogerNeural)",
        "ShortName": "en-US-RogerNeural",
        "Gender": "Male",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Roger Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "News",
                "Novel"
            ],
            "VoicePersonalities": [
                "Lively"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (en-US, SteffanNeural)",
        "ShortName": "en-US-SteffanNeural",
        "Gender": "Male",
        "Locale": "en-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Steffan Online (Natural) - English (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "News",
                "Novel"
            ],
            "VoicePersonalities": [
                "Rational"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (et-EE, AnuNeural)",
        "ShortName": "et-EE-AnuNeural",
        "Gender": "Female",
        "Locale": "et-EE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Anu Online (Natural) - Estonian (Estonia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (et-EE, KertNeural)",
        "ShortName": "et-EE-KertNeural",
        "Gender": "Male",
        "Locale": "et-EE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Kert Online (Natural) - Estonian (Estonia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fil-PH, AngeloNeural)",
        "ShortName": "fil-PH-AngeloNeural",
        "Gender": "Male",
        "Locale": "fil-PH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Angelo Online (Natural) - Filipino (Philippines)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fil-PH, BlessicaNeural)",
        "ShortName": "fil-PH-BlessicaNeural",
        "Gender": "Female",
        "Locale": "fil-PH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Blessica Online (Natural) - Filipino (Philippines)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fi-FI, HarriNeural)",
        "ShortName": "fi-FI-HarriNeural",
        "Gender": "Male",
        "Locale": "fi-FI",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Harri Online (Natural) - Finnish (Finland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fi-FI, NooraNeural)",
        "ShortName": "fi-FI-NooraNeural",
        "Gender": "Female",
        "Locale": "fi-FI",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Noora Online (Natural) - Finnish (Finland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-BE, CharlineNeural)",
        "ShortName": "fr-BE-CharlineNeural",
        "Gender": "Female",
        "Locale": "fr-BE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Charline Online (Natural) - French (Belgium)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-BE, GerardNeural)",
        "ShortName": "fr-BE-GerardNeural",
        "Gender": "Male",
        "Locale": "fr-BE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Gerard Online (Natural) - French (Belgium)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-CA, ThierryNeural)",
        "ShortName": "fr-CA-ThierryNeural",
        "Gender": "Male",
        "Locale": "fr-CA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Thierry Online (Natural) - French (Canada)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-CA, AntoineNeural)",
        "ShortName": "fr-CA-AntoineNeural",
        "Gender": "Male",
        "Locale": "fr-CA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Antoine Online (Natural) - French (Canada)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-CA, JeanNeural)",
        "ShortName": "fr-CA-JeanNeural",
        "Gender": "Male",
        "Locale": "fr-CA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Jean Online (Natural) - French (Canada)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-CA, SylvieNeural)",
        "ShortName": "fr-CA-SylvieNeural",
        "Gender": "Female",
        "Locale": "fr-CA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sylvie Online (Natural) - French (Canada)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-FR, VivienneMultilingualNeural)",
        "ShortName": "fr-FR-VivienneMultilingualNeural",
        "Gender": "Female",
        "Locale": "fr-FR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft VivienneMultilingual Online (Natural) - French (France)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-FR, RemyMultilingualNeural)",
        "ShortName": "fr-FR-RemyMultilingualNeural",
        "Gender": "Male",
        "Locale": "fr-FR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft RemyMultilingual Online (Natural) - French (France)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-FR, DeniseNeural)",
        "ShortName": "fr-FR-DeniseNeural",
        "Gender": "Female",
        "Locale": "fr-FR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Denise Online (Natural) - French (France)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-FR, EloiseNeural)",
        "ShortName": "fr-FR-EloiseNeural",
        "Gender": "Female",
        "Locale": "fr-FR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Eloise Online (Natural) - French (France)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-FR, HenriNeural)",
        "ShortName": "fr-FR-HenriNeural",
        "Gender": "Male",
        "Locale": "fr-FR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Henri Online (Natural) - French (France)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-CH, ArianeNeural)",
        "ShortName": "fr-CH-ArianeNeural",
        "Gender": "Female",
        "Locale": "fr-CH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ariane Online (Natural) - French (Switzerland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fr-CH, FabriceNeural)",
        "ShortName": "fr-CH-FabriceNeural",
        "Gender": "Male",
        "Locale": "fr-CH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Fabrice Online (Natural) - French (Switzerland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (gl-ES, RoiNeural)",
        "ShortName": "gl-ES-RoiNeural",
        "Gender": "Male",
        "Locale": "gl-ES",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Roi Online (Natural) - Galician",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (gl-ES, SabelaNeural)",
        "ShortName": "gl-ES-SabelaNeural",
        "Gender": "Female",
        "Locale": "gl-ES",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sabela Online (Natural) - Galician",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ka-GE, EkaNeural)",
        "ShortName": "ka-GE-EkaNeural",
        "Gender": "Female",
        "Locale": "ka-GE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Eka Online (Natural) - Georgian (Georgia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ka-GE, GiorgiNeural)",
        "ShortName": "ka-GE-GiorgiNeural",
        "Gender": "Male",
        "Locale": "ka-GE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Giorgi Online (Natural) - Georgian (Georgia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (de-AT, IngridNeural)",
        "ShortName": "de-AT-IngridNeural",
        "Gender": "Female",
        "Locale": "de-AT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ingrid Online (Natural) - German (Austria)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (de-AT, JonasNeural)",
        "ShortName": "de-AT-JonasNeural",
        "Gender": "Male",
        "Locale": "de-AT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Jonas Online (Natural) - German (Austria)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (de-DE, SeraphinaMultilingualNeural)",
        "ShortName": "de-DE-SeraphinaMultilingualNeural",
        "Gender": "Female",
        "Locale": "de-DE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft SeraphinaMultilingual Online (Natural) - German (Germany)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (de-DE, FlorianMultilingualNeural)",
        "ShortName": "de-DE-FlorianMultilingualNeural",
        "Gender": "Male",
        "Locale": "de-DE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft FlorianMultilingual Online (Natural) - German (Germany)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (de-DE, AmalaNeural)",
        "ShortName": "de-DE-AmalaNeural",
        "Gender": "Female",
        "Locale": "de-DE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Amala Online (Natural) - German (Germany)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (de-DE, ConradNeural)",
        "ShortName": "de-DE-ConradNeural",
        "Gender": "Male",
        "Locale": "de-DE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Conrad Online (Natural) - German (Germany)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (de-DE, KatjaNeural)",
        "ShortName": "de-DE-KatjaNeural",
        "Gender": "Female",
        "Locale": "de-DE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Katja Online (Natural) - German (Germany)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (de-DE, KillianNeural)",
        "ShortName": "de-DE-KillianNeural",
        "Gender": "Male",
        "Locale": "de-DE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Killian Online (Natural) - German (Germany)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (de-CH, JanNeural)",
        "ShortName": "de-CH-JanNeural",
        "Gender": "Male",
        "Locale": "de-CH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Jan Online (Natural) - German (Switzerland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (de-CH, LeniNeural)",
        "ShortName": "de-CH-LeniNeural",
        "Gender": "Female",
        "Locale": "de-CH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Leni Online (Natural) - German (Switzerland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (el-GR, AthinaNeural)",
        "ShortName": "el-GR-AthinaNeural",
        "Gender": "Female",
        "Locale": "el-GR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Athina Online (Natural) - Greek (Greece)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (el-GR, NestorasNeural)",
        "ShortName": "el-GR-NestorasNeural",
        "Gender": "Male",
        "Locale": "el-GR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Nestoras Online (Natural) - Greek (Greece)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (gu-IN, DhwaniNeural)",
        "ShortName": "gu-IN-DhwaniNeural",
        "Gender": "Female",
        "Locale": "gu-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Dhwani Online (Natural) - Gujarati (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (gu-IN, NiranjanNeural)",
        "ShortName": "gu-IN-NiranjanNeural",
        "Gender": "Male",
        "Locale": "gu-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Niranjan Online (Natural) - Gujarati (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (he-IL, AvriNeural)",
        "ShortName": "he-IL-AvriNeural",
        "Gender": "Male",
        "Locale": "he-IL",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Avri Online (Natural) - Hebrew (Israel)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (he-IL, HilaNeural)",
        "ShortName": "he-IL-HilaNeural",
        "Gender": "Female",
        "Locale": "he-IL",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Hila Online (Natural) - Hebrew (Israel)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (hi-IN, MadhurNeural)",
        "ShortName": "hi-IN-MadhurNeural",
        "Gender": "Male",
        "Locale": "hi-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Madhur Online (Natural) - Hindi (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (hi-IN, SwaraNeural)",
        "ShortName": "hi-IN-SwaraNeural",
        "Gender": "Female",
        "Locale": "hi-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Swara Online (Natural) - Hindi (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (hu-HU, NoemiNeural)",
        "ShortName": "hu-HU-NoemiNeural",
        "Gender": "Female",
        "Locale": "hu-HU",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Noemi Online (Natural) - Hungarian (Hungary)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (hu-HU, TamasNeural)",
        "ShortName": "hu-HU-TamasNeural",
        "Gender": "Male",
        "Locale": "hu-HU",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Tamas Online (Natural) - Hungarian (Hungary)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (is-IS, GudrunNeural)",
        "ShortName": "is-IS-GudrunNeural",
        "Gender": "Female",
        "Locale": "is-IS",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Gudrun Online (Natural) - Icelandic (Iceland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (is-IS, GunnarNeural)",
        "ShortName": "is-IS-GunnarNeural",
        "Gender": "Male",
        "Locale": "is-IS",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Gunnar Online (Natural) - Icelandic (Iceland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (id-ID, ArdiNeural)",
        "ShortName": "id-ID-ArdiNeural",
        "Gender": "Male",
        "Locale": "id-ID",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ardi Online (Natural) - Indonesian (Indonesia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (id-ID, GadisNeural)",
        "ShortName": "id-ID-GadisNeural",
        "Gender": "Female",
        "Locale": "id-ID",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Gadis Online (Natural) - Indonesian (Indonesia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (iu-Latn-CA, SiqiniqNeural)",
        "ShortName": "iu-Latn-CA-SiqiniqNeural",
        "Gender": "Female",
        "Locale": "iu-Latn-CA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Siqiniq Online (Natural) - Inuktitut (Latin, Canada)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (iu-Latn-CA, TaqqiqNeural)",
        "ShortName": "iu-Latn-CA-TaqqiqNeural",
        "Gender": "Male",
        "Locale": "iu-Latn-CA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Taqqiq Online (Natural) - Inuktitut (Latin, Canada)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (iu-Cans-CA, SiqiniqNeural)",
        "ShortName": "iu-Cans-CA-SiqiniqNeural",
        "Gender": "Female",
        "Locale": "iu-Cans-CA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Siqiniq Online (Natural) - Inuktitut (Syllabics, Canada)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (iu-Cans-CA, TaqqiqNeural)",
        "ShortName": "iu-Cans-CA-TaqqiqNeural",
        "Gender": "Male",
        "Locale": "iu-Cans-CA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Taqqiq Online (Natural) - Inuktitut (Syllabics, Canada)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ga-IE, ColmNeural)",
        "ShortName": "ga-IE-ColmNeural",
        "Gender": "Male",
        "Locale": "ga-IE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Colm Online (Natural) - Irish (Ireland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ga-IE, OrlaNeural)",
        "ShortName": "ga-IE-OrlaNeural",
        "Gender": "Female",
        "Locale": "ga-IE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Orla Online (Natural) - Irish (Ireland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (it-IT, GiuseppeMultilingualNeural)",
        "ShortName": "it-IT-GiuseppeMultilingualNeural",
        "Gender": "Male",
        "Locale": "it-IT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft GiuseppeMultilingual Online (Natural) - Italian (Italy)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (it-IT, DiegoNeural)",
        "ShortName": "it-IT-DiegoNeural",
        "Gender": "Male",
        "Locale": "it-IT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Diego Online (Natural) - Italian (Italy)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (it-IT, ElsaNeural)",
        "ShortName": "it-IT-ElsaNeural",
        "Gender": "Female",
        "Locale": "it-IT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Elsa Online (Natural) - Italian (Italy)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (it-IT, IsabellaNeural)",
        "ShortName": "it-IT-IsabellaNeural",
        "Gender": "Female",
        "Locale": "it-IT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Isabella Online (Natural) - Italian (Italy)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ja-JP, KeitaNeural)",
        "ShortName": "ja-JP-KeitaNeural",
        "Gender": "Male",
        "Locale": "ja-JP",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Keita Online (Natural) - Japanese (Japan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ja-JP, NanamiNeural)",
        "ShortName": "ja-JP-NanamiNeural",
        "Gender": "Female",
        "Locale": "ja-JP",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Nanami Online (Natural) - Japanese (Japan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (jv-ID, DimasNeural)",
        "ShortName": "jv-ID-DimasNeural",
        "Gender": "Male",
        "Locale": "jv-ID",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Dimas Online (Natural) - Javanese (Indonesia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (jv-ID, SitiNeural)",
        "ShortName": "jv-ID-SitiNeural",
        "Gender": "Female",
        "Locale": "jv-ID",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Siti Online (Natural) - Javanese (Indonesia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (kn-IN, GaganNeural)",
        "ShortName": "kn-IN-GaganNeural",
        "Gender": "Male",
        "Locale": "kn-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Gagan Online (Natural) - Kannada (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (kn-IN, SapnaNeural)",
        "ShortName": "kn-IN-SapnaNeural",
        "Gender": "Female",
        "Locale": "kn-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sapna Online (Natural) - Kannada (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (kk-KZ, AigulNeural)",
        "ShortName": "kk-KZ-AigulNeural",
        "Gender": "Female",
        "Locale": "kk-KZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Aigul Online (Natural) - Kazakh (Kazakhstan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (kk-KZ, DauletNeural)",
        "ShortName": "kk-KZ-DauletNeural",
        "Gender": "Male",
        "Locale": "kk-KZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Daulet Online (Natural) - Kazakh (Kazakhstan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (km-KH, PisethNeural)",
        "ShortName": "km-KH-PisethNeural",
        "Gender": "Male",
        "Locale": "km-KH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Piseth Online (Natural) - Khmer (Cambodia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (km-KH, SreymomNeural)",
        "ShortName": "km-KH-SreymomNeural",
        "Gender": "Female",
        "Locale": "km-KH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sreymom Online (Natural) - Khmer (Cambodia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ko-KR, HyunsuMultilingualNeural)",
        "ShortName": "ko-KR-HyunsuMultilingualNeural",
        "Gender": "Male",
        "Locale": "ko-KR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft HyunsuMultilingual Online (Natural) - Korean (Korea)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ko-KR, InJoonNeural)",
        "ShortName": "ko-KR-InJoonNeural",
        "Gender": "Male",
        "Locale": "ko-KR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft InJoon Online (Natural) - Korean (Korea)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ko-KR, SunHiNeural)",
        "ShortName": "ko-KR-SunHiNeural",
        "Gender": "Female",
        "Locale": "ko-KR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft SunHi Online (Natural) - Korean (Korea)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (lo-LA, ChanthavongNeural)",
        "ShortName": "lo-LA-ChanthavongNeural",
        "Gender": "Male",
        "Locale": "lo-LA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Chanthavong Online (Natural) - Lao (Laos)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (lo-LA, KeomanyNeural)",
        "ShortName": "lo-LA-KeomanyNeural",
        "Gender": "Female",
        "Locale": "lo-LA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Keomany Online (Natural) - Lao (Laos)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (lv-LV, EveritaNeural)",
        "ShortName": "lv-LV-EveritaNeural",
        "Gender": "Female",
        "Locale": "lv-LV",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Everita Online (Natural) - Latvian (Latvia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (lv-LV, NilsNeural)",
        "ShortName": "lv-LV-NilsNeural",
        "Gender": "Male",
        "Locale": "lv-LV",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Nils Online (Natural) - Latvian (Latvia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (lt-LT, LeonasNeural)",
        "ShortName": "lt-LT-LeonasNeural",
        "Gender": "Male",
        "Locale": "lt-LT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Leonas Online (Natural) - Lithuanian (Lithuania)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (lt-LT, OnaNeural)",
        "ShortName": "lt-LT-OnaNeural",
        "Gender": "Female",
        "Locale": "lt-LT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ona Online (Natural) - Lithuanian (Lithuania)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (mk-MK, AleksandarNeural)",
        "ShortName": "mk-MK-AleksandarNeural",
        "Gender": "Male",
        "Locale": "mk-MK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Aleksandar Online (Natural) - Macedonian (North Macedonia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (mk-MK, MarijaNeural)",
        "ShortName": "mk-MK-MarijaNeural",
        "Gender": "Female",
        "Locale": "mk-MK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Marija Online (Natural) - Macedonian (North Macedonia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ms-MY, OsmanNeural)",
        "ShortName": "ms-MY-OsmanNeural",
        "Gender": "Male",
        "Locale": "ms-MY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Osman Online (Natural) - Malay (Malaysia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ms-MY, YasminNeural)",
        "ShortName": "ms-MY-YasminNeural",
        "Gender": "Female",
        "Locale": "ms-MY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Yasmin Online (Natural) - Malay (Malaysia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ml-IN, MidhunNeural)",
        "ShortName": "ml-IN-MidhunNeural",
        "Gender": "Male",
        "Locale": "ml-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Midhun Online (Natural) - Malayalam (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ml-IN, SobhanaNeural)",
        "ShortName": "ml-IN-SobhanaNeural",
        "Gender": "Female",
        "Locale": "ml-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sobhana Online (Natural) - Malayalam (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (mt-MT, GraceNeural)",
        "ShortName": "mt-MT-GraceNeural",
        "Gender": "Female",
        "Locale": "mt-MT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Grace Online (Natural) - Maltese (Malta)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (mt-MT, JosephNeural)",
        "ShortName": "mt-MT-JosephNeural",
        "Gender": "Male",
        "Locale": "mt-MT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Joseph Online (Natural) - Maltese (Malta)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (mr-IN, AarohiNeural)",
        "ShortName": "mr-IN-AarohiNeural",
        "Gender": "Female",
        "Locale": "mr-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Aarohi Online (Natural) - Marathi (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (mr-IN, ManoharNeural)",
        "ShortName": "mr-IN-ManoharNeural",
        "Gender": "Male",
        "Locale": "mr-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Manohar Online (Natural) - Marathi (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (mn-MN, BataaNeural)",
        "ShortName": "mn-MN-BataaNeural",
        "Gender": "Male",
        "Locale": "mn-MN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Bataa Online (Natural) - Mongolian (Mongolia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (mn-MN, YesuiNeural)",
        "ShortName": "mn-MN-YesuiNeural",
        "Gender": "Female",
        "Locale": "mn-MN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Yesui Online (Natural) - Mongolian (Mongolia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ne-NP, HemkalaNeural)",
        "ShortName": "ne-NP-HemkalaNeural",
        "Gender": "Female",
        "Locale": "ne-NP",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Hemkala Online (Natural) - Nepali (Nepal)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ne-NP, SagarNeural)",
        "ShortName": "ne-NP-SagarNeural",
        "Gender": "Male",
        "Locale": "ne-NP",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sagar Online (Natural) - Nepali (Nepal)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (nb-NO, FinnNeural)",
        "ShortName": "nb-NO-FinnNeural",
        "Gender": "Male",
        "Locale": "nb-NO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Finn Online (Natural) - Norwegian (Bokmål Norway)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (nb-NO, PernilleNeural)",
        "ShortName": "nb-NO-PernilleNeural",
        "Gender": "Female",
        "Locale": "nb-NO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Pernille Online (Natural) - Norwegian (Bokmål, Norway)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ps-AF, GulNawazNeural)",
        "ShortName": "ps-AF-GulNawazNeural",
        "Gender": "Male",
        "Locale": "ps-AF",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft GulNawaz Online (Natural) - Pashto (Afghanistan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ps-AF, LatifaNeural)",
        "ShortName": "ps-AF-LatifaNeural",
        "Gender": "Female",
        "Locale": "ps-AF",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Latifa Online (Natural) - Pashto (Afghanistan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fa-IR, DilaraNeural)",
        "ShortName": "fa-IR-DilaraNeural",
        "Gender": "Female",
        "Locale": "fa-IR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Dilara Online (Natural) - Persian (Iran)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (fa-IR, FaridNeural)",
        "ShortName": "fa-IR-FaridNeural",
        "Gender": "Male",
        "Locale": "fa-IR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Farid Online (Natural) - Persian (Iran)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (pl-PL, MarekNeural)",
        "ShortName": "pl-PL-MarekNeural",
        "Gender": "Male",
        "Locale": "pl-PL",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Marek Online (Natural) - Polish (Poland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (pl-PL, ZofiaNeural)",
        "ShortName": "pl-PL-ZofiaNeural",
        "Gender": "Female",
        "Locale": "pl-PL",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Zofia Online (Natural) - Polish (Poland)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (pt-BR, ThalitaMultilingualNeural)",
        "ShortName": "pt-BR-ThalitaMultilingualNeural",
        "Gender": "Female",
        "Locale": "pt-BR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft ThalitaMultilingual Online (Natural) - Portuguese (Brazil)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (pt-BR, AntonioNeural)",
        "ShortName": "pt-BR-AntonioNeural",
        "Gender": "Male",
        "Locale": "pt-BR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Antonio Online (Natural) - Portuguese (Brazil)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (pt-BR, FranciscaNeural)",
        "ShortName": "pt-BR-FranciscaNeural",
        "Gender": "Female",
        "Locale": "pt-BR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Francisca Online (Natural) - Portuguese (Brazil)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (pt-PT, DuarteNeural)",
        "ShortName": "pt-PT-DuarteNeural",
        "Gender": "Male",
        "Locale": "pt-PT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Duarte Online (Natural) - Portuguese (Portugal)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (pt-PT, RaquelNeural)",
        "ShortName": "pt-PT-RaquelNeural",
        "Gender": "Female",
        "Locale": "pt-PT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Raquel Online (Natural) - Portuguese (Portugal)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ro-RO, AlinaNeural)",
        "ShortName": "ro-RO-AlinaNeural",
        "Gender": "Female",
        "Locale": "ro-RO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Alina Online (Natural) - Romanian (Romania)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ro-RO, EmilNeural)",
        "ShortName": "ro-RO-EmilNeural",
        "Gender": "Male",
        "Locale": "ro-RO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Emil Online (Natural) - Romanian (Romania)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ru-RU, DmitryNeural)",
        "ShortName": "ru-RU-DmitryNeural",
        "Gender": "Male",
        "Locale": "ru-RU",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Dmitry Online (Natural) - Russian (Russia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ru-RU, SvetlanaNeural)",
        "ShortName": "ru-RU-SvetlanaNeural",
        "Gender": "Female",
        "Locale": "ru-RU",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Svetlana Online (Natural) - Russian (Russia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sr-RS, NicholasNeural)",
        "ShortName": "sr-RS-NicholasNeural",
        "Gender": "Male",
        "Locale": "sr-RS",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Nicholas Online (Natural) - Serbian (Serbia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sr-RS, SophieNeural)",
        "ShortName": "sr-RS-SophieNeural",
        "Gender": "Female",
        "Locale": "sr-RS",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sophie Online (Natural) - Serbian (Serbia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (si-LK, SameeraNeural)",
        "ShortName": "si-LK-SameeraNeural",
        "Gender": "Male",
        "Locale": "si-LK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sameera Online (Natural) - Sinhala (Sri Lanka)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (si-LK, ThiliniNeural)",
        "ShortName": "si-LK-ThiliniNeural",
        "Gender": "Female",
        "Locale": "si-LK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Thilini Online (Natural) - Sinhala (Sri Lanka)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sk-SK, LukasNeural)",
        "ShortName": "sk-SK-LukasNeural",
        "Gender": "Male",
        "Locale": "sk-SK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Lukas Online (Natural) - Slovak (Slovakia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sk-SK, ViktoriaNeural)",
        "ShortName": "sk-SK-ViktoriaNeural",
        "Gender": "Female",
        "Locale": "sk-SK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Viktoria Online (Natural) - Slovak (Slovakia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sl-SI, PetraNeural)",
        "ShortName": "sl-SI-PetraNeural",
        "Gender": "Female",
        "Locale": "sl-SI",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Petra Online (Natural) - Slovenian (Slovenia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sl-SI, RokNeural)",
        "ShortName": "sl-SI-RokNeural",
        "Gender": "Male",
        "Locale": "sl-SI",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Rok Online (Natural) - Slovenian (Slovenia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (so-SO, MuuseNeural)",
        "ShortName": "so-SO-MuuseNeural",
        "Gender": "Male",
        "Locale": "so-SO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Muuse Online (Natural) - Somali (Somalia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (so-SO, UbaxNeural)",
        "ShortName": "so-SO-UbaxNeural",
        "Gender": "Female",
        "Locale": "so-SO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ubax Online (Natural) - Somali (Somalia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-AR, ElenaNeural)",
        "ShortName": "es-AR-ElenaNeural",
        "Gender": "Female",
        "Locale": "es-AR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Elena Online (Natural) - Spanish (Argentina)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-AR, TomasNeural)",
        "ShortName": "es-AR-TomasNeural",
        "Gender": "Male",
        "Locale": "es-AR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Tomas Online (Natural) - Spanish (Argentina)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-BO, MarceloNeural)",
        "ShortName": "es-BO-MarceloNeural",
        "Gender": "Male",
        "Locale": "es-BO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Marcelo Online (Natural) - Spanish (Bolivia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-BO, SofiaNeural)",
        "ShortName": "es-BO-SofiaNeural",
        "Gender": "Female",
        "Locale": "es-BO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sofia Online (Natural) - Spanish (Bolivia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-CL, CatalinaNeural)",
        "ShortName": "es-CL-CatalinaNeural",
        "Gender": "Female",
        "Locale": "es-CL",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Catalina Online (Natural) - Spanish (Chile)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-CL, LorenzoNeural)",
        "ShortName": "es-CL-LorenzoNeural",
        "Gender": "Male",
        "Locale": "es-CL",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Lorenzo Online (Natural) - Spanish (Chile)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-CO, GonzaloNeural)",
        "ShortName": "es-CO-GonzaloNeural",
        "Gender": "Male",
        "Locale": "es-CO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Gonzalo Online (Natural) - Spanish (Colombia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-CO, SalomeNeural)",
        "ShortName": "es-CO-SalomeNeural",
        "Gender": "Female",
        "Locale": "es-CO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Salome Online (Natural) - Spanish (Colombia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-ES, XimenaNeural)",
        "ShortName": "es-ES-XimenaNeural",
        "Gender": "Female",
        "Locale": "es-ES",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ximena Online (Natural) - Spanish (Colombia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-CR, JuanNeural)",
        "ShortName": "es-CR-JuanNeural",
        "Gender": "Male",
        "Locale": "es-CR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Juan Online (Natural) - Spanish (Costa Rica)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-CR, MariaNeural)",
        "ShortName": "es-CR-MariaNeural",
        "Gender": "Female",
        "Locale": "es-CR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Maria Online (Natural) - Spanish (Costa Rica)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-CU, BelkysNeural)",
        "ShortName": "es-CU-BelkysNeural",
        "Gender": "Female",
        "Locale": "es-CU",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Belkys Online (Natural) - Spanish (Cuba)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-CU, ManuelNeural)",
        "ShortName": "es-CU-ManuelNeural",
        "Gender": "Male",
        "Locale": "es-CU",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Manuel Online (Natural) - Spanish (Cuba)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-DO, EmilioNeural)",
        "ShortName": "es-DO-EmilioNeural",
        "Gender": "Male",
        "Locale": "es-DO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Emilio Online (Natural) - Spanish (Dominican Republic)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-DO, RamonaNeural)",
        "ShortName": "es-DO-RamonaNeural",
        "Gender": "Female",
        "Locale": "es-DO",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ramona Online (Natural) - Spanish (Dominican Republic)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-EC, AndreaNeural)",
        "ShortName": "es-EC-AndreaNeural",
        "Gender": "Female",
        "Locale": "es-EC",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Andrea Online (Natural) - Spanish (Ecuador)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-EC, LuisNeural)",
        "ShortName": "es-EC-LuisNeural",
        "Gender": "Male",
        "Locale": "es-EC",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Luis Online (Natural) - Spanish (Ecuador)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-SV, LorenaNeural)",
        "ShortName": "es-SV-LorenaNeural",
        "Gender": "Female",
        "Locale": "es-SV",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Lorena Online (Natural) - Spanish (El Salvador)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-SV, RodrigoNeural)",
        "ShortName": "es-SV-RodrigoNeural",
        "Gender": "Male",
        "Locale": "es-SV",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Rodrigo Online (Natural) - Spanish (El Salvador)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-GQ, JavierNeural)",
        "ShortName": "es-GQ-JavierNeural",
        "Gender": "Male",
        "Locale": "es-GQ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Javier Online (Natural) - Spanish (Equatorial Guinea)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-GQ, TeresaNeural)",
        "ShortName": "es-GQ-TeresaNeural",
        "Gender": "Female",
        "Locale": "es-GQ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Teresa Online (Natural) - Spanish (Equatorial Guinea)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-GT, AndresNeural)",
        "ShortName": "es-GT-AndresNeural",
        "Gender": "Male",
        "Locale": "es-GT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Andres Online (Natural) - Spanish (Guatemala)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-GT, MartaNeural)",
        "ShortName": "es-GT-MartaNeural",
        "Gender": "Female",
        "Locale": "es-GT",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Marta Online (Natural) - Spanish (Guatemala)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-HN, CarlosNeural)",
        "ShortName": "es-HN-CarlosNeural",
        "Gender": "Male",
        "Locale": "es-HN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Carlos Online (Natural) - Spanish (Honduras)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-HN, KarlaNeural)",
        "ShortName": "es-HN-KarlaNeural",
        "Gender": "Female",
        "Locale": "es-HN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Karla Online (Natural) - Spanish (Honduras)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-MX, DaliaNeural)",
        "ShortName": "es-MX-DaliaNeural",
        "Gender": "Female",
        "Locale": "es-MX",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Dalia Online (Natural) - Spanish (Mexico)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-MX, JorgeNeural)",
        "ShortName": "es-MX-JorgeNeural",
        "Gender": "Male",
        "Locale": "es-MX",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Jorge Online (Natural) - Spanish (Mexico)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-NI, FedericoNeural)",
        "ShortName": "es-NI-FedericoNeural",
        "Gender": "Male",
        "Locale": "es-NI",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Federico Online (Natural) - Spanish (Nicaragua)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-NI, YolandaNeural)",
        "ShortName": "es-NI-YolandaNeural",
        "Gender": "Female",
        "Locale": "es-NI",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Yolanda Online (Natural) - Spanish (Nicaragua)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-PA, MargaritaNeural)",
        "ShortName": "es-PA-MargaritaNeural",
        "Gender": "Female",
        "Locale": "es-PA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Margarita Online (Natural) - Spanish (Panama)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-PA, RobertoNeural)",
        "ShortName": "es-PA-RobertoNeural",
        "Gender": "Male",
        "Locale": "es-PA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Roberto Online (Natural) - Spanish (Panama)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-PY, MarioNeural)",
        "ShortName": "es-PY-MarioNeural",
        "Gender": "Male",
        "Locale": "es-PY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Mario Online (Natural) - Spanish (Paraguay)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-PY, TaniaNeural)",
        "ShortName": "es-PY-TaniaNeural",
        "Gender": "Female",
        "Locale": "es-PY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Tania Online (Natural) - Spanish (Paraguay)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-PE, AlexNeural)",
        "ShortName": "es-PE-AlexNeural",
        "Gender": "Male",
        "Locale": "es-PE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Alex Online (Natural) - Spanish (Peru)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-PE, CamilaNeural)",
        "ShortName": "es-PE-CamilaNeural",
        "Gender": "Female",
        "Locale": "es-PE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Camila Online (Natural) - Spanish (Peru)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-PR, KarinaNeural)",
        "ShortName": "es-PR-KarinaNeural",
        "Gender": "Female",
        "Locale": "es-PR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Karina Online (Natural) - Spanish (Puerto Rico)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-PR, VictorNeural)",
        "ShortName": "es-PR-VictorNeural",
        "Gender": "Male",
        "Locale": "es-PR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Victor Online (Natural) - Spanish (Puerto Rico)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-ES, AlvaroNeural)",
        "ShortName": "es-ES-AlvaroNeural",
        "Gender": "Male",
        "Locale": "es-ES",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Alvaro Online (Natural) - Spanish (Spain)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-ES, ElviraNeural)",
        "ShortName": "es-ES-ElviraNeural",
        "Gender": "Female",
        "Locale": "es-ES",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Elvira Online (Natural) - Spanish (Spain)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-US, AlonsoNeural)",
        "ShortName": "es-US-AlonsoNeural",
        "Gender": "Male",
        "Locale": "es-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Alonso Online (Natural) - Spanish (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-US, PalomaNeural)",
        "ShortName": "es-US-PalomaNeural",
        "Gender": "Female",
        "Locale": "es-US",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Paloma Online (Natural) - Spanish (United States)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-UY, MateoNeural)",
        "ShortName": "es-UY-MateoNeural",
        "Gender": "Male",
        "Locale": "es-UY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Mateo Online (Natural) - Spanish (Uruguay)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-UY, ValentinaNeural)",
        "ShortName": "es-UY-ValentinaNeural",
        "Gender": "Female",
        "Locale": "es-UY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Valentina Online (Natural) - Spanish (Uruguay)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-VE, PaolaNeural)",
        "ShortName": "es-VE-PaolaNeural",
        "Gender": "Female",
        "Locale": "es-VE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Paola Online (Natural) - Spanish (Venezuela)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (es-VE, SebastianNeural)",
        "ShortName": "es-VE-SebastianNeural",
        "Gender": "Male",
        "Locale": "es-VE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sebastian Online (Natural) - Spanish (Venezuela)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (su-ID, JajangNeural)",
        "ShortName": "su-ID-JajangNeural",
        "Gender": "Male",
        "Locale": "su-ID",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Jajang Online (Natural) - Sundanese (Indonesia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (su-ID, TutiNeural)",
        "ShortName": "su-ID-TutiNeural",
        "Gender": "Female",
        "Locale": "su-ID",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Tuti Online (Natural) - Sundanese (Indonesia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sw-KE, RafikiNeural)",
        "ShortName": "sw-KE-RafikiNeural",
        "Gender": "Male",
        "Locale": "sw-KE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Rafiki Online (Natural) - Swahili (Kenya)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sw-KE, ZuriNeural)",
        "ShortName": "sw-KE-ZuriNeural",
        "Gender": "Female",
        "Locale": "sw-KE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Zuri Online (Natural) - Swahili (Kenya)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sw-TZ, DaudiNeural)",
        "ShortName": "sw-TZ-DaudiNeural",
        "Gender": "Male",
        "Locale": "sw-TZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Daudi Online (Natural) - Swahili (Tanzania)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sw-TZ, RehemaNeural)",
        "ShortName": "sw-TZ-RehemaNeural",
        "Gender": "Female",
        "Locale": "sw-TZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Rehema Online (Natural) - Swahili (Tanzania)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sv-SE, MattiasNeural)",
        "ShortName": "sv-SE-MattiasNeural",
        "Gender": "Male",
        "Locale": "sv-SE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Mattias Online (Natural) - Swedish (Sweden)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (sv-SE, SofieNeural)",
        "ShortName": "sv-SE-SofieNeural",
        "Gender": "Female",
        "Locale": "sv-SE",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sofie Online (Natural) - Swedish (Sweden)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ta-IN, PallaviNeural)",
        "ShortName": "ta-IN-PallaviNeural",
        "Gender": "Female",
        "Locale": "ta-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Pallavi Online (Natural) - Tamil (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ta-IN, ValluvarNeural)",
        "ShortName": "ta-IN-ValluvarNeural",
        "Gender": "Male",
        "Locale": "ta-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Valluvar Online (Natural) - Tamil (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ta-MY, KaniNeural)",
        "ShortName": "ta-MY-KaniNeural",
        "Gender": "Female",
        "Locale": "ta-MY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Kani Online (Natural) - Tamil (Malaysia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ta-MY, SuryaNeural)",
        "ShortName": "ta-MY-SuryaNeural",
        "Gender": "Male",
        "Locale": "ta-MY",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Surya Online (Natural) - Tamil (Malaysia)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ta-SG, AnbuNeural)",
        "ShortName": "ta-SG-AnbuNeural",
        "Gender": "Male",
        "Locale": "ta-SG",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Anbu Online (Natural) - Tamil (Singapore)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ta-SG, VenbaNeural)",
        "ShortName": "ta-SG-VenbaNeural",
        "Gender": "Female",
        "Locale": "ta-SG",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Venba Online (Natural) - Tamil (Singapore)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ta-LK, KumarNeural)",
        "ShortName": "ta-LK-KumarNeural",
        "Gender": "Male",
        "Locale": "ta-LK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Kumar Online (Natural) - Tamil (Sri Lanka)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ta-LK, SaranyaNeural)",
        "ShortName": "ta-LK-SaranyaNeural",
        "Gender": "Female",
        "Locale": "ta-LK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Saranya Online (Natural) - Tamil (Sri Lanka)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (te-IN, MohanNeural)",
        "ShortName": "te-IN-MohanNeural",
        "Gender": "Male",
        "Locale": "te-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Mohan Online (Natural) - Telugu (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (te-IN, ShrutiNeural)",
        "ShortName": "te-IN-ShrutiNeural",
        "Gender": "Female",
        "Locale": "te-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Shruti Online (Natural) - Telugu (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (th-TH, NiwatNeural)",
        "ShortName": "th-TH-NiwatNeural",
        "Gender": "Male",
        "Locale": "th-TH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Niwat Online (Natural) - Thai (Thailand)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (th-TH, PremwadeeNeural)",
        "ShortName": "th-TH-PremwadeeNeural",
        "Gender": "Female",
        "Locale": "th-TH",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Premwadee Online (Natural) - Thai (Thailand)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (tr-TR, EmelNeural)",
        "ShortName": "tr-TR-EmelNeural",
        "Gender": "Female",
        "Locale": "tr-TR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Emel Online (Natural) - Turkish (Turkey)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (tr-TR, AhmetNeural)",
        "ShortName": "tr-TR-AhmetNeural",
        "Gender": "Male",
        "Locale": "tr-TR",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ahmet Online (Natural) - Turkish (Türkiye)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (uk-UA, OstapNeural)",
        "ShortName": "uk-UA-OstapNeural",
        "Gender": "Male",
        "Locale": "uk-UA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Ostap Online (Natural) - Ukrainian (Ukraine)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (uk-UA, PolinaNeural)",
        "ShortName": "uk-UA-PolinaNeural",
        "Gender": "Female",
        "Locale": "uk-UA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Polina Online (Natural) - Ukrainian (Ukraine)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ur-IN, GulNeural)",
        "ShortName": "ur-IN-GulNeural",
        "Gender": "Female",
        "Locale": "ur-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Gul Online (Natural) - Urdu (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ur-IN, SalmanNeural)",
        "ShortName": "ur-IN-SalmanNeural",
        "Gender": "Male",
        "Locale": "ur-IN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Salman Online (Natural) - Urdu (India)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ur-PK, AsadNeural)",
        "ShortName": "ur-PK-AsadNeural",
        "Gender": "Male",
        "Locale": "ur-PK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Asad Online (Natural) - Urdu (Pakistan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (ur-PK, UzmaNeural)",
        "ShortName": "ur-PK-UzmaNeural",
        "Gender": "Female",
        "Locale": "ur-PK",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Uzma Online (Natural) - Urdu (Pakistan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (uz-UZ, MadinaNeural)",
        "ShortName": "uz-UZ-MadinaNeural",
        "Gender": "Female",
        "Locale": "uz-UZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Madina Online (Natural) - Uzbek (Uzbekistan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (uz-UZ, SardorNeural)",
        "ShortName": "uz-UZ-SardorNeural",
        "Gender": "Male",
        "Locale": "uz-UZ",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Sardor Online (Natural) - Uzbek (Uzbekistan)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (vi-VN, HoaiMyNeural)",
        "ShortName": "vi-VN-HoaiMyNeural",
        "Gender": "Female",
        "Locale": "vi-VN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft HoaiMy Online (Natural) - Vietnamese (Vietnam)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (vi-VN, NamMinhNeural)",
        "ShortName": "vi-VN-NamMinhNeural",
        "Gender": "Male",
        "Locale": "vi-VN",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft NamMinh Online (Natural) - Vietnamese (Vietnam)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (cy-GB, AledNeural)",
        "ShortName": "cy-GB-AledNeural",
        "Gender": "Male",
        "Locale": "cy-GB",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Aled Online (Natural) - Welsh (United Kingdom)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (cy-GB, NiaNeural)",
        "ShortName": "cy-GB-NiaNeural",
        "Gender": "Female",
        "Locale": "cy-GB",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Nia Online (Natural) - Welsh (United Kingdom)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zu-ZA, ThandoNeural)",
        "ShortName": "zu-ZA-ThandoNeural",
        "Gender": "Female",
        "Locale": "zu-ZA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Thando Online (Natural) - Zulu (South Africa)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    },
    {
        "Name": "Microsoft Server Speech Text to Speech Voice (zu-ZA, ThembaNeural)",
        "ShortName": "zu-ZA-ThembaNeural",
        "Gender": "Male",
        "Locale": "zu-ZA",
        "SuggestedCodec": "audio-24khz-48kbitrate-mono-mp3",
        "FriendlyName": "Microsoft Themba Online (Natural) - Zulu (South Africa)",
        "Status": "GA",
        "VoiceTag": {
            "ContentCategories": [
                "General"
            ],
            "VoicePersonalities": [
                "Friendly",
                "Positive"
            ]
        }
    }
];


  @override
  Widget build(BuildContext context) {
    return settingsSections(sections: [
      SettingsSection(
        title:Text(L10n.of(context).reading_page_reading),
        tiles: [
          CustomSettingsTile(child: ReadingMoreSettings()),
        ]
      ),
      SettingsSection(
        title:Text(L10n.of(context).reading_page_style),
        tiles: [
          CustomSettingsTile(child: StyleSettings()),
        ]
      ),
      SettingsSection(
        title:Text(L10n.of(context).reading_page_other),
        tiles: [
          CustomSettingsTile(child: OtherSettings()),

        ]
      ),
      
    ]);
  }
}
