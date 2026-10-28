enum SearchDisplayMode {
  popup('popup'),
  fullScreen('fullScreen'),
  external('external');

  const SearchDisplayMode(this.code);

  final String code;

  static SearchDisplayMode fromCode(String code) {
    return SearchDisplayMode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => SearchDisplayMode.popup,
    );
  }
}
