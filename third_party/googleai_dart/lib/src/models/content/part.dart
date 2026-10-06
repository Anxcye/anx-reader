import 'dart:convert';

import '../copy_with_sentinel.dart';
import '../files/video_metadata.dart';
import '../tools/code_execution_result.dart';
import '../tools/executable_code.dart';
import '../tools/function_call.dart';
import '../tools/function_response.dart';
import 'blob.dart';
import 'file_data.dart';
import 'media_resolution.dart';

/// A single unit of content (text, media, function call, etc.).
///
/// Exactly one field must be set.
sealed class Part {
  /// Creates a [Part].
  const Part();

  /// Creates a text part.
  ///
  /// Example:
  /// ```dart
  /// final part = Part.text('Hello, world!');
  /// ```
  factory Part.text(String text) = TextPart;

  /// Creates an inline data part from base64-encoded data.
  ///
  /// Example:
  /// ```dart
  /// final part = Part.base64(imageBase64, 'image/png');
  /// ```
  factory Part.base64(String data, String mimeType) =>
      InlineDataPart(Blob(mimeType: mimeType, data: data));

  /// Creates a file reference part.
  ///
  /// Use for files uploaded via the Files API.
  ///
  /// Example:
  /// ```dart
  /// final part = Part.file('files/abc123', mimeType: 'image/jpeg');
  /// ```
  factory Part.file(String fileUri, {String? mimeType}) =>
      FileDataPart(FileData(fileUri: fileUri, mimeType: mimeType));

  /// Creates a function call part.
  ///
  /// Example:
  /// ```dart
  /// final part = Part.functionCall('get_weather', args: {'city': 'SF'});
  /// ```
  factory Part.functionCall(String name, {Map<String, dynamic>? args}) =>
      FunctionCallPart(FunctionCall(name: name, args: args));

  /// Creates a function response part.
  ///
  /// Example:
  /// ```dart
  /// final part = Part.functionResponse('get_weather', {'temp': 72});
  /// ```
  factory Part.functionResponse(
    String name,
    Map<String, dynamic> response, {
    String? id,
  }) => FunctionResponsePart(
    FunctionResponse(name: name, response: response, id: id),
  );

  /// Creates a [Part] from JSON.
  factory Part.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('text')) {
      return TextPart(json['text'] as String);
    }
    if (json.containsKey('inlineData')) {
      return InlineDataPart(
        Blob.fromJson(json['inlineData'] as Map<String, dynamic>),
        mediaResolution: json['mediaResolution'] != null
            ? MediaResolution.fromJson(
                json['mediaResolution'] as Map<String, dynamic>,
              )
            : null,
      );
    }
    if (json.containsKey('fileData')) {
      return FileDataPart(
        FileData.fromJson(json['fileData'] as Map<String, dynamic>),
        mediaResolution: json['mediaResolution'] != null
            ? MediaResolution.fromJson(
                json['mediaResolution'] as Map<String, dynamic>,
              )
            : null,
      );
    }
    if (json.containsKey('functionCall')) {
      final signature = json['thoughtSignature'];
      return FunctionCallPart(
        FunctionCall.fromJson(json['functionCall'] as Map<String, dynamic>),
        thoughtSignature: signature is String ? base64Decode(signature) : null,
      );
    }
    if (json.containsKey('functionResponse')) {
      return FunctionResponsePart(
        FunctionResponse.fromJson(
          json['functionResponse'] as Map<String, dynamic>,
        ),
      );
    }
    if (json.containsKey('executableCode')) {
      return ExecutableCodePart(
        ExecutableCode.fromJson(json['executableCode'] as Map<String, dynamic>),
      );
    }
    if (json.containsKey('codeExecutionResult')) {
      return CodeExecutionResultPart(
        CodeExecutionResult.fromJson(
          json['codeExecutionResult'] as Map<String, dynamic>,
        ),
      );
    }
    if (json.containsKey('videoMetadata')) {
      return VideoMetadataPart(
        VideoMetadata.fromJson(json['videoMetadata'] as Map<String, dynamic>),
      );
    }
    if (json.containsKey('thought')) {
      return ThoughtPart(thought: json['thought'] as bool);
    }
    if (json.containsKey('thoughtSignature')) {
      return ThoughtSignaturePart(
        base64Decode(json['thoughtSignature'] as String),
      );
    }
    if (json.containsKey('partMetadata')) {
      return PartMetadataPart(json['partMetadata'] as Map<String, dynamic>);
    }
    throw FormatException('Unknown Part type: ${json.keys}');
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson();
}

/// Text content.
class TextPart extends Part {
  /// Plain text content.
  final String text;

  /// Creates a [TextPart].
  const TextPart(this.text);

  @override
  Map<String, dynamic> toJson() => {'text': text};

  /// Creates a copy with replaced values.
  TextPart copyWith({Object? text = unsetCopyWithValue}) {
    return TextPart(text == unsetCopyWithValue ? this.text : text! as String);
  }
}

/// Inline binary data (base64).
class InlineDataPart extends Part {
  /// Inline binary data.
  final Blob inlineData;

  /// Optional media resolution for the input media.
  final MediaResolution? mediaResolution;

  /// Creates an [InlineDataPart].
  const InlineDataPart(this.inlineData, {this.mediaResolution});

  @override
  Map<String, dynamic> toJson() => {
    'inlineData': inlineData.toJson(),
    if (mediaResolution != null) 'mediaResolution': mediaResolution!.toJson(),
  };

  /// Creates a copy with replaced values.
  InlineDataPart copyWith({
    Object? inlineData = unsetCopyWithValue,
    Object? mediaResolution = unsetCopyWithValue,
  }) {
    return InlineDataPart(
      inlineData == unsetCopyWithValue ? this.inlineData : inlineData! as Blob,
      mediaResolution: mediaResolution == unsetCopyWithValue
          ? this.mediaResolution
          : mediaResolution as MediaResolution?,
    );
  }
}

/// Reference to uploaded file.
class FileDataPart extends Part {
  /// File reference.
  final FileData fileData;

  /// Optional media resolution for the input media.
  final MediaResolution? mediaResolution;

  /// Creates a [FileDataPart].
  const FileDataPart(this.fileData, {this.mediaResolution});

  @override
  Map<String, dynamic> toJson() => {
    'fileData': fileData.toJson(),
    if (mediaResolution != null) 'mediaResolution': mediaResolution!.toJson(),
  };

  /// Creates a copy with replaced values.
  FileDataPart copyWith({
    Object? fileData = unsetCopyWithValue,
    Object? mediaResolution = unsetCopyWithValue,
  }) {
    return FileDataPart(
      fileData == unsetCopyWithValue ? this.fileData : fileData! as FileData,
      mediaResolution: mediaResolution == unsetCopyWithValue
          ? this.mediaResolution
          : mediaResolution as MediaResolution?,
    );
  }
}

/// Model's request to call a function.
class FunctionCallPart extends Part {
  /// Function call.
  final FunctionCall functionCall;

  /// Opaque thought signature that must be echoed back for thinking models.
  final List<int>? thoughtSignature;

  /// Creates a [FunctionCallPart].
  const FunctionCallPart(this.functionCall, {this.thoughtSignature});

  @override
  Map<String, dynamic> toJson() => {
    'functionCall': functionCall.toJson(),
    if (thoughtSignature != null)
      'thoughtSignature': base64Encode(thoughtSignature!),
  };

  /// Creates a copy with replaced values.
  FunctionCallPart copyWith({
    Object? functionCall = unsetCopyWithValue,
    Object? thoughtSignature = unsetCopyWithValue,
  }) {
    return FunctionCallPart(
      functionCall == unsetCopyWithValue
          ? this.functionCall
          : functionCall! as FunctionCall,
      thoughtSignature: thoughtSignature == unsetCopyWithValue
          ? this.thoughtSignature
          : thoughtSignature as List<int>?,
    );
  }
}

/// Result from function execution.
class FunctionResponsePart extends Part {
  /// Function response.
  final FunctionResponse functionResponse;

  /// Creates a [FunctionResponsePart].
  const FunctionResponsePart(this.functionResponse);

  @override
  Map<String, dynamic> toJson() => {
    'functionResponse': functionResponse.toJson(),
  };

  /// Creates a copy with replaced values.
  FunctionResponsePart copyWith({
    Object? functionResponse = unsetCopyWithValue,
  }) {
    return FunctionResponsePart(
      functionResponse == unsetCopyWithValue
          ? this.functionResponse
          : functionResponse! as FunctionResponse,
    );
  }
}

/// Code for model to execute.
class ExecutableCodePart extends Part {
  /// Executable code.
  final ExecutableCode executableCode;

  /// Creates an [ExecutableCodePart].
  const ExecutableCodePart(this.executableCode);

  @override
  Map<String, dynamic> toJson() => {'executableCode': executableCode.toJson()};

  /// Creates a copy with replaced values.
  ExecutableCodePart copyWith({Object? executableCode = unsetCopyWithValue}) {
    return ExecutableCodePart(
      executableCode == unsetCopyWithValue
          ? this.executableCode
          : executableCode! as ExecutableCode,
    );
  }
}

/// Result from code execution.
class CodeExecutionResultPart extends Part {
  /// Code execution result.
  final CodeExecutionResult codeExecutionResult;

  /// Creates a [CodeExecutionResultPart].
  const CodeExecutionResultPart(this.codeExecutionResult);

  @override
  Map<String, dynamic> toJson() => {
    'codeExecutionResult': codeExecutionResult.toJson(),
  };

  /// Creates a copy with replaced values.
  CodeExecutionResultPart copyWith({
    Object? codeExecutionResult = unsetCopyWithValue,
  }) {
    return CodeExecutionResultPart(
      codeExecutionResult == unsetCopyWithValue
          ? this.codeExecutionResult
          : codeExecutionResult! as CodeExecutionResult,
    );
  }
}

/// Video timing/sampling metadata.
class VideoMetadataPart extends Part {
  /// Video metadata.
  final VideoMetadata videoMetadata;

  /// Creates a [VideoMetadataPart].
  const VideoMetadataPart(this.videoMetadata);

  @override
  Map<String, dynamic> toJson() => {'videoMetadata': videoMetadata.toJson()};

  /// Creates a copy with replaced values.
  VideoMetadataPart copyWith({Object? videoMetadata = unsetCopyWithValue}) {
    return VideoMetadataPart(
      videoMetadata == unsetCopyWithValue
          ? this.videoMetadata
          : videoMetadata! as VideoMetadata,
    );
  }
}

/// Reasoning step indicator.
class ThoughtPart extends Part {
  /// Whether this is a thought/reasoning step.
  final bool thought;

  /// Creates a [ThoughtPart].
  const ThoughtPart({required this.thought});

  @override
  Map<String, dynamic> toJson() => {'thought': thought};

  /// Creates a copy with replaced values.
  ThoughtPart copyWith({Object? thought = unsetCopyWithValue}) {
    return ThoughtPart(
      thought: thought == unsetCopyWithValue ? this.thought : thought! as bool,
    );
  }
}

/// Cached thought key (base64).
class ThoughtSignaturePart extends Part {
  /// Thought signature bytes.
  final List<int> thoughtSignature;

  /// Creates a [ThoughtSignaturePart].
  const ThoughtSignaturePart(this.thoughtSignature);

  @override
  Map<String, dynamic> toJson() => {
    'thoughtSignature': base64Encode(thoughtSignature),
  };

  /// Creates a copy with replaced values.
  ThoughtSignaturePart copyWith({
    Object? thoughtSignature = unsetCopyWithValue,
  }) {
    return ThoughtSignaturePart(
      thoughtSignature == unsetCopyWithValue
          ? this.thoughtSignature
          : thoughtSignature! as List<int>,
    );
  }
}

/// Custom metadata.
class PartMetadataPart extends Part {
  /// Part metadata.
  final Map<String, dynamic> partMetadata;

  /// Creates a [PartMetadataPart].
  const PartMetadataPart(this.partMetadata);

  @override
  Map<String, dynamic> toJson() => {'partMetadata': partMetadata};

  /// Creates a copy with replaced values.
  PartMetadataPart copyWith({Object? partMetadata = unsetCopyWithValue}) {
    return PartMetadataPart(
      partMetadata == unsetCopyWithValue
          ? this.partMetadata
          : partMetadata! as Map<String, dynamic>,
    );
  }
}
