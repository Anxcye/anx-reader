# Google AI & Vertex AI Gemini API Dart Client

[![tests](https://img.shields.io/github/actions/workflow/status/davidmigloz/langchain_dart/test.yaml?logo=github&label=tests)](https://github.com/davidmigloz/langchain_dart/actions/workflows/test.yaml)
[![googleai_dart](https://img.shields.io/pub/v/googleai_dart.svg)](https://pub.dev/packages/googleai_dart)
![Discord](https://img.shields.io/discord/1123158322812555295?label=discord)
[![MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://github.com/davidmigloz/langchain_dart/blob/main/LICENSE)

Unofficial Dart client for the **[Google AI Gemini Developer API](https://ai.google.dev/gemini-api/docs)** and **[Vertex AI Gemini API](https://cloud.google.com/vertex-ai/generative-ai/docs/overview)** with unified interface.

> [!NOTE]
> The official [`google_generative_ai`](https://pub.dev/packages/google_generative_ai) Dart package has been deprecated in favor of [`firebase_ai`](https://pub.dev/packages/firebase_ai). However, since [`firebase_ai`](https://pub.dev/packages/firebase_ai) is a **Flutter package** rather than a **pure Dart package**, this **unofficial client** bridges the gap by providing a **pure Dart, fully type-safe** API client for both Google AI and Vertex AI.

*Ideal for server-side Dart, CLI tools, and backend services needing a type-safe Gemini API client without Flutter dependencies.*

<details>
<summary><b>Table of Contents</b></summary>

- [Features](#features)
- [Why choose this client?](#why-choose-this-client)
- [Quickstart](#quickstart)
- [Installation](#installation)
- [API Versions](#api-versions)
- [Vertex AI Support](#vertex-ai-support)
- [Advanced Configuration](#advanced-configuration)
- [Usage](#usage)
- [Migrating from Google AI to Vertex AI](#migrating-from-google-ai-to-vertex-ai)
- [Examples](#examples)
- [API Coverage](#api-coverage)
- [Development](#development)
- [License](#license)

</details>

## Features

### 🌍 **Core Features** (Both Google AI & Vertex AI)

#### Generation & Streaming

- ✅ Content generation (`generateContent`)
- ✅ Streaming support (`streamGenerateContent`) with SSE
- ✅ Request abortion (cancelable requests via `abortTrigger`)
- ✅ Token counting (`countTokens`)
- ✅ Tool support:
  - Function calling (custom function declarations)
  - Code execution (Python sandbox)
  - Google Search grounding
  - URL Context (fetch and analyze web content)
  - File search (Semantic Retrieval with FileSearchStores)
  - Google Maps (geospatial context)
  - MCP servers (Model Context Protocol)
- ✅ Safety settings support

#### Embeddings

- ✅ Content embeddings (`embedContent`)
- ✅ Batch embeddings with automatic fallback

#### Models

- ✅ Model listing & discovery (`listModels`, `getModel`)
- ✅ Content caching (full CRUD operations)

---

### 🔵 **Google AI Only** (Not available on Vertex AI)

#### Files API

- ✅ File management (upload, list, get, download, delete)
- ✅ Multiple upload methods: file path (IO), bytes (all platforms), streaming (IO)
- ℹ️ *Vertex AI: Use [Cloud Storage URIs](https://cloud.google.com/vertex-ai/docs/multimodal/send-multimodal-prompts) or base64*

#### Tuned Models

- ✅ Tuned models (create, list, get, patch, delete, listOperations)
- ✅ Generation with tuned models
- ℹ️ *Vertex AI: Use [Vertex AI Tuning API](https://cloud.google.com/vertex-ai/docs/tuning)*

#### Corpora & File Search

- ✅ Corpus management (create, list, get, update, delete)
- ✅ Document management within corpora
- ✅ FileSearchStores for semantic retrieval (create, list, get, delete, import/upload files)
- ℹ️ *Vertex AI: Use [RAG Engine](https://cloud.google.com/vertex-ai/docs/generative-ai/rag-overview) for enterprise RAG capabilities*

#### Permissions

- ✅ Permission management (create, list, get, update, delete)
- ✅ Ownership transfer (`transferOwnership`)
- ✅ Grantee types (user, group, everyone)
- ✅ Role-based access (owner, writer, reader)

#### Prediction (Video Generation)

- ✅ Synchronous prediction (`predict`)
- ✅ Long-running prediction (`predictLongRunning`) for video generation with Veo
- ✅ Operation status polling for async predictions
- ✅ RAI (Responsible AI) filtering support

#### Batch Operations

- ✅ Batch content generation (`batchGenerateContent`)
- ✅ Synchronous batch embeddings (`batchEmbedContents`)
- ✅ Asynchronous batch embeddings (`asyncBatchEmbedContent`)
- ✅ Batch management (list, get, update, delete, cancel)
- ✅ LRO polling for async batch jobs

#### Interactions API (Experimental)

- ✅ Server-side conversation state management
- ✅ Multi-turn conversations with `previousInteractionId`
- ✅ Streaming responses with SSE events
- ✅ Function calling with automatic result handling
- ✅ Agent support (e.g., Deep Research)
- ✅ 17 content types (text, image, audio, function calls, etc.)
- ✅ Background interactions with cancel support

#### Live API (WebSocket Streaming)

- ✅ Real-time bidirectional WebSocket communication
- ✅ Audio streaming (16kHz input, 24kHz output PCM)
- ✅ Text streaming with real-time responses
- ✅ Voice Activity Detection (VAD) - automatic and manual modes
- ✅ Input/output audio transcription
- ✅ Tool/function calling in live sessions
- ✅ Session resumption with tokens
- ✅ Context window compression for long conversations
- ✅ Multiple voice options (Puck, Charon, Kore, etc.)
- ✅ Ephemeral tokens for secure client-side authentication

### Quick Comparison

| Aspect | Google AI | Vertex AI |
|--------|-----------|-----------|
| **Auth** | API Key | OAuth 2.0 |
| **Core Features** | ✅ Full support | ✅ Full support |
| **Files API** | ✅ Supported | ❌ Use Cloud Storage URIs |
| **Tuned Models** | ✅ Supported | ❌ Different tuning API |
| **File Search** | ✅ FileSearchStores | ✅ RAG Engine |
| **Enterprise** | ❌ None | ✅ VPC, CMEK, HIPAA |

## Why choose this client?

- ✅ Type-safe with sealed classes
- ✅ Multiple auth methods (API key, OAuth)
- ✅ Minimal dependencies (http, logging only)
- ✅ Works on all compilation targets (native, web, WASM)
- ✅ Interceptor-driven architecture
- ✅ Comprehensive error handling
- ✅ Automatic retry with exponential backoff
- ✅ Long-running operations (LRO polling)
- ✅ Pagination support (Paginator utility)
- ✅ 560+ tests

## Quickstart

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Initialize from environment variable (GOOGLE_GENAI_API_KEY)
final client = GoogleAIClient.fromEnvironment();

final response = await client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [Content.text('Hello Gemini!')],  // Convenience factory
  ),
);

// Use .text extension to get the response text
print(response.text);
client.close();
```

<details>
<summary><b>Or with explicit API key</b></summary>

```dart
final client = GoogleAIClient(
  config: GoogleAIConfig.googleAI(
    authProvider: ApiKeyProvider('YOUR_API_KEY'),
  ),
);
```

</details>

## Installation

```yaml
dependencies:
  googleai_dart: {version}
```

## API Versions

This client supports both [stable and beta versions](https://ai.google.dev/gemini-api/docs/api-versions) of the API:

| Version | Stability | Use Case | Features |
|---------|-----------|----------|----------|
| **v1** | Stable | Production apps | Guaranteed stability, breaking changes trigger new major version |
| **v1beta** | Beta | Testing & development | Early-access features, subject to rapid/breaking changes |

**Default**: The client defaults to `v1beta` for broadest feature access.

<details>
<summary><b>API Version Configuration</b></summary>

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Use stable v1
final client = GoogleAIClient(
  config: GoogleAIConfig.googleAI(
    apiVersion: ApiVersion.v1,
    authProvider: ApiKeyProvider('YOUR_API_KEY'),
  ),
);

// Use beta v1beta
final betaClient = GoogleAIClient(
  config: GoogleAIConfig.googleAI(
    apiVersion: ApiVersion.v1beta,
    authProvider: ApiKeyProvider('YOUR_API_KEY'),
  ),
);
```

</details>

## Vertex AI Support

To use Vertex AI, you need:

1. A Google Cloud Platform (GCP) project
2. Vertex AI Gemini API enabled
3. Service account with `roles/aiplatform.user` role
4. OAuth 2.0 credentials

<details>
<summary><b>Complete Vertex AI Setup</b></summary>

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Create an OAuth provider (implement token refresh logic)
class MyOAuthProvider implements AuthProvider {
  @override
  Future<AuthCredentials> getCredentials() async {
    // Your OAuth token refresh logic here
    final token = await getAccessToken(); // Implement this
    // You can use https://pub.dev/packages/googleapis_auth
    return BearerTokenCredentials(token);
  }
}

// Configure for Vertex AI
final vertexClient = GoogleAIClient(
  config: GoogleAIConfig.vertexAI(
    projectId: 'your-gcp-project-id',
    location: 'us-central1', // Or 'global', 'europe-west1', etc.
    apiVersion: ApiVersion.v1, // Stable version
    authProvider: MyOAuthProvider(),
  ),
);

// Use the same API as Google AI
final response = await vertexClient.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [
      Content(
        parts: [TextPart('Explain quantum computing')],
        role: 'user',
      ),
    ],
  ),
);
```

</details>

## Advanced Configuration

<details>
<summary><b>Custom Configuration Options</b></summary>

For advanced use cases, you can use the main `GoogleAIConfig` constructor with full control over all parameters:

```dart
import 'package:googleai_dart/googleai_dart.dart';

final client = GoogleAIClient(
  config: GoogleAIConfig(
    baseUrl: 'https://my-custom-proxy.example.com',
    apiMode: ApiMode.googleAI,
    apiVersion: ApiVersion.v1,
    authProvider: ApiKeyProvider('YOUR_API_KEY'),
    timeout: Duration(minutes: 5),
    retryPolicy: RetryPolicy(maxRetries: 5),
    // ... other parameters
  ),
);
```

**Use cases for custom base URLs:**

- **Proxy servers**: Route requests through a corporate proxy
- **Testing**: Point to a mock server for integration tests
- **Regional endpoints**: Use region-specific URLs if needed
- **Custom deployments**: Self-hosted or specialized endpoints

The factory constructors (`GoogleAIConfig.googleAI()` and `GoogleAIConfig.vertexAI()`) are convenience methods that set sensible defaults, but you can always use the main constructor for full control.

</details>

## Usage

### Authentication

<details>
<summary><b>All Authentication Methods</b></summary>

The client uses an `AuthProvider` pattern for flexible authentication:

```dart
import 'package:googleai_dart/googleai_dart.dart';

// API Key authentication (query parameter)
final client = GoogleAIClient(
  config: GoogleAIConfig(
    authProvider: ApiKeyProvider('YOUR_API_KEY'),
  ),
);

// API Key as header
final clientWithHeader = GoogleAIClient(
  config: GoogleAIConfig(
    authProvider: ApiKeyProvider(
      'YOUR_API_KEY',
      placement: AuthPlacement.header,
    ),
  ),
);

// Bearer token (for OAuth)
final clientWithBearer = GoogleAIClient(
  config: GoogleAIConfig(
    authProvider: BearerTokenProvider('YOUR_BEARER_TOKEN'),
  ),
);

// Custom OAuth with automatic token refresh
class CustomOAuthProvider implements AuthProvider {
  @override
  Future<AuthCredentials> getCredentials() async {
    // Your token refresh logic here
    // Called on each request, including retries
    return BearerTokenCredentials(await refreshToken());
  }
}

final oauthClient = GoogleAIClient(
  config: GoogleAIConfig(
    authProvider: CustomOAuthProvider(),
  ),
);
```

</details>

### Basic Generation

<details>
<summary><b>Basic Generation Example</b></summary>

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Initialize from environment variable (GOOGLE_GENAI_API_KEY)
final client = GoogleAIClient.fromEnvironment();

final response = await client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [Content.text('Explain quantum computing')],
  ),
);

// Use .text extension for easy text extraction
print(response.text);
client.close();
```

</details>

### Streaming

<details>
<summary><b>Streaming Example</b></summary>

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
await for (final chunk in client.models.streamGenerateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [Content.text('Write a poem about AI')],
  ),
)) {
  // Use .text extension for each chunk
  final text = chunk.text;
  if (text != null) print(text);
}
```

</details>

### Canceling Requests

<details>
<summary><b>Request Cancellation Examples</b></summary>

You can cancel long-running requests using an abort trigger:

```dart
import 'dart:async';
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
final abortController = Completer<void>();

// Start request with abort capability
final requestFuture = client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: request,
  abortTrigger: abortController.future,
);

// To cancel:
abortController.complete();

// Handle cancellation
try {
  final response = await requestFuture;
} on AbortedException {
  print('Request was canceled');
}
```

This works for both regular and streaming requests. You can also use it with timeouts:

```dart
// Auto-cancel after 30 seconds
final response = await client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: request,
  abortTrigger: Future.delayed(Duration(seconds: 30)),
);
```

</details>

### Function Calling

<details>
<summary><b>Function Calling Example</b></summary>

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
final tools = [
  Tool(
    functionDeclarations: [
      FunctionDeclaration(
        name: 'get_weather',
        description: 'Get current weather',
        parameters: Schema(
          type: SchemaType.object,
          properties: {
            'location': Schema(type: SchemaType.string),
          },
          required: ['location'],
        ),
      ),
    ],
  ),
];

final response = await client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [/* ... */],
    tools: tools,
  ),
);
```

</details>

### Grounding Tools

googleai_dart supports multiple grounding tools that enhance model responses with real-world data.

<details>
<summary><b>Google Search Grounding</b></summary>

Ground responses with real-time web information:

```dart
final response = await client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [Content.text('Who won Euro 2024?')],
    // Enable Google Search grounding with an empty map
    tools: [Tool(googleSearch: {})],
  ),
);

// Use .text extension for easy text extraction
print(response.text);

// Access grounding metadata
final metadata = response.candidates?.first.groundingMetadata;
if (metadata != null) {
  // Search queries executed by the model
  print('Queries: ${metadata.webSearchQueries}');

  // Web sources used
  for (final chunk in metadata.groundingChunks ?? []) {
    if (chunk.web != null) {
      print('Source: ${chunk.web!.title} - ${chunk.web!.uri}');
    }
  }

  // Search entry point widget (required for attribution)
  if (metadata.searchEntryPoint?.renderedContent != null) {
    print('Widget HTML available for display');
  }
}
```

Or use the Interactions API for streaming:

```dart
await for (final event in client.interactions.createStream(
  model: 'gemini-3-flash-preview',
  input: 'What are today\'s top technology news?',
  tools: [GoogleSearchTool()],
)) {
  if (event case ContentDeltaEvent(:final delta)) {
    if (delta is TextDelta) {
      print(delta.text);
    } else if (delta is GoogleSearchCallDelta) {
      print('Searching: ${delta.queries?.join(", ")}');
    }
  }
}
```

See [google_search_example.dart](example/google_search_example.dart) for a complete example.

</details>

<details>
<summary><b>URL Context</b></summary>

Fetch and analyze content from specific URLs (up to 20 URLs, max 34MB per URL):

```dart
final response = await client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [
      Content.text('Summarize the main points from: https://dart.dev/overview'),
    ],
    // Enable URL Context with an empty map
    tools: [Tool(urlContext: {})],
  ),
);

// Use .text extension for easy text extraction
print(response.text);
```

Or with the Interactions API:

```dart
await for (final event in client.interactions.createStream(
  model: 'gemini-3-flash-preview',
  input: 'Summarize https://pub.dev/packages/googleai_dart',
  tools: [UrlContextTool()],
)) {
  if (event case ContentDeltaEvent(:final delta)) {
    if (delta is TextDelta) {
      stdout.write(delta.text);
    } else if (delta is UrlContextCallDelta) {
      print('Fetching: ${delta.urls?.join(", ")}');
    }
  }
}
```

See [url_context_example.dart](example/url_context_example.dart) for a complete example.

</details>

<details>
<summary><b>Google Maps</b></summary>

Add geospatial context for location-based queries:

```dart
final response = await client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [Content.text('Find Italian restaurants nearby')],
    // Enable Google Maps with widget support
    tools: [Tool(googleMaps: GoogleMaps(enableWidget: true))],
    // Provide user location context (as Map)
    toolConfig: {
      'retrievalConfig': {
        'latLng': {
          'latitude': 40.758896,
          'longitude': -73.985130,
        },
      },
    },
  ),
);

// Access place information
final metadata = response.candidates?.first.groundingMetadata;
for (final chunk in metadata?.groundingChunks ?? []) {
  if (chunk.maps != null) {
    print('Place: ${chunk.maps!.title}');
    print('Place ID: ${chunk.maps!.placeId}');
  }
}

// Widget token for rendering Google Maps widget
if (metadata?.googleMapsWidgetContextToken != null) {
  print('Widget token: ${metadata!.googleMapsWidgetContextToken}');
}
```

See [google_maps_example.dart](example/google_maps_example.dart) for a complete example.

</details>

<details>
<summary><b>File Search (Semantic Retrieval)</b></summary>

Search your own documents using FileSearchStores:

```dart
// Create a FileSearchStore
final store = await client.fileSearchStores.create(
  displayName: 'My Knowledge Base',
);

// Upload a document with custom chunking and metadata
final uploadResponse = await client.fileSearchStores.upload(
  parent: store.name!,
  filePath: '/path/to/document.pdf',
  mimeType: 'application/pdf',
  request: UploadToFileSearchStoreRequest(
    displayName: 'Technical Documentation',
    chunkingConfig: ChunkingConfig(
      whiteSpaceConfig: WhiteSpaceConfig(
        maxTokensPerChunk: 200,
        maxOverlapTokens: 20,
      ),
    ),
    customMetadata: [
      FileSearchCustomMetadata(key: 'author', stringValue: 'Jane Doe'),
      FileSearchCustomMetadata(key: 'year', numericValue: 2024),
    ],
  ),
);

// Use FileSearch in generation with optional metadata filter
final response = await client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [
      Content.text('What does the documentation say about X?'),
    ],
    tools: [
      Tool(
        fileSearch: FileSearch(
          fileSearchStoreNames: [store.name!],
          topK: 5,
          metadataFilter: 'author = "Jane Doe"',
        ),
      ),
    ],
  ),
);

// Access grounding metadata (citations)
final metadata = response.candidates?.first.groundingMetadata;
for (final chunk in metadata?.groundingChunks ?? []) {
  if (chunk.retrievedContext != null) {
    print('Source: ${chunk.retrievedContext!.title}');
  }
}

// Cleanup
await client.fileSearchStores.delete(name: store.name!);
```

See [file_search_example.dart](example/file_search_example.dart) for a complete example.

</details>

### Embeddings

<details>
<summary><b>Embeddings Example</b></summary>

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
final response = await client.models.embedContent(
  model: 'gemini-embedding-001',
  request: EmbedContentRequest(
    content: Content(
      parts: [TextPart('Hello world')],
    ),
    taskType: TaskType.retrievalDocument,
  ),
);

print(response.embedding.values); // List<double>
```

</details>

### File Management

<details>
<summary><b>Complete File Management Example</b></summary>

Upload files for use in multimodal prompts:

```dart
import 'dart:io' as io;
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
// Upload a file
final file = await client.files.upload(
  filePath: '/path/to/image.jpg',
  mimeType: 'image/jpeg',
  displayName: 'My Image',
);

print('File uploaded: ${file.name}');
print('State: ${file.state}');
print('URI: ${file.uri}');

// Wait for file to be processed (if needed)
while (file.state == FileState.processing) {
  await Future.delayed(Duration(seconds: 2));
  file = await client.files.get(name: file.name);
}

// Use the file in a prompt
final response = await client.models.generateContent(
  model: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [
      Content(
        parts: [
          TextPart('Describe this image'),
          FileData(
            fileUri: file.uri,
            mimeType: file.mimeType,
          ),
        ],
        role: 'user',
      ),
    ],
  ),
);

// List all files
final listResponse = await client.files.list(pageSize: 10);
for (final f in listResponse.files ?? []) {
  print('${f.displayName}: ${f.state}');
}

// Download file content (if needed)
final bytes = await client.files.download(name: file.name);
// Save to disk or process bytes
await io.File('downloaded_file.jpg').writeAsBytes(bytes);

// Delete the file when done
await client.files.delete(name: file.name);
```

**Note:** Files are automatically deleted after 48 hours.

</details>

### Context Caching

<details>
<summary><b>Complete Context Caching Example</b></summary>

Context caching allows you to save frequently used content and reuse it across requests, reducing latency and costs:

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
// Create cached content with system instructions
final cachedContent = await client.cachedContents.create(
  cachedContent: const CachedContent(
    model: 'models/gemini-3-flash-preview',
    displayName: 'Math Expert Cache',
    systemInstruction: Content(
      parts: [TextPart('You are an expert mathematician...')],
    ),
    ttl: '3600s', // Cache for 1 hour
  ),
);

// Use cached content in requests (saves tokens!)
final response = await client.models.generateContent(
  model: 'gemini-3-flash',
  request: GenerateContentRequest(
    cachedContent: cachedContent.name,
    contents: [Content.text('Explain the Pythagorean theorem')],
  ),
);

// Update cache TTL
await client.cachedContents.update(
  name: cachedContent.name!,
  cachedContent: const CachedContent(
    model: 'models/gemini-3-flash-preview',
    ttl: '7200s', // Extend to 2 hours
  ),
  updateMask: 'ttl',
);

// Clean up when done
await client.cachedContents.delete(name: cachedContent.name!);
```

**Benefits:**

- ✅ Reduced latency for requests with large contexts
- ✅ Lower costs by reusing cached content
- ✅ Consistent system instructions across requests

</details>

### Grounded Question Answering

<details>
<summary><b>Complete generateAnswer Examples</b></summary>

The `generateAnswer` API provides answers grounded in specific sources, ideal for Retrieval Augmented Generation (RAG):

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
// Using inline passages (for small knowledge bases)
final response = await client.models.generateAnswer(
  model: 'aqa',
  request: const GenerateAnswerRequest(
    contents: [
      Content(
        parts: [TextPart('What is the capital of France?')],
        role: 'user',
      ),
    ],
    answerStyle: AnswerStyle.abstractive, // Or: extractive, verbose
    inlinePassages: GroundingPassages(
      passages: [
        GroundingPassage(
          id: 'passage-1',
          content: Content(
            parts: [TextPart('Paris is the capital of France.')],
          ),
        ),
      ],
    ),
    temperature: 0.2, // Low temperature for factual answers
  ),
);

// Check answerability
if (response.answerableProbability != null &&
    response.answerableProbability! < 0.5) {
  print('⚠️ Answer may not be grounded in sources');
}

// Using semantic retriever (for large corpora)
final ragResponse = await client.models.generateAnswer(
  model: 'aqa',
  request: const GenerateAnswerRequest(
    contents: [
      Content(
        parts: [TextPart('What are the key features of Dart?')],
        role: 'user',
      ),
    ],
    answerStyle: AnswerStyle.verbose,
    semanticRetriever: SemanticRetrieverConfig(
      source: 'corpora/my-corpus',
      query: Content(
        parts: [TextPart('Dart programming language features')],
      ),
      maxChunksCount: 5,
      minimumRelevanceScore: 0.5,
    ),
  ),
);
```

**Features:**

- ✅ Multiple answer styles (abstractive, extractive, verbose)
- ✅ Inline passages or semantic retriever grounding
- ✅ Answerability probability for quality control
- ✅ Safety settings support
- ✅ Input feedback for blocked content

</details>

### Batch Operations

<details>
<summary><b>Batch Operations Example</b></summary>

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
// Create a batch for processing multiple requests
// The model in the batch is auto-populated from the method parameter
final batch = await client.models.batchGenerateContent(
  model: 'gemini-3-flash-preview',
  batch: const GenerateContentBatch(
    displayName: 'My Batch Job',
    inputConfig: InputConfig(
      requests: InlinedRequests(
        requests: [
          InlinedRequest(
            request: GenerateContentRequest(
              contents: [Content.text('What is 2+2?')],
            ),
          ),
          InlinedRequest(
            request: GenerateContentRequest(
              contents: [Content.text('What is 3+3?')],
            ),
          ),
        ],
      ),
    ),
  ),
);

// Monitor batch status
final status = await client.batches.getGenerateContentBatch(name: batch.name!);
print('Batch state: ${status.state}');
```

</details>

### Corpus & RAG

<details>
<summary><b>Corpus Example</b></summary>

> **⚠️ Important**: Document, chunk, and RAG features are only available in Vertex AI. Google AI only supports basic corpus management.

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured Google AI client
// Google AI supports basic corpus CRUD operations
final corpus = await client.corpora.create(
  corpus: const Corpus(displayName: 'My Knowledge Base'),
);

// List corpora
final corpora = await client.corpora.list(pageSize: 10);

// Get corpus
final retrieved = await client.corpora.get(name: corpus.name!);

// Update corpus
final updated = await client.corpora.update(
  name: corpus.name!,
  corpus: const Corpus(displayName: 'Updated Name'),
  updateMask: 'displayName',
);

// Delete corpus
await client.corpora.delete(name: corpus.name!);
```

**For full RAG capabilities (documents, chunks, semantic search):**
- Use **Vertex AI** with [RAG Stores](https://cloud.google.com/vertex-ai/docs/grounding) and [Vector Search](https://cloud.google.com/vertex-ai/docs/vector-search)
- The Semantic Retriever API has been succeeded by Vertex AI Vector Search

</details>

### Permissions

<details>
<summary><b>Permission Management Examples</b></summary>

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
// Grant permissions to a resource
final permission = await client.tunedModels.permissions(parent: 'tunedModels/my-model').create(
  permission: const Permission(
    granteeType: GranteeType.user,
    emailAddress: 'user@example.com',
    role: PermissionRole.reader,
  ),
);

// List permissions
final permissions = await client.tunedModels.permissions(parent: 'tunedModels/my-model').list();

// Transfer ownership
await client.tunedModels.permissions(parent: 'tunedModels/my-model').transferOwnership(
  emailAddress: 'newowner@example.com',
);
```

</details>

### Tuned Models

<details>
<summary><b>List and Inspect Tuned Models</b></summary>

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
// List all tuned models
final tunedModels = await client.tunedModels.list(
  pageSize: 10,
  filter: 'owner:me', // Filter by ownership
);

for (final model in tunedModels.tunedModels) {
  print('Model: ${model.displayName} (${model.name})');
  print('State: ${model.state}');
  print('Base model: ${model.baseModel}');
}

// Get specific tuned model details
final myModel = await client.tunedModels.get(
  name: 'tunedModels/my-model-abc123',
);

print('Model: ${myModel.displayName}');
print('State: ${myModel.state}');
print('Training examples: ${myModel.tuningTask?.trainingData?.examples?.exampleCount}');

// List operations for a tuned model (monitor training progress)
final operations = await client.tunedModels.operations(parent: 'tunedModels/my-model-abc123').list();

for (final operation in operations.operations) {
  print('Operation: ${operation.name}');
  print('Done: ${operation.done}');
  if (operation.metadata != null) {
    print('Progress: ${operation.metadata}');
  }
}
```

</details>

### Using Tuned Models for Generation

<details>
<summary><b>Generate Content with Tuned Models</b></summary>

Once you have a tuned model, you can use it for content generation just like base models:

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
// Generate content with a tuned model
final response = await client.tunedModels.generateContent(
  tunedModel: 'my-model-abc123', // Your tuned model ID
  request: GenerateContentRequest(
    contents: [Content.text('Explain quantum computing')],
  ),
);

// Use the convenience extension to get text
print(response.text);

// Stream responses with a tuned model
await for (final chunk in client.tunedModels.streamGenerateContent(
  tunedModel: 'my-model-abc123',
  request: request,
)) {
  final text = chunk.text;
  if (text != null) print(text);
}

// Batch generation with a tuned model
// The model in the batch is auto-populated from the tunedModel parameter
final batch = await client.tunedModels.batchGenerateContent(
  tunedModel: 'my-model-abc123',
  batch: GenerateContentBatch(
    displayName: 'My Batch Job',
    inputConfig: InputConfig(
      requests: InlinedRequests(
        requests: [
          InlinedRequest(
            request: GenerateContentRequest(
              contents: [Content.text('Question 1')],
            ),
          ),
        ],
      ),
    ),
  ),
);
```

**Benefits of tuned models:**

- ✅ Customized behavior for your specific domain
- ✅ Improved accuracy for specialized tasks
- ✅ Consistent output style and format
- ✅ Reduced need for extensive prompting

</details>

### Prediction (Video Generation)

<details>
<summary><b>Video Generation with Veo Example</b></summary>

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Assumes you have a configured client instance
// Synchronous prediction
final response = await client.models.predict(
  model: 'veo-3.0-generate-001',
  instances: [
    {'prompt': 'A cat playing piano in a jazz club'},
  ],
);

print('Predictions: ${response.predictions}');

// Long-running prediction for video generation
final operation = await client.models.predictLongRunning(
  model: 'veo-3.0-generate-001',
  instances: [
    {'prompt': 'A golden retriever running on a beach at sunset'},
  ],
  parameters: {
    'aspectRatio': '16:9',
  },
);

print('Operation: ${operation.name}');
print('Done: ${operation.done}');

// Check for generated videos
if (operation.done == true && operation.response != null) {
  final videoResponse = operation.response!.generateVideoResponse;
  if (videoResponse?.generatedSamples != null) {
    for (final media in videoResponse!.generatedSamples!) {
      if (media.video?.uri != null) {
        print('Video URI: ${media.video!.uri}');
      }
    }
  }

  // Check for RAI filtering
  if (videoResponse?.raiMediaFilteredCount != null) {
    print('Filtered: ${videoResponse!.raiMediaFilteredCount} videos');
    print('Reasons: ${videoResponse.raiMediaFilteredReasons}');
  }
}
```

</details>

### Live API (Real-time Streaming)

The Live API provides bidirectional WebSocket streaming for real-time audio/text conversations.

<details>
<summary><b>Live API Example</b></summary>

```dart
import 'package:googleai_dart/googleai_dart.dart';

// Create the main client
final client = GoogleAIClient(
  config: GoogleAIConfig(
    authProvider: ApiKeyProvider('YOUR_API_KEY'),
  ),
);

// Create a Live client for WebSocket streaming
final liveClient = client.createLiveClient();

try {
  // Connect to the Live API with configuration
  final session = await liveClient.connect(
    model: 'gemini-2.0-flash-live-001',
    liveConfig: LiveConfig(
      generationConfig: LiveGenerationConfig.textAndAudio(
        speechConfig: SpeechConfig.withVoice(LiveVoices.puck),
        temperature: 0.7,
      ),
      // Enable transcription for both input and output
      inputAudioTranscription: AudioTranscriptionConfig.enabled(),
      outputAudioTranscription: AudioTranscriptionConfig.enabled(),
      // Configure voice activity detection
      realtimeInputConfig: RealtimeInputConfig.withVAD(
        silenceDurationMs: 500,
        activityHandling: ActivityHandling.startOfActivityInterrupts,
      ),
    ),
  );

  print('Connected! Session ID: ${session.sessionId}');

  // Send a text message
  session.sendText('Hello! Tell me a short joke.');

  // Listen for responses
  await for (final message in session.messages) {
    switch (message) {
      case BidiGenerateContentSetupComplete(:final sessionId):
        print('Setup complete, session: $sessionId');

      case BidiGenerateContentServerContent(
          :final modelTurn,
          :final turnComplete,
          :final inputTranscription,
          :final outputTranscription,
        ):
        // Handle model response
        if (modelTurn != null) {
          for (final part in modelTurn.parts) {
            if (part is TextPart) {
              print('Model: ${part.text}');
            } else if (part is InlineDataPart) {
              // Audio data (24kHz PCM)
              print('Audio: ${part.inlineData.data.length} bytes');
            }
          }
        }

        // Show transcriptions
        if (inputTranscription?.text != null) {
          print('You said: ${inputTranscription!.text}');
        }
        if (outputTranscription?.text != null) {
          print('Model said: ${outputTranscription!.text}');
        }

        if (turnComplete ?? false) {
          print('--- Turn complete ---');
          break;
        }

      case BidiGenerateContentToolCall(:final functionCalls):
        // Handle tool calls and send responses
        final responses = functionCalls.map((call) => FunctionResponse(
          name: call.name,
          response: {'result': 'executed'},
        )).toList();
        session.sendToolResponse(responses);

      case GoAway(:final timeLeft):
        print('Server disconnect in: $timeLeft');
        // Save session.resumptionToken for later resumption

      case SessionResumptionUpdate(:final resumable):
        print('Session resumable: $resumable');
    }
  }

  await session.close();
} on LiveConnectionException catch (e) {
  print('Connection failed: ${e.message}');
} finally {
  await liveClient.close();
  client.close();
}
```

</details>

<details>
<summary><b>Sending Audio</b></summary>

```dart
// Audio must be 16kHz, 16-bit, mono PCM
void sendAudio(LiveSession session, List<int> pcmBytes) {
  session.sendAudio(pcmBytes);
}
```

</details>

<details>
<summary><b>Manual Voice Activity Detection</b></summary>

```dart
// For manual VAD mode (when automaticActivityDetection.disabled = true)
void manualVAD(LiveSession session) {
  // Signal when user starts speaking
  session.signalActivityStart();

  // ... user speaks ...

  // Signal when user stops speaking
  session.signalActivityEnd();
}
```

</details>

<details>
<summary><b>Session Resumption</b></summary>

```dart
// Resume a previous session
final session = await liveClient.resume(
  model: 'gemini-2.0-flash-live-001',
  resumptionToken: savedToken, // From previous session
  liveConfig: LiveConfig(
    generationConfig: LiveGenerationConfig.textAndAudio(),
  ),
);

print('Session resumed! ID: ${session.sessionId}');
```

</details>

<details>
<summary><b>Ephemeral Tokens (Secure Client-Side Auth)</b></summary>

For client-side applications (mobile apps, web apps), use ephemeral tokens instead of exposing your API key:

**Server-side (create token):**

```dart
// On your backend server
final token = await client.authTokens.create(
  authToken: AuthToken(
    expireTime: DateTime.now().add(Duration(minutes: 30)),
    uses: 1, // Single use
  ),
);
// Send token.name to client securely
```

**Client-side (use token):**

```dart
// On mobile/web client - no API key needed!
final liveClient = LiveClient(
  config: GoogleAIConfig.googleAI(
    authProvider: NoAuthProvider(), // No API key
  ),
);

final session = await liveClient.connect(
  model: 'gemini-2.0-flash-live-001',
  accessToken: tokenFromServer, // Use ephemeral token
);
```

> **Note**: Ephemeral tokens are only available with Google AI (not Vertex AI).

</details>

<details>
<summary><b>Platform Notes</b></summary>

**Web (Browser) Limitations:**

- Browser WebSocket API does NOT support custom HTTP headers during handshake
- Google AI: Works on web via query parameter authentication (`?key=...` or `?access_token=...`)
- Vertex AI OAuth: Requires Bearer token in headers, which doesn't work in browsers
- **Recommendation**: For Vertex AI on web, use a backend proxy or ephemeral tokens with Google AI

**Audio Streaming Notes:**

- Audio data is base64-encoded before sending (~33% size overhead)
- The underlying WebSocket handles buffering automatically
- Audio format: 16kHz, 16-bit PCM mono input (32 KB/s raw, ~43 KB/s encoded)
- Output audio: 24kHz, 16-bit PCM mono

</details>

## Migrating from Google AI to Vertex AI

Switching from Google AI to Vertex AI requires minimal code changes:

### Step 1: Change Configuration

<details>
<summary><b>Configuration Migration Examples</b></summary>

**Before (Google AI):**

```dart
import 'package:googleai_dart/googleai_dart.dart';

final client = GoogleAIClient(
  config: GoogleAIConfig.googleAI(
    authProvider: ApiKeyProvider('YOUR_API_KEY'),
  ),
);
```

**After (Vertex AI):**

```dart
import 'package:googleai_dart/googleai_dart.dart';

final client = GoogleAIClient(
  config: GoogleAIConfig.vertexAI(
    projectId: 'your-project-id',
    location: 'us-central1',
    authProvider: MyOAuthProvider(), // Implement OAuth
  ),
);
```

</details>

### Step 2: Replace Google AI-Only Features

If you use any of these features, you'll need to use Vertex AI alternatives:

| Google AI Feature | Vertex AI Alternative |
|-------------------|----------------------|
| `client.files.upload()` | Upload to Cloud Storage, use `gs://` URIs in requests |
| `client.tunedModels.*` | Use [Vertex AI Tuning API](https://cloud.google.com/vertex-ai/docs/tuning) directly |
| `client.corpora.*` | Use [Vertex AI RAG Stores](https://cloud.google.com/vertex-ai/docs/grounding) |
| `client.models.generateAnswer()` | Use `generateContent()` with grounding |

## Examples

See the [`example/`](example/) directory for comprehensive examples:

1. **[generate_content.dart](example/generate_content.dart)** - Basic content generation
2. **[streaming_example.dart](example/streaming_example.dart)** - Real-time SSE streaming
3. **[function_calling_example.dart](example/function_calling_example.dart)** - Tool usage with functions
4. **[embeddings_example.dart](example/embeddings_example.dart)** - Text embeddings generation
5. **[error_handling_example.dart](example/error_handling_example.dart)** - Exception handling patterns
6. **[abort_example.dart](example/abort_example.dart)** - Request cancellation
7. **[models_example.dart](example/models_example.dart)** - Model listing and inspection
8. **[files_example.dart](example/files_example.dart)** - File upload and management
9. **[pagination_example.dart](example/pagination_example.dart)** - Paginated API calls
10. **[batch_example.dart](example/batch_example.dart)** - Batch operations
11. **[caching_example.dart](example/caching_example.dart)** - Context caching for cost/latency optimization
12. **[permissions_example.dart](example/permissions_example.dart)** - Permission management
13. **[oauth_refresh_example.dart](example/oauth_refresh_example.dart)** - OAuth token refresh with AuthProvider
14. **[prediction_example.dart](example/prediction_example.dart)** - Video generation with Veo model
15. **[generate_answer_example.dart](example/generate_answer_example.dart)** - Grounded question answering with inline passages or semantic retriever
16. **[tuned_model_generation_example.dart](example/tuned_model_generation_example.dart)** - Generate content with custom tuned models
17. **[api_versions_example.dart](example/api_versions_example.dart)** - Using v1 (stable) vs v1beta (beta)
18. **[vertex_ai_example.dart](example/vertex_ai_example.dart)** - Using Vertex AI with OAuth authentication
19. **[complete_api_example.dart](example/complete_api_example.dart)** - Demonstrating 100% API coverage
20. **[interactions_example.dart](example/interactions_example.dart)** - Interactions API for server-side state management (experimental)
21. **[google_search_example.dart](example/google_search_example.dart)** - Google Search grounding for real-time web information
22. **[url_context_example.dart](example/url_context_example.dart)** - URL Context for fetching and analyzing web content
23. **[google_maps_example.dart](example/google_maps_example.dart)** - Google Maps grounding for geospatial context
24. **[file_search_example.dart](example/file_search_example.dart)** - File Search with FileSearchStores for semantic retrieval (RAG)
25. **[live_example.dart](example/live_example.dart)** - Live API for real-time WebSocket streaming (audio/text)

## API Coverage

This client implements **78 endpoints** covering **100% of all non-deprecated Gemini API operations**:

### Models Resource (`client.models`)

- **Generation**: generateContent, streamGenerateContent, countTokens, generateAnswer
- **Dynamic Content**: dynamicGenerateContent, dynamicStreamGenerateContent (for live content with dynamic IDs)
- **Embeddings**: embedContent, batchEmbedContents (synchronous), asyncBatchEmbedContent (asynchronous)
- **Prediction**: predict, predictLongRunning (for video generation with Veo)
- **Model Management**: list, get, listOperations, create, patch, delete

### Tuned Models Resource (`client.tunedModels`)

- **Generation**: generateContent, streamGenerateContent, batchGenerateContent, asyncBatchEmbedContent
- **Management**: list, get
- **Operations**: operations(parent).list
- **Permissions**: permissions(parent).create, permissions(parent).list, permissions(parent).get, permissions(parent).update, permissions(parent).delete, permissions(parent).transferOwnership

### Files Resource (`client.files`)

- **Management**: upload, list, get, delete, download
- **Upload Methods**:
  - `filePath`: Upload from file system (IO platforms, streaming)
  - `bytes`: Upload from memory (all platforms)
  - `contentStream`: Upload large files via streaming (IO platforms, memory efficient)
- **Generated Files**: generatedFiles.list, generatedFiles.get, generatedFiles.getOperation (for video outputs)

### Cached Contents Resource (`client.cachedContents`)

- **Management**: create, get, update, delete, list

### Batches Resource (`client.batches`)

- **Management**: list, getGenerateContentBatch, getEmbedBatch, updateGenerateContentBatch, updateEmbedContentBatch, delete, cancel

### Corpora Resource (`client.corpora`)

- **Corpus Management**: create, list, get, update, delete
- **Document Management**: documents(corpus).create, documents(corpus).list, documents(corpus).get, documents(corpus).update, documents(corpus).delete
- **Permissions**: permissions(parent).create, permissions(parent).list, permissions(parent).get, permissions(parent).update, permissions(parent).delete

### FileSearchStores Resource (`client.fileSearchStores`)

- **Store Management**: create, list, get, delete
- **Document Operations**: importFile, uploadToFileSearchStore
- **Document Management**: documents.list, documents.get, documents.delete
- **Operations**: getOperation, getUploadOperation

### Interactions Resource (`client.interactions`) - Experimental

- **Creation**: create, createWithAgent, createStream
- **Management**: get, cancel, delete
- **Streaming**: createStream, resumeStream (SSE with event types)
- **Content Types**: 17 types including text, image, audio, function calls, code execution, etc.
- **Events**: InteractionStart, ContentDelta, ContentStop, InteractionComplete, Error

### Auth Tokens Resource (`client.authTokens`)

- **Management**: create (creates ephemeral tokens for secure client-side authentication)

### Live API (`client.createLiveClient()`)

- **Connection**: connect, resume (WebSocket streaming, ephemeral token support)
- **Client Messages**: setup, clientContent, realtimeInput, toolResponse
- **Server Messages**: setupComplete, serverContent, toolCall, toolCallCancellation, goAway, sessionResumptionUpdate, unknownServerMessage
- **Session Methods**: sendText, sendAudio, sendContent, sendToolResponse, signalActivityStart, signalActivityEnd
- **Configuration**: LiveConfig, LiveGenerationConfig, SpeechConfig, RealtimeInputConfig, SessionResumptionConfig
- **Audio Format**: 16kHz/16-bit/mono PCM input, 24kHz/16-bit/mono PCM output

### Universal Operations

- **getOperation**: Available for all long-running operations

## Development

```bash
# Install dependencies
dart pub get

# Run tests
dart test

# Format code
dart format .

# Analyze
dart analyze
```

## License

**googleai_dart** is licensed under the [MIT License](https://github.com/davidmigloz/langchain_dart/blob/main/LICENSE).
