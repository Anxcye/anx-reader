import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';

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
        "url": "string",
        "api_key": "string",
        "model": "string",
      },
    },
    {
      "identifier": "claude",
      "title": "Claude",
      "logo": "assets/images/claude.png",
      "config": {
        "url": "string",
        "api_key": "string",
        "model": "string",
      },
    },
    {
      "identifier": "gemini",
      "title": "Gemini",
      "logo": "assets/images/gemini.png",
      "config": {
        "url": "string",
        "api_key": "string",
        "model": "string",
      },
    },
    {
      "identifier": "deepseek",
      "title": "DeepSeek",
      "logo": "assets/images/deepseek.png",
      "config": {
        "url": "string",
        "api_key": "string",
        "model": "string",
      },
    }
  ];

  @override
  Widget build(BuildContext context) {
    return settingsSections(sections: [
      SettingsSection(
        title: Text("services"),
        tiles: [
          CustomSettingsTile(
              child: AnimatedSize(
            duration: const Duration(milliseconds: 400),
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
                                  const Duration(milliseconds: 100),
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
                  !showSettings
                      ? const SizedBox()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                services[currentIndex]["title"],
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            for (var key
                                in services[currentIndex]["config"].keys)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TextField(
                                  controller: TextEditingController(
                                    text: Prefs().getAiConfig(
                                            services[currentIndex]
                                                ['identifier'])[key] ??
                                        services[currentIndex]["config"][key],
                                  ),
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText: key,
                                    hintText: services[currentIndex]["config"]
                                        [key],
                                  ),
                                  onChanged: (value) {
                                    services[currentIndex]["config"][key] =
                                        value;
                                  },
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                    onPressed: () {},
                                    child: const Text("Cancel")),
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
                                    child: const Text("Save")),
                              ],
                            )
                          ],
                        ),
                ],
              ),
            ),
          )),
        ],
      ),
      SettingsSection(
        title: Text("prompt"),
        tiles: [],
      ),
    ]);
  }
}
