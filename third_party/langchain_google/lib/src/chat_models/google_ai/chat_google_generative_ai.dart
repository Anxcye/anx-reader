import 'package:googleai_dart/googleai_dart.dart' as g;
import 'package:http/http.dart' as http;
import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/language_models.dart';
import 'package:langchain_core/prompts.dart';
import 'package:uuid/uuid.dart';

import 'mappers.dart';
import 'types.dart';

/// Wrapper around [Google AI for Developers](https://ai.google.dev/) API
/// (aka Gemini API).
///
/// Example:
/// ```dart
/// final chatModel = ChatGoogleGenerativeAI(apiKey: '...');
/// final messages = [
///   ChatMessage.humanText('Tell me a joke.'),
/// ];
/// final prompt = PromptValue.chat(messages);
/// final res = await llm.invoke(prompt);
/// ```
///
/// - [Google AI API docs](https://ai.google.dev/docs)
///
/// ### Setup
///
/// To use `ChatGoogleGenerativeAI` you need to have an API key.
/// You can get one [here](https://aistudio.google.com/app/apikey).
///
/// ### Available models
///
/// **Latest models (Gemini 2.5 series):**
///
/// - `gemini-2.5-flash`:
///   * Best price-performance model
///   * text / image / video / audio -> text
///   * Max input tokens: 1,048,576 (1M)
///   * Max output tokens: 8,192
///   * Supports: code execution, function calling, search grounding
///
/// - `gemini-2.5-pro`:
///   * State-of-the-art thinking model for complex reasoning
///   * text / image / video / audio / PDF -> text
///   * Max input tokens: 1,048,576 (1M)
///   * Max output tokens: 8,192
///   * Supports: code execution, function calling, search grounding
///
/// - `gemini-2.5-flash-lite`:
///   * Fastest and most cost-efficient
///   * text / image / video / audio / PDF -> text
///   * Max input tokens: 1,048,576 (1M)
///   * Max output tokens: 8,192
///   * Supports: function calling, structured outputs
///
/// **Previous generation models:**
///
/// - `gemini-1.5-flash` (still supported)
/// - `gemini-1.5-pro` (still supported)
/// - `gemini-1.0-pro` (legacy)
///
/// Mind that this list may not be up-to-date.
/// Refer to the [documentation](https://ai.google.dev/gemini-api/docs/models/gemini)
/// for the updated list.
///
/// #### Tuned models
///
/// You can specify a tuned model by setting the `model` parameter to
/// `tunedModels/{your-model-name}`. For example:
///
/// ```dart
/// final chatModel = ChatGoogleGenerativeAI(
///   defaultOptions: ChatGoogleGenerativeAIOptions(
///     model: 'tunedModels/my-tuned-model',
///   ),
/// );
/// ```
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
/// final chatModel = ChatGoogleGenerativeAI(
///   defaultOptions: ChatGoogleGenerativeAIOptions(
///     model: 'gemini-2.5-flash',
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
///   prompt,
///   options: const ChatGoogleGenerativeAIOptions(temperature: 1),
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
/// final chatModel = ChatGoogleGenerativeAI(apiKey: '...');
/// const outputParser = StringOutputParser();
/// final prompt1 = PromptTemplate.fromTemplate('How are you {name}?');
/// final prompt2 = PromptTemplate.fromTemplate('How old are you {name}?');
/// final chain = Runnable.fromMap({
///   'q1': prompt1 | chatModel.bind(const ChatGoogleGenerativeAIOptions(model: 'gemini-2.5-flash')) | outputParser,
///   'q2': prompt2 | chatModel.bind(const ChatGoogleGenerativeAIOptions(model: 'gemini-2.5-pro')) | outputParser,
/// });
/// final res = await chain.invoke({'name': 'David'});
/// ```
///
/// ### Advanced parameters
///
/// **Presence and Frequency Penalties:**
///
/// Control repetition in generated text:
///
/// ```dart
/// final chatModel = ChatGoogleGenerativeAI(
///   defaultOptions: ChatGoogleGenerativeAIOptions(
///     presencePenalty: 0.5,  // Discourage repeating topics
///     frequencyPenalty: 0.8,  // Discourage verbatim repetition
///   ),
/// );
/// ```
///
/// **Content Caching:**
///
/// Reduce costs and latency for long contexts:
///
/// ```dart
/// // First, create cached content via the Google AI API
/// // Then reference it by name:
/// final chatModel = ChatGoogleGenerativeAI(
///   defaultOptions: ChatGoogleGenerativeAIOptions(
///     cachedContent: 'cachedContents/abc123',
///   ),
/// );
/// ```
///
/// See: https://ai.google.dev/gemini-api/docs/caching
///
/// ### Tool calling
///
/// [ChatGoogleGenerativeAI] supports tool calling.
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
/// final chatModel = ChatGoogleGenerativeAI(
///   defaultOptions: ChatGoogleGenerativeAIOptions(
///     model: 'gemini-2.5-flash',
///     temperature: 0,
///     tools: [tool],
///   ),
/// );
/// final res = await model.invoke(
///   PromptValue.string('What's the weather like in Boston and Madrid right now in celsius?'),
/// );
/// ```
class ChatGoogleGenerativeAI
    extends BaseChatModel<ChatGoogleGenerativeAIOptions> {
  /// Create a new [ChatGoogleGenerativeAI] instance.
  ///
  /// Main configuration options:
  /// - `apiKey`: your Google AI API key. You can find your API key in the
  ///   [Google AI Studio dashboard](https://aistudio.google.com/app/apikey).
  /// - [ChatGoogleGenerativeAI.defaultOptions]
  ///
  /// Advance configuration options:
  /// - `baseUrl`: the base URL to use. Defaults to Google AI's API URL. You can
  ///   override this to use a different API URL, or to use a proxy.
  /// - `headers`: global headers to send with every request. You can use
  ///   this to set custom headers, or to override the default headers.
  /// - `queryParams`: global query parameters to send with every request. You
  ///   can use this to set custom query parameters.
  /// - `retries`: the number of retries to attempt if a request fails.
  /// - `client`: the HTTP client to use. You can set your own HTTP client if
  ///   you need further customization (e.g. to use a Socks5 proxy).
  ChatGoogleGenerativeAI({
    final String? apiKey,
    final String? baseUrl,
    final Map<String, String>? headers,
    final Map<String, String>? queryParams,
    final int retries = 3,
    final http.Client? client,
    super.defaultOptions = const ChatGoogleGenerativeAIOptions(
      model: defaultModel,
    ),
  }) {
    _googleAiClient = g.GoogleAIClient(
      config: g.GoogleAIConfig(
        authProvider: apiKey != null ? g.ApiKeyProvider(apiKey) : null,
        baseUrl: baseUrl ?? 'https://generativelanguage.googleapis.com',
        defaultHeaders: headers ?? const {},
        defaultQueryParams: queryParams ?? const {},
        retryPolicy: g.RetryPolicy(maxRetries: retries),
      ),
      httpClient: client,
    );
  }

  /// A client for interacting with Google AI API.
  late g.GoogleAIClient _googleAiClient;

  /// A UUID generator.
  late final _uuid = const Uuid();

  @override
  String get modelType => 'chat-google-generative-ai';

  /// The default model to use unless another is specified.
  static const defaultModel = 'gemini-1.5-flash';

  @override
  Future<ChatResult> invoke(
    final PromptValue input, {
    final ChatGoogleGenerativeAIOptions? options,
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
    final ChatGoogleGenerativeAIOptions? options,
  }) {
    final id = _uuid.v4();
    final messages = input.toChatMessages();
    final model = _getModel(options);

    final request = _generateCompletionRequest(messages, options: options);
    return _googleAiClient.models
        .streamGenerateContent(model: model, request: request)
        .map((final response) => response.toChatResult(id, model));
  }

  /// Creates a [g.GenerateContentRequest] from the given input.
  g.GenerateContentRequest _generateCompletionRequest(
    final List<ChatMessage> messages, {
    final ChatGoogleGenerativeAIOptions? options,
  }) {
    // Extract system instruction if present
    final systemInstruction = messages.firstOrNull is SystemChatMessage
        ? g.Content(parts: [g.TextPart(messages.firstOrNull!.contentAsString)])
        : null;

    return g.GenerateContentRequest(
      contents: messages.toContentList(),
      systemInstruction: systemInstruction,
      safetySettings: (options?.safetySettings ?? defaultOptions.safetySettings)
          ?.toSafetySettings(),
      generationConfig: g.GenerationConfig(
        candidateCount:
            options?.candidateCount ?? defaultOptions.candidateCount,
        stopSequences: options?.stopSequences ?? defaultOptions.stopSequences,
        maxOutputTokens:
            options?.maxOutputTokens ?? defaultOptions.maxOutputTokens,
        temperature: options?.temperature ?? defaultOptions.temperature,
        topP: options?.topP ?? defaultOptions.topP,
        topK: options?.topK ?? defaultOptions.topK,
        presencePenalty:
            options?.presencePenalty ?? defaultOptions.presencePenalty,
        frequencyPenalty:
            options?.frequencyPenalty ?? defaultOptions.frequencyPenalty,
        responseMimeType:
            options?.responseMimeType ?? defaultOptions.responseMimeType,
        responseSchema:
            options?.responseSchema ?? defaultOptions.responseSchema,
      ),
      tools: (options?.tools ?? defaultOptions.tools).toToolList(
        enableCodeExecution:
            options?.enableCodeExecution ??
            defaultOptions.enableCodeExecution ??
            false,
      ),
      toolConfig: (options?.toolChoice ?? defaultOptions.toolChoice)
          ?.toToolConfig(),
      cachedContent: options?.cachedContent ?? defaultOptions.cachedContent,
    );
  }

  @override
  Future<List<int>> tokenize(
    final PromptValue promptValue, {
    final ChatGoogleGenerativeAIOptions? options,
  }) {
    throw UnsupportedError(
      'Google AI does not expose a tokenizer, only counting tokens is supported.',
    );
  }

  @override
  Future<int> countTokens(
    final PromptValue promptValue, {
    final ChatGoogleGenerativeAIOptions? options,
  }) async {
    final messages = promptValue.toChatMessages();
    final model = _getModel(options);

    final result = await _googleAiClient.models.countTokens(
      model: model,
      request: g.CountTokensRequest(contents: messages.toContentList()),
    );

    return result.totalTokens;
  }

  @override
  void close() {
    _googleAiClient.close();
  }

  /// Gets the model to use for the request.
  String _getModel(final ChatGoogleGenerativeAIOptions? options) {
    return options?.model ?? defaultOptions.model ?? defaultModel;
  }

  /// {@template chat_google_generative_ai_list_models}
  /// Returns a list of available chat models from Google AI.
  ///
  /// This method fetches all models from the Google AI API and filters them
  /// to only return models that support content generation (chat-capable models).
  ///
  /// The returned [ModelInfo] includes rich metadata such as:
  /// - Token limits (input and output)
  /// - Description
  /// - Display name
  ///
  /// Example:
  /// ```dart
  /// final chatModel = ChatGoogleGenerativeAI(apiKey: '...');
  /// final models = await chatModel.listModels();
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

    // Filter to only chat-capable models (those supporting generateContent)
    return models
        .where(_isChatModel)
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

  /// Returns true if the model supports chat (generateContent).
  static bool _isChatModel(final g.Model model) {
    return model.supportedGenerationMethods?.contains('generateContent') ??
        false;
  }

  /// Extracts the model ID from the full resource name.
  /// e.g., "models/gemini-1.5-flash" -> "gemini-1.5-flash"
  static String _extractModelId(final String name) {
    const prefix = 'models/';
    if (name.startsWith(prefix)) {
      return name.substring(prefix.length);
    }
    return name;
  }
}
