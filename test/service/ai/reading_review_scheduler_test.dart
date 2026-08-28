import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/service/ai/reading_review_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const day = Duration.millisecondsPerDay;
  test('ratings move stages within bounds and use transparent intervals', () {
    expect(
        ReadingReviewScheduler.schedule(
                currentStage: 1, rating: ReadingReviewRating.hard, now: 0)
            .stage,
        1);
    expect(
        ReadingReviewScheduler.schedule(
                currentStage: 2, rating: ReadingReviewRating.remembered, now: 0)
            .nextReviewAt,
        7 * day);
    expect(
        ReadingReviewScheduler.schedule(
                currentStage: 4, rating: ReadingReviewRating.mastered, now: 0)
            .stage,
        5);
    expect(
        ReadingReviewScheduler.schedule(
                currentStage: 5, rating: ReadingReviewRating.mastered, now: 0)
            .nextReviewAt,
        30 * day);
  });
}
