import 'package:flutter/material.dart';

enum PageTurningType {
  next,
  prev,
  menu,
}

Widget getPageTurningDiagram(
  BuildContext context,
  List<PageTurningType> types,
  List<int> iconPosition,
  bool selected,
  Function() onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 100,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              selected ? Theme.of(context).colorScheme.primary : Colors.black26,
          width: 1,
        ),
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemBuilder: (context, index) {
          return Container(
            color: types[index] == PageTurningType.next
                ? Colors.red.withAlpha(100)
                : types[index] == PageTurningType.prev
                    ? Colors.blue.withAlpha(100)
                    : types[index] == PageTurningType.menu
                        ? Colors.green.withAlpha(100)
                        : Colors.white,
            child: Center(
              child: iconPosition.contains(index)
                  ? Icon(
                      index == iconPosition[0]
                          ? Icons.arrow_forward
                          : index == iconPosition[1]
                              ? Icons.arrow_back
                              : index == iconPosition[2]
                                  ? Icons.menu
                                  : null,
                      size: 10,
                    )
                  : null,
            ),
          );
        },
        itemCount: 9,
      ),
    ),
  );
}
