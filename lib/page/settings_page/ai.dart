import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/ai_prompts.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class AISettings extends StatefulWidget {
  const AISettings({super.key});

  @override
  State<AISettings> createState() => _AISettingsState();
}

class _AISettingsState extends State<AISettings> {
  bool showSettings = false;
  int currentIndex = 0;
  List<Map<String, dynamic>> services = [
    {
      "identifier": "openai",
      "title": "OpenAI",
      "logo": "assets/images/openai.png",
      "config": {
        "url": "https://api.openai.com/v1/chat/completions",
        "api_key": "YOUR_API_KEY",
        "model": "gpt-4o-mini",
      },
    },
    {
      "identifier": "claude",
      "title": "Claude",
      "logo": "assets/images/claude.png",
      "config": {
        "url": "https://api.anthropic.com/v1/messages",
        "api_key": "YOUR_API_KEY",
        "model": "claude-3-5-sonnet-20240620",
      },

    },
    {
      "identifier": "gemini",
      "title": "Gemini",
      "logo": "assets/images/gemini.png",
      "config": {
        "api_key": "YOUR_API_KEY",
      },
    },
    {
      "identifier": "deepseek",
      "title": "DeepSeek",
      "logo": "assets/images/deepseek.png",
      "config": {
        "url": "https://api.deepseek.com/v1/chat/completions",
        "api_key": "YOUR_API_KEY",
        "model": "deepseek-v3",
      },
    },
  ];

  @override
  void initState() {
    for (var service in services) {
      for (var key in service["config"].keys) {
        service["config"][key] =
            Prefs().getAiConfig(service["identifier"])[key] ??
                service["config"][key];
      }
    }
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> prompts = [
      {
        "identifier": AiPrompts.test,
        "title": L10n.of(context).settings_ai_prompt_test,
        "variables": ["language_locale"],
      },
      {
        "identifier": AiPrompts.summaryTheChapter,
        "title": L10n.of(context).settings_ai_prompt_summary_the_chapter,
        "variables": ["chapter"],
      },

      {
        "identifier": AiPrompts.summaryTheBook,
        "title": L10n.of(context).settings_ai_prompt_summary_the_book,
        "variables": ["book", "author"],
      },
      {
        "identifier": AiPrompts.summaryThePreviousContent,
        "title":
            L10n.of(context).settings_ai_prompt_summary_the_previous_content,
        "variables": ["previous_content"],
      }
    ];

    Widget aiConfig = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            services[currentIndex]["title"],
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (var key in services[currentIndex]["config"].keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: TextEditingController(
                text: Prefs().getAiConfig(
                        services[currentIndex]['identifier'])[key] ??
                    services[currentIndex]["config"][key],
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: key,
                hintText: services[currentIndex]["config"][key],
              ),
              onChanged: (value) {
                services[currentIndex]["config"][key] = value;
              },
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
                onPressed: () {
                  SmartDialog.show(
                    builder: (context) => AlertDialog(
                        title: Text(L10n.of(context).common_test),
                        content: StreamBuilder(
                            stream: aiGenerateStream(
                              generatePromptTest(),
                              identifier: services[currentIndex]["identifier"],
                              config: services[currentIndex]["config"],
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text(snapshot.error.toString());
                              }

                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return Text(snapshot.data!);
                            })),
                  );
                },
                child: Text(L10n.of(context).common_test)),
            TextButton(
                onPressed: () {
                  Prefs().saveAiConfig(
                    services[currentIndex]["identifier"],
                    services[currentIndex]["config"],
                  );

                  setState(() {
                    showSettings = false;
                  });
                },
                child: Text(L10n.of(context).common_save)),
            TextButton(
                onPressed: () {
                  Prefs().selectedAiService =
                      services[currentIndex]["identifier"];
                  Prefs().saveAiConfig(
                    services[currentIndex]["identifier"],
                    services[currentIndex]["config"],
                  );

                  setState(() {
                    showSettings = false;
                  });
                },
                child: Text(L10n.of(context).common_apply)),
          ],
        )
      ],
    );
    var servicesTile = CustomSettingsTile(
        child: AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        if (showSettings) {
                          showSettings = false;
                          Future.delayed(
                            const Duration(milliseconds: 200),
                            () {
                              setState(() {
                                showSettings = true;
                                currentIndex = index;
                              });
                            },
                          );
                        } else {
                          showSettings = true;
                          currentIndex = index;
                        }

                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Prefs().selectedAiService ==
                                      services[index]["identifier"]
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Image.asset(
                              services[index]["logo"],
                              height: 25,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(services[index]["title"]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            !showSettings ? const SizedBox() : aiConfig,
          ],
        ),
      ),
    ));

    var promptTile = CustomSettingsTile(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          return SettingsTile.navigation(
            title: Text(prompts[index]["title"]),
            onPressed: (context) {
              SmartDialog.show(builder: (context) {
                final controller = TextEditingController(
                  text: Prefs().getAiPrompt(
                    AiPrompts.values[index],
                  ),
                );

                return AlertDialog(
                  title: Text(L10n.of(context).common_edit),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      Row(
                        children: [
                          for (var variable in prompts[index]["variables"])
                            TextButton(
                              onPressed: () {
                                // insert the variables at the cursor
                                if (controller.selection.start == -1 ||
                                    controller.selection.end == -1) {
                                  return;
                                }

                                TextSelection.fromPosition(
                                  TextPosition(
                                    offset: controller.selection.start,
                                  ),
                                );

                                controller.text = controller.text.replaceRange(
                                  controller.selection.start,
                                  controller.selection.end,
                                  '{{$variable}}',
                                );
                              },
                              child: Text(
                                '{{$variable}}',
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Prefs().saveAiPrompt(
                          AiPrompts.values[index],
                          controller.text,
                        );
                      },
                      child: Text(L10n.of(context).common_save),
                    ),
                  ],
                );
              });
            },
          );
        },
      ),
    );
    return settingsSections(sections: [
      SettingsSection(
        title: Text(L10n.of(context).settings_ai_services),
        tiles: [
          servicesTile,
        ],
      ),
      SettingsSection(
        title: Text(L10n.of(context).settings_ai_prompt),
        tiles: [
          promptTile,
        ],
      ),
    ]);
  }
}
