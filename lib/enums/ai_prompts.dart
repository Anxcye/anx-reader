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
        return 'Introduce yourself in one concise sentence, clearly stating that you are a helpful AI assistant. Ensure the introduction is in the language specified by the locale: {{language_locale}}.';
      case AiPrompts.summaryTheChapter:
        return 'Summarize the following chapter in approximately 3-5 sentences focusing on the main plot points, key characters involved, and the overall theme or message. Ensure the summary is written in the same language as the original chapter. The chapter content is: {{chapter}}';
      case AiPrompts.summaryTheBook:
        return "Provide a concise summary of the book '{{book}}' by {{author}}, in approximately 5-7 sentences. Highlight the central conflict, the main characters and their motivations, and the book's primary themes or message to the reader.";
      case AiPrompts.summaryThePreviousContent:
        return "You are helping a user recall the content of a book they read a long time ago. Summarize the following excerpt in approximately 3-5 sentences, focusing on the most important plot developments, key character interactions, and any significant events that would help the user remember the story. The content is: {{previous_content}}";
    }
  }
}
