import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/bgimg_type.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/bgimg.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/providers/bgimg.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class BgimgSelector extends ConsumerStatefulWidget {
  const BgimgSelector({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BgimgSelectorState();
}

class _BgimgSelectorState extends ConsumerState<BgimgSelector> {
  Widget buildItemContainer({
    required Widget child,
    required Function() onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 120,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void applyBgimg(BgimgModel bgimgModel) {
    Prefs().bgimg = bgimgModel;
    epubPlayerKey.currentState?.changeStyle(null);
  }

  Widget buildImportBgimgItem() {
    return buildItemContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: Theme.of(context).colorScheme.onSecondary),
          SizedBox(height: 10),
          Text(L10n.of(context).readingPageStyleImportBackgroundImage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
              )),
        ],
      ),
      onTap: () {
        ref.read(bgimgProvider.notifier).importImg();
      },
    );
  }

  Widget buildNoneBgimgItem(BgimgModel bgimgModel) {
    return buildItemContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.not_interested,
              color: Theme.of(context).colorScheme.onSecondary),
          SizedBox(height: 10),
          Text(L10n.of(context).readingPageStyleNoBackgroundImage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
              )),
        ],
      ),
      onTap: () {
        applyBgimg(bgimgModel);
      },
    );
  }

  Widget buildAssetBgimgItem(BgimgModel bgimgModel) {
    return buildItemContainer(
      child: Image.asset(
        bgimgModel.path,
        fit: BoxFit.cover,
        alignment: bgimgModel.alignment.alignment,
      ),
      onTap: () {
        applyBgimg(bgimgModel);
      },
    );
  }

  Widget buildLocalFileBgimgItem(BgimgModel bgimgModel) {
    final path = getBgimgDir().path + Platform.pathSeparator + bgimgModel.path;
    final actionPane = ActionPane(
      motion: const StretchMotion(),
      children: [
        SlidableAction(
          onPressed: (context) {
            ref.read(bgimgProvider.notifier).deleteBgimg(bgimgModel);
          },
          icon: Icons.delete,
          label: L10n.of(context).commonDelete,
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      ],
    );
    return Slidable(
      key: ValueKey(bgimgModel.path),
      startActionPane: actionPane,
      endActionPane: actionPane,
      child: buildItemContainer(
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          alignment: bgimgModel.alignment.alignment,
        ),
        onTap: () {
          applyBgimg(bgimgModel);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgimgList = ref.watch(bgimgProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: ListView.builder(
          itemCount: bgimgList.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return buildImportBgimgItem();
            }
            return switch (bgimgList[index - 1].type) {
              BgimgType.none => buildNoneBgimgItem(bgimgList[index - 1]),
              BgimgType.assets => buildAssetBgimgItem(bgimgList[index - 1]),
              BgimgType.localFile =>
                buildLocalFileBgimgItem(bgimgList[index - 1]),
            };
          },
        ),
      ),
    );
  }
}
