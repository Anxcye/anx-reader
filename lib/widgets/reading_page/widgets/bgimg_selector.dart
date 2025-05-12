import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BgimgSelector extends ConsumerStatefulWidget {
  const BgimgSelector({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BgimgSelectorState();
}

class _BgimgSelectorState extends ConsumerState<BgimgSelector> {

  @override
  Widget build(BuildContext context) {
    return Text('bgimg selector');
  }
}