class TocItem {
  final String id;
  final String href;
  final String label;
  final int level;
  final int startPage;
  final double startPercentage;
  final List<TocItem> subitems;

  TocItem(
      {required this.id,
      required this.href,
      required this.label,
      required this.subitems,
      required this.level,
      required this.startPage,
      required this.startPercentage});

  get percentage => '${(startPercentage * 100).toStringAsFixed(2)}%';
  get hasChildren => subitems.isNotEmpty;

  factory TocItem.fromJson(Map<String, dynamic> json) {
    return TocItem(
      id: json['id'].toString(),
      href: json['href'],
      label: json['label'],
      startPage: json['startPage'] ?? 0,
      startPercentage: (json['startPercentage'] ?? 0.0).toDouble(),
      level: json['level'] ?? 0,
      subitems: json['subitems'] == null
          ? []
          : (json['subitems'] as List).map((i) => TocItem.fromJson(i)).toList(),

    );
  }
}
