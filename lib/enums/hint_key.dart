enum HintKey {
  releaseLocalSpace('release_local_space'),
  dragAndDropToCreateFolder('drag_and_drop_to_create_folder');
  const HintKey(this.code);

  final String code;
}
