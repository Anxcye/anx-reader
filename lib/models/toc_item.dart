class TocItem {
  final String id;
  final String href;
  final String label;
  final List<TocItem> subitems;

  TocItem({required this.id, required this.href, required this.label, required this.subitems});

  factory TocItem.fromJson(Map<String, dynamic> json) {
    return TocItem(
      id: json['id'].toString(),
      href: json['href'],
      label: json['label'],
      subitems: json['subitems'] == null ? [] : (json['subitems'] as List).map((i) => TocItem.fromJson(i)).toList(),
    );
  }
}