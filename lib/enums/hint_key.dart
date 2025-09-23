enum HintKey {
  releaseLocalSpace('release_local_space'),
  dragAndDropToCreateFolder('drag_and_drop_to_create_folder'),
  statisticsSwipeToDelete('statistics_swipe_to_delete'),
  bookNotesOperations('book_notes_operations');
  const HintKey(this.code);

  final String code;
}
