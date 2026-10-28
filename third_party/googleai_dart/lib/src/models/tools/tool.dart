import '../copy_with_sentinel.dart';
import 'computer_use.dart';
import 'file_search.dart';
import 'function_declaration.dart';
import 'google_maps.dart';
import 'google_search_retrieval.dart';
import 'mcp_server.dart';

/// Tool that the model may use to generate a response.
class Tool {
  /// List of function declarations.
  final List<FunctionDeclaration>? functionDeclarations;

  /// Code execution capability.
  final Map<String, dynamic>? codeExecution;

  /// Google search capability.
  final Map<String, dynamic>? googleSearch;

  /// File search tool that retrieves knowledge from Semantic Retrieval
  /// corpora.
  final FileSearch? fileSearch;

  /// List of MCP servers that can be called by the model.
  final List<McpServer>? mcpServers;

  /// Google Maps tool that provides geospatial context.
  final GoogleMaps? googleMaps;

  /// URL context tool that fetches and analyzes web content.
  ///
  /// Enables the model to retrieve and process content from URLs provided
  /// in the prompt. Supports HTML, JSON, text, XML, CSS, JavaScript, CSV,
  /// RTF, images, and PDFs. Maximum 20 URLs per request, 34MB per URL.
  final Map<String, dynamic>? urlContext;

  /// Tool to support the model interacting directly with the computer.
  ///
  /// If enabled, it automatically populates computer-use specific
  /// Function Declarations.
  final ComputerUse? computerUse;

  /// Retrieval tool that is powered by Google search.
  ///
  /// This is different from [googleSearch] - it provides dynamic retrieval
  /// configuration options.
  final GoogleSearchRetrieval? googleSearchRetrieval;

  /// Creates a [Tool].
  const Tool({
    this.functionDeclarations,
    this.codeExecution,
    this.googleSearch,
    this.fileSearch,
    this.mcpServers,
    this.googleMaps,
    this.urlContext,
    this.computerUse,
    this.googleSearchRetrieval,
  });

  /// Creates a [Tool] from JSON.
  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
    functionDeclarations: json['functionDeclarations'] != null
        ? (json['functionDeclarations'] as List)
              .map(
                (e) => FunctionDeclaration.fromJson(e as Map<String, dynamic>),
              )
              .toList()
        : null,
    codeExecution: json['codeExecution'] as Map<String, dynamic>?,
    googleSearch: json['googleSearch'] as Map<String, dynamic>?,
    fileSearch: json['fileSearch'] != null
        ? FileSearch.fromJson(json['fileSearch'] as Map<String, dynamic>)
        : null,
    mcpServers: json['mcpServers'] != null
        ? (json['mcpServers'] as List)
              .map((e) => McpServer.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
    googleMaps: json['googleMaps'] != null
        ? GoogleMaps.fromJson(json['googleMaps'] as Map<String, dynamic>)
        : null,
    urlContext: json['urlContext'] as Map<String, dynamic>?,
    computerUse: json['computerUse'] != null
        ? ComputerUse.fromJson(json['computerUse'] as Map<String, dynamic>)
        : null,
    googleSearchRetrieval: json['googleSearchRetrieval'] != null
        ? GoogleSearchRetrieval.fromJson(
            json['googleSearchRetrieval'] as Map<String, dynamic>,
          )
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (functionDeclarations != null)
      'functionDeclarations': functionDeclarations!
          .map((e) => e.toJson())
          .toList(),
    if (codeExecution != null) 'codeExecution': codeExecution,
    if (googleSearch != null) 'googleSearch': googleSearch,
    if (fileSearch != null) 'fileSearch': fileSearch!.toJson(),
    if (mcpServers != null)
      'mcpServers': mcpServers!.map((e) => e.toJson()).toList(),
    if (googleMaps != null) 'googleMaps': googleMaps!.toJson(),
    if (urlContext != null) 'urlContext': urlContext,
    if (computerUse != null) 'computerUse': computerUse!.toJson(),
    if (googleSearchRetrieval != null)
      'googleSearchRetrieval': googleSearchRetrieval!.toJson(),
  };

  /// Creates a copy with replaced values.
  Tool copyWith({
    Object? functionDeclarations = unsetCopyWithValue,
    Object? codeExecution = unsetCopyWithValue,
    Object? googleSearch = unsetCopyWithValue,
    Object? fileSearch = unsetCopyWithValue,
    Object? mcpServers = unsetCopyWithValue,
    Object? googleMaps = unsetCopyWithValue,
    Object? urlContext = unsetCopyWithValue,
    Object? computerUse = unsetCopyWithValue,
    Object? googleSearchRetrieval = unsetCopyWithValue,
  }) {
    return Tool(
      functionDeclarations: functionDeclarations == unsetCopyWithValue
          ? this.functionDeclarations
          : functionDeclarations as List<FunctionDeclaration>?,
      codeExecution: codeExecution == unsetCopyWithValue
          ? this.codeExecution
          : codeExecution as Map<String, dynamic>?,
      googleSearch: googleSearch == unsetCopyWithValue
          ? this.googleSearch
          : googleSearch as Map<String, dynamic>?,
      fileSearch: fileSearch == unsetCopyWithValue
          ? this.fileSearch
          : fileSearch as FileSearch?,
      mcpServers: mcpServers == unsetCopyWithValue
          ? this.mcpServers
          : mcpServers as List<McpServer>?,
      googleMaps: googleMaps == unsetCopyWithValue
          ? this.googleMaps
          : googleMaps as GoogleMaps?,
      urlContext: urlContext == unsetCopyWithValue
          ? this.urlContext
          : urlContext as Map<String, dynamic>?,
      computerUse: computerUse == unsetCopyWithValue
          ? this.computerUse
          : computerUse as ComputerUse?,
      googleSearchRetrieval: googleSearchRetrieval == unsetCopyWithValue
          ? this.googleSearchRetrieval
          : googleSearchRetrieval as GoogleSearchRetrieval?,
    );
  }
}
