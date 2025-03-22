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
Summarize the chapter content. Your reply must follow these requirements:
Language: Use the same language as the original chapter content.
Length: 8-10 complete sentences.
Structure: Three paragraphs: Main plot, Core characters, Themes/messages.
Style: Avoid boilerplate phrases like "This chapter describes..."
Perspective: Maintain a literary analysis perspective, not just narration.
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
Same language as original previous content
Avoid verbatim repetition; preserve core information

[Previous Content]
{{previous_content}}
        ''';
    }
  }
}
