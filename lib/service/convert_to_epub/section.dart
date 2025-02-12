
class Section {
  final String title;
  final String content;
  final int level; 

  Section(this.title, this.content, this.level);

  @override
  String toString() {
    final prefix = '#' * level;
    return '$prefix $title\n$content';
  }
}