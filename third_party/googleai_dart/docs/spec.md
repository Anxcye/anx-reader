# googleai_dart Specification

## Contents

- [Design Goals](#design-goals)
- [Architecture](#architecture)
- [Configuration](#configuration)
- [Serialization](#serialization)
- [Error Handling](#error-handling)
- [Critical Requirements](#critical-requirements)
- [Development Guidelines](#development-guidelines)

---

## Design Goals

### Minimal Dependencies

**Runtime dependencies limited to `http` and `logging` ONLY.**

**Why**: Smaller attack surface, easier audits, fewer supply-chain risks, better long-term maintenance.

### Interceptor-Driven Architecture

**Composable, ordered middleware for cross-cutting concerns (auth, logging, retry, error mapping).**

**Why**: Clean separation of concerns, extensibility, predictable ordering, isolated testing.

### Resource-Based API Organization

**API methods are organized into logical resource groups matching the REST API structure.**

```dart
client.models.generateContent(...)      // Content generation
client.files.upload(...)                // File management
client.corpora.create(...)              // Corpus management
client.corpora.documents(corpus).chunks(doc).list()  // Nested sub-resources
```

**Why**: Improved discoverability, cleaner namespace (avoids flat client with 90+ methods), mirrors official API structure.

### Cancelable Requests

**Support abortable requests via `abortTrigger` parameter.**

**Why**: Improves UX and efficiency, allows canceling long-running or obsolete requests.

### Manual Serialization (No Codegen)

**All models use hand-written `fromJson`/`toJson` methods. No `build_runner`, `json_serializable`, or `freezed`.**

**Why**: Zero codegen overhead, explicit control over wire formats, simpler debugging, easier upgrades.

### Type Safety

**No `dynamic` types except in JSON parsing (`Map<String, dynamic>`). All function signatures, return types, and variables are explicitly typed.**

**Why**: Fail early at compile time, better IDE support, reduced runtime errors.

### Immutability

**All model fields are `final`. Use `const` constructors where possible. Mutations via `copyWith` only.**

**Why**: Thread safety, predictable state, easier debugging.

---

## Architecture

### Resource Organization

All resources extend `ResourceBase` which provides shared infrastructure:
- `config`, `httpClient`, `interceptorChain`, `requestBuilder`

Resources delegate HTTP execution to the interceptor chain for consistent auth, retry, logging, and error handling.

Sub-resources are accessed via methods that return resource instances:
```dart
client.corpora                          // Top-level resource
  .documents(corpus: 'corpora/123')     // Sub-resource accessor
    .chunks(document: 'documents/456')  // Nested sub-resource
      .list()                           // Method on chunks
```

### Interceptor Interface

```dart
abstract interface class Interceptor {
  Future<http.Response> intercept(RequestContext context, InterceptorNext next);
}

typedef InterceptorNext = Future<http.Response> Function(RequestContext context);
```

**Capabilities**:
- **Short-circuiting**: Return early without invoking transport (e.g., cache hit)
- **Chaining**: Call `next(context)` to continue the chain
- **Wrapping**: Mutate request before, transform response after

### Interceptor Ordering

```
Auth → Logging → Error → Transport (wrapped by Retry)
```

- **Auth**: Adds credentials via `AuthProvider.getCredentials()`
- **Logging**: Adds `X-Request-ID` if absent (never overwrites), records timing
- **Error**: Maps HTTP errors to typed exceptions
- **Retry**: Wraps transport (NOT the interceptor chain) with exponential backoff

**Note**: Retry wraps only the transport execution. Auth is applied once before retry attempts, NOT refreshed on each retry. For OAuth token refresh during retries, implement refresh logic in your custom `AuthProvider.getCredentials()`.

### Retry Policy

Retry is attempted for:
- Rate limit errors (429)
- Server errors (5xx)
- Timeouts

**Idempotency check**: Only idempotent methods are retried: `GET`, `HEAD`, `OPTIONS`, `PUT`, `DELETE`. Non-idempotent methods (`POST`, `PATCH`) are NOT retried to avoid duplicate operations.

### Request/Response Pipeline

1. **Build Request**: Merge config (global → endpoint → request), finalize URL/headers/body
2. **Run Interceptors**: Auth → Logging → Error
3. **Transport Execution**: HTTP call with retry wrapper
4. **Deserialize**: Parse JSON to typed DTOs
5. **Return**: Surface result or throw exception

### Streaming Requests

Streaming responses (SSE) cannot pass through the full interceptor chain since `StreamedResponse` is consumed incrementally.

**Pattern**: Auth, logging, and error mapping applied manually before/during streaming.

This is an acceptable tradeoff for real-time streaming while maintaining security.

### Request Cancellation

Requests can be canceled via `abortTrigger` parameter:

```dart
final completer = Completer<void>();
final response = client.models.generateContent(
  ...,
  abortTrigger: completer.future,
);

// Later: cancel the request
completer.complete();
```

Cancellation works at any stage: before request, during request, during response, or during retry delay.

---

## Configuration

### Precedence Rules (Last-Write-Wins)

When multiple levels set the same value, **last write wins**:

**Headers**: Global → Auth → Endpoint → Request (highest)
**Query Params**: Global → Endpoint → Request (highest)
**Base URL**: Global → Endpoint → Request (highest)
**Timeout/Retry**: Global → Endpoint → Request (highest)
**Auth**: Global `AuthProvider` → Request-level headers (highest)

**Exception**: `X-Request-ID` is only added if absent (never overwrites).

### AuthProvider Pattern

```dart
abstract interface class AuthProvider {
  Future<AuthCredentials> getCredentials();
}
```

Called once per request (before interceptor chain), enabling:
- API keys, bearer tokens, or custom flows
- Dynamic credential resolution

**Built-in providers**:
- `ApiKeyProvider(apiKey, placement: queryParam|header)`
- `BearerTokenProvider(token)`
- `NoAuthProvider()`

---

## Serialization

### DTO Conventions

```dart
class ModelName {
  final String? field;

  const ModelName({this.field});

  factory ModelName.fromJson(Map<String, dynamic> json) => ModelName(
    field: json['field'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (field != null) 'field': field,
  };

  ModelName copyWith({Object? field = unsetCopyWithValue}) => ModelName(
    field: field == unsetCopyWithValue ? this.field : field as String?,
  );

  @override
  bool operator ==(Object other) => ...;

  @override
  int get hashCode => ...;
}
```

### Sealed Classes for Polymorphism

Use sealed classes for types with mutually exclusive variants:

```dart
sealed class Part {
  const Part();

  factory Part.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('text')) return TextPart(json['text'] as String);
    if (json.containsKey('inlineData')) return InlineDataPart.fromJson(...);
    // ... all variants
    throw FormatException('Unknown Part type');
  }
}

class TextPart extends Part {
  final String text;
  const TextPart(this.text);
}
```

### copyWith with Sentinel

Use `unsetCopyWithValue` sentinel to distinguish "not provided" from "set to null":

```dart
/// Sentinel value for copyWith to distinguish null from unset.
const Object unsetCopyWithValue = Object();

ModelName copyWith({Object? field = unsetCopyWithValue}) => ModelName(
  field: field == unsetCopyWithValue ? this.field : field as String?,
);
```

### Enum Conventions

```dart
enum HarmCategory { unspecified, hateSpeech, dangerous }

HarmCategory harmCategoryFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'HARM_CATEGORY_HATE_SPEECH' => HarmCategory.hateSpeech,
    'HARM_CATEGORY_DANGEROUS' => HarmCategory.dangerous,
    _ => HarmCategory.unspecified, // Always include fallback
  };
}

String harmCategoryToString(HarmCategory value) {
  return switch (value) {
    HarmCategory.hateSpeech => 'HARM_CATEGORY_HATE_SPEECH',
    HarmCategory.dangerous => 'HARM_CATEGORY_DANGEROUS',
    HarmCategory.unspecified => 'HARM_CATEGORY_UNSPECIFIED',
  };
}
```

### Type Mappings

| OpenAPI | Dart |
|---------|------|
| `string` | `String` |
| `integer` | `int` |
| `number` | `double` (use `(json['x'] as num?)?.toDouble()`) |
| `boolean` | `bool` |
| `array` | `List<T>` |
| `object` | `Map<String, dynamic>` or custom class |

### Nested Objects

```dart
// fromJson
nested: json['nested'] != null
    ? Nested.fromJson(json['nested'] as Map<String, dynamic>)
    : null,

// toJson
if (nested != null) 'nested': nested!.toJson(),
```

### Lists

```dart
// Simple list
items: (json['items'] as List?)?.cast<String>(),

// List of objects
items: (json['items'] as List?)
    ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
    .toList(),
```

---

## Error Handling

### Exception Hierarchy

```dart
sealed class GoogleAIException implements Exception {
  String get message;
  StackTrace? get stackTrace;
  Exception? get cause;  // For exception chaining
}

class ApiException extends GoogleAIException {
  final int code;                      // HTTP status code
  final String message;
  final List<Object> details;          // Server error details
  final RequestMetadata? requestMetadata;
  final ResponseMetadata? responseMetadata;
  final Exception? cause;
}

class RateLimitException extends ApiException {
  final DateTime? retryAfter;          // Server-suggested retry time
}

class TimeoutException extends GoogleAIException {
  final Duration timeout;
  final Duration elapsed;
}

class ValidationException extends GoogleAIException {
  final Map<String, List<String>> fieldErrors;
}

class AbortedException extends GoogleAIException {
  final String correlationId;
  final DateTime timestamp;
  final AbortionStage stage;           // beforeRequest, duringRequest, duringResponse, duringStream
}
```

### Context Classes

```dart
class RequestMetadata {
  final String method;
  final Uri url;
  final Map<String, String> headers;   // Redacted
  final String correlationId;
  final DateTime timestamp;
  final int attemptNumber;
}

class ResponseMetadata {
  final int statusCode;
  final Map<String, String> headers;
  final String bodyExcerpt;            // First 200 chars, redacted
  final Duration latency;
}
```

### Error Transformation

- Map HTTP status → exception type deterministically
- Preserve original cause and stack trace
- Attach attempt counter and correlation ID
- Redact secrets in all logged contexts

---

## Developer Experience Principles

### Reduce Boilerplate

Provide convenience methods that eliminate repetitive code patterns. When the same
code pattern appears in multiple examples, it should be abstracted into the library.

**Guidance:**
- Use extension methods to add convenience getters to response types
- Use factory constructors for common object creation patterns
- Return `null` or empty collections for missing data (don't throw)

### Dart-Idiomatic API Design

Follow Dart conventions rather than porting patterns from other SDKs:

| Pattern | Implementation |
|---------|----------------|
| Object creation | Factory constructors (`Content.text()`) not top-level functions |
| Role variants | Named constructors (`Content.user()`, `Content.model()`) |
| Response helpers | Extension methods (keeps model classes clean) |
| Async streaming | Dart `Stream` (not generators) |
| Deep copy | `copyWith()` or `fromJson(toJson())` |

### Type Safety

Use strong types wherever possible:
- Replace `List<dynamic>` with typed lists when the element type is known
- Keep `dynamic` only for truly polymorphic API fields (e.g., Vertex AI generic payloads)
- Use sealed classes for discriminated unions

### Extension Method Principles

Extensions should:
1. Be pure and have no side effects
2. Return nullable types for potentially missing data
3. Use lazy evaluation (compute on access)
4. Follow naming conventions from official SDKs (e.g., `.text`, `.functionCalls`)
5. Use `whereType<T>()` for type-safe filtering of sealed class instances

---

## Critical Requirements

**Non-negotiable requirements (must all pass):**

1. Zero runtime dependencies except `http` and `logging`
2. No codegen (`build_runner`, `json_serializable`, `freezed`)
3. Sealed classes for polymorphic types
4. Interceptor chain with proper ordering
5. Manual `fromJson`/`toJson` on all models
6. Immutable data structures (`final` fields, `const` constructors)
7. Type-safe (no `dynamic` except in JSON parsing)
8. Zero analyzer warnings
9. Configuration precedence (last-write-wins)
10. Error transformation with context preservation

---

## Development Guidelines

### Adding New Resources

1. Create file: `lib/src/resources/{resource}_resource.dart`
2. Extend `ResourceBase`
3. Implement methods following existing patterns
4. Add to `GoogleAIClient` constructor

### Adding New Models

1. Create file: `lib/src/models/{category}/{model_name}.dart`
2. Implement with:
   - `final` fields
   - `const` constructor
   - `fromJson` factory
   - `toJson` method
   - `copyWith` with sentinel (if needed)
   - `==`, `hashCode`, `toString`
3. Export from `lib/googleai_dart.dart`
4. Write unit tests: `test/unit/models/{category}/{model_name}_test.dart`

### Adding New Resource Methods

1. Add method to appropriate resource class
2. Follow pattern:
```dart
Future<ResponseType> methodName({required String param}) async {
  final url = requestBuilder.buildUrl('/v1beta/path');
  final headers = requestBuilder.buildHeaders();
  final request = http.Request('POST', url)
    ..headers.addAll(headers)
    ..body = jsonEncode(requestBody);

  final response = await interceptorChain.execute(request);
  return ResponseType.fromJson(jsonDecode(response.body));
}
```
3. Write unit tests (mock) and integration tests (real API)
4. Create example in `example/`
5. Update README.md

### Adding New Examples

1. Create: `example/{feature}_example.dart`
2. Include: imports, `main()`, API key from env, error handling, `client.close()`
3. Add to README.md examples section
4. Verify compilation

### What NOT to Do

1. **DO NOT** add runtime dependencies beyond `http` and `logging`
2. **DO NOT** use codegen
3. **DO NOT** break existing tests
4. **DO NOT** change interceptor ordering
5. **DO NOT** add mutable fields
6. **DO NOT** use `dynamic` outside JSON parsing
7. **DO NOT** skip analyzer checks
8. **DO NOT** retry non-idempotent methods (POST, PATCH)

---

## Testing Standards

### Unit Tests

- Every model: serialization round-trip tests
- All enum conversions (including unknown values → unspecified)
- `copyWith` semantics (including null setting)
- Test in `test/unit/models/{category}/`

### Integration Tests

- Real API calls (gated by `GEMINI_API_KEY`)
- Happy paths and error scenarios
- Long-running operations complete
- Streaming responses work
- Request cancellation works
- Test in `test/integration/`
- Use `@Tags(['integration'])`

### Quality Commands

```bash
dart analyze --fatal-infos    # Zero warnings required
dart format --set-exit-if-changed .
dart test                     # All tests pass
```
