# Migration Guide

This guide helps you migrate from the old `googleai_dart` client (v0.1.x) to the new **v1.0.0** (complete rewrite with resource-based organization and comprehensive API coverage).

## Overview of Changes

The new client mirrors the official REST structure with **resource-based APIs**. Instead of calling methods directly on the client, you now use resource objects:

* `client.models` — Content generation, streaming, embeddings, tokens, prediction, model info
* `client.tunedModels` — Custom tuned model management and generation
* `client.files` — File upload/management (Google AI only)
* `client.generatedFiles` — Generated file (video) output management
* `client.cachedContents` — Context caching for cost/latency
* `client.batches` — Batch operation management
* `client.corpora` — Corpus/Document/Chunk management (Google AI only)
* `client.ragStores` — RAG Stores document/operations (Google AI only)

> **Dual API support**: Same Dart interface for **Google AI Gemini Developer API** and **Vertex AI Gemini API**. Switch via configuration only.

## Quick Reference Table

| Operation             | Old API (v0.1.x)                                               | New API (v1.0.0)                                                              |
| --------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| **Initialize Client** | `GoogleAIClient(apiKey: 'KEY')`                                | `GoogleAIClient(config: GoogleAIConfig(authProvider: ApiKeyProvider('KEY')))` |
| **Generate Content**  | `client.generateContent(modelId: 'model', request: ...)`       | `client.models.generateContent(model: 'model', request: ...)`                 |
| **Stream Content**    | `client.streamGenerateContent(modelId: 'model', request: ...)` | `client.models.streamGenerateContent(model: 'model', request: ...)`           |
| **Embed Content**     | `client.embedContent(modelId: 'model', request: ...)`          | `client.models.embedContent(model: 'model', request: ...)`                    |
| **Count Tokens**      | `client.countTokens(modelId: 'model', request: ...)`           | `client.models.countTokens(model: 'model', request: ...)`                     |
| **List Models**       | `client.listModels()`                                          | `client.models.list()`                                                        |
| **Get Model**         | `client.getModel(modelId: 'model')`                            | `client.models.get(model: 'model')`                                           |
| **Upload File**       | ❌ Not available                                                | `client.files.upload(...)` *(Google AI only)*                                 |
| **Create Cache**      | ❌ Not available                                                | `client.cachedContents.create(...)`                                           |
| **Create Corpus**     | ❌ Not available                                                | `client.corpora.create(...)` *(Google AI only)*                               |

## 1) Client Initialization

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Before
final old = GoogleAIClient(apiKey: 'YOUR_API_KEY');

// After
final client = GoogleAIClient(
  config: GoogleAIConfig(
    authProvider: ApiKeyProvider('YOUR_API_KEY'),
  ),
);
```

### Switching between Google AI and Vertex AI

```dart
// Google AI Gemini Developer API
final googleAI = GoogleAIClient(
  config: GoogleAIConfig.googleAI(
    authProvider: ApiKeyProvider('YOUR_API_KEY'),
  ),
);

// Vertex AI Gemini API (OAuth)
final vertexAI = GoogleAIClient(
  config: GoogleAIConfig.vertexAI(
    projectId: 'your-gcp-project-id',
    location: 'us-central1',
    authProvider: YourOAuthProvider(),
  ),
);
```

> **Note:** On Vertex AI, some Google-AI-only features (Files, Tuned Models API, Corpora/RAG, `generateAnswer`) are **not available**. The client throws **`UnsupportedError`** with links to Vertex alternatives (Cloud Storage URIs, Tuning API, RAG Stores, grounding).

## 2) Content Generation

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Before
final r1 = await old.generateContent(
  modelId: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [Content(parts: [TextPart('Hello')], role: 'user')],
  ),
);

// After
final r2 = await client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [Content(parts: [TextPart('Hello')], role: 'user')],
  ),
);
```

**Key changes:**

* Access under `client.models`
* `modelId` → `model`

## 3) Streaming

```dart
// Before
await for (final chunk in old.streamGenerateContent(
  modelId: 'gemini-3-flash-preview',
  request: request,
)) { /* ... */ }

// After
await for (final chunk in client.models.streamGenerateContent(
  model: 'gemini-3-flash-preview',
  request: request,
)) { /* ... */ }
```

## 4) Embeddings

```dart
// Before
final e1 = await old.embedContent(
  modelId: 'gemini-embedding-001',
  request: EmbedContentRequest(content: Content(parts: [TextPart('Hello')])),
);

// After
final e2 = await client.models.embedContent(
  model: 'gemini-embedding-001',
  request: EmbedContentRequest(content: Content(parts: [TextPart('Hello')])),
);

// New: batch embeddings
final batch = await client.models.batchEmbedContents(
  model: 'gemini-embedding-001',
  request: BatchEmbedContentsRequest(
    requests: [
      EmbedContentRequest(content: Content(parts: [TextPart('Text 1')])),
      EmbedContentRequest(content: Content(parts: [TextPart('Text 2')])),
    ],
  ),
);
```

## 5) Token Counting

```dart
// Before
final t1 = await old.countTokens(
  modelId: 'gemini-3-flash-preview',
  request: CountTokensRequest(
    contents: [Content(parts: [TextPart('Hello')], role: 'user')],
  ),
);

// After
final t2 = await client.models.countTokens(
  model: 'gemini-3-flash-preview',
  request: CountTokensRequest(
    contents: [Content(parts: [TextPart('Hello')], role: 'user')],
  ),
);
```

## 6) Model Info

```dart
// Before
final list1 = await old.listModels();
final m1 = await old.getModel(modelId: 'gemini-3-flash-preview');

// After
final list2 = await client.models.list();
final m2 = await client.models.get(model: 'gemini-3-flash-preview');
```

## 7) Files API (New, Google AI only)

```dart
import 'dart:io' as io;

// Upload
final file = await client.files.upload(
  filePath: '/path/to/image.jpg',
  mimeType: 'image/jpeg',
  displayName: 'My Image',
);

// List / Get
final files = await client.files.list(pageSize: 10);
final details = await client.files.get(name: file.name);

// Download
final bytes = await client.files.download(name: file.name);
await io.File('download.jpg').writeAsBytes(bytes);

// Delete
await client.files.delete(name: file.name);
```

## 8) Context Caching (New)

```dart
// Create cached content with system instructions
final cached = await client.cachedContents.create(
  cachedContent: CachedContent(
    model: 'models/gemini-3-flash-preview',
    systemInstruction: Content(
      parts: [TextPart('You are a helpful assistant.')],
    ),
    ttl: '3600s',
  ),
);

// Use cached content in generation
final res = await client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    cachedContent: cached.name,
    contents: [Content(parts: [TextPart('Explain Pythagoras')], role: 'user')],
  ),
);

// Update TTL / Delete
await client.cachedContents.update(
  name: cached.name!,
  cachedContent: CachedContent(ttl: '7200s'),
  updateMask: 'ttl',
);
await client.cachedContents.delete(name: cached.name!);
```

## 9) Batch Operations (New)

```dart
final batch = await client.models.batchGenerateContent(
  model: 'gemini-3-flash-preview',
  batch: GenerateContentBatch(
    displayName: 'My Batch',
    model: 'models/gemini-3-flash-preview',
    inputConfig: InputConfig(
      requests: InlinedRequests(
        requests: [
          InlinedRequest(request: GenerateContentRequest(
            contents: [Content(parts: [TextPart('Query 1')], role: 'user')],
          )),
          InlinedRequest(request: GenerateContentRequest(
            contents: [Content(parts: [TextPart('Query 2')], role: 'user')],
          )),
        ],
      ),
    ),
  ),
);

final status = await client.batches.get(name: batch.name!);
await client.batches.cancel(name: batch.name!);
await client.batches.delete(name: batch.name!);
```

## 10) Corpora (New)

> **⚠️ Important**: Document, chunk, and RAG query features are **Vertex AI only**. Google AI only supports basic corpus management (create, list, get, update, delete).

```dart
// Google AI: Corpus management only
final corpus = await client.corpora.create(
  corpus: Corpus(displayName: 'My KB'),
);

final list = await client.corpora.list();
final retrieved = await client.corpora.get(name: corpus.name!);

await client.corpora.update(
  name: corpus.name!,
  corpus: Corpus(displayName: 'Updated KB'),
  updateMask: 'displayName',
);

await client.corpora.delete(name: corpus.name!);
```

**For full RAG capabilities (documents, chunks, semantic search):**
- Use **Vertex AI** with `client.ragStores` for document management and RAG operations
- The Semantic Retriever API has been succeeded by Vertex AI Vector Search

## 11) Permissions (New)

```dart
final created = await client.tunedModels
  .permissions(parent: 'tunedModels/my-model')
  .create(permission: Permission(
    granteeType: GranteeType.user,
    emailAddress: 'user@example.com',
    role: PermissionRole.reader,
  ));

await client.tunedModels.permissions(parent: 'tunedModels/my-model').update(
  name: created.name!,
  permission: Permission(role: PermissionRole.writer),
  updateMask: 'role',
);

await client.tunedModels
  .permissions(parent: 'tunedModels/my-model')
  .delete(name: created.name!);
```

## 12) Exception Handling

```dart
try {
  await client.models.generateContent(/* ... */);
} on RateLimitException catch (e) {
  // 429 with retry-after
} on ValidationException catch (e) {
  // client-side validation
} on ApiException catch (e) {
  // server error with request/response metadata
} on TimeoutException catch (e) {
  // request timed out
} on AbortedException catch (e) {
  // request canceled via abortTrigger
}
```

## 13) Advanced Configuration

```dart
final client = GoogleAIClient(
  config: GoogleAIConfig(
    authProvider: ApiKeyProvider('YOUR_API_KEY'),
    apiMode: ApiMode.googleAI,        // or ApiMode.vertexAI
    apiVersion: ApiVersion.v1beta,    // default; use v1 for production stability
    baseUrl: 'https://custom.example.com',
    defaultHeaders: {'X-Custom': 'value'},
    retryPolicy: RetryPolicy(maxRetries: 5),
    timeout: Duration(minutes: 2),
    logLevel: Level.INFO,
  ),
);
```

## Common Pitfalls & Notes

* **Vertex AI vs Google AI**:
  * Vertex AI does **not** support Google-AI Files/Tuned Models APIs. Use **Cloud Storage URIs** and **Vertex Tuning API** instead.
  * Corpora: Both support corpus CRUD operations. For document/chunk/RAG features, use **Vertex AI RAG Stores**.
  * The client throws `UnsupportedError` with guidance when you call unsupported features.
* **Default API version**:
  * If the default is `v1beta`, outputs/limits may differ from `v1`.

## Getting Help

* Browse the [examples](example/)
* Check the [API docs](https://pub.dev/documentation/googleai_dart/latest/)
* Open an issue: [https://github.com/davidmigloz/langchain_dart/issues](https://github.com/davidmigloz/langchain_dart/issues)

---

For the complete list of changes, see [CHANGELOG.md](CHANGELOG.md).
