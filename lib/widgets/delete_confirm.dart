import 'package:flutter/material.dart';

class DeleteConfirm extends StatefulWidget {
  const DeleteConfirm(
      {super.key,
      required this.delete,
      required this.deleteIcon,
      required this.confirmIcon});

  final Function delete;
  final Widget deleteIcon;
  final Widget confirmIcon;

  @override
  State<DeleteConfirm> createState() => _DeleteConfirmState();
}

class _DeleteConfirmState extends State<DeleteConfirm> {
  bool isDelete = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          if (isDelete) {
            widget.delete();
            setState(() {
              isDelete = false;
            });
          } else {
            setState(() {
              isDelete = true;
            });
          }
        },
        icon: isDelete ? widget.confirmIcon : widget.deleteIcon);
  }
}
