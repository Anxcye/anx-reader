import '../content/content.dart';
import '../copy_with_sentinel.dart';
import '../tools/tool.dart';
import '../tools/tool_config.dart';
import 'cached_content_usage_metadata.dart';

/// Cached content for reuse across requests.
///
/// Context caching allows you to save frequently used content (e.g., system
/// instructions, large context documents) and reuse it across multiple requests,
/// significantly reducing latency and costs for subsequent requests.
///
/// ## Creating Cached Content
///
/// **Required fields**:
/// - [model]: The model to use with this cache (e.g., "models/gemini-3-flash-preview")
///
/// **Expiration** (must provide one):
/// - [ttl]: Duration string (e.g., "3600s" for 1 hour, "7200s" for 2 hours)
/// - [expireTime]: Absolute timestamp when cache expires
///
/// **Note**: Use either [ttl] OR [expireTime], not both.
///
/// **Content to cache** (at least one recommended):
/// - [systemInstruction]: System instruction for consistent behavior
/// - [contents]: Conversation history or context documents
/// - [tools]: Tool definitions for function calling
/// - [toolConfig]: Tool configuration settings
///
/// **Optional**:
/// - [displayName]: Human-readable name (max 128 characters)
///
/// ## Updating Cached Content
///
/// **Mutable fields** (can be updated after creation):
/// - [ttl]: Extend cache lifetime with a new duration
/// - [expireTime]: Set a new absolute expiration time
///
/// **Immutable fields** (cannot be changed after creation):
/// - [model], [systemInstruction], [contents], [tools], [toolConfig]
///
/// ## Output-only Fields
///
/// These fields are populated by the API and should not be set on create:
/// - [name]: Resource identifier (format: "cachedContents/{id}")
/// - [createTime]: When the cache was created
/// - [updateTime]: When the cache was last updated
/// - [usageMetadata]: Token usage statistics
///
/// ## Example
///
/// ```dart
/// // Create cache with system instruction
/// final cache = await client.createCachedContent(
///   cachedContent: CachedContent(
///     model: 'models/gemini-3-flash-preview',
///     displayName: 'Math Expert',
///     systemInstruction: Content(
///       parts: [TextPart('You are a math expert...')],
///     ),
///     ttl: '3600s', // 1 hour
///   ),
/// );
///
/// // Use cache in generation requests
/// final response = await client.generateContent(
///   model: 'gemini-3-flash-preview',
///   request: GenerateContentRequest(
///     cachedContent: cache.name,
///     contents: [Content(parts: [TextPart('What is 2+2?')])],
///   ),
/// );
/// ```
class CachedContent {
  /// Output only. The resource name in format `cachedContents/{id}`.
  ///
  /// This is assigned by the API when the cache is created.
  final String? name;

  /// Optional. Immutable. Human-readable display name (max 128 Unicode characters).
  ///
  /// Helps identify the cache in listings and logs.
  final String? displayName;

  /// Required. Immutable. The model to use with this cached content.
  ///
  /// Format: `models/{model}` (e.g., "models/gemini-3-flash-preview-8b")
  ///
  /// The cached content can only be used with this specific model.
  final String? model;

  /// Optional. Input only. Immutable. System instruction for the model.
  ///
  /// This instruction is included with every request that uses this cache,
  /// ensuring consistent model behavior without repeating it in each request.
  final Content? systemInstruction;

  /// Optional. Input only. Immutable. The content to cache.
  ///
  /// Typically used to cache large context documents or conversation history
  /// that will be reused across multiple requests.
  final List<Content>? contents;

  /// Optional. Input only. Immutable. Tools available to the model.
  ///
  /// Function calling definitions that the model can use when generating
  /// responses with this cached content.
  final List<Tool>? tools;

  /// Optional. Input only. Immutable. Tool configuration shared for all tools.
  ///
  /// Controls how the model uses the provided tools (e.g., function calling mode).
  final ToolConfig? toolConfig;

  /// Output only (on read). Input for expiration (on create/update).
  /// Timestamp when this cache expires.
  ///
  /// On output: Always provided, showing when cache will expire.
  /// On input: Alternative to [ttl] for setting absolute expiration time.
  ///
  /// **Important**: Use either [expireTime] OR [ttl], not both.
  final DateTime? expireTime;

  /// Input only. Time-to-live duration for the cached content.
  ///
  /// Format: Duration string (e.g., "3600s" for 1 hour, "7200s" for 2 hours).
  ///
  /// On create: Sets initial expiration (default 1 hour, max 24 hours).
  /// On update: Extends cache lifetime from current time.
  ///
  /// **Important**: Use either [ttl] OR [expireTime], not both.
  final String? ttl;

  /// Output only. Creation timestamp of this cache entry.
  final DateTime? createTime;

  /// Output only. Last update timestamp of this cache entry.
  final DateTime? updateTime;

  /// Output only. Usage metadata showing token counts.
  ///
  /// Indicates how many tokens this cached content consumes.
  final CachedContentUsageMetadata? usageMetadata;

  /// Creates a [CachedContent].
  const CachedContent({
    this.name,
    this.displayName,
    this.model,
    this.systemInstruction,
    this.contents,
    this.tools,
    this.toolConfig,
    this.expireTime,
    this.ttl,
    this.createTime,
    this.updateTime,
    this.usageMetadata,
  });

  /// Creates a [CachedContent] from JSON.
  factory CachedContent.fromJson(Map<String, dynamic> json) => CachedContent(
    name: json['name'] as String?,
    displayName: json['displayName'] as String?,
    model: json['model'] as String?,
    systemInstruction: json['systemInstruction'] != null
        ? Content.fromJson(json['systemInstruction'] as Map<String, dynamic>)
        : null,
    contents: (json['contents'] as List<dynamic>?)
        ?.map((e) => Content.fromJson(e as Map<String, dynamic>))
        .toList(),
    tools: (json['tools'] as List<dynamic>?)
        ?.map((e) => Tool.fromJson(e as Map<String, dynamic>))
        .toList(),
    toolConfig: json['toolConfig'] != null
        ? ToolConfig.fromJson(json['toolConfig'] as Map<String, dynamic>)
        : null,
    expireTime: json['expireTime'] != null
        ? DateTime.parse(json['expireTime'] as String)
        : null,
    ttl: json['ttl'] as String?,
    createTime: json['createTime'] != null
        ? DateTime.parse(json['createTime'] as String)
        : null,
    updateTime: json['updateTime'] != null
        ? DateTime.parse(json['updateTime'] as String)
        : null,
    usageMetadata: json['usageMetadata'] != null
        ? CachedContentUsageMetadata.fromJson(
            json['usageMetadata'] as Map<String, dynamic>,
          )
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (displayName != null) 'displayName': displayName,
    if (model != null) 'model': model,
    if (systemInstruction != null)
      'systemInstruction': systemInstruction!.toJson(),
    if (contents != null) 'contents': contents!.map((e) => e.toJson()).toList(),
    if (tools != null) 'tools': tools!.map((e) => e.toJson()).toList(),
    if (toolConfig != null) 'toolConfig': toolConfig!.toJson(),
    if (expireTime != null) 'expireTime': expireTime!.toIso8601String(),
    if (ttl != null) 'ttl': ttl,
    if (createTime != null) 'createTime': createTime!.toIso8601String(),
    if (updateTime != null) 'updateTime': updateTime!.toIso8601String(),
    if (usageMetadata != null) 'usageMetadata': usageMetadata!.toJson(),
  };

  /// Creates a copy with replaced values.
  CachedContent copyWith({
    Object? name = unsetCopyWithValue,
    Object? displayName = unsetCopyWithValue,
    Object? model = unsetCopyWithValue,
    Object? systemInstruction = unsetCopyWithValue,
    Object? contents = unsetCopyWithValue,
    Object? tools = unsetCopyWithValue,
    Object? toolConfig = unsetCopyWithValue,
    Object? expireTime = unsetCopyWithValue,
    Object? ttl = unsetCopyWithValue,
    Object? createTime = unsetCopyWithValue,
    Object? updateTime = unsetCopyWithValue,
    Object? usageMetadata = unsetCopyWithValue,
  }) {
    return CachedContent(
      name: name == unsetCopyWithValue ? this.name : name as String?,
      displayName: displayName == unsetCopyWithValue
          ? this.displayName
          : displayName as String?,
      model: model == unsetCopyWithValue ? this.model : model as String?,
      systemInstruction: systemInstruction == unsetCopyWithValue
          ? this.systemInstruction
          : systemInstruction as Content?,
      contents: contents == unsetCopyWithValue
          ? this.contents
          : contents as List<Content>?,
      tools: tools == unsetCopyWithValue ? this.tools : tools as List<Tool>?,
      toolConfig: toolConfig == unsetCopyWithValue
          ? this.toolConfig
          : toolConfig as ToolConfig?,
      expireTime: expireTime == unsetCopyWithValue
          ? this.expireTime
          : expireTime as DateTime?,
      ttl: ttl == unsetCopyWithValue ? this.ttl : ttl as String?,
      createTime: createTime == unsetCopyWithValue
          ? this.createTime
          : createTime as DateTime?,
      updateTime: updateTime == unsetCopyWithValue
          ? this.updateTime
          : updateTime as DateTime?,
      usageMetadata: usageMetadata == unsetCopyWithValue
          ? this.usageMetadata
          : usageMetadata as CachedContentUsageMetadata?,
    );
  }
}
