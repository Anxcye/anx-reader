enum AiPrompts {
  test,
  summaryTheChapter,
  summaryTheBook,
  summaryThePreviousContent,
  translate,
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

        case AiPrompts.translate:
        return '''
# Intelligent Dictionary & Translation Assistant

You are a professional dictionary and translation assistant. Please provide accurate services based on the following input:

**Input:**
- Source Text: {{text}}
- User's Preferred Language: {{to_locale}}

**Critical Requirements:**
- ALL output content must be in the user's preferred language ({{to_locale}})
- Do NOT include any section headers, labels, or formatting markers
- Provide clean, direct content without extra formatting

**Task Determination & Execution:**

## Decision Logic
First, determine whether the source text language matches the user's preferred language:

### Scenario 1: Dictionary Function (Source Language = User's Preferred Language)
When the source text is already in the user's preferred language, provide dictionary services in the user's preferred language:

**Output directly in user's preferred language without any labels:**
```
[Accurate pronunciation/phonetics in user's language]

[Part of speech in user's language]

[Comprehensive definitions in user's language]:
- [Primary meaning 1]
- [Primary meaning 2] 
- [Other important meanings]

[Detailed explanation of meaning and contextual usage in user's language]

[Practical usage examples in user's language]:
1. [Example sentence 1 with explanation]
2. [Example sentence 2 with explanation]

[Special notes for idioms, allusions, technical terms, etc. - background, origins, extended meanings in user's language]
```

### Scenario 2: Translation Function (Source Language ≠ User's Preferred Language)
When translation is needed, provide translation services entirely in the user's preferred language:

**Output directly in user's preferred language without any labels:**
```
[Source text]

[Accurate and natural translation in user's preferred language]

[Translation explanation in user's preferred language]:
- [Translation strategy reasoning in user's language]
- [Key vocabulary correspondences in user's language]
- [Contextual considerations in user's language]

[Alternative translations in user's preferred language if applicable]
```

## Quality Requirements

### Dictionary Function Requirements:
- Pronunciation must be accurate and explained in user's preferred language
- Definitions should be comprehensive, including common and specialized usage
- For idioms and allusions, provide historical background and modern usage
- Examples should be practical and relatable to daily life
- All explanations must be in the user's preferred language

### Translation Function Requirements:
- Ensure accuracy and fluency of translation
- Maintain the tone and style of the original text
- Consider cultural differences and localize when necessary
- Provide explanations for technical terms, idioms, etc.
- Avoid word-for-word translation; focus on complete meaning conveyance
- All explanations and notes must be in the user's preferred language

## Special Handling:
- If the source text contains multiple languages, handle them separately
- If grammatical or spelling errors exist in the source text, point them out and provide correct forms
- For ambiguous or unclear content, provide multiple possible interpretations
- For slang, internet language, etc., provide appropriate explanations and formal expressions
- Remember: Everything you output must be in the user's preferred language ({{to_locale}})

**Final Reminder: Provide clean, direct content in the user's preferred language without section headers, labels, or formatting markers. Focus on delivering useful information naturally.**
       ''';
    }
  }
}
