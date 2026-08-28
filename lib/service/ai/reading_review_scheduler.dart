import 'package:anx_reader/models/reading_memory.dart';

class ReadingReviewSchedule {
  const ReadingReviewSchedule(this.stage, this.nextReviewAt);
  final int stage;
  final int nextReviewAt;
}

class ReadingReviewScheduler {
  static const intervals = [1, 3, 7, 14, 30];
  static ReadingReviewSchedule schedule(
      {required int currentStage,
      required ReadingReviewRating rating,
      required int now}) {
    final stage = switch (rating) {
      ReadingReviewRating.hard => (currentStage - 1).clamp(1, 5),
      ReadingReviewRating.remembered => (currentStage + 1).clamp(1, 5),
      ReadingReviewRating.mastered => (currentStage + 2).clamp(1, 5),
    };
    return ReadingReviewSchedule(
        stage, now + Duration(days: intervals[stage - 1]).inMilliseconds);
  }
}
