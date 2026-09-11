import 'package:langchain_core/vector_stores.dart';
import 'package:meta/meta.dart';

import 'mappers.dart';

/// {@template vertex_ai_matching_engine_similarity_search}
/// Vertex AI Matching Engine similarity search config.
///
/// Example:
/// ```dart
/// VertexAIMatchingEngineSimilaritySearch(
///   k: 5,
///   filters: [
///     const VertexAIMatchingEngineFilter(
///       namespace: 'class',
///       allowList: ['pet'],
///     ),
///     const VertexAIMatchingEngineFilter(
///       namespace: 'category',
///       denyList: ['canine'],
///     ),
///   ]
/// ),
/// ```
/// {@endtemplate}
class VertexAIMatchingEngineSimilaritySearch
    extends VectorStoreSimilaritySearch {
  /// {@macro vertex_ai_matching_engine_similarity_search}
  VertexAIMatchingEngineSimilaritySearch({
    super.k = 4,
    final List<VertexAIMatchingEngineFilter>? filters,
    super.scoreThreshold,
  }) : super(
         filter: filters != null
             ? {
                 filterKey: filters
                     .map(VertexAIMatchingEngineFilterMapper.toDto)
                     .toList(growable: false),
               }
             : null,
       );

  /// The key for the filter.
  static const filterKey = 'restricts';
}

/// {@template vertex_ai_matching_engine_filter}
/// Filter for the Vertex AI Matching Engine.
/// See: https://cloud.google.com/vertex-ai/docs/matching-engine/filtering
/// {@endtemplate}
@immutable
class VertexAIMatchingEngineFilter {
  /// {@macro vertex_ai_matching_engine_filter}
  const VertexAIMatchingEngineFilter({
    required this.namespace,
    this.allowList = const [],
    this.denyList = const [],
  });

  /// The namespace of this restriction.
  ///
  /// eg: color.
  final String namespace;

  /// The attributes to allow in this namespace.
  ///
  /// eg: 'red'
  final List<String> allowList;

  /// The attributes to deny in this namespace.
  ///
  /// eg: 'blue'
  final List<String> denyList;
}
