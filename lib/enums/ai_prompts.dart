enum AiPrompts {
  test,
  summaryTheChapter,
  summaryTheBook,
  summaryThePreviousContent,
}

extension AiPromptsJson on AiPrompts {
  String getPrompt() {
    switch (this) {
      case AiPrompts.test:
        return '''
        Write a concise and friendly self-introduction. Use the language code: {{language_locale}}
        ''';

      case AiPrompts.summaryTheChapter:
        return '''
Summarize the chapter content with these requirements:
[Structure]
8-10 complete sentences
Three paragraphs: Main plot → Core characters → Themes/messages
[Content rules]
Use the same language as the original chapter content
Avoid meaningless boilerplate phrases like "This chapter describes..."
Maintain literary analysis perspective rather than mere narration
Chapter content: {{chapter}}
        ''';

      case AiPrompts.summaryTheBook:
        return '''
Generate a book summary for "{{book}}" by {{author}}
[Requirements]:
Language matches the book title's language
Central conflict (highlight with » symbol)
3 core characters + their motivations (name + critical choice)
Theme keywords (3-5)
Avoid spoiling the final outcome
        ''';

      case AiPrompts.summaryThePreviousContent:
        return '''
I'm revisiting a book I read long ago. Help me quickly recall the previous content to continue reading:
[Requirements]
3-5 sentences
Same language as original text
Avoid verbatim repetition; preserve core information

[Content]
{{previous_content}}
        ''';
    }
  }
}
