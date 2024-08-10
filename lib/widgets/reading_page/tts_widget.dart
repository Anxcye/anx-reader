import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/tts.dart';
import 'package:anx_reader/widgets/reading_page/widget_title.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/more_settings.dart';
import 'package:flutter/material.dart';

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

  bool isPlaying = Tts.isPlaying;

  @override
  void initState() {
    int x = 66666;
    String getText() {
      print(x);
      return (x++).toString();
    }

    String getPreviousText() {
      print(x);
      return (x--).toString();
    }
    if (!Tts.isInit) {
    Tts.init(getText, getPreviousText);
    Tts.speak();
    }
    super.initState();
  }

  Widget _volume() {
    return Row(
      children: [
        Text(L10n.of(context).tts_volume),
        Expanded(
          child: Slider(
              value: Tts.volume,
              onChanged: (newVolume) {
                setState(() {
                  isPlaying = true;
                  Tts.volume = newVolume;
                });
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
              setState(() {
                isPlaying = true;
                Tts.pitch = newPitch;
              });
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
              setState(() {
                isPlaying = true;
                Tts.rate = newRate;
              });
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
            onPressed: () {
              setState(() {
                isPlaying = true;
                Tts.prev();
              });
            },
            icon: const Icon(Icons.skip_previous)),
        IconButton(
            onPressed: () async {
              Tts.toggle();
              setState(() {
                isPlaying = !isPlaying;
              });
            },
            icon: isPlaying
                ? const Icon(Icons.pause)
                : const Icon(Icons.play_arrow)),
        IconButton(
            onPressed: () {
              setState(() {
                isPlaying = true;
                Tts.next();
              });
            },
            icon: const Icon(Icons.skip_next)),
      ],
    );
  }

  // Widget

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widgetTitle(L10n.of(context).reading_page_style, ReadingSettings.style),
        buttons(),
        const Divider(),
        sliders(),
      ],
    );
  }
}
