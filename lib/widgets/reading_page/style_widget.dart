import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/more_settings.dart';
import 'package:anx_reader/widgets/reading_page/widget_title.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class StyleWidget extends StatefulWidget {
  final List<ReadTheme> themes;
  final GlobalKey<EpubPlayerState> epubPlayerKey;
  final Function setCurrentPage;

  const StyleWidget({
    super.key,
    required this.themes,
    required this.epubPlayerKey,
    required this.setCurrentPage,
  });

  @override
  _StyleWidgetState createState() => _StyleWidgetState();
}

class _StyleWidgetState extends State<StyleWidget> {
  BookStyle bookStyle = Prefs().bookStyle;
  int? currentThemeId = Prefs().readTheme.id;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widgetTitle(L10n.of(context).reading_page_style, ReadingSettings.theme),
        sliders(),
        const Divider(),
        themeSelector(),
      ],
    );
  }

  Padding sliders() {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Column(
        children: [
          fontSizeSlider(),
          sideMarginSlider(),
          topBottomMarginSlider(),
          lineHeightAndParagraphSpacingSlider(),
          letterSpacingSlider(),
        ],
      ),
    );
  }

  Row letterSpacingSlider() {
    return Row(
      children: [
        const Icon(Icons.compare_arrows),
        Expanded(
          child: Slider(
            value: bookStyle.letterSpacing,
            onChanged: (double value) {
              setState(() {
                bookStyle.letterSpacing = value;
                widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: -3,
            max: 7,
            divisions: 10,
            label: (bookStyle.letterSpacing).toString(),
          ),
        ),
      ],
    );
  }

  Row lineHeightAndParagraphSpacingSlider() {
    return Row(
      children: [
        const Icon(Icons.line_weight),
        Expanded(
          child: Slider(
              value: bookStyle.lineHeight,
              onChanged: (double value) {
                setState(() {
                  bookStyle.lineHeight = value;
                  widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                  Prefs().saveBookStyleToPrefs(bookStyle);
                });
              },
              min: 0,
              max: 3,
              divisions: 10,
              label: (bookStyle.lineHeight / 3 * 10).round().toString()),
        ),
        const Icon(Icons.height),
        Expanded(
          child: Slider(
            value: bookStyle.paragraphSpacing,
            onChanged: (double value) {
              setState(() {
                bookStyle.paragraphSpacing = value;
                widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0,
            max: 5,
            divisions: 10,
            label: (bookStyle.paragraphSpacing / 5 * 10).round().toString(),
          ),
        ),
      ],
    );
  }

  Row topBottomMarginSlider() {
    return Row(
      children: [
        const Icon(Icons.vertical_align_top_outlined),
        Expanded(
          child: Slider(
            value: bookStyle.topMargin,
            onChanged: (double value) {
              setState(() {
                bookStyle.topMargin = value;
                widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0,
            max: 200,
            divisions: 10,
            label: (bookStyle.topMargin / 20).toStringAsFixed(0),
          ),
        ),
        const Icon(Icons.vertical_align_bottom_outlined),
        Expanded(
          child: Slider(
            value: bookStyle.bottomMargin,
            onChanged: (double value) {
              setState(() {
                bookStyle.bottomMargin = value;
                widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0,
            max: 200,
            divisions: 10,
            label: (bookStyle.bottomMargin / 20).toStringAsFixed(0),
          ),
        ),
      ],
    );
  }

  Row sideMarginSlider() {
    return Row(
      children: [
        const Icon(Icons.format_indent_increase),
        Expanded(
          child: Slider(
            value: bookStyle.sideMargin,
            onChanged: (double value) {
              setState(() {
                bookStyle.sideMargin = value;
                widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0,
            max: 20,
            divisions: 20,
            label: bookStyle.sideMargin.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  Row fontSizeSlider() {
    return Row(
      children: [
        const Icon(Icons.format_size),
        Expanded(
          child: Slider(
            value: bookStyle.fontSize,
            onChanged: (double value) {
              setState(() {
                bookStyle.fontSize = value;
                widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0.4,
            max: 3.0,
            divisions: 13,
            label: bookStyle.fontSize.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  SizedBox themeSelector() {
    const size = 50.0;
    const paddingSize = 5.0;
    EdgeInsetsGeometry padding = const EdgeInsets.all(paddingSize);
    return SizedBox(
      height: size + paddingSize * 2,
      child: ListView.builder(
        itemCount: widget.themes.length + 1,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          if (index == widget.themes.length) {
            // add a new theme
            return Padding(
              padding: padding,
              child: Container(
                  padding: padding,
                  width: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.black45,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
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
                    child: Icon(Icons.add,
                        size: size / 2,
                        color: Color(int.parse('0x${'ffcccccc'}'))),
                  )),
            );
          }
          // theme list
          return Padding(
            padding: padding,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Color(
                    int.parse('0x${widget.themes[index].backgroundColor}')),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: index + 1 == currentThemeId
                      ? Theme.of(context).primaryColor
                      : Colors.black45,
                  width: index + 1 == currentThemeId ? 3 : 1,
                ),
              ),
              height: size,
              width: size,
              child: InkWell(
                onTap: () {
                  Prefs().saveReadThemeToPrefs(widget.themes[index]);
                  widget.epubPlayerKey.currentState!
                      .changeTheme(widget.themes[index]);
                  setState(() {
                    currentThemeId = widget.themes[index].id;
                  });
                },
                onLongPress: () {
                  setState(() {
                    widget.setCurrentPage(ThemeChangeWidget(
                      readTheme: widget.themes[index],
                      setCurrentPage: widget.setCurrentPage,
                    ));
                  });
                },
                child: Center(
                  child: Text(
                    "A",
                    style: TextStyle(
                      color: Color(
                          int.parse('0x${widget.themes[index].textColor}')),
                      fontSize: size / 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ThemeChangeWidget extends StatefulWidget {
  const ThemeChangeWidget({
    super.key,
    required this.readTheme,
    required this.setCurrentPage,
  });

  final ReadTheme readTheme;
  final Function setCurrentPage;

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
    return Row(children: [
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
    ]);
  }

  Future<String?> showColorPickerDialog(String currColor) async {
    Color pickedColor = Color(int.parse('0x$currColor'));

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
