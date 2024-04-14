
import 'package:flutter/material.dart';

import '../../models/toc_item.dart';

class TocWidget extends StatelessWidget {
  const TocWidget({
    super.key,
    required this.tocItems,
    required this.epubPlayerKey,
    required this.hideAppBarAndBottomBar,
  });

  final List<TocItem> tocItems;
  final epubPlayerKey;
  final hideAppBarAndBottomBar;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 700,
        child: ListView.builder(
          itemCount: tocItems.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(tocItems[index].label),
              onTap: () {
                hideAppBarAndBottomBar(false);
                epubPlayerKey.currentState!.goTo(tocItems[index].href);
              },
            );
          },
        ));
  }
}
