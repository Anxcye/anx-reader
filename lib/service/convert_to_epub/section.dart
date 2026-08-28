class Section {
  final String title;
  final String content;
  final int level;
  final String? xhtmlContent;

  Section(this.title, this.content, this.level, {this.xhtmlContent});

  @override
  String toString() {
    final prefix = '#' * level;
    return '$prefix $title\n$content';
  }
}
