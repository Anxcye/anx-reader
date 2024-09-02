class SearchResultModel {
  final String label;
  final String cfi;
  final List<SearchResultSubitemModel> subitems;

  SearchResultModel({
    required this.label,
    required this.cfi,
    required this.subitems,
  });

  static SearchResultModel fromJson(Map<String, dynamic> search) {
    return SearchResultModel(
      label: search['label'] ?? '',
      cfi: search['cfi'] ?? '',
      subitems: (search['subitems'] as List)
          .map<SearchResultSubitemModel>(
              (subitem) => SearchResultSubitemModel.fromJson(subitem))
          .toList(),
    );
  }
}

class SearchResultSubitemModel {
  final String cfi;
  final String pre;
  final String match;
  final String post;

  SearchResultSubitemModel({
    required this.cfi,
    required this.pre,
    required this.match,
    required this.post,
  });

  static SearchResultSubitemModel fromJson(Map<String, dynamic> subitem) {
    return SearchResultSubitemModel(
      cfi: subitem['cfi'],
      pre: subitem['excerpt']['pre'],
      match: subitem['excerpt']['match'],
      post: subitem['excerpt']['post'],
    );
  }
}