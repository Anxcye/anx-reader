import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/widgets/reading_page/more_settings.dart';
import 'package:anx_reader/widgets/reading_page/widget_title.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';


class ThemeWidget extends StatefulWidget {
  final List<ReadTheme> themes;
  final GlobalKey<EpubPlayerState> epubPlayerKey;
  final Function setCurrentPage;

  const ThemeWidget({
    required this.themes,
    required this.epubPlayerKey,
    required this.setCurrentPage,
  });

  @override
  _ThemeWidgetState createState() => _ThemeWidgetState();
}

class _ThemeWidgetState extends State<ThemeWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widgetTitle(context.readingPageTheme, ReadingSettings.theme),
        SizedBox(
          height: 100, // specify the height
          child: ListView.builder(
            itemCount: widget.themes.length + 1,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              if (index == widget.themes.length) {
                return Container(
                    padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
                    height: 90,
                    width: 90,
                    child: GestureDetector(
                      onTap: () async {
                        int currId = await insertTheme(ReadTheme(
                            backgroundColor: 'ff121212',
                            textColor: 'ffcccccc',
                            backgroundImagePath: ''));
                        widget.setCurrentPage(ThemeChangeWidget(
                          readTheme: ReadTheme(
                              id: currId,
                              backgroundColor: 'ff121212',
                              textColor: 'ffcccccc',
                              backgroundImagePath: ''),
                          setCurrentPage: widget.setCurrentPage,
                        ));
                      },
                      child: Container(
                          decoration: BoxDecoration(
                            // color: Color(int.parse('0x${'ff121212'}')),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Colors.black45,
                              width: 1,
                            ),
                          ),
                          child: Icon(Icons.add,
                              size: 50,
                              color: Color(int.parse('0x${'ffcccccc'}')))),
                    ));
              }

              return Container(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
                height: 90,
                width: 90,
                child: GestureDetector(
                  onTap: () {
                    Prefs().saveReadThemeToPrefs(widget.themes[index]);
                    widget.epubPlayerKey.currentState!
                        .changeTheme(widget.themes[index]);
                  },
                  onLongPress: () {
                    setState(() {
                      widget.setCurrentPage(ThemeChangeWidget(
                        readTheme: widget.themes[index],
                        setCurrentPage: widget.setCurrentPage,
                      ));
                    });
                  },
                  child: Container(
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                            '0x${widget.themes[index].backgroundColor}')),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.black45,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "A",
                          style: TextStyle(
                            color: Color(int.parse(
                                '0x${widget.themes[index].textColor}')),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ThemeChangeWidget extends StatefulWidget {
  ThemeChangeWidget({
    super.key,
    required this.readTheme,
    required this.setCurrentPage,
  });

  ReadTheme readTheme;
  Function setCurrentPage;

  @override
  State<ThemeChangeWidget> createState() => _ThemeChangeWidgetState();
}

class _ThemeChangeWidgetState extends State<ThemeChangeWidget> {
  late ReadTheme readTheme;

  @override
  void initState() {
    super.initState();
    readTheme = widget.readTheme;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Row(children: [
      IconButton(
        onPressed: () async {
          String? pickingColor =
              await showColorPickerDialog(readTheme.backgroundColor);
          if (pickingColor != '') {
            setState(() {
              readTheme.backgroundColor = pickingColor!;
            });
            updateTheme(readTheme);
          }
        },
        icon: Icon(Icons.circle,
            size: 80,
            color: Color(int.parse('0x${readTheme.backgroundColor}'))),
      ),
      IconButton(
          onPressed: () async {
            String? pickingColor =
                await showColorPickerDialog(readTheme.textColor);
            if (pickingColor != '') {
              setState(() {
                readTheme.textColor = pickingColor!;
              });
              updateTheme(readTheme);
            }
          },
          icon: Icon(Icons.text_fields,
              size: 60, color: Color(int.parse('0x${readTheme.textColor}')))),
      const Expanded(
        child: SizedBox(),
      ),
      IconButton(
        onPressed: () {
          deleteTheme(readTheme.id!);
          widget.setCurrentPage(const SizedBox(height: 1));
          // setState(() {});
        },
        icon: const Icon(
          Icons.delete,
          size: 40,
        ),
      ),
    ]));
  }

  Future<String?> showColorPickerDialog(String currColor) async {
    Color pickedColor = Color(int.parse('0x' + currColor));

    await showDialog<void>(
      context: navigatorKey.currentState!.overlay!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickedColor,
              onColorChanged: (Color color) {
                pickedColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(pickedColor.value.toRadixString(16));
              },
            ),
          ],
        );
      },
    );

    return pickedColor.value.toRadixString(16);
  }
}
