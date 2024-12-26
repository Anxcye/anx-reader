import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/service/tts.dart';
import 'package:anx_reader/widgets/reading_page/widget_title.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/more_settings.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class TtsWidget extends StatefulWidget {
  const TtsWidget({super.key, required this.epubPlayerKey});

  final GlobalKey<EpubPlayerState> epubPlayerKey;

  @override
  State<TtsWidget> createState() => _TtsWidgetState();
}

class _TtsWidgetState extends State<TtsWidget> {
  double volume = Tts.volume;
  double pitch = Tts.pitch;
  double rate = Tts.rate;

  @override
  void initState() {
    if (Tts.ttsStateNotifier.value != TtsStateEnum.playing) {
      Tts.init(
          widget.epubPlayerKey.currentState!.initTts,
          widget.epubPlayerKey.currentState!.ttsNext,
          widget.epubPlayerKey.currentState!.ttsPrev);
      audioHandler.play();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TtsStateEnum>(
        valueListenable: Tts.ttsStateNotifier,
        builder: (context, ttsState, child) {
          Widget _volume() {
            return Row(
              children: [
                Text(L10n.of(context).tts_volume),
                Expanded(
                  child: Slider(
                      value: Tts.volume,
                      onChanged: (newVolume) {
                        Tts.volume = newVolume;
                      },
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: Tts.volume.toStringAsFixed(1)),
                ),
              ],
            );
          }

          Widget _pitch() {
            return Row(
              children: [
                Text(L10n.of(context).tts_pitch),
                Expanded(
                  child: Slider(
                    value: Tts.pitch,
                    onChanged: (newPitch) {
                      Tts.pitch = newPitch;
                    },
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: Tts.pitch.toStringAsFixed(1),
                  ),
                ),
              ],
            );
          }

          Widget _rate() {
            return Row(
              children: [
                Text(L10n.of(context).tts_rate),
                Expanded(
                  child: Slider(
                    value: Tts.rate,
                    onChanged: (newRate) {
                      Tts.rate = newRate;
                    },
                    min: 0.0,
                    max: 2.0,
                    divisions: 10,
                    label: Tts.rate.toStringAsFixed(1),
                  ),
                ),
              ],
            );
          }

          Widget sliders() {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
              child: Column(
                children: [
                  _volume(),
                  _pitch(),
                  _rate(),
                ],
              ),
            );
          }

          Widget buttons() {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                    onPressed: () async {
                      audioHandler.stop();
                      Tts.speak(
                          content: await epubPlayerKey.currentState!
                              .ttsPrevSection());
                    },
                    icon: const Icon(EvaIcons.arrowhead_left)),
                IconButton(
                    onPressed: () {
                      Tts.prev();
                    },
                    icon: const Icon(EvaIcons.chevron_left)),
                IconButton(
                    onPressed: () async {
                      // Tts.toggle();
                      ttsState == TtsStateEnum.playing
                          ? audioHandler.pause()
                          : audioHandler.play();
                    },
                    icon: ttsState == TtsStateEnum.playing
                        ? const Icon(EvaIcons.pause_circle_outline)
                        : const Icon(EvaIcons.play_circle_outline)),
                IconButton(
                    onPressed: () {
                      audioHandler.stop();
                    },
                    icon: const Icon(EvaIcons.stop_circle_outline)),
                IconButton(
                    onPressed: () {
                      Tts.next();
                    },
                    icon: const Icon(EvaIcons.chevron_right)),
                IconButton(
                    onPressed: () async {
                      Tts.stopStatic();
                      Tts.speak(
                          content: await epubPlayerKey.currentState!
                              .ttsNextSection());
                    },
                    icon: const Icon(EvaIcons.arrowhead_right)),
              ],
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                widgetTitle(
                    L10n.of(context).tts_narrator, ReadingSettings.style),
                buttons(),
                const Divider(),
                sliders(),
              ],
            ),
          );
        });
  }
}
