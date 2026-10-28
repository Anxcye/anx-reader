import 'package:vertex_ai/vertex_ai.dart';

import 'types.dart';

/// Mapper for [VertexAIIndexDatapointRestriction].
abstract class VertexAIMatchingEngineFilterMapper {
  /// Converts a [VertexAIMatchingEngineFilter] to a
  /// [VertexAIIndexDatapointRestriction].
  static VertexAIIndexDatapointRestriction toDto(
    final VertexAIMatchingEngineFilter filter,
  ) {
    return VertexAIIndexDatapointRestriction(
      namespace: filter.namespace,
      allowList: filter.allowList,
      denyList: filter.denyList,
    );
  }
}
