# Selection Interaction

## Goal

Long-press selection is a reading command surface. It should expose the most
likely action in one tap, preserve the selected context until an action accepts
it, and never silently fail after the menu closes.

## Information Architecture

Primary actions remain in stable semantic positions:

| Selection | Primary actions |
| --- | --- |
| Dictionary candidate | Look up, vocabulary, AI, more |
| Phrase or passage | Translate, AI, copy, more |

The expanded group contains web search, paragraph translation, narration,
note, and sharing. Annotation type and color remain a separate visual group
because they modify the selection rather than consume it.

## AI Contract

- Opening AI captures book, chapter, CFI, selected text, and surrounding text
  before closing the selection overlay.
- Opening AI creates a pending action card and does not request the model.
- The pending selection is cleared only after a selected AI action starts.
- Basic selection actions go directly to the primary assistant. Multi-Agent is
  reserved for explicit research, verification, calculation, risk, or deep
  analysis tasks.
- Model output is displayed as it streams. An idle stream times out instead of
  leaving the workspace permanently loading.

## Failure And Layout States

- Missing reader or workspace state keeps the menu open and shows an error.
- Async actions capture their reader state before closing the menu.
- Expanding or collapsing actions triggers overlay measurement and placement.
- Footnotes do not expose note editing; disabled AI and vocabulary capabilities
  are removed rather than shown as dead controls.
- E-INK uses the existing reduced-motion and high-contrast menu treatment.
