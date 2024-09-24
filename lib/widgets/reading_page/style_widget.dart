import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/font_model.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/service/font.dart';
import 'package:anx_reader/utils/font_parser.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/more_settings.dart';
import 'package:anx_reader/widgets/reading_page/widget_title.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum PageTurn {
  noAnimation,
  slide,
  scroll;

  String getLabel(BuildContext context) {
    switch (this) {
      case PageTurn.noAnimation:
        return L10n.of(context).no_animation;
      case PageTurn.slide:
        return L10n.of(context).slide;
      case PageTurn.scroll:
        return L10n.of(context).scroll;
    }
  }
}

class StyleWidget extends StatefulWidget {
  const StyleWidget({
    super.key,
    required this.themes,
    required this.epubPlayerKey,
    required this.setCurrentPage,
  });

  final List<ReadTheme> themes;
  final GlobalKey<EpubPlayerState> epubPlayerKey;
  final Function setCurrentPage;

  @override
  _StyleWidgetState createState() => _StyleWidgetState();
}

class _StyleWidgetState extends State<StyleWidget> {
  BookStyle bookStyle = Prefs().bookStyle;
  int? currentThemeId = Prefs().readTheme.id;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          widgetTitle(
              L10n.of(context).reading_page_style, ReadingSettings.theme),
          sliders(),
          fontAndPageTurn(),
          const Divider(),
          themeSelector(),
        ],
      ),
    );
  }

  List<FontModel> fonts() {
    Directory fontDir = getFontDir();
    List<FontModel> fontList = [
      FontModel(
        label: L10n.of(context).add_new_font,
        name: 'newFont',
        path: '',
      ),
      FontModel(
        label: L10n.of(context).follow_book,
        name: 'book',
        path: '',
      ),
      FontModel(
        label: L10n.of(context).system_font,
        name: 'system',
        path: 'system',
      ),
    ];
    // fontDir.listSync().forEach((element) {
    //   if (element is File) {
    //     fontList.add(FontModel(
    //       label: getFontNameFromFile(element),
    //       name: 'customFont' + ,
    //       path:
    //           'http://localhost:${Server().port}/fonts/${element.path.split('/').last}',
    //     ));
    //   }
    // });
    // name = 'customFont' + index
    for (int i = 0; i < fontDir.listSync().length; i++) {
      File element = fontDir.listSync()[i] as File;
      fontList.add(FontModel(
        label: getFontNameFromFile(element),
        name: 'customFont$i',
        path:
            'http://localhost:${Server().port}/fonts/${element.path.split(Platform.pathSeparator).last}',
      ));
    }

    return fontList;
  }

  Widget fontAndPageTurn() {
    return Row(children: [
      Expanded(
        child: DropdownMenu<PageTurn>(
          label: Text(L10n.of(context).reading_page_page_turning_method),
          initialSelection: Prefs().pageTurnStyle,
          expandedInsets: const EdgeInsets.only(right: 5),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          onSelected: (PageTurn? value) {
            if (value != null) {
              Prefs().pageTurnStyle = value;
              epubPlayerKey.currentState!.changePageTurnStyle(value);
            }
          },
          dropdownMenuEntries: PageTurn.values
              .map((e) => DropdownMenuEntry(
                    value: e,
                    label: e.getLabel(context),
                  ))
              .toList(),
        ),
      ),
      Expanded(
        child: DropdownMenu<FontModel>(
          label: Text(L10n.of(context).font),
          expandedInsets: const EdgeInsets.only(left: 5),
          initialSelection: Prefs().font,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          onSelected: (FontModel? font) async {
            if (font == null) return;
            if (font.name == 'newFont') {
              await importFont();
              setState(() {});
              return;
            }
            epubPlayerKey.currentState!.changeFont(font);
            Prefs().font = font;
          },
          dropdownMenuEntries: fonts()
              .map((font) => DropdownMenuEntry(
                    value: font,
                    label: font.label,
                    leadingIcon:
                        font.name == 'newFont' ? const Icon(Icons.add) : null,
                  ))
              .toList(),
        ),
      ),
    ]);
  }

  Padding sliders() {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Column(
        children: [
          fontSizeSlider(),
          lineHeightAndParagraphSpacingSlider(),
        ],
      ),
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
            min: 0.5,
            max: 2.0,
            divisions: 30,
            label: bookStyle.fontSize.toStringAsFixed(2),
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
