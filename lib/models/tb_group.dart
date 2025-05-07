import 'package:freezed_annotation/freezed_annotation.dart';

part 'tb_group.freezed.dart';
part 'tb_group.g.dart';

@freezed
abstract class TbGroup with _$TbGroup {
  const factory TbGroup({
    required int id,
    required String name,
    int? parentId,
    @Default(0) int isDeleted,
    String? createTime,
    String? updateTime,
  }) = _TbGroup;

  factory TbGroup.fromJson(Map<String, dynamic> json) =>
      _$TbGroupFromJson(json);
}
