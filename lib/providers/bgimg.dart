import 'package:anx_reader/enums/bgimg_type.dart';
import 'package:anx_reader/models/bgimg.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bgimg.g.dart';

@Riverpod(keepAlive: true)
class Bgimg extends _$Bgimg {
  @override
  List<BgimgModel> build() {
    return [
      BgimgModel(type: BgimgType.none, path: ''),
    ];
  }

  void add(BgimgModel bgimg) {
    state = [...state, bgimg];
  }

  void remove(BgimgModel bgimg) {
    state = state.where((e) => e != bgimg).toList();
  }
}

