# Vendored dependency patches

These path packages are wired through `dependency_overrides` in the root `pubspec.yaml`.

## googleai_dart
- Preserve `thoughtSignature` on `FunctionCallPart` during JSON parse/serialize (Gemini thinking models).

## langchain_google
- Cache raw Gemini `Content` (including thought signatures) when tool calls are returned, and replay that content on the next history turn so tool round-trips do not drop signatures (#977).

Remove these overrides once upstream `langchain_google` / `googleai_dart` versions that include the fix are compatible with our langchain forks.
