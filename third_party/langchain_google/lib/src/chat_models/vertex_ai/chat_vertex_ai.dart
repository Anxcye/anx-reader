import 'package:collection/collection.dart';
import 'package:googleai_dart/googleai_dart.dart' as g;
import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/prompts.dart';
import 'package:uuid/uuid.dart';

import '../../utils/auth/http_client_auth_provider.dart';
import 'mappers.dart';
import 'types.dart';

/// {@template chat_vertex_ai}
/// Wrapper around GCP Vertex AI chat models API (Gemini API).
///
/// Example:
/// ```dart
/// final authProvider = HttpClientAuthProvider(
///   credentials: ServiceAccountCredentials.fromJson({...}),
///   scopes: ['https://www.googleapis.com/auth/cloud-platform'],
/// );
/// final chatModel = ChatVertexAI(
///   authProvider: authProvider,
///   project: 'your-project-id',
/// );
/// final result = await chatModel([ChatMessage.humanText('Hello')]);
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
/// To create an instance of `ChatVertexAI` you need to provide an
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
/// final chatModel = ChatVertexAI(
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
///   constant [ChatVertexAI.cloudPlatformScope])
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
/// ### Call options
///
/// You can configure the parameters that will be used when calling the
/// chat completions API in several ways:
///
/// **Default options:**
///
/// Use the [defaultOptions] parameter to set the default options. These
/// options will be used unless you override them when generating completions.
///
/// ```dart
/// final chatModel = ChatVertexAI(
///   authProvider: authProvider,
///   project: 'your-project-id',
///   defaultOptions: ChatVertexAIOptions(
///     temperature: 0,
///   ),
/// );
/// ```
///
/// **Call options:**
///
/// You can override the default options when invoking the model:
///
/// ```dart
/// final res = await chatModel.invoke(
///   PromptValue.string('Tell me a joke'),
///   options: const ChatVertexAIOptions(temperature: 1),
/// );
/// ```
///
/// **Bind:**
///
/// You can also change the options in a [Runnable] pipeline using the bind
/// method.
///
/// In this example, we are using two totally different models for each
/// question:
///
/// ```dart
/// final chatModel = ChatVertexAI(
///   authProvider: authProvider,
///   project: 'your-project-id',
/// );
/// const outputParser = StringOutputParser();
/// final prompt1 = PromptTemplate.fromTemplate('How are you {name}?');
/// final prompt2 = PromptTemplate.fromTemplate('How old are you {name}?');
/// final chain = Runnable.fromMap({
///   'q1': prompt1 | chatModel.bind(const ChatVertexAIOptions(model: 'gemini-2.5-flash')) | outputParser,
///   'q2': prompt2 | chatModel.bind(const ChatVertexAIOptions(model: 'gemini-1.5-pro')) | outputParser,
/// });
/// final res = await chain.invoke({'name': 'David'});
/// ```
///
/// ### Tool calling
///
/// [ChatVertexAI] supports tool calling (aka function calling).
///
/// Check the [docs](https://langchaindart.dev/#/modules/model_io/models/chat_models/how_to/tools)
/// for more information on how to use tools.
///
/// Example:
/// ```dart
/// const tool = ToolSpec(
///   name: 'get_current_weather',
///   description: 'Get the current weather in a given location',
///   inputJsonSchema: {
///     'type': 'object',
///     'properties': {
///       'location': {
///         'type': 'string',
///         'description': 'The city and state, e.g. San Francisco, CA',
///       },
///     },
///     'required': ['location'],
///   },
/// );
/// final chatModel = ChatVertexAI(
///   authProvider: authProvider,
///   project: 'your-project-id',
///   defaultOptions: ChatVertexAIOptions(
///     model: 'gemini-2.5-flash',
///     temperature: 0,
///     tools: [tool],
///   ),
/// );
/// final res = await model.invoke(
///   PromptValue.string('What\'s the weather like in Boston and Madrid right now in celsius?'),
/// );
/// ```
/// {@endtemplate}
class ChatVertexAI extends BaseChatModel<ChatVertexAIOptions> {
  /// {@macro chat_vertex_ai}
  ChatVertexAI({
    required final HttpClientAuthProvider authProvider,
    required final String project,
    final String location = 'us-central1',
    super.defaultOptions = const ChatVertexAIOptions(model: defaultModel),
  }) {
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

  @override
  String get modelType => 'vertex-ai-chat';

  /// The default model to use unless another is specified.
  static const defaultModel = 'gemini-2.5-flash';

  @override
  Future<ChatResult> invoke(
    final PromptValue input, {
    final ChatVertexAIOptions? options,
  }) async {
    final id = _uuid.v4();
    final messages = input.toChatMessages();
    final model = _getModel(options);

    final request = _generateCompletionRequest(messages, options: options);
    final response = await _googleAiClient.models.generateContent(
      model: model,
      request: request,
    );

    return response.toChatResult(id, model);
  }

  @override
  Stream<ChatResult> stream(
    final PromptValue input, {
    final ChatVertexAIOptions? options,
  }) {
    final id = _uuid.v4();
    final messages = input.toChatMessages();
    final model = _getModel(options);

    final request = _generateCompletionRequest(messages, options: options);
    return _googleAiClient.models
        .streamGenerateContent(model: model, request: request)
        .map((final response) => response.toChatResult(id, model));
  }

  @override
  Future<List<int>> tokenize(
    final PromptValue promptValue, {
    final ChatVertexAIOptions? options,
  }) {
    throw UnsupportedError(
      'Vertex AI does not expose a tokenizer, only counting tokens is supported.',
    );
  }

  @override
  Future<int> countTokens(
    final PromptValue promptValue, {
    final ChatVertexAIOptions? options,
  }) async {
    final messages = promptValue.toChatMessages();
    final model = _getModel(options);

    final request = _generateCompletionRequest(messages, options: options);
    final response = await _googleAiClient.models.countTokens(
      model: model,
      request: g.CountTokensRequest(
        contents: request.contents,
        systemInstruction: request.systemInstruction,
      ),
    );
    return response.totalTokens;
  }

  /// Creates a [g.GenerateContentRequest] from the given input.
  g.GenerateContentRequest _generateCompletionRequest(
    final List<ChatMessage> messages, {
    final ChatVertexAIOptions? options,
  }) {
    final mergedOptions = options != null
        ? defaultOptions.merge(options)
        : defaultOptions;

    final firstMessage = messages.firstOrNull;
    final systemInstruction = firstMessage is SystemChatMessage
        ? firstMessage.contentAsString
        : null;

    return g.GenerateContentRequest(
      contents: messages.toContentList(),
      systemInstruction: systemInstruction != null
          ? g.Content(parts: [g.TextPart(systemInstruction)])
          : null,
      generationConfig: g.GenerationConfig(
        temperature: mergedOptions.temperature,
        topP: mergedOptions.topP,
        topK: mergedOptions.topK,
        candidateCount: mergedOptions.candidateCount,
        maxOutputTokens: mergedOptions.maxOutputTokens,
        stopSequences: mergedOptions.stopSequences ?? const [],
        responseMimeType: mergedOptions.responseMimeType,
        responseSchema: mergedOptions.responseSchema?.toSchema().toJson(),
        presencePenalty: mergedOptions.presencePenalty,
        frequencyPenalty: mergedOptions.frequencyPenalty,
      ),
      safetySettings: mergedOptions.safetySettings?.toSafetySettings(),
      tools: mergedOptions.tools.toToolList(
        enableCodeExecution: mergedOptions.enableCodeExecution ?? false,
      ),
      toolConfig: mergedOptions.toolChoice?.toToolConfig(),
      cachedContent: mergedOptions.cachedContent,
    );
  }

  /// Gets the model to use for the request.
  String _getModel(final ChatVertexAIOptions? options) {
    return options?.model ?? defaultOptions.model ?? defaultModel;
  }

  /// Closes the client and cleans up any resources associated with it.
  @override
  void close() {
    _googleAiClient.close();
  }
}
