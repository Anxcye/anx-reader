## 3.0.0

> Note: This release has breaking changes.

 - **FEAT**(googleai_dart): add convenience helpers for improved DX ([#924](https://github.com/davidmigloz/langchain_dart/issues/924)). ([634b4f97](https://github.com/davidmigloz/langchain_dart/commit/634b4f970ec3264cddaa6e42d7d03fc8af3593ff))
 - **FEAT**(googleai_dart): Update default models to Gemini 3 family ([#922](https://github.com/davidmigloz/langchain_dart/issues/922)). ([62bca9da](https://github.com/davidmigloz/langchain_dart/commit/62bca9da1abc4a64267c2d3085ad969cad33f4d6))
 - **FEAT**(googleai_dart): Auto-populate batch.model from method parameter ([#921](https://github.com/davidmigloz/langchain_dart/issues/921)). ([abfeded8](https://github.com/davidmigloz/langchain_dart/commit/abfeded8f602b1db28d0f8f35f4e275982a7fed6))
 - **BREAKING** **FEAT**(googleai_dart): replace List<dynamic> with strongly-typed lists ([#923](https://github.com/davidmigloz/langchain_dart/issues/923)). ([403d5319](https://github.com/davidmigloz/langchain_dart/commit/403d5319d67fb39298cc6182d883a8e2f1b731f8))

## 2.1.0

 - **FEAT**(googleai_dart): Add Gemini Live API (WebSocket) support ([#920](https://github.com/davidmigloz/langchain_dart/issues/920)). ([4beb01dd](https://github.com/davidmigloz/langchain_dart/commit/4beb01dd532582257e3d06c1619da1ee1793c5f4))
 - **FEAT**(googleai_dart): Add missing model properties from OpenAPI spec ([#916](https://github.com/davidmigloz/langchain_dart/issues/916)). ([fc0e2f8a](https://github.com/davidmigloz/langchain_dart/commit/fc0e2f8ac70ccb8fc8bc3992f76aa05f90d81690))
 - **DOCS**(googleai_dart): Add documentation for grounding tools ([#917](https://github.com/davidmigloz/langchain_dart/issues/917)). ([b5a529fe](https://github.com/davidmigloz/langchain_dart/commit/b5a529fe015095e2a8c4dfff32c2b5155eb608fa))

## 2.0.0

> Note: This release has breaking changes.

 - **BREAKING** **FEAT**(googleai_dart): Remove deprecated schema fields ([#848](https://github.com/davidmigloz/langchain_dart/issues/848)). ([e6d07ec4](https://github.com/davidmigloz/langchain_dart/commit/e6d07ec4a94d1b09e9dbd71f30904d510fb749c6))
 - **BREAKING** **FEAT**(googleai_dart): Remove deprecated Chunks and query APIs ([#847](https://github.com/davidmigloz/langchain_dart/issues/847)). ([9cae76d5](https://github.com/davidmigloz/langchain_dart/commit/9cae76d534d45bcd36622216a0926bfbc8800d86))
 - **BREAKING** **FEAT**(googleai_dart): Remove deprecated RagStores resource ([#846](https://github.com/davidmigloz/langchain_dart/issues/846)). ([1ab553f1](https://github.com/davidmigloz/langchain_dart/commit/1ab553f1da173dbed72a1d9089e56ce11b78eac6))
 - **FEAT**(googleai_dart): Add InteractionsResource and client integration ([#905](https://github.com/davidmigloz/langchain_dart/issues/905)). ([af6b13ea](https://github.com/davidmigloz/langchain_dart/commit/af6b13ea3c91ca4f05196940505d3eddb5c55831))
 - **FEAT**(googleai_dart): Add Interactions API tool types ([#904](https://github.com/davidmigloz/langchain_dart/issues/904)). ([2258cfa1](https://github.com/davidmigloz/langchain_dart/commit/2258cfa187cb011eddfa204d7f2a68a2ab329a37))
 - **FEAT**(googleai_dart): Add Interactions API events and deltas ([#903](https://github.com/davidmigloz/langchain_dart/issues/903)). ([826d3f64](https://github.com/davidmigloz/langchain_dart/commit/826d3f64845eb7178b9567f5193951796f476ea1))
 - **FEAT**(googleai_dart): Add Interactions API content types ([#902](https://github.com/davidmigloz/langchain_dart/issues/902)). ([b8c61743](https://github.com/davidmigloz/langchain_dart/commit/b8c61743e2e6ffa9cd6cd44df289135f6250b30d))
 - **FEAT**(googleai_dart): Add Interactions API core models ([#901](https://github.com/davidmigloz/langchain_dart/issues/901)). ([65f5db17](https://github.com/davidmigloz/langchain_dart/commit/65f5db17d91282bfc7edaca7e9fcb97b505631c6))
 - **FEAT**(googleai_dart): Update existing models with new properties ([#856](https://github.com/davidmigloz/langchain_dart/issues/856)). ([dd3893e0](https://github.com/davidmigloz/langchain_dart/commit/dd3893e07e78f2ce852ba26fd7e67744402ec11a))
 - **FEAT**(googleai_dart): Add RetrievalConfig to ToolConfig ([#855](https://github.com/davidmigloz/langchain_dart/issues/855)). ([5e11aa70](https://github.com/davidmigloz/langchain_dart/commit/5e11aa7000d74dfc09201620e38670c505cc525b))
 - **FEAT**(googleai_dart): Add MediaResolution to Part ([#854](https://github.com/davidmigloz/langchain_dart/issues/854)). ([df76f8c5](https://github.com/davidmigloz/langchain_dart/commit/df76f8c5b967efd5ac11aa83760459b71e55a000))
 - **FEAT**(googleai_dart): Add GoogleMaps tool ([#853](https://github.com/davidmigloz/langchain_dart/issues/853)). ([54814614](https://github.com/davidmigloz/langchain_dart/commit/548146143cfe48c4f24c9644d27b88550b816904))
 - **FEAT**(googleai_dart): Add McpServers tool ([#852](https://github.com/davidmigloz/langchain_dart/issues/852)). ([97970687](https://github.com/davidmigloz/langchain_dart/commit/97970687d43ff8dea4c6a87633d0e82287eedc30))
 - **FEAT**(googleai_dart): Add FileSearch tool ([#851](https://github.com/davidmigloz/langchain_dart/issues/851)). ([a00895b1](https://github.com/davidmigloz/langchain_dart/commit/a00895b1e264164894b56f6cf7dccea5f3c6c5b6))
 - **FEAT**(googleai_dart): Add grounding models ([#850](https://github.com/davidmigloz/langchain_dart/issues/850)). ([bb1a6228](https://github.com/davidmigloz/langchain_dart/commit/bb1a62286d5e04b612e148a4e55bceacf289e57c))
 - **FEAT**(googleai_dart): Add FileSearchStores resource ([#849](https://github.com/davidmigloz/langchain_dart/issues/849)). ([acb63d72](https://github.com/davidmigloz/langchain_dart/commit/acb63d72f03af13c1e1d4ff62f3f5e43a3ec34fd))
 - **FEAT**(googleai_dart): Add ThinkingConfig support to GenerationConfig ([#817](https://github.com/davidmigloz/langchain_dart/issues/817)). ([36de62a9](https://github.com/davidmigloz/langchain_dart/commit/36de62a9c65b24d9db35589772e053bb9c090035))
 - **FIX**(googleai_dart): Complete alignment with target implementation ([#884](https://github.com/davidmigloz/langchain_dart/issues/884)). ([60476e8d](https://github.com/davidmigloz/langchain_dart/commit/60476e8db17ca9badba217269169f3f8eb11a318))
 - **DOCS**(googleai_dart): Add Interactions API docs and example ([#897](https://github.com/davidmigloz/langchain_dart/issues/897)). ([f4a04677](https://github.com/davidmigloz/langchain_dart/commit/f4a04677e1e0743f85ca7f06756ba148c49cad01))

## 1.1.0

 - **FEAT**: Make googleai_dart fully WASM compatible ([#808](https://github.com/davidmigloz/langchain_dart/issues/808)). ([07e597f3](https://github.com/davidmigloz/langchain_dart/commit/07e597f3984b2c0396ebfb5ae7e981bb52872368))
 - **REFACTOR**: Fix pub format warnings ([#809](https://github.com/davidmigloz/langchain_dart/issues/809)). ([640cdefb](https://github.com/davidmigloz/langchain_dart/commit/640cdefbede9c0a0182fb6bb4005a20aa6f35635))

## 1.0.0

> Note: This release has breaking changes.

**TL;DR**: Complete reimplementation with a new architecture, minimal dependencies, unified resource-based API, and full Gemini API coverage. Includes new Files, Batches, Caching, Corpora/RAG, RAG Stores, Dynamic Content, Permissions, Tuned Models, and Prediction (Veo) support.

### What's new

- **Unified client for both**:
  - Google AI Gemini Developer API
  - Vertex AI Gemini API
- **Complete API coverage**: 78 endpoints.
  - **Files API**: upload, list, get, delete, download.
  - **Generated Files API**: list, get, getOperation (video outputs).
  - **Cached Contents**: full CRUD.
  - **Batch operations**: batchGenerateContent, batchEmbedContents, asyncBatchEmbedContent with LRO polling.
  - **Corpora & RAG**: corpus CRUD (Google AI); documents/chunks/query, metadata filters, batch chunk ops (Vertex AI only).
  - **RAG Stores**: documents list/create/get/delete/query + operations.
  - **Dynamic Content**: generate/stream content with dynamic model IDs.
  - **Permissions**: create/list/get/update/delete/transferOwnership for eligible resources.
  - **Tuned Models**: list, get, listOperations, generation APIs.
  - **Prediction (Veo)**: predict, predictLongRunning, operation polling, RAI filtering.
- **Architecture**:
  - Interceptor chain (Auth → Logging → Error).
  - **Authentication**: API key, Bearer token, custom OAuth via `AuthProvider`.
  - **Retry** with exponential backoff + jitter.
  - **Abortable** requests via `abortTrigger` (streaming and non-streaming).
  - **SSE** streaming parser.
  - Central `GoogleAIConfig` (timeouts, retry policy, log level, baseUrl).
- **Testing**:
  - **560+ tests** covering all endpoints, error branches, streaming/abort flows.

### Breaking Changes

- **Resource-based API**: Methods reorganized under strongly-typed resources:
  - `client.models.*` (generation, streaming, embeddings, tokens, prediction)
  - `client.tunedModels.*`
  - `client.files.*`, `client.generatedFiles.*`
  - `client.cachedContents.*`
  - `client.batches.*`
  - `client.corpora.*`
  - `client.ragStores.*`
- **Parameter rename**: `modelId` → `model`.
- **Configuration**: New `GoogleAIConfig` with `AuthProvider` pattern (API key / bearer / custom OAuth).
- **Exceptions**: Replaced ad-hoc errors with a typed hierarchy:
  - `ApiException`, `ValidationException`, `RateLimitException`, `TimeoutException`, `AbortedException`.
- **Dependencies**: Removed `fetch_client`; now minimal (`http`, `logging`).

See **[MIGRATION.md](MIGRATION.md)** for step-by-step examples and mapping tables.

## 0.1.3

- **FEAT**: Migrate to Freezed v3 ([#773](https://github.com/davidmigloz/langchain_dart/issues/773)). ([f87c8c03](https://github.com/davidmigloz/langchain_dart/commit/f87c8c03711ef382d2c9de19d378bee92e7631c1))

## 0.1.2

- **BUILD**: Update dependencies ([#751](https://github.com/davidmigloz/langchain_dart/issues/751)). ([250a3c6](https://github.com/davidmigloz/langchain_dart/commit/250a3c6a6c1815703a61a142ba839c0392a31015))

## 0.1.1

- **FEAT**: Update dependencies (requires Dart 3.6.0) ([#709](https://github.com/davidmigloz/langchain_dart/issues/709)). ([9e3467f7](https://github.com/davidmigloz/langchain_dart/commit/9e3467f7caabe051a43c0eb3c1110bc4a9b77b81))
- **REFACTOR**: Remove fetch_client dependency in favor of http v1.3.0 ([#659](https://github.com/davidmigloz/langchain_dart/issues/659)). ([0e0a685c](https://github.com/davidmigloz/langchain_dart/commit/0e0a685c376895425dbddb0f9b83758c700bb0c7))
- **FIX**: Fix linter issues ([#656](https://github.com/davidmigloz/langchain_dart/issues/656)). ([88a79c65](https://github.com/davidmigloz/langchain_dart/commit/88a79c65aad23bcf5859e58a7375a4b686cf02ef))

## 0.1.0+3

- **REFACTOR**: Upgrade api clients generator version ([#610](https://github.com/davidmigloz/langchain_dart/issues/610)). ([0c8750e8](https://github.com/davidmigloz/langchain_dart/commit/0c8750e85b34764f99b6e34cc531776ffe8fba7c))

## 0.1.0+2

- **REFACTOR**: Migrate conditional imports to js_interop ([#453](https://github.com/davidmigloz/langchain_dart/issues/453)). ([a6a78cfe](https://github.com/davidmigloz/langchain_dart/commit/a6a78cfe05fb8ce68e683e1ad4395ca86197a6c5))

## 0.1.0+1

- **FIX**: Fix deserialization of sealed classes ([#435](https://github.com/davidmigloz/langchain_dart/issues/435)). ([7b9cf223](https://github.com/davidmigloz/langchain_dart/commit/7b9cf223e42eae8496f864ad7ef2f8d0dca45678))

## 0.1.0

- **REFACTOR**: Minor changes ([#407](https://github.com/davidmigloz/langchain_dart/issues/407)). ([fa4b5c37](https://github.com/davidmigloz/langchain_dart/commit/fa4b5c376a191fea50c3f8b1d6b07cef0480a74e))

## 0.0.4

- **FEAT**: Support generateContent for tuned model in googleai_dart client ([#358](https://github.com/davidmigloz/langchain_dart/issues/358)). ([b4641a09](https://github.com/davidmigloz/langchain_dart/commit/b4641a09af7f6d67d503d526451a370eca920c5c))
- **FEAT**: Support output dimensionality in Google AI Embeddings ([#373](https://github.com/davidmigloz/langchain_dart/issues/373)). ([6dcb27d8](https://github.com/davidmigloz/langchain_dart/commit/6dcb27d861fa65d2c882e31ce28e8c0a92b65cc1))
- **FEAT**: Support updating API key in Google AI client ([#357](https://github.com/davidmigloz/langchain_dart/issues/357)). ([b9b808e7](https://github.com/davidmigloz/langchain_dart/commit/b9b808e72f02b9f38ab355d581284a0d848d4bd1))
- **FIX**: Have the == implementation use Object instead of dynamic ([#334](https://github.com/davidmigloz/langchain_dart/issues/334)). ([89f7b0b9](https://github.com/davidmigloz/langchain_dart/commit/89f7b0b94144c216de19ec7244c48f3c34c2c635))

## 0.0.3

- **FEAT**: Add streaming support to googleai_dart client ([#299](https://github.com/davidmigloz/langchain_dart/issues/299)). ([2cbd538a](https://github.com/davidmigloz/langchain_dart/commit/2cbd538a3b67ef6bdd9ab7b92bebc3c8c7a1bea1))
- **FEAT**: Update meta and test dependencies ([#331](https://github.com/davidmigloz/langchain_dart/issues/331)). ([912370ee](https://github.com/davidmigloz/langchain_dart/commit/912370ee0ba667ee9153303395a457e6caf5c72d))
- **DOCS**: Update pubspecs. ([d23ed89a](https://github.com/davidmigloz/langchain_dart/commit/d23ed89adf95a34a78024e2f621dc0af07292f44))

## 0.0.2+2

- **DOCS**: Update CHANGELOG.md. ([d0d46534](https://github.com/davidmigloz/langchain_dart/commit/d0d46534565d6f52d819d62329e8917e00bc7030))

## 0.0.2+1

- **REFACTOR**: Make all LLM options fields nullable and add copyWith ([#284](https://github.com/davidmigloz/langchain_dart/issues/284)). ([57eceb9b](https://github.com/davidmigloz/langchain_dart/commit/57eceb9b47da42cf19f64ddd88bfbd2c9676fd5e))

## 0.0.2

- Update a dependency to the latest release.

## 0.0.1+1

- **FIX**: Fetch web requests with big payloads dropping connection ([#273](https://github.com/davidmigloz/langchain_dart/issues/273)). ([425889dc](https://github.com/davidmigloz/langchain_dart/commit/425889dc24a74790a7072c75f0bdb0d19ab40cf6))

## 0.0.1

- **FEAT**: Implement Dart client for Google AI API ([#267](https://github.com/davidmigloz/langchain_dart/issues/267)). ([99083cd2](https://github.com/davidmigloz/langchain_dart/commit/99083cd22ec35b3256b800ce76df328b9c9165e4))

## 0.0.1-dev.1

- Bootstrap project.
