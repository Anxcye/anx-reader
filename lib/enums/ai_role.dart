enum AiRole {
  system,
  user,
  assistant,
}

extension AiRoleJson on AiRole {
  static AiRole fromJson(String value) {
    switch (value) {
      case 'system':
        return AiRole.system;
      case 'user':
        return AiRole.user;
      case 'assistant':
        return AiRole.assistant;
      default:
        throw ArgumentError('invalid ai role: $value');
    }
  }

  String toJson() {
    switch (this) {
      case AiRole.system:
        return 'system';
      case AiRole.user:
        return 'user';
      case AiRole.assistant:
        return 'assistant';
    }
  }
}
