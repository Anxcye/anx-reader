# Issue Triage Ledger

Working notes for GitHub issue maintenance in the anx-reader project.

## Purpose

- Use GitHub Issues as the source of truth.
- Record triage decisions, duplicate clusters, and follow-up notes here.
- Do not mirror every issue — keep only what helps future triage.

## Label Set

- `bug` `documentation` `duplicate` `enhancement` `good first issue` `help wanted`
- `invalid` `question` `wontfix` `stale` `Specific books` `upstream limitation`
- `P0` `P1` `P2` `P3`
- `need-test-file` `need-more-info`

## Label Maintenance Guide

### Labels Overview

| Label | Purpose | Auto-triggered? |
|---|---|---|
| `bug` | Something isn't working | No — triage adds manually |
| `enhancement` | New feature or request | No — triage adds manually |
| `duplicate` | Already exists | No — used when closing duplicates |
| `question` | More info needed | **Yes** — GitHub Action adds when platform info incomplete, or when `need-test-file`/`need-more-info` is added |
| `stale` | Inactive for a long time | Manual |
| `wontfix` | Will not be worked on | Manual |
| `P0`–`P3` | Priority level | No — triage adds manually |
| `need-test-file` | Need a test file to reproduce | No — triage adds manually; **triggers `question` label via GitHub Action** |
| `need-more-info` | Need more details from reporter | No — triage adds manually; **triggers `question` label via GitHub Action** |
| `upstream limitation` | Caused by upstream dependency | Manual |
| `Specific books` | Reproducible only with specific book files | Manual |
| `good first issue` | Good for newcomers | Manual |
| `help wanted` | Extra attention needed | Manual |

### GitHub Action Automation

Two workflows manage labels automatically:

1. **`label-trigger.yml`** — When `bug` label is added:
   - Checks if platform info (Platform/OS/Version/Device) is complete
   - If incomplete → adds `question` label + bilingual comment requesting info
   - When `need-test-file` or `need-more-info` is added → adds `question` + request comment

2. **`remove-question-label.yml`** — When issue author responds or edits:
   - Automatically removes `question` label

### Priority Labels (P0–P3)

Apply during triage based on impact:

| Label | Meaning | When to apply |
|---|---|---|
| `P0` | Critical — data loss, security, crash | Immediate fix required |
| `P1` | High — core feature broken, many users affected | Fix before next release |
| `P2` | Medium — feature degraded, workaround exists | Schedule for upcoming cycle |
| `P3` | Low — enhancement, minor, edge case | Backlog, no deadline |
| `P4` | Parking lot — long-term vision, no near-term plan | No deadline; revisit when roadmap shifts |

**Rules:**
- Every bug/enhancement should have exactly one priority label
- When closing a duplicate, do NOT transfer priority — the canonical issue keeps its own
- Priority can change as more reports come in

### When to Add/Remove Labels

**Add labels when:**
- Triaging a new issue (always add `bug` or `enhancement` + priority)
- Confirming a bug (add `bug` if not already tagged)
- Identifying an enhancement (add `enhancement`)
- Requiring info from reporter (add `need-more-info` or `need-test-file`)
- Confirming upstream cause (add `upstream limitation`)

**Remove labels when:**
- `question` — reporter has provided enough info (or auto-removed by Action)
- `duplicate` — when closing (use `gh issue close` with `--reason "not planned"` comment instead)
- `stale` — when issue gets new activity or is being worked on

**Never add these manually:**
- `question` — let the GitHub Action handle it
- `duplicate` — use issue comments with link instead

### Label Maintenance Commands

```bash
export GH_CONFIG_DIR=/home/ubuntu/.config/gh

# Add a label
gh issue edit NUM -R Anxcye/anx-reader --add-label "P2"

# Remove a label
gh issue edit NUM -R Anxcye/anx-reader --remove-label "question"

# Add multiple labels
gh issue edit NUM -R Anxcye/anx-reader --add-label "bug,P1"

# Check current labels
gh issue view NUM -R Anxcye/anx-reader --json labels
```

## Complexity Scale

| Level | Name | Description |
|---|---|---|
| 1 | Trivial | UI text, config, typo, minimal change |
| 2 | Low | Single file, clear logic, small scope |
| 3 | Medium | Multiple files, some context needed |
| 4 | High | Architectural change, core logic involved |
| 5 | Critical | Major refactor, deep system understanding required |

## Record Format

| Topic | Issue | Canonical | Related | Status | Priority | Complexity | Code Ref | Conclusion | Action |
|---|---|---|---|---|---|---|---|---|---|
| short name | #123 | — | #124, #130 | open / review / closed / needs-update | P0-P3 / — | 1-5 | `lib/path/file.dart` or N/A | one-line judgment | one-line next step |

## Progress

| Date | Issues Tried | Unread Before | Unread After | Notes |
|---|---|---|---|---|
| 2026-05-24 | 85 | 85 | ~0 | First comprehensive triage. Closed 6 duplicates/invalid. |
| 2026-05-24 | 41 | 0 | 0 | Second pass: added 41 missing issues, fixed 3 duplicate entries, corrected #839 classification. |
| 2026-05-24 | 5 | 0 | 0 | Third pass (review): added P4 definition, closed #93→#920, #858→#849 as duplicates, fixed #612 wording. |

## Triage Records

### Duplicate Clusters (Closed)

| Topic | Closed | Canonical | Closure Reason | Date |
|---|---|---|---|---|
| Translation popup too small | #916 | #901 | Duplicate — same UI issue | 2026-05-24 |
| Local TTS support | #915 | #827 | Duplicate — same feature request | 2026-05-24 |
| Batch book selection | #837 | #841 | Duplicate — #841 is more comprehensive | 2026-05-24 |
| Linux support | #599 | #486 | Duplicate of closed stale issue | 2026-05-24 |
| Vague feature request | #819 | — | Closed as stale — no actionable content | 2026-05-24 |
| Star count comment | #908 | — | Closed — not a real issue | 2026-05-24 |
| SafeArea white lines | #920 | #93 | Duplicate — same as #93; upstream: flutter_inappwebview#1204 | 2026-05-24 |

### TTS / Narrate Cluster

| Topic | Issue | Canonical | Related | Status | Priority | Complexity | Code Ref | Conclusion | Action |
|---|---|---|---|---|---|---|---|---|---|
| TTS background chapter skip | #544 | #544 | #842 | open | P1 | 4 | `epub_player.dart`, `online_tts.dart`, `system_tts.dart` | Core arch flaw: all TTS text fetching depends on WebView JS;后台时 WebView pauses | High-priority refactor: pre-parse EPUB chapters in Dart layer |
| TTS + scroll page turn | #822 | — | — | open | P2 | 3 | `epub_player.dart`, `tts_widget.dart` | TTS highlight causes scroll jumping in scroll mode | Disable auto-scroll follow during TTS highlight |
| OpenAI TTS custom params | #826 | — | — | open | P2 | 2 | `openai_tts_backend.dart` | speed param not passed in request body | Add speed field to OpenAI TTS request body |
| Local TTS (self-hosted) | #827 | #827 | #915(closed) | open | P3 | 3 | `tts_service.dart`, `tts_factory.dart` | User wants local TTS service support | Add custom HTTP TTS provider or enhance OpenAI provider |
| Azure TTS 429 rate limit | #828 | — | — | open | P2 | 2 | `online_tts.dart`, `azure_tts_backend.dart` | No backoff strategy on 429 errors | Add exponential backoff and rate limiting |
| Add mimo TTS provider | #829 | — | #885 | open | P3 | 3 | `tts_service.dart`, `tts_factory.dart` | New cloud TTS provider request | Build generic provider template to lower cost |
| Add volcano TTS provider | #885 | — | #829 | open | P3 | 3 | `tts_service.dart`, `tts_factory.dart` | Same category as #829 | Build generic provider template |
| BGM during TTS | #852 | — | — | open | P3 | 4 | `tts_handler.dart`, `tts_widget.dart` | Full new feature: background music during TTS | Independent feature, no overlap |

### WebDAV / Sync Cluster

| Topic | Issue | Canonical | Related | Status | Priority | Complexity | Code Ref | Conclusion | Action |
|---|---|---|---|---|---|---|---|---|---|
| Android WebDAV cert trust | #719 | — | — | open | P2 | 3 | `webdav_client.dart`, `sync_connection_tester.dart` | Dart SSL doesn't read Android user trust store | Add "trust all certs" toggle or custom SecurityContext |
| Custom storage path error | #745 | — | #839 | open | P2 | 3 | `storage_migration.dart` | DB file locked during migration on Windows | Close/release DB before migration; add rollback |
| WebDAV custom folder | #758 | — | — | open | P3 | 3 | `webdav_client.dart`, `sync.dart` | Remote path hardcoded to `/anx/data/file` | Add remote path config input in settings |
| ZSpace WebDAV connection | #890 | — | — | open | P2 | 3 | `webdav_client.dart` (testFullCapabilities) | ZSpace returns non-standard 201 on MKCOL | Relax directory creation error check |
| Sync data loss | #911 | #911 | — | open | P1 | 4 | `sync.dart` (syncDatabase, determineSyncDirection) | Full-DB overwrite mode, no record-level merge | Design incremental merge sync (mid-term CRDT) |
| WebDAV upload fail | #912 | — | — | open | P2 | 3 | `webdav_client.dart` (uploadFile) | DELETE not supported by some servers → 405 | Try PUT overwrite first, fallback to DELETE+PUT |
| Single book sync | #898 | — | #911 | open | P3 | 4 | `sync.dart`, `book_notes.dart` | No per-book granularity in sync | Implement per-book export as data safety net |
| Storage migration empty dir | #839 | — | #745 | open | P1 | 2 | `storage_migration.dart` | Migration requires empty target dir; user can't migrate to existing data dir | Allow merge mode, not just empty dir |
| WebDAV 302 redirect | #345 | — | #760 | open | P2 | 3 | `webdav_client.dart`, `sync.dart` | 302 redirect not followed during sync | Add redirect following in HTTP client |
| WebDAV sync time | #588 | — | #911 | open | P3 | 3 | `sync.dart`, `database.dart` | Sync uses file mtime; cd2 upload delay causes false conflicts | Store sync timestamp in DB |

### AI / Custom API Cluster

| Topic | Issue | Canonical | Related | Status | Priority | Complexity | Code Ref | Conclusion | Action |
|---|---|---|---|---|---|---|---|---|---|
| AI prompt/API sync | #767 | — | — | open | P3 | 3 | `shared_preference_provider.dart`, `sync.dart` | AI prompts/config not in WebDAV sync scope | Extend sync to include AI settings |
| AI display improvement | #843 | — | — | open | P3 | 3 | `ai_history.dart`, `ai_chat_stream.dart` | No rename/book-association for AI history | Add bookId and title fields to AiChatHistoryEntry |
| Windows AI crash | #844 | — | — | open | P1 | 4 | `ai/index.dart`, `langchain_runner.dart` | AI dialog crashes on Windows | Analyze user-provided crash log |
| AI opens on book open | #849 | #849 | — | closed | P2 | 2 | `reading_page.dart` (onLoadEnd) | Setting already exists: "自动总结前文内容" toggle in More Settings → Other Settings | Already implemented; user instruction provided |
| AI summary threshold | #858 | — | — | open | P3 | 2 | `reading_page.dart` (onLoadEnd), `shared_preference_provider.dart` | Want configurable delay before auto-summary triggers | Add time threshold setting for auto-summary |
| Custom prompts in home AI | #853 | — | — | open | P2 | 2 | `home_page.dart`, `reading_page.dart` | User prompts work in reader AI but not home AI tab | Pass quickPromptChips to home AiChatStream (~10 LOC) |
| Custom provider test error | #868 | — | — | open | P1 | 3 | `ai_provider_detail_page.dart`, `langchain_ai_config.dart` | Null cast to String in Claude protocol | Add null safety in config parsing |
| AI panel accessibility | #871 | — | — | open | P3 | 3 | `reading_page.dart`, `ai.dart`, `ai_chat_display_mode.dart` | No gesture shortcut for AI panel in reader | Add swipe gesture and mode switch UI |
| DeepSeek reasoning_content | #896 | — | — | open | P1 | 3 | `index.dart` (_sanitizeMessagesForPrompt) | reasoningContent stripped, DeepSeek API requires it | Preserve reasoningContent for DeepSeek (~5 LOC) |
| Custom API provider config | #897 | — | #868 | open | P3 | 5 | `ai_provider_detail_page.dart`, `langchain_ai_config.dart` | Advanced: template-based API config | Long-term vision, low priority |
| HarmonyOS AI | #919 | — | — | open | P2 | 1 | `env_var.dart`, `platform_utils.dart` | AI disabled in OHOS store builds (intentional) | Confirm restriction scope; add UI explanation |
| AI crash on book_content_search | #888 | — | #844 | open | P1 | 4 | `ai/index.dart`, tool execution | Crash/restart when AI tool `book_content_search` triggered during EPUB | Analyze crash log; likely null in tool result handling |
| Separate API for AI vs translation | #848 | — | #868 | open | P2 | 3 | `ai_provider_detail_page.dart`, translation settings | Different API configs for AI daily use vs translation | Add separate provider config for translation |

### Bookshelf / Library Organization Cluster

| Topic | Issue | Canonical | Related | Status | Priority | Complexity | Code Ref | Conclusion | Action |
|---|---|---|---|---|---|---|---|---|---|
| Nested folders | #757 | #757 | #895 | open | P2 | 4 | `tb_group.dart`, `book_folder.dart`, `bookshelf_page.dart` | DB has parentId but UI doesn't use it | Mid-term target, coordinate with #895 |
| Windows + bookshelf UI | #763 | — | — | open | P2 | 2 | `book_folder.dart`, `book_bottom_sheet.dart` | 3 independent suggestions: file association, folder UI, annotations | Split into sub-issues |
| Mind-map book classification | #832 | — | — | open | P3 | 5 | `bookshelf_organize_service.dart` | Niche request, very high complexity | Close or reclassify as long-term vision |
| Local bookshelf path | #856 | — | — | open | P3 | 4 | `get_base_path.dart`, `sync.dart` | User wants external sync tool support | Long-term roadmap item |
| Multi bookshelves | #895 | #895 | #757, #866 | open | P1 | 4 | `book.dart`, `tb_group.dart`, `bookshelf_page.dart` | Detailed well-designed request for named bookshelves | **Phase 1 priority**: multi-shelf data model + switch UI |
| Series support (display) | #866 | — | #865 | open | P2 | 4 | `book.dart`, `book_folder.dart`, `book_item.dart` | Detailed series feature: badges, detail page, filtering | Mid-term, after #841 |
| Bookshelf completeness | #905 | — | #837(closed), #841 | open | P2 | 3 | `bookshelf_page.dart`, `book_item.dart` | Batch select + drag sort; batch part overlaps #841 | Batch → #841; sort → #763 |
| Android widgets | #834 | — | — | open | P3 | 5 | `AndroidManifest.xml` | No widget infrastructure at all | Low priority, after core features |
| Batch book selection | #841 | #841 | #837(closed), #905 | open | P1 | 3 | `bookshelf_page.dart`, `book_item.dart` | Manual read status + batch select; **前置依赖** for all org features | **Phase 1 priority**: implement first |
| Bookshelf management | #668 | — | #757, #895 | open | P2 | 3 | `bookshelf_page.dart`, `book_folder.dart` | List layout + local folder grouping + sub-sorting | Coordinate with #757; add list view option |
| Android widgets | #612 | #612 | #834 | open | P3 | 4 | `AndroidManifest.xml` | Quick book open + TTS playback from home screen | Close #834 as duplicate; same scope |
| Multi-user sync | #667 | — | #898 | open | P3 | 4 | `sync.dart`, `database.dart` | Shared library causes cross-user reading record conflicts | Add user ID to reading records; long-term design |

### Translation Cluster

| Topic | Issue | Canonical | Related | Status | Priority | Complexity | Code Ref | Conclusion | Action |
|---|---|---|---|---|---|---|---|---|---|
| Translation suggestions | #817 | — | #901, #916(closed) | open | P3 | 3 | `translation_menu.dart`, `translate.dart` | Part 1 (auto-translate) already implemented; Part 2 (popup) = #901 | Guide user to autoTranslate setting; merge popup with #901 |
| Azure Translator 401 | #872 | — | — | open | P2 | 2 | `microsoft_api.dart` | No API key format validation; poor error messages | Add key format pre-validation and detailed error info |
| Translation popup too small | #901 | #901 | #916(closed), #817 | open | P2 | 2 | `translation_menu.dart` (height: 150) | Fixed 150px height too small for translation results | Increase to 200-250px; add expand/collapse button |

### Reading Experience Cluster

| Topic | Issue | Canonical | Related | Status | Priority | Complexity | Code Ref | Conclusion | Action |
|---|---|---|---|---|---|---|---|---|---|
| Image paragraph font size | #861 | — | — | open | P2 | 3 | `foliate-js/`, epub CSS rendering | Image paragraphs have smaller font than text-only | Fix CSS font-size inheritance for img-containing paragraphs |
| Scroll page turn stuck | #899 | — | — | open | P1 | 2 | `epub_player.dart` (animation controller) | Page stuck at 50% when animation disabled | Fix animation controller state reset in no-animation mode |
| Long-press no toolbar | #900 | — | — | open | P1 | 2 | `context_menu.dart` (auto-highlight) | Auto-highlight logic not triggered on long press | Fix long-press event to trigger toolbar display |
| Slider mis-touch | #902 | — | — | open | P3 | 2 | `reading_settings.dart`, `style_settings.dart` | E-ink screens: slider easy to mis-touch | Add save/cancel buttons; increase slider padding |
| Header covers first line | #903 | — | #791 | open | P2 | 3 | `reading_page.dart`, `epub_player.dart` | Scroll mode top padding doesn't account for header height | Include header height in scroll container padding |
| Back button behavior | #815 | — | — | open | P4 | 2 | `reading_page.dart`, navigation | Stale. Back button exits to desktop instead of prev page | Keep stale; check Navigator.pop() logic if revisited |
| Header/footer settings | #791 | — | #903 | open | P4 | 3 | `reading_page.dart`, `progress_widget.dart` | Stale. Request header/footer font size and margin settings | Keep stale; consider with #903 fix |
| Chapter transition | #842 | — | #544 | open | P2 | 3 | `tts_service.dart`, `tts_widget.dart` | TTS stops at chapter end, doesn't auto-continue | Merge into #544 TTS chapter transition fix |
| TOC rendering bug | #833 | — | — | open | P2 | 3 | `epub_player.dart`, TOC parsing | TOC blank when chapter count exceeds threshold | Check TOC parsing limits; likely array overflow |
| Selection overflow | #231 | — | — | open | P2 | 3 | `epub_player.dart`, text selection | Text selection spans pages incorrectly after翻页 | Check selection range calculation across page boundaries |
| macOS keyboard失灵 | #323 | — | — | open | P2 | 3 | `reading_page.dart`, keyboard events | Scroll mode breaks arrow key navigation on macOS | Fix keyboard event handling in scroll mode |

### Windows Cluster

| Topic | Issue | Canonical | Related | Status | Priority | Complexity | Code Ref | Conclusion | Action |
|---|---|---|---|---|---|---|---|---|---|
| Windows close hang | #878 | #878 | #904 | open | P2 | 3 | `main.dart`, exit handling | App freezes on close button, needs Task Manager | Check async tasks blocking window close |
| Windows 11 multi-bug | #904 | — | #878, #763 | open | P2 | 3 | `main.dart`, cache management, WebView | 3 issues: trackpad scroll, close hang, cache path | Split into sub-issues; close hang → #878 |
| No file extension visible | #910 | — | — | open | P3 | 2 | `book_detail.dart` | Detail page doesn't show file format/extension | Add format display in book_detail metadata area |
| Windows DPI font issue | #546 | — | — | open | P2 | 3 | `reading_page.dart`, `epub_player.dart` | Non-100% DPI scaling causes font size mismatch | Use device pixel ratio for font scaling |
| Windows location permission | #564 | — | — | open | P2 | 2 | `main.dart`, Windows manifest | Unknown location permission request on Windows | Audit Windows permission declarations |
| Windows desktop icon broken | #243 | — | — | open | P2 | 3 | `main.dart`, Windows installer | Desktop icon can't click after app launch | Check Windows shortcut/URL handler registration |

### PDF Cluster

| Topic | Issue | Canonical | Related | Status | Priority | Complexity | Code Ref | Conclusion | Action |
|---|---|---|---|---|---|---|---|---|---|
| PDF chapter lag | #887 | #887 | #889, #23 | open | P2 | 4 | `book.dart`, `epub_player.dart`, PDF layer | PDF performance poor: slow load, lag between chapters | Systematic PDF render pipeline optimization |
| PDF general issues | #889 | — | #887, #23 | open | P2 | 4 | `book.dart`, `epub_player.dart`, PDF layer | PDF: slow, laggy, TTS reads only title+first sentence | Merge with #887; implement PDF preload and cache |
| Samsung Notes PDF feature | #855 | — | — | open | P4 | 5 | N/A (new module) | Request: full PDF annotation like Samsung Notes | Long-term roadmap; reference Saber project |
| PDF highlight broken | #884 | — | — | open | P2 | 3 | `context_menu.dart`, `epub_player.dart` | PDF text highlight not working on Windows | Check PDF text layer extraction |

### Standalone Features / Enhancements

| Topic | Issue | Canonical | Related | Status | Priority | Complexity | Code Ref | Conclusion | Action |
|---|---|---|---|---|---|---|---|---|---|
| Stylus support | #27 | — | — | open | P3 | 4 | `reading_page.dart`, stylus events | Stylus input for annotation/highlight | Platform-specific stylus event handling |
| Import md files | #109 | — | — | open | P3 | 4 | `import_service.dart`, `foliate-js/` | Import markdown as book + directory import | Major feature; needs markdown→epub pipeline |
| Offline dictionary | #150 | — | — | open | P2 | 4 | `translation_menu.dart`, new module | Chinese dictionary for classical text reading | New module; bundle dictionary data or use API |
| Page turn animation | #164 | — | #835 | open | P2 | 3 | `epub_player.dart`, animation | WeChat-style page turn animations | Coordinate with #835 infinite scroll; may conflict |
| Word count stats | #251 | — | — | open | P3 | 2 | `book_notes.dart`, `book_detail.dart` | Chapter + total word count display | Add word count to book stats |
| Win on ARM | #265 | — | — | open | P3 | 3 | build config, Flutter Engine | Native Windows ARM64 build | Check Flutter ARM64 support; may need custom build |
| More sync methods | #285 | — | #760 | open | P3 | 3 | `sync.dart`, new providers | OneDrive/Google Drive/Alist sync | Extend sync abstraction; lower priority than WebDAV fix |
| Monet dynamic icons | #287 | — | — | open | P3 | 2 | `AndroidManifest.xml`, adaptive icons | Android 12+ Material You icon theming | Add monochrome icon variant |
| Proxy support | #318 | — | — | open | P2 | 3 | `http_client.dart`, settings | HTTP/SOCKS5 proxy for AI/translation in restricted networks | Add proxy config in settings; affects all HTTP calls |
| FODT format support | #319 | — | — | open | P3 | 4 | `foliate-js/`, format detection | FODT (OpenDocument) for TTS-friendly reading | Low demand; evaluate if epub conversion covers this |
| Import from WebDAV | #366 | — | #760 | open | P3 | 3 | `webdav_client.dart`, `import_service.dart` | Import books from remote WebDAV to local | Add remote file browser in import flow |
| Custom highlight color | #368 | — | — | open | P2 | 2 | `context_menu.dart`, `highlight.dart` | User wants transparent/custom highlight colors | Add color picker in highlight menu |
| Highlight share | #392 | — | — | open | P2 | 3 | `excerpt_menu.dart`, `context_menu.dart` | Export highlights + call external translation apps | Add share menu item; integrate with system share sheet |
| CHM file support | #394 | — | — | open | P3 | 4 | `foliate-js/`, new parser | CHM (old novel format) support | Need CHM parser; evaluate demand |
| Gesture bar immersive | #413 | — | — | open | P3 | 2 | `main.dart`, Android system UI | Gesture navigation bar not transparent on ColorOS/MIUI | Set system UI overlay style per platform |
| Paragraph notes | #416 | — | — | open | P3 | 3 | `context_menu.dart`, `book_notes.dart` | Add paragraph-level note button (like 番茄小说) | Add note icon at paragraph end in context menu |
| Book description field | #429 | — | #851 | open | P2 | 2 | `book_detail.dart`, `book.dart` | Add editable description box in book details | Extend book metadata model with description field |
| DJVU support | #443 | — | — | open | P3 | 4 | `foliate-js/`, new parser | DJVU format support | Need DJVU parser; low demand |
| DeepLx support | #475 | — | — | open | P3 | 2 | `translation_service.dart` | Free DeepL translation backend | Add as translation provider option |
| View source code | #515 | — | — | open | P3 | 3 | `reading_page.dart`, new UI | View epub source/CSS for debugging | Add developer menu with source viewer |
| Invert color filter | #622 | — | — | open | P3 | 3 | `reading_page.dart`, CSS filter | Dark mode color inversion for PDF/images | Add CSS filter option; similar to Mihon |
| Vertical text border | #824 | — | — | open | P3 | 3 | `foliate-js/`, epub CSS | Border/frame decoration for vertical text layout | Verify if CSS can handle this; low priority |
| Paragraph action buttons | #825 | — | — | open | P3 | 2 | `context_menu.dart` | Small action button at paragraph endings | Niche; evaluate if context menu is sufficient |
| Book detail metadata | #851 | — | #429, #865 | open | P2 | 2 | `book_detail.dart`, `book.dart` | Missing description, file type, size in detail page | Extend book_detail with metadata fields |
| Quick font size adjust | #854 | — | — | open | P2 | 3 | `reading_page.dart`, gesture zones | Edge swipe to adjust font size | Add gesture detection on screen edges |
| Copy book filename | #857 | — | — | open | P3 | 2 | `book_detail.dart`, `book_bottom_sheet.dart` | Can't quickly copy book name/path | Add copy button or long-press action |
| Custom bottom buttons | #859 | — | — | open | P3 | 3 | `reading_page.dart` (bottom bar) | Customize reader bottom toolbar buttons | Add button config persistence |
| Custom selection toolbar | #860 | — | — | open | P3 | 3 | `excerpt_menu.dart`, `context_menu.dart` | Customize text selection action buttons | Add toolbar config persistence |
| Large TXT lag | #864 | — | — | open | P2 | 3 | `convert_from_txt.dart`, `foliate-js` | 3.6MB txt slow load and reading lag | Implement streaming/chunked txt conversion |
| Writing direction bug | #867 | — | — | open | P2 | 2 | `epub_player.dart`, `writing_mode.dart` | EPUB CSS overrides user writing-mode setting | Ensure user pref takes priority over EPUB CSS |
| Mind map export | #846 | — | — | open | P2 | 3 | `mindmap_step_tile.dart`, `save_img.dart` | Can't export mind map to JPG/MD | Add export button with screenshot |
| Long-press popup UX | #845 | — | — | open | P2 | 3 | `book_bottom_sheet.dart`, `book_item.dart` | Bottom sheet too far from touch point | Consider inline popup or detail page as default |
| Audio book support | #847 | — | — | open | P3 | 5 | `service/tts/`, `main.dart` | Play audio files as audiobooks | New module; evaluate roadmap priority |
| In-app search | #881 | — | — | open | P3 | 3 | `reading_page.dart`, search UI | Configurable in-app search engine instead of external browser | Add search engine config; integrate results in-app |
| CJK ruby annotation | #883 | — | — | open | P3 | 3 | `foliate-js/` | Furigana/pinyin ruby text support | Verify foliate-js ruby tag rendering |
| Multi-request issue | #892 | — | #835, #887 | open | P2 | 3 | `epub_player.dart`, `reading_page.dart` | 6 requests: PDF scroll, chapter scroll, dark mode, search, resume | Split into sub-issues; PDF→#887, scroll→#835 |
| FPS locked 60 | #873 | — | — | open | P3 | 3 | `main.dart`, Flutter Engine | 120Hz screen locked to 60fps | Check FlutterEngine frame rate config |
| OPDS Grimmory support | #874 | #874 | #114 | open | P3 | 2 | `foliate-js/src/opds.js` | Already has OPDS 1.0; test with Grimmory | Test current OPDS with Grimmory server |
| Warning message | #877 | — | — | open | P3 | 2 | `foliate-js/`, epub parsing | epub warning in logs; no platform info | Add `needs-more-info`; check warning source |
| Modularity roadmap | #879 | — | — | open | P4 | 5 | N/A (architecture) | Plugin system like Obsidian | Long-term vision |
| MOAINE 9 can't open books | #891 | — | — | open | P3 | 4 | `epub_player.dart` | ARMv7 device: epub shows only center rectangle | Check WebView compat on ARMv7 |
| Notes won't save locally | #754 | — | — | open | P2 | 3 | `bookmark.dart`, `book_notes.dart`, `database.dart` | Highlights not saved locally + permissions greyed out | Check AndroidManifest permissions and local save logic |
| Book podcast summary | #917 | — | — | open | P4 | 5 | `service/ai/` | AI book → podcast (like Google NotebookLM) | Long-term roadmap |
| Global page numbering | #918 | — | — | open | P2 | 4 | `progress_widget.dart`, `foliate-js` | Only chapter-level; request full-book pagination | Need foliate-js full-book support |
| Moon+ Reader import | #921 | — | — | open | P3 | 4 | `reading_time.dart`, `book.dart` | Import reading stats from Moon+ backups | Need Moon+ backup file samples |
| Volume key turn page | #634 | — | — | open | P2 | 2 | `reading_page.dart`, key events | Volume key page turn not working (upstream limitation) | Check Flutter key event handling; may be platform limitation |
| Self-signed cert OpenAI | #643 | — | — | open | P3 | 2 | `http_client.dart`, SSL | CERTIFICATE_VERIFY_FAILED with self-signed OpenAI API | Add cert bypass option for custom endpoints |

## Code Read Notes

- 2026-05-24: WebDAV sync cluster — inspected `webdav_client.dart`, `sync.dart`. Full-DB overwrite mode confirmed.
- 2026-05-24: TTS cluster — all TTS text fetching depends on WebView JS (`callAsyncJavaScript`). Architecture-level flaw for background playback.
- 2026-05-24: AI cluster — `LangchainAiConfig` null safety issue; `_sanitizeMessagesForPrompt` strips reasoningContent.
- 2026-05-24: Bookshelf cluster — `tb_groups.parentId` exists in DB but UI never uses nested folders. No batch selection mechanism.
- 2026-05-24: Translation cluster — `TranslationMenu` hardcoded to 150px height. Azure 401 = no key format validation.
- 2026-05-24: PDF cluster — PDF rendering performance is systemic issue across multiple reports.
- 2026-05-24: Reading experience — animation controller state bug in no-animation mode (#899); context_menu auto-highlight logic issue (#900).
- 2026-05-24: Windows — close hang likely from async tasks blocking main thread during exit.

## Triage Log

- 2026-05-24: Created ledger with seed entries and label set.
- 2026-05-24: Added Priority, Complexity (1-5) columns; updated to use `isReadByViewer` for incremental triage.
- 2026-05-24: First comprehensive triage — processed 85 unread issues across 8 clusters. Closed 6 duplicates/invalid (#916, #915, #837, #599, #819, #908). Identified key architectural issues: TTS WebView dependency (#544), sync full-DB overwrite (#911), AI null safety (#868, #896). Identified quick wins: #853 (10 LOC), #896 (5 LOC).
|- 2026-05-24: Second pass — added 41 missing issues (231, 243, 323, 546, 564, 634, 643, 667, 668, 833, 848, etc.). Fixed 3 duplicate entries (#754, #919, #839). Corrected #839 classification from WebDAV/Sync to Storage Migration. Added cross-references: #345→WebDAV, #588→Sync, #668→Bookshelf, #612→#834, #888→AI. All 120 open issues now covered.
|- 2026-05-24: Third pass (review) — Added P4 definition to Priority Labels. Closed #93 as duplicate of #920 (canon: more detailed bug report; #93 noted upstream flutter_inappwebview#1204). Closed #858 as duplicate of #849 (same root cause). Fixed #612 Action wording. Noted #835, #23, #114 as referenced-but-unlisted (open issues with no entry).