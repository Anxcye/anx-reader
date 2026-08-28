enum BookLoadStage { bootstrap, fetch, detect, parse, render, ready, failed }

class BookLoadFailure {
  const BookLoadFailure({
    required this.code,
    required this.message,
    this.stage = BookLoadStage.failed,
    this.details,
  });

  final String code;
  final String message;
  final BookLoadStage stage;
  final String? details;

  factory BookLoadFailure.fromJson(Map<String, dynamic> json) {
    return BookLoadFailure(
      code: json['code']?.toString() ?? 'unknown',
      message: json['message']?.toString() ?? 'Unknown reader error',
      stage: BookLoadStage.values.firstWhere(
        (value) => value.name == json['stage']?.toString(),
        orElse: () => BookLoadStage.failed,
      ),
      details: json['details']?.toString(),
    );
  }
}

class BookLoadState {
  const BookLoadState({
    this.stage = BookLoadStage.bootstrap,
    this.elapsedMs = 0,
    this.format,
    this.failure,
    this.isSlow = false,
  });

  final BookLoadStage stage;
  final int elapsedMs;
  final String? format;
  final BookLoadFailure? failure;
  final bool isSlow;

  bool get isReady => stage == BookLoadStage.ready;
  bool get hasFailed => failure != null || stage == BookLoadStage.failed;

  BookLoadState copyWith({
    BookLoadStage? stage,
    int? elapsedMs,
    String? format,
    BookLoadFailure? failure,
    bool? isSlow,
  }) =>
      BookLoadState(
        stage: stage ?? this.stage,
        elapsedMs: elapsedMs ?? this.elapsedMs,
        format: format ?? this.format,
        failure: failure ?? this.failure,
        isSlow: isSlow ?? this.isSlow,
      );
}
