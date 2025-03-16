import 'package:anx_reader/enums/ai_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_message.g.dart';
part 'ai_message.freezed.dart';

class AiRoleConverter implements JsonConverter<AiRole, String> {
  const AiRoleConverter();

  @override
  AiRole fromJson(String json) => AiRoleJson.fromJson(json);

  @override
  String toJson(AiRole object) => object.toJson();
}

@freezed
abstract class AiMessage with _$AiMessage {
  const factory AiMessage({
    required String content,
    @AiRoleConverter() required AiRole role,
  }) = _AiMessage;

  factory AiMessage.fromJson(Map<String, dynamic> json) =>
      _$AiMessageFromJson(json);
}
