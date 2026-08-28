class WordMorphology {
  WordMorphology._();

  static const Map<String, String> _englishIrregular = {
    'am': 'be',
    'are': 'be',
    'is': 'be',
    'was': 'be',
    'were': 'be',
    'been': 'be',
    'went': 'go',
    'gone': 'go',
    'did': 'do',
    'done': 'do',
    'had': 'have',
    'children': 'child',
    'men': 'man',
    'women': 'woman',
    'mice': 'mouse',
    'teeth': 'tooth',
    'feet': 'foot',
    'better': 'good',
    'best': 'good',
    'worse': 'bad',
    'worst': 'bad',
  };

  static List<String> englishLemmas(String text) {
    final word = text.trim().toLowerCase();
    if (!RegExp(r"^[a-z][a-z'-]{0,63}$").hasMatch(word)) return const [];
    final result = <String>{word};
    final irregular = _englishIrregular[word];
    if (irregular != null) result.add(irregular);

    if (word.endsWith('ies') && word.length > 3) {
      result.add('${word.substring(0, word.length - 3)}y');
    }
    if (word.endsWith('ves') && word.length > 3) {
      final stem = word.substring(0, word.length - 3);
      result.add('${stem}f');
      result.add('${stem}fe');
    }
    if (word.endsWith('ing') && word.length > 4) {
      _addVerbStems(result, word.substring(0, word.length - 3));
    }
    if (word.endsWith('ed') && word.length > 3) {
      _addVerbStems(result, word.substring(0, word.length - 2));
    }
    if (word.endsWith('es') && word.length > 3) {
      result.add(word.substring(0, word.length - 2));
    }
    if (word.endsWith('s') && !word.endsWith('ss') && word.length > 2) {
      result.add(word.substring(0, word.length - 1));
    }
    return result.toList(growable: false);
  }

  static void _addVerbStems(Set<String> result, String stem) {
    result.add(stem);
    result.add('${stem}e');
    if (stem.length > 2 && stem[stem.length - 1] == stem[stem.length - 2]) {
      result.add(stem.substring(0, stem.length - 1));
    }
  }
}
