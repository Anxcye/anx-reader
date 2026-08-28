enum ReadingMemorySourceType { difficulty, annotation, readingNote }

enum ReadingMemoryItemStatus { suggested, kept, active, ignored, archived }

enum ReadingReviewRating { hard, remembered, mastered }

class ReadingMemorySource {
  const ReadingMemorySource({
    required this.id,
    required this.bookId,
    required this.type,
    this.sourceRef,
    this.chapterHref,
    this.chapterTitle,
    this.cfi,
    required this.text,
    required this.contentHash,
    required this.createdAt,
    this.isAvailable = true,
  });
  final String id;
  final int bookId;
  final ReadingMemorySourceType type;
  final String? sourceRef;
  final String? chapterHref;
  final String? chapterTitle;
  final String? cfi;
  final String text;
  final String contentHash;
  final int createdAt;
  final bool isAvailable;

  ReadingMemorySource copyWith({bool? isAvailable}) => ReadingMemorySource(
        id: id,
        bookId: bookId,
        type: type,
        sourceRef: sourceRef,
        chapterHref: chapterHref,
        chapterTitle: chapterTitle,
        cfi: cfi,
        text: text,
        contentHash: contentHash,
        createdAt: createdAt,
        isAvailable: isAvailable ?? this.isAvailable,
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'source_type': type.name,
        'source_ref': sourceRef,
        'chapter_href': chapterHref,
        'chapter_title': chapterTitle,
        'cfi': cfi,
        'text_snapshot': text,
        'content_hash': contentHash,
        'created_at': createdAt,
      };
  factory ReadingMemorySource.fromDb(Map<String, dynamic> row) =>
      ReadingMemorySource(
        id: row['id'].toString(),
        bookId: row['book_id'] as int,
        type: ReadingMemorySourceType.values
            .byName(row['source_type'].toString()),
        sourceRef: row['source_ref']?.toString(),
        chapterHref: row['chapter_href']?.toString(),
        chapterTitle: row['chapter_title']?.toString(),
        cfi: row['cfi']?.toString(),
        text: row['text_snapshot']?.toString() ?? '',
        contentHash: row['content_hash'].toString(),
        createdAt: row['created_at'] as int,
      );
}

class ReadingMemoryTopic {
  const ReadingMemoryTopic(
      {required this.id,
      required this.bookId,
      required this.title,
      required this.summary,
      required this.status,
      required this.batchId,
      this.sourceIds = const [],
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final int bookId;
  final String title;
  final String summary;
  final ReadingMemoryItemStatus status;
  final String batchId;
  final List<String> sourceIds;
  final int createdAt;
  final int updatedAt;
  ReadingMemoryTopic copyWith(
          {ReadingMemoryItemStatus? status, int? updatedAt}) =>
      ReadingMemoryTopic(
          id: id,
          bookId: bookId,
          title: title,
          summary: summary,
          status: status ?? this.status,
          batchId: batchId,
          sourceIds: sourceIds,
          createdAt: createdAt,
          updatedAt: updatedAt ?? this.updatedAt);
  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'title': title,
        'summary': summary,
        'status': status.name,
        'batch_id': batchId,
        'created_at': createdAt,
        'updated_at': updatedAt
      };
  factory ReadingMemoryTopic.fromDb(Map<String, dynamic> row,
          [List<String> sources = const []]) =>
      ReadingMemoryTopic(
          id: row['id'].toString(),
          bookId: row['book_id'] as int,
          title: row['title'].toString(),
          summary: row['summary'].toString(),
          status:
              ReadingMemoryItemStatus.values.byName(row['status'].toString()),
          batchId: row['batch_id'].toString(),
          sourceIds: sources,
          createdAt: row['created_at'] as int,
          updatedAt: row['updated_at'] as int);
}

class ReadingKnowledgeCard {
  const ReadingKnowledgeCard(
      {required this.id,
      required this.bookId,
      required this.topicId,
      required this.question,
      required this.answer,
      required this.status,
      this.sourceIds = const [],
      this.reviewStage = 1,
      required this.nextReviewAt,
      this.hardCount = 0,
      this.rememberedCount = 0,
      this.masteredCount = 0,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final int bookId;
  final String topicId;
  final String question;
  final String answer;
  final ReadingMemoryItemStatus status;
  final List<String> sourceIds;
  final int reviewStage;
  final int nextReviewAt;
  final int hardCount;
  final int rememberedCount;
  final int masteredCount;
  final int createdAt;
  final int updatedAt;
  ReadingKnowledgeCard copyWith(
          {ReadingMemoryItemStatus? status,
          int? reviewStage,
          int? nextReviewAt,
          int? hardCount,
          int? rememberedCount,
          int? masteredCount,
          int? updatedAt}) =>
      ReadingKnowledgeCard(
          id: id,
          bookId: bookId,
          topicId: topicId,
          question: question,
          answer: answer,
          status: status ?? this.status,
          sourceIds: sourceIds,
          reviewStage: reviewStage ?? this.reviewStage,
          nextReviewAt: nextReviewAt ?? this.nextReviewAt,
          hardCount: hardCount ?? this.hardCount,
          rememberedCount: rememberedCount ?? this.rememberedCount,
          masteredCount: masteredCount ?? this.masteredCount,
          createdAt: createdAt,
          updatedAt: updatedAt ?? this.updatedAt);
  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'topic_id': topicId,
        'question': question,
        'answer': answer,
        'status': status.name,
        'review_stage': reviewStage,
        'next_review_at': nextReviewAt,
        'hard_count': hardCount,
        'remembered_count': rememberedCount,
        'mastered_count': masteredCount,
        'created_at': createdAt,
        'updated_at': updatedAt
      };
  factory ReadingKnowledgeCard.fromDb(Map<String, dynamic> row,
          [List<String> sources = const []]) =>
      ReadingKnowledgeCard(
          id: row['id'].toString(),
          bookId: row['book_id'] as int,
          topicId: row['topic_id'].toString(),
          question: row['question'].toString(),
          answer: row['answer'].toString(),
          status:
              ReadingMemoryItemStatus.values.byName(row['status'].toString()),
          sourceIds: sources,
          reviewStage: row['review_stage'] as int,
          nextReviewAt: row['next_review_at'] as int,
          hardCount: row['hard_count'] as int,
          rememberedCount: row['remembered_count'] as int,
          masteredCount: row['mastered_count'] as int,
          createdAt: row['created_at'] as int,
          updatedAt: row['updated_at'] as int);
}

class ReadingCardReview {
  const ReadingCardReview(
      {required this.id,
      required this.cardId,
      required this.bookId,
      required this.rating,
      required this.previousStage,
      required this.nextStage,
      required this.previousReviewAt,
      required this.nextReviewAt,
      required this.reviewedAt});
  final String id;
  final String cardId;
  final int bookId;
  final ReadingReviewRating rating;
  final int previousStage;
  final int nextStage;
  final int previousReviewAt;
  final int nextReviewAt;
  final int reviewedAt;
  Map<String, Object?> toDb() => {
        'id': id,
        'card_id': cardId,
        'book_id': bookId,
        'rating': rating.name,
        'previous_stage': previousStage,
        'next_stage': nextStage,
        'previous_review_at': previousReviewAt,
        'next_review_at': nextReviewAt,
        'reviewed_at': reviewedAt
      };
  factory ReadingCardReview.fromDb(Map<String, dynamic> row) =>
      ReadingCardReview(
          id: row['id'].toString(),
          cardId: row['card_id'].toString(),
          bookId: row['book_id'] as int,
          rating: ReadingReviewRating.values.byName(row['rating'].toString()),
          previousStage: row['previous_stage'] as int,
          nextStage: row['next_stage'] as int,
          previousReviewAt: row['previous_review_at'] as int,
          nextReviewAt: row['next_review_at'] as int,
          reviewedAt: row['reviewed_at'] as int);
}
