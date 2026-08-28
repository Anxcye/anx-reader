# Anx Reader Product Design Decisions

## AI 架构索引

当前 AI 分层、调用链、持久化归属、同步边界、Token 用量统计和扩展契约见
[`docs/architecture/ai-architecture.md`](docs/architecture/ai-architecture.md)。
已实现功能、代码入口、复用边界和明确未实现项见
[`docs/architecture/feature-map.md`](docs/architecture/feature-map.md)，新增能力前应先查该地图。
本文继续作为产品行为、权限、剧透边界和低打扰交互的事实来源。

## Reading Task Runtime — P1

- AI and reading work uses one stable task lifecycle: `queued`, `running`,
  `paused`, `completed`, `failed`, or `cancelled`. Terminal tasks cannot be
  silently restarted; failed tasks require an explicit retry.
- Priorities are `background`, `normal`, `userInitiated`, and `critical`.
  Higher-priority work may cooperatively preempt pausable work. Equal priority
  remains FIFO. The scheduler runs one task at a time so provider limits and
  persistent writes stay predictable.
- Pause, cancel, and preemption take effect only at declared safe points
  between chapter loads, model calls, and database writes. A transaction or an
  in-flight provider response is never force-killed midway.
- Durable tasks persist immutable input payload, progress, resumable
  checkpoint, attempt count, timestamps, and error. Ephemeral tasks remain
  memory-only.
- After process restart, formerly queued or running durable tasks restore as
  `paused`. They never resume a cloud request automatically. The owning
  feature must register its executor again and the user must resume it.
- Fiction backfill is the first durable workload using the scheduler. Its
  existing per-batch Artifact checkpoints remain the data-level source of
  truth, while `ReadingTask` tracks scheduling state and visible progress.

## Reading Agent Beta — Phase 1

### Intent

Reading Agent is part of the reading environment, not a chat feature placed on
top of it. It maintains local reading state and can carry out bounded reader
actions while preserving the user's attention and control.

### Quiet-first interaction contract

- Reading Agent is opt-in and defaults off.
- Page turns, dwell time, chapter changes, and rereading are local signals.
  They must never directly invoke a cloud model or open modal UI.
- Raw relocation events stay in memory. A location becomes observable Agent
  state only after 750ms of stability and duplicate locations are discarded.
- A chapter transition creates one pending checkpoint after the new location
  remains stable for two seconds. It changes only the status capsule count.
- The capsule is attached to the existing reader controls. It is absent when
  there is no active state and hidden whenever reader controls are hidden.
- The capsule contains only a short goal, progress, and pending count. It has
  no flashing animation, respects the platform's reduced-motion behavior, and
  exposes a complete accessibility label.
- Leaving the reader never asks for confirmation. Durable goal progress is
  saved and restored on the next session.

### Authority and confirmation

- Explicit requests such as “save”, “create”, or “mark” may execute directly
  and must offer immediate undo.
- Agent-initiated ideas are previews only until the user confirms them.
- Navigation is non-persistent and does not require confirmation. It is valid
  only for the mounted book and provides a return-to-previous-location action.
- A reading goal created from natural language is presented as structured
  preview before persistence. Template goals remain available without AI.
- User input, manual navigation, and close actions always take priority over
  Agent work.

### Data truth and memory

- There is at most one active goal per book. Comprehension criteria such as
  “can explain” are completed only by the user; location-based progress may be
  updated automatically.
- Reader Profile stores supported preferences as candidate, confirmed, or
  rejected. Only confirmed values enter Agent context.
- Explicit preferences can become candidates immediately. Behavioral evidence
  needs three distinct reading sessions before surfacing. Rejected candidates
  are suppressed for 90 days.
- Source text, user facts, and model inferences remain distinguishable. An AI
  note stores its text snapshot, CFI, chapter, model, and session provenance.

### Reversibility

- Persistent Reading Agent mutations go through `AgentActionService` and are
  journaled in the same database transaction as their data change.
- Undo is idempotent and available immediately from Snackbar and for 30 days
  in the AI workspace action history. At most 200 action records are retained.
- Undo refuses to overwrite data modified after the action and explains the
  conflict. There is no redo.
- Undoing an AI note removes its formal note and Agent-owned annotation.
  Difficulty undo restores the exact pre-action state.

### Phase boundaries

Phase 1 has no background wakeups, vector database, cross-book knowledge graph,
automatic skill learning, or automatic cloud analysis. It does not enable the
legacy `readingCoach` or its MaterialBanner behavior.

## Reading Agent Beta — Phase 2

### Reading closure

- A stable transition out of a chapter persists one local pending checkpoint.
  It changes only the capsule count; it never starts a model call or opens UI.
- A chapter check begins only after the user opens the Agent panel and presses
  “检查”. The user supplies the mastery level; the model cannot promote its own
  explanation into evidence of mastery.
- An optional one-sentence recall becomes a local knowledge card due the next
  day. Reviews use a deliberately small schedule: “再学习” returns in one day,
  while “记住了” doubles the interval up to 60 days.
- Unresolved difficulties are book-scoped rather than chapter-scoped in the
  queue. They remain visible across chapter and session boundaries and retain
  their original chapter and CFI for navigation.

### Resumable context and Markdown memory

- Starting the next reading session restores the active goal, pending chapter
  checks, unresolved difficulties, due-card count, recent mastery summary,
  confirmed profile, and Markdown memory titles before Agent chat is used.
- Markdown memory is a small, database-backed document format: title, Markdown
  body, optional source references, and timestamps. It is local-first and is
  included in the existing database snapshot sync; it is not a vector store.
- Explicit user requests may save Markdown memory immediately. Agent-initiated
  memory is a confirmation preview. Writes are journaled and undoable under the
  same 30-day conflict-safe rules as other Agent writes.
- Only memory titles enter the automatic world-state prompt. The document body
  is available through the explicit `reading_memory_recall` tool, preventing
  silent growth of prompt context.

### Low-interruption policy

- The policy output is intentionally limited to `none` or `passiveCapsule`.
  It has no authority to invoke a model, show a modal/banner/notification, or
  persist an Agent suggestion.
- The capsule appears only with reader controls, remains dismissible for the
  session, contains counts and short labels only, and never reveals a card
  answer or generated review text.
- All completion checks, card reviews, mastery updates, and memory previews are
  entered from a user click. Manual navigation, selection, and closing the
  reader remain higher priority than the closure workflow.

### Book reading outcomes

- “Book reading outcomes” is the durable review surface for the reading loop.
  It is reachable from book details and from the Reading Agent panel; it does
  not depend on a pending capsule being visible.
- The page answers four questions in order: what is the next action, what was
  read, what is understood, and what remains unresolved. It combines the
  active goal and goal history, pending chapter checks, chapter mastery,
  unresolved difficulties, active knowledge cards, and Markdown memories.
- The overview uses compact local metrics only. It never generates a summary
  or invokes a model merely because the page opens or refreshes.
- Knowledge-card answers stay collapsed until the user expands a card. Review
  actions remain explicit. “Learn again” schedules one day; “Remembered”
  doubles the interval up to 60 days.
- Markdown memory bodies are readable on demand and remain visually secondary
  to their titles. Source references navigate the mounted reader when opened
  during a reading session, otherwise they open the book at that location.
- Empty states teach the smallest complete loop: enable Reading Agent Beta,
  create a goal, finish a chapter check, and return to see the result.
- The page uses existing Material surface, typography, and color roles. On
  narrow screens it is one scrollable column; metric tiles wrap rather than
  forcing horizontal scrolling. All sections remain visible when empty so the
  reader understands what outcomes can be formed.

### Reading Skill registry and progressive loading

- A Reading Skill is a reading method, not a bundle of executable tools. The
  built-in registry contains Socratic concept teaching, argument mapping,
  historical source checking, fiction character tracking, academic critical
  reading, contextual language learning, financial assumption validation,
  chapter closure, exam review, and reading-to-action planning.
- The registry has three context layers. Catalog content is a title and one
  sentence for method selection; summary guidance is the only layer included
  for an ordinary AI turn; full guidance is loaded only after explicit method
  intent, deep analysis, or a user-opened chapter closure. The system never
  places every full method in one prompt, and ordinary reader events do not
  load a method or invoke a model.
- Matching is local and deterministic. A per-book pinned method wins, then an
  explicit task intent, then book metadata and reading mode. Fiction defaults
  to spoiler-safe character tracking, economics to argument or financial
  assumption analysis, and psychology to Socratic concept teaching. Chapter
  closure becomes the primary method only while that workflow is active, with
  at most one domain method included as a summary.
- Method output is not a mastery fact. A method may contribute a checkpoint,
  self-assessed mastery, unresolved difficulty, due knowledge card, Markdown
  memory, or next goal, but persistent writes still use the existing explicit
  request/confirmation and 30-day undo contract.
- Readers see the current method as a compact row in the AI workspace and as
  provenance on Book Reading Outcomes. They can pin one method for the book or
  restore automatic matching without exposing prompts, tools, or orchestration
  terminology.

### In-product help and teaching

- Reading Agent Beta and Reading Skill each have a durable, scrollable teaching
  page. Help is available before enabling the beta from AI Settings and while
  reading from the Agent panel, Skill row, Skill picker, and Book Reading
  Outcomes; it is not a one-time onboarding overlay.
- Both pages lead with a short purpose statement and a four-step quick start,
  then progressively disclose behavior and safeguards. Reading Agent teaching
  explains the closure loop, passive capsule, model-call boundary, write
  permissions, source traceability, undo, and local event handling. Reading
  Skill teaching explains local matching, per-book pinning, explicit intent,
  three prompt-loading layers, closure outputs, and all registered methods.
- The Skill page includes tailored starting points for fiction, economics, and
  psychology. Method descriptions use reader-facing language and never expose
  internal prompts or tool orchestration. The two pages cross-link so users can
  understand that Agent owns the loop while Skill owns the reading method.
- Help pages use the existing Material color and typography roles, a single
  responsive scroll column, semantic headings, minimum touch targets, and
  expandable catalog rows. Opening help never calls a model or changes reading
  state.

### Genre-adaptive reading closure policies

- Reading Agent Runtime, events, permissions, undo, and local persistence are
  shared infrastructure. A separate Closure Policy decides what counts as an
  outcome, whether a chapter checkpoint should surface, what the checkpoint
  asks, and whether mastery or review cards belong in the loop. Reading Skill
  continues to decide how AI reasons; it does not own product intervention.
- Closure selection is local and deterministic. A per-book override wins;
  otherwise psychology mode or metadata selects psychology reflection, fiction
  metadata selects fiction immersion, and remaining books use knowledge
  argument. Readers can inspect and override the result from the Reading Agent
  panel and Book Reading Outcomes.
- Fiction immersion prioritizes narrative flow and spoiler safety. Chapter
  switches may create local, optional review checkpoints but checkpoint-only
  state never surfaces the capsule. Fiction has no mastery score or scheduled
  review-card UI. Its explicit checkpoint captures an optional feeling or open
  question as undoable Markdown memory and uses only information available at
  the current progress.
- Knowledge argument uses claim, evidence, assumption, counterexample, and
  applicability as its checkpoint language and outcome vocabulary. Mastery is
  user-confirmed. A one-day recall card is opt-in rather than an automatic side
  effect of writing a reflection.
- Psychology reflection uses concept clarity instead of generic mastery. It
  distinguishes definition, boundary, example, counterexample, and application;
  personal reflection is always optional, is never treated as a diagnostic
  fact, and can be kept as undoable Markdown memory. Review cards remain opt-in.
- Goal templates, quick AI prompts, pending-checkpoint labels, difficulty and
  memory sections, outcome metrics, next action, and empty-state language all
  come from the active Closure Policy. Switching policy does not delete old
  outcomes; it only changes how the shared records are presented and what new
  interactions create.

### Extensible reading experience modules

- A closure module is identified by a stable, namespaced string such as
  `fiction.immersion`; persisted data must never depend on a Dart enum name.
  The former enum remains only as a compatibility adapter, and legacy values
  are normalized when read rather than copied into new records.
- `BookReadingProfile` is the synchronized per-book source of truth for the
  primary module, content facets, match confidence, match source, and whether
  the reader pinned the choice. The in-memory cache exists only to support
  synchronous UI and prompt lookups. A legacy SharedPreferences choice is
  lazily migrated to this table and removed after a successful database save.
- Suspense books keep `fiction.immersion` as their primary closure and add the
  stable `fiction.suspense` facet. The facet selects the
  `processing.volume_case_scene` strategy, durable relationship filtering and
  narrative-order timeline without introducing a genre-specific page branch.
- A module contributes declarations: goal templates, checkpoint behavior,
  mastery choices, outcome sections, quick prompts, capabilities, and reader-
  facing language. It cannot invoke a model, write persistent data, or open
  UI. Reader and outcomes surfaces render registry declarations without
  branching on built-in module ids.
- Registry extensibility is a tested contract. Registering another module with
  a new stable id and existing outcome sources must make its picker entry,
  goal templates, quick prompts, checkpoint vocabulary, and outcome sections
  render without edits to the reading page or outcomes page.

### Source-safe Reading Artifacts

- A Reading Artifact is a versioned module projection with a stable kind,
  structured payload, epistemic status, lifecycle status, source snapshot and
  location, session provenance, and creator. Text facts, user reflections,
  Agent inferences, and externally checked facts remain distinguishable.
- Artifact position and ingestion time are separate. `sourceProgress` records
  where an event occurred, `visibleFromProgress` is the enforceable spoiler
  boundary, and `ingestedAt` plus `ingestionMode` record when and how it entered
  the system (`live`, `backfill`, `imported`, or `synced`). A backfilled event
  from 18% therefore remains hidden when the reader navigates to 10%, even if
  the Agent created it today.
- User- or Agent-authored Artifact writes require a traceable source, use the
  common Agent action transaction, and are conflict-safe and undoable for 30
  days. A deterministic runtime resume marker is local reader state rather
  than AI-authored content, so it is synchronized but does not create a noisy
  undo action.
- Fiction phase-one projections provide character recall, a suspense ledger,
  and resumable context. They are local-first and never trigger a model from a
  page turn or session start. On the next session, availability is shown only
  in the passive controls-attached capsule; details open after the reader taps.

### Fiction Story Atlas

- Collection EPUBs are parsed as `work -> volume -> arc -> scene`. A top-level
  TOC entry with children establishes a stable href-derived `workId` and
  `workTitle`; ordinary “第一章/第二章” entries inside that work are scenes, not
  separate cases. Backfill artifacts and checkpoints carry the work scope,
  and Atlas filtering applies `workId` before `arcId`, so adjacent novels in a
  single EPUB can never share characters, relationships, or timeline events.
  Legacy artifacts without work scope remain readable.
- The character graph and story timeline are projections of synchronized
  Reading Artifacts, not new database truth sources. `fiction.character`,
  `fiction.relationship`, and `fiction.event` remain forward-compatible kinds;
  unknown kinds are preserved by sync and safely ignored by these views.
- Both views filter with `visibleFromProgress` at the book's current position.
  Relationship history is ordered by source position and the latest visible
  revision becomes the current edge. Returning to an earlier position hides
  later characters, events, and relationship revisions.
- When Artifacts carry an `arcId`, `FictionStoryAtlasService` derives the latest
  arc encountered at the current source progress and filters the graph and
  timeline to that case. Explicitly global/main-character Artifacts remain
  visible; legacy Artifacts without an `arcId` remain compatible. Callers may
  provide an explicit arc scope for a focused case view.
- Timeline order is narrative encounter order (`sourceProgress`, source CFI,
  then creation order). `storyTimeLabel` is display-only; missing story time is
  shown as unknown rather than inferred into a false calendar date.
- Extraction distinguishes the frame/outer narrator (`narrator.outer`,
  `narrative.outer`) from a named character narrating their own story
  (`narrative.inner`). Legacy `narrator.primary` data resolves to the outer
  narrator but is not written by new extraction. Relationship labels use
  stable namespaced types such as `relation.mentor`, `relation.partner`,
  `relation.schoolmate`, `relation.colleague`, `relation.family`,
  `relation.ally`, and `relation.rival`, while the original Chinese label
  remains for display. Character artifacts are layered as `protagonist`,
  `case`, `case_victim`, or `background`; the graph defaults to protagonist
  and current-case layers.
- Event artifacts carry namespaced semantic tracks (`story.case`,
  `story.family`, `story.historical`, `story.character`, and related tracks)
  and deterministic stages (`stage.incident`, `stage.investigation`,
  `stage.autopsy`, `stage.conflict`, `stage.revelation`, etc.). Legacy and
  localized values are normalized on read; unknown model values become the
  corresponding `*.other/general` ID instead of entering persistence as a new
  taxonomy. `BookReadingProfile` selects the default case, family, historical,
  or character-growth track; a missing preferred track falls back to all
  visible events rather than showing an empty archive.
- Opening an atlas page never invokes a model. Organizing or updating is only
  available from an active reader, previews the completed safe chapter range,
  and calls AI after explicit confirmation. Stable content-derived Artifact
  ids make repeated organization idempotent and every accepted write remains
  in the Agent action/undo path.
- Backfill uses the persisted Artifact coverage start as its lower bound after
  the reader chooses “from here”. A first-run “整理已读部分” explicitly opts
  into the 0% prefix. Synced Artifacts can therefore restore work from another
  device without treating this device's unseen prefix as locally read; only
  the missing range inside the confirmed safe boundary is considered.
- A manual organize action always uses this device's current settled reading
  position as its upper bound. The synchronized global farthest position is a
  resume suggestion only and never authorizes AI to scan farther. Its lower
  bound defaults to 0%; only a device-local, explicit “from here” choice raises
  that bound. This local choice is excluded from preference backup/import.
- Fiction backfill is incremental and resumable. Each successfully processed
  chapter stores a synchronized `fiction.backfill_checkpoint` Artifact with a
  content hash and extractor version. Unchanged completed chapters are skipped;
  changed chapters are processed again. Checkpoints are emitted only after the
  corresponding AI Artifacts have been persisted.
- Initial backfill groups chapters within a 7,200 source-character extraction
  budget and at most two requests in flight. Long chapters split at sentence
  boundaries before retrying, so one malformed result cannot replay an entire
  case. A failed concurrent batch
  must not discard checkpoints from successful sibling batches. The default
  extraction surface is deliberately limited to characters, relationships, and
  important events to avoid token-heavy scene-by-scene summaries.
- Character identity resolution is culture-aware. Chinese historical and
  classical fiction keeps formal name (`name`), courtesy name (`字`), art name
  (`号`), and titles as separate fields on one canonical person; a 字、号 or
  title never becomes another node when its identity is explicit. Western
  fiction resolves full names, given names, family names, nicknames, and title
  forms under Western ordering and punctuation rules. Generated short forms
  are accepted only when unique; ambiguous surnames, given names, 字 or titles
  remain unresolved instead of being guessed or rendered as duplicate nodes.
- Character nodes use local text avatars only, selecting the given-name
  character for Chinese full names rather than the surname. No portrait is
  generated or downloaded. Phones use a zoomable graph with bottom details and
  a vertical timeline; wide layouts reserve a details rail and use a horizontal
  alternating timeline. Entry visibility is capability-driven (`storyAtlas`),
  not a hard-coded closure id.

### Mid-book Reading Agent activation

- `currentPosition`, `safeKnowledgeBoundary`, and Artifact coverage are three
  independent states. Current position stays in the in-memory world state;
  the spoiler boundary and coverage interval live in the synchronized per-book
  coverage table. Coverage must never imply that the Agent read text it did
  not ingest.
- When fiction support is first enabled after meaningful progress, the default
  behavior is “from here.” The Agent does not scan earlier chapters or claim
  knowledge of them. A passive controls-attached capsule may say where support
  began and offer archive setup; it never opens a modal or calls a model by
  itself.
- The reader may explicitly choose “from here,” “organize read chapters,” or
  “import existing outcomes.” Organizing shows the boundary and chapter count
  before confirmation, calls the model only after confirmation, and must not
  request any chapter beyond the safe boundary. Imported notes, Markdown, and
  synchronized Artifacts retain their provenance; highlights are not silently
  converted into story facts.
- Returning to an earlier location always filters Artifacts by
  `visibleFromProgress`. Ingestion time, device arrival time, and sync order do
  not relax the spoiler boundary.

### Multi-device Reading Agent synchronization

- Legacy whole-database WebDAV sync remains a compatibility fallback, but it
  is not the conflict model for Reading Agent state. Before any database
  replacement, the runtime captures per-book state; after replacement it
  merges that capture with every remote device package and only then uploads
  this device's merged package.
- Remote packages are isolated by stable book key and installation id:
  `reading-agent/{file-md5-or-id}/{device-id}.json`. A device replaces only its
  own package. Unknown schema versions, malformed JSON, and packages for books
  absent locally are ignored without changing local data.
- Reading position is keyed by `(book, deviceId)` and merged by latest
  `updatedAt`. Reopening a book restores this installation's own position. The
  global farthest progress is derived with `MAX(progress)` and may advance the
  spoiler-safe knowledge boundary, but it must never force another device to
  jump forward.
- After the reader is ready, a valid position from another device that is more
  than one percentage point ahead may produce one session-scoped choice:
  continue locally (the emphasized default) or explicitly jump to the remote
  CFI. Dismissing the dialog keeps the local position. A cloud-sync control
  beside the AI entry lets the reader repeat this check manually; it reports
  when no farther position exists and never navigates without confirmation.
- Records with stable ids use last-write-wins. Equal-time lifecycle conflicts
  prefer terminal states so completed, resolved, or retracted work is not
  accidentally reopened. Artifact conflicts retain the later/more
  conservative `visibleFromProgress`. A user-pinned book profile beats an
  automatic profile. Coverage unions known ranges and never lets `pending`
  replace an initialized state. If concurrent packages contain multiple active
  goals, only the most recently updated remains active.
- Hard deletion is represented by a per-device tombstone and wins over an
  older row. Agent undo creates tombstones for newly created goals,
  difficulties, Markdown memories, and Artifacts. Action logs are device-local:
  remote state can be consumed on every device, but cross-device undo is not
  promised in this phase.

### Fiction character archive presentation

- The fiction entry is named “故事人物档案”; the relationship network remains
  available as a secondary view rather than a required reading output.
- Compact mode is selected by default for small casts and shows current-person
  recall plus the protagonist's local one-hop relationships. Complete mode is
  an explicit user choice for the full network. The choice is stored per book
  and per device, not synchronized.
- Person recall and the mystery ledger are the baseline fiction outputs;
  generating or opening a relationship graph is optional and never triggers AI.

## CloudBase Reading Agent Sync

CloudBase is an optional transport for Reading Agent state, not a replacement
for WebDAV whole-database or book-file sync. Each device uploads an independent
`ReadingAgentBookDelta`. The local `ReadingAgentSyncService` remains the source
of truth for tombstones, per-device positions, coverage, goals and Artifact
merge rules; the server only isolates and returns packages.

- Flutter never contains a CloudBase administrator API Key. The normal flow
  keeps only an account session token. Legacy sync-space IDs and recovery codes
  are deliberately unsupported; users sign in with the same account on every
  device.
- The account session token is excluded from normal preferences backup/import.
- CloudBase PG stores only hashes of account sessions and scrypt password
  hashes. Tables deny direct
  `anon` and `authenticated` access; the HTTP Function is the only data path.
- The HTTP Function does not return headers, environment variables or CloudBase
  context, caps request bodies at 2 MiB, and validates package/path identities.
- Automatic CloudBase sync is silent. Failures are logged and do not block
  reading or WebDAV; explicit manual sync reports success or failure.
- CloudBase settings use explicit actions: register/sign in, test connection,
  and sign out. There is no separate Save button. Registration/sign-in saves
  the endpoint and session immediately; a successful connection test saves a
  newly entered endpoint, while dismissing the dialog leaves it unchanged.
- CloudBase sync never invokes an AI model and does not broaden the Reading
  Agent's spoiler boundary or artifact coverage.
- New CloudBase sync accounts no longer require an invitation. Registration
  creates one account-owned sync space, and any number of devices can sign in
  to that account. Passwords are scrypt-hashed in the function's PG boundary;
  the account session is the only sync credential exposed to Flutter.

### WebDAV automatic-sync interruption policy

- Automatic WebDAV checks never open the upload/download direction dialog. A
  local database change is uploaded silently when the remote timestamp still
  matches the last successful sync baseline; a remote-only change is downloaded
  silently. If both sides changed, the check is deferred and the next explicit
  manual sync presents the conflict choice.
- The client stores both the last acknowledged remote timestamp and the local
  database/WAL timestamp captured after a successful sync. This prevents the
  device's own reading progress or upload mtime from being reported as an
  external change on the next periodic check.
- All automatic and manual requests still pass through the single-flight gate;
  repeated taps or overlapping lifecycle triggers join the in-flight operation.
- Automatic sync has a short device-local cooldown and an offline backoff. This
  coalesces lifecycle, bookshelf and reading-progress triggers and avoids
  repeated network wakeups while Wi-Fi is unavailable; manual sync is never
  blocked by the cooldown.

## Hybrid extraction and internal summary engine

### Science-fiction and sparse-TOC fiction

- Science-fiction remains inside the fiction immersion closure. Its profile
  adds stable `fiction.science_fiction`, `entities.worldbuilding`, and
  `timeline.default.worldbuilding` facets, so the default timeline is
  `story.worldbuilding` without adding a science-fiction page branch.
- Collection EPUBs may expose only volume titles in NCX while keeping real
  chapters in spine documents. Only after the reader explicitly confirms
  story-archive organization may the reader request a local spine manifest of
  href, heading, progress, and text length. The manifest contains no body text,
  does not invoke a model, and is never built from page-turn events or merely
  opening outcomes. Roman-numbered series entries form independent works.
- Extraction distinguishes stable `entity.*` types. People and intelligent
  non-human actors with durable identities may enter the character archive;
  civilizations, organizations, species, technologies, places, and concepts
  must not become person nodes or relationship endpoints. Their effects belong
  on the worldbuilding event track. Every accepted cloud or local candidate
  still requires a bounded verbatim source quote.
- A chapter prompt caps output candidates to four characters, two durable
  relationships, and four meaningful events. This prevents worldbuilding-heavy
  chapters from turning every technical noun into a node or exhausting the
  structured-output budget.

- The lightweight extraction engine is a device-local AI role selected from
  the existing Provider registry. It is disabled by default. Custom
  OpenAI-compatible providers may explicitly use no authentication for a
  trusted local or private-network LM Studio/Ollama endpoint; built-in cloud
  providers still require credentials. A local endpoint selection is excluded
  from preference restore because `localhost` and LAN addresses are not
  portable between devices. Its product role is explicitly “local candidate
  extractor + evidence filter”, not a full-book relationship-graph generator.
- User-visible chapter and book summaries remain on the general model. The
  lightweight role is limited to Story Atlas candidate extraction, cached
  rolling conversation summaries, and reading-memory topic grouping. These
  internal jobs never run because of page turns, dwell time, or opening an
  outcomes page.
- Story Atlas hybrid backfill sends full eligible chapter text only to the
  selected extraction provider. A long chapter is segmented at paragraph or
  sentence boundaries within the extraction input budget and receives one
  completed checkpoint only after every segment succeeds. Malformed JSON is
  retried once with smaller current-chapter inputs, never as an unbounded batch
  retry. Every candidate needs an exact, bounded source
  quote. Deterministic validation rejects missing evidence, generic roles,
  background references, transient interactions, and unsupported relation
  types. Only ambiguous durable relations cross the cloud boundary, with the
  two endpoints and short quote rather than the complete chapter.
  The task-level cloud-verification input budget is capped at 20% of the same
  batch's full-text baseline; ambiguous candidates beyond that budget remain
  pending rather than expanding the cloud request.
- If the extraction provider is absent or unavailable, full-text cloud
  fallback requires a second explicit confirmation that shows the range,
  chapter count, model destination, and estimated input. The safe default is
  cancel/later. Opportunistic internal summaries simply defer on failure.
- Connection/structured-output test failure disables the extraction role on
  that device. It never silently reassigns the role to the general provider.
- Token diagnostics distinguish local extraction, cloud extraction, cloud
  verification, and general generation. Story Atlas reports avoided main-model
  input against an equivalent full-text baseline. A cloud small model may be
  cheaper without reducing total cloud tokens, so it is never labelled as a
  raw-token saving unless the measured totals support that claim.

## Specialist orchestration P1

- A reading turn captures one immutable, token-bounded expert context snapshot.
  Every selected specialist receives that same snapshot; specialists must not
  independently rebuild or expand the complete chat history.
- Specialist work has a separate budget from the primary answer: at most two
  specialists, 5,000 estimated input tokens and 1,200 reserved output tokens
  per specialist, and at most four Evidence Objects per result. The primary
  assistant still owns the final answer.
- Specialist output crosses the orchestration boundary only as an
  `EvidenceObject`: attributable claim, short support, uncertainty, confidence,
  and source URLs. URLs not present in the retrieved source set are discarded.
  Raw verbose specialist prose is not appended to the user request or stored
  as the authoritative answer.
- Search, provider, timeout, malformed JSON, and individual specialist failures
  degrade independently. Available evidence from other specialists remains
  usable; when no valid evidence remains, the original messages continue to
  the primary assistant without an error dialog or invented citation.
- Evidence is persisted inside the existing Agent trace. It is explicitly an
  inference draft, not a source fact, Reader Profile item, or permission to
  perform a write action.

## Per-device display profiles

- Display hardware and interface color are independent dimensions. The device
  profile is `standard` (OLED/LCD) or `eink`; color appearance remains system,
  light, or dark, with OLED pure black as a retained dark-surface preference.
- The device profile, color mode, and pure-black choice are local settings and
  are excluded from preferences backup/restore. Reading progress and user
  content may synchronize, but one device must never change another device's
  display profile.
- E-ink applies effective, reversible overrides: light high-contrast colors,
  no page animation, no background image, and no code highlighting. It does
  not delete or replace the stored color mode, reader theme, page-turn style,
  or OLED preference. Switching back to OLED/LCD restores those choices.
- Appearance settings lead with a status card for this device, including an
  explicit “device-only” explanation. Interface colors are a separate section.
  Options unavailable under E-ink remain visible with a reason, rather than
  being silently reset or hidden.
- Legacy `themeMode=eInk` and the older `eInkMode` boolean migrate to the E-ink
  device profile. The stored color mode becomes light only when the legacy
  combined value has no independent color preference to recover.

## Book Wiki

### 整理输入与证据

Wiki 与 Story Atlas 的长章节整理统一经过 `ReadingChunker`：先按段落、句末和换行
切分为有上限的 `ReadingChunk`，每个对象带稳定 ID、内容哈希、原章节字符 offset 和
pipeline 版本。它只在用户确认生成/更新后创建，不是新的事实表；任务 checkpoint 只
保存 chunk 元数据，不保存完整正文。

模型返回的 evidence 必须通过 `ReadingEvidenceResolver` 定位到原文。Resolver 支持
精确子串、空白/全半角标点归一化和有限的引用外壳清理，最终 `textSnapshot` 始终是
原章节的精确切片，并保留起止 offset。无法安全定位的证据会被跳过，不调用模型补证据，
也不接受模糊关键词。chunk 范围是重复证据选择和安全边界，不能泄露其他片段内容。

- Book Wiki is a local-first browsing index over persisted Wiki entries,
  Story Atlas artifacts, Markdown memories, and reading outcomes. It does not
  replace those sources of truth and opening the Wiki never loads chapter text
  or invokes a model.
- The default generation scope is the current device's safe reading boundary.
  Full-book generation is a separate action with a second confirmation that
  states chapter count, estimated input, full-book access, and spoiler risk.
- Each persisted entry has a stable namespaced kind, source references,
  `visibleFromProgress`, epistemic status, version, and creator. Returning to
  an earlier position hides later entries. Synchronization must not expand a
  device's default spoiler visibility.
- AI generation is chapter-bounded and incremental. A content hash and stable
  entry ID prevent unchanged chapters from being regenerated. Invalid JSON,
  unsupported kinds, missing exact evidence, and out-of-bound chapters are
  rejected without replacing existing usable entries.
- AI writes, hiding, and local correction use AgentActionService. A user
  correction increments the entry version, is recorded as a revision, wins
  synchronization conflicts over generated content, and cannot be silently
  overwritten by a later generation.
- The reading toolbar exposes `AI | Wiki | Reading outcomes | Sync`. The book
  details page exposes a read-only Wiki entrance; generation remains in an
  active reader where chapter access and the confirmation boundary are known.
- E-ink uses the same static cards and native navigation with no required
  animation. New book types register Wiki mappings; Wiki pages do not branch
  on book genre.
