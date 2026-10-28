import 'package:googleai_dart/googleai_dart.dart' as g;
import 'package:langchain_core/language_models.dart';
import 'package:langchain_core/llms.dart';
import 'package:langchain_core/prompts.dart';
import 'package:uuid/uuid.dart';

import '../../utils/auth/http_client_auth_provider.dart';
import 'mappers.dart';
import 'types.dart';

/// {@template vertex_ai}
/// Wrapper around GCP Vertex AI text models API (Gemini API).
///
/// Example:
/// ```dart
/// final authProvider = HttpClientAuthProvider(
///   credentials: ServiceAccountCredentials.fromJson({...}),
///   scopes: ['https://www.googleapis.com/auth/cloud-platform'],
/// );
/// final llm = VertexAI(
///   authProvider: authProvider,
///   project: 'your-project-id',
/// );
/// final result = await llm('Hello world!');
/// ```
///
/// Vertex AI documentation:
/// https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/overview
///
/// ### Set up your Google Cloud Platform project
///
/// 1. [Select or create a Google Cloud project](https://console.cloud.google.com/cloud-resource-manager).
/// 2. [Make sure that billing is enabled for your project](https://cloud.google.com/billing/docs/how-to/modify-project).
/// 3. [Enable the Vertex AI API](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com).
/// 4. [Configure the Vertex AI location](https://cloud.google.com/vertex-ai/docs/general/locations).
///
/// ### Authentication
///
/// To create an instance of `VertexAI` you need to provide an
/// [HttpClientAuthProvider] that wraps your service account credentials.
///
/// Example using a service account JSON:
///
/// ```dart
/// final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
///   json.decode(serviceAccountJson),
/// );
/// final authProvider = HttpClientAuthProvider(
///   credentials: serviceAccountCredentials,
///   scopes: ['https://www.googleapis.com/auth/cloud-platform'],
/// );
/// final llm = VertexAI(
///   authProvider: authProvider,
///   project: 'your-project-id',
/// );
/// ```
///
/// The service account should have the following
/// [permission](https://cloud.google.com/vertex-ai/docs/general/iam-permissions):
/// - `aiplatform.endpoints.predict`
///
/// The required [OAuth2 scope](https://developers.google.com/identity/protocols/oauth2/scopes)
/// is:
/// - `https://www.googleapis.com/auth/cloud-platform` (you can use the
///   constant [VertexAI.cloudPlatformScope])
///
/// See: https://cloud.google.com/vertex-ai/docs/generative-ai/access-control
///
/// ### Available models
///
/// **Latest stable models:**
///
/// - `gemini-2.5-flash` (recommended):
///   * Multimodal input and text output
///   * Context window: 1M tokens
///   * Max output: 8,192 tokens
///
/// - `gemini-2.0-flash-exp`:
///   * Multimodal input and output
///   * Context window: 1M tokens
///   * Max output: 8,192 tokens
///
/// - `gemini-1.5-pro`:
///   * Multimodal input and text output
///   * Context window: 2M tokens
///   * Max output: 8,192 tokens
///
/// - `gemini-1.5-flash`:
///   * Multimodal input and text output
///   * Context window: 1M tokens
///   * Max output: 8,192 tokens
///
/// The previous list of models may not be exhaustive or up-to-date. Check out
/// the [Vertex AI documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions#latest-stable)
/// for the latest stable models.
///
/// ### Model options
///
/// You can define default options to use when calling the model (e.g.
/// temperature, stop sequences, etc.) using the [defaultOptions] parameter.
///
/// The default options can be overridden when calling the model using the
/// `options` parameter.
///
/// Example:
/// ```dart
/// final llm = VertexAI(
///   authProvider: authProvider,
///   project: 'your-project-id',
///   defaultOptions: VertexAIOptions(
///     temperature: 0.9,
///   ),
/// );
/// final result = await llm(
///   'Hello world!',
///   options: VertexAIOptions(
///     temperature: 0.5,
///   ),
/// );
/// ```
/// {@endtemplate}
class VertexAI extends BaseLLM<VertexAIOptions> {
  /// {@macro vertex_ai}
  VertexAI({
    required final HttpClientAuthProvider authProvider,
    required final String project,
    final String location = 'us-central1',
    super.defaultOptions = const VertexAIOptions(model: defaultModel),
  }) : _currentModel = defaultOptions.model ?? defaultModel {
    _googleAiClient = g.GoogleAIClient(
      config: g.GoogleAIConfig.vertexAI(
        projectId: project,
        location: location,
        authProvider: authProvider,
      ),
    );
  }

  /// A client for interacting with Vertex AI API.
  late g.GoogleAIClient _googleAiClient;

  /// Scope required for Vertex AI API calls.
  static const String cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// A UUID generator.
  late final _uuid = const Uuid();

  /// The current model.
  String _currentModel;

  @override
  String get modelType => 'vertex-ai';

  /// The default model to use unless another is specified.
  static const defaultModel = 'gemini-2.5-flash';

  @override
  Future<LLMResult> invoke(
    final PromptValue input, {
    final VertexAIOptions? options,
  }) async {
    final id = _uuid.v4();
    _updateCurrentModel(options);

    final request = _generateCompletionRequest(
      input.toString(),
      options: options,
    );
    final response = await _googleAiClient.models.generateContent(
      model: _currentModel,
      request: request,
    );

    return response.toLLMResult(id, _currentModel);
  }

  @override
  Stream<LLMResult> stream(
    final PromptValue input, {
    final VertexAIOptions? options,
  }) {
    final id = _uuid.v4();
    _updateCurrentModel(options);

    final request = _generateCompletionRequest(
      input.toString(),
      options: options,
    );
    return _googleAiClient.models
        .streamGenerateContent(model: _currentModel, request: request)
        .map((final response) => response.toLLMResult(id, _currentModel));
  }

  @override
  Future<List<int>> tokenize(
    final PromptValue promptValue, {
    final VertexAIOptions? options,
  }) {
    throw UnsupportedError(
      'Vertex AI does not expose a tokenizer, only counting tokens is supported.',
    );
  }

  @override
  Future<int> countTokens(
    final PromptValue promptValue, {
    final VertexAIOptions? options,
  }) async {
    _updateCurrentModel(options);

    final request = _generateCompletionRequest(
      promptValue.toString(),
      options: options,
    );
    final response = await _googleAiClient.models.countTokens(
      model: _currentModel,
      request: g.CountTokensRequest(
        contents: request.contents,
        systemInstruction: request.systemInstruction,
      ),
    );
    return response.totalTokens;
  }

  /// Creates a [g.GenerateContentRequest] from the given input.
  g.GenerateContentRequest _generateCompletionRequest(
    final String prompt, {
    final VertexAIOptions? options,
  }) {
    final mergedOptions = options != null
        ? defaultOptions.merge(options)
        : defaultOptions;

    return g.GenerateContentRequest(
      contents: [
        g.Content(parts: [g.TextPart(prompt)]),
      ],
      generationConfig: g.GenerationConfig(
        temperature: mergedOptions.temperature,
        topP: mergedOptions.topP,
        topK: mergedOptions.topK,
        candidateCount: mergedOptions.candidateCount,
        maxOutputTokens: mergedOptions.maxOutputTokens,
        stopSequences: mergedOptions.stopSequences ?? const [],
      ),
    );
  }

  /// Updates the current model if needed.
  void _updateCurrentModel(final VertexAIOptions? options) {
    final model = options?.model ?? defaultOptions.model ?? defaultModel;
    if (model != _currentModel) {
      _currentModel = model;
    }
  }

  /// {@template vertex_ai_llm_list_models}
  /// Returns a list of available models from Vertex AI.
  ///
  /// This method filters models to return only those that support text
  /// generation (generateContent method).
  ///
  /// Example:
  /// ```dart
  /// final llm = VertexAI(
  ///   authProvider: authProvider,
  ///   project: 'your-project-id',
  /// );
  /// final models = await llm.listModels();
  /// for (final model in models) {
  ///   print('${model.id} - ${model.displayName}');
  ///   print('  Input limit: ${model.inputTokenLimit}');
  ///   print('  Output limit: ${model.outputTokenLimit}');
  /// }
  /// ```
  /// {@endtemplate}
  @override
  Future<List<ModelInfo>> listModels() async {
    final models = <g.Model>[];
    String? pageToken;

    // Paginate through all models
    do {
      final response = await _googleAiClient.models.list(pageToken: pageToken);
      models.addAll(response.models);
      pageToken = response.nextPageToken;
    } while (pageToken != null);

    // Filter to only models supporting generateContent
    return models
        .where(_isGenerativeModel)
        .map(
          (final m) => ModelInfo(
            id: _extractModelId(m.name),
            displayName: m.displayName,
            description: m.description,
            inputTokenLimit: m.inputTokenLimit,
            outputTokenLimit: m.outputTokenLimit,
          ),
        )
        .toList();
  }

  /// Returns true if the model supports text generation (generateContent).
  static bool _isGenerativeModel(final g.Model model) {
    return model.supportedGenerationMethods?.contains('generateContent') ??
        false;
  }

  /// Extracts the model ID from the full model name.
  static String _extractModelId(final String name) {
    const prefix = 'models/';
    if (name.startsWith(prefix)) {
      return name.substring(prefix.length);
    }
    return name;
  }

  /// Closes the client and cleans up any resources associated with it.
  @override
  void close() {
    _googleAiClient.close();
  }
}
