import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/utils/time_to_human.dart';
import 'package:anx_reader/widgets/context_menu/excerpt_menu.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:flutter/material.dart';

class BookNoteTile extends StatelessWidget {
  const BookNoteTile({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.trailing,
    this.backgroundColor,
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  final BookNote note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final Widget? trailing;
  final Color? backgroundColor;
  final EdgeInsetsGeometry margin;

  Icon _buildIcon(Color color) {
    try {
      final iconData = notesType
          .firstWhere((element) => element['type'] == note.type)['icon'];
      if (iconData is IconData) {
        return Icon(iconData, color: color);
      }
      if (iconData is Icon) {
        return Icon(iconData.icon, color: color);
      }
    } catch (_) {
      // ignore and fall back to default icon below
    }
    return Icon(Icons.bookmark, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Color(int.tryParse('0xaa${note.color}') ?? 0xaa555555);
    final infoStyle = const TextStyle(
      fontSize: 14,
      color: Colors.grey,
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      behavior: HitTestBehavior.opaque,
      child: FilledContainer(
        color: backgroundColor,
        padding: const EdgeInsets.all(8.0),
        margin: margin,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
              child: _buildIcon(iconColor),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.content,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  if (note.readerNote != null && note.readerNote!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              const VerticalDivider(
                                thickness: 3,
                              ),
                              Expanded(
                                child: Text(
                                  note.readerNote!,
                                  style: infoStyle.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  Divider(
                    indent: 4,
                    height: 3,
                    color: Colors.grey.shade300,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          note.chapter,
                          style: infoStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeToHuman(note.createTime, context),
                        style: infoStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
