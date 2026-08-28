import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:anx_reader/utils/get_path/get_cache_dir.dart';
import 'package:anx_reader/utils/platform_utils.dart';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Current app database version
const int currentDbVersion = 22;

String _canonicalHash(Object? value) => sha256
    .convert(utf8.encode(jsonEncode(_canonicalDatabaseValue(value))))
    .toString();

Object? _canonicalDatabaseValue(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {
      for (final key in keys) key: _canonicalDatabaseValue(value[key]),
    };
  }
  if (value is List) {
    return value.map(_canonicalDatabaseValue).toList(growable: false);
  }
  return value;
}

const createBookSQL = '''
CREATE TABLE tb_books (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  cover_path TEXT,
  file_path TEXT,
  last_read_position TEXT,
  reading_percentage REAL,
  author TEXT,
  is_deleted INTEGER,
  description TEXT,
  create_time TEXT,
  update_time TEXT
)
''';

const createThemeSQL = '''
CREATE TABLE tb_themes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  background_color TEXT,
  text_color TEXT,
  background_image_path TEXT
)
''';

const createStyleSQL = '''
CREATE TABLE tb_styles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  font_size REAL,
  font_family TEXT,
  line_height REAL,
  letter_spacing REAL,
  word_spacing REAL,
  paragraph_spacing REAL,
  side_margin REAL,
  top_margin REAL,
  bottom_margin REAL
)
''';

const primaryTheme1 = '''
INSERT INTO tb_themes (background_color, text_color, background_image_path) VALUES ('fffbfbf3', 'ff343434', '')
''';
const primaryTheme2 = '''
INSERT INTO tb_themes (background_color, text_color, background_image_path) VALUES ('ff040404', 'fffeffeb', '')
''';

const createNoteSQL = '''
CREATE TABLE tb_notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER,
  content TEXT,
  cfi TEXT,
  chapter TEXT,
  type TEXT,
  color TEXT,
  create_time TEXT,
  update_time TEXT
)
''';

const createReadingTimeSQL = '''
CREATE TABLE tb_reading_time (
  id INTEGER PRIMARY KEY,
  book_id INTEGER,
  date TEXT,
  reading_time INTEGER
)
''';

const createGroupSQL = '''
CREATE TABLE tb_groups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  parent_id INTEGER,
  is_deleted INTEGER DEFAULT 0,
  create_time TEXT,
  update_time TEXT,
  FOREIGN KEY (parent_id) REFERENCES tb_groups(id)
)
''';

const createVocabularySQL = '''
CREATE TABLE IF NOT EXISTS tb_vocabulary (
  id TEXT PRIMARY KEY,
  word TEXT NOT NULL,
  normalized_word TEXT NOT NULL UNIQUE,
  lemma TEXT,
  phonetic TEXT,
  definition_cn TEXT,
  definition_en TEXT,
  part_of_speech TEXT,
  audio_url TEXT,
  book_id TEXT NOT NULL,
  book_title TEXT,
  chapter_id TEXT,
  chapter_title TEXT,
  source_sentence TEXT NOT NULL,
  source_sentence_translation TEXT,
  contextual_definition TEXT,
  context_before TEXT,
  context_after TEXT,
  example_sentence TEXT,
  example_translation TEXT,
  position TEXT,
  review_stage INTEGER NOT NULL DEFAULT 0,
  next_review_at TEXT NOT NULL,
  last_reviewed_at TEXT,
  familiarity TEXT NOT NULL DEFAULT 'newWord',
  correct_count INTEGER NOT NULL DEFAULT 0,
  wrong_count INTEGER NOT NULL DEFAULT 0,
  is_mastered INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''';

const createVocabularyReviewIndexSQL = '''
CREATE INDEX IF NOT EXISTS idx_vocabulary_next_review_at
ON tb_vocabulary(next_review_at, is_mastered)
''';

const createAiSessionsSQL = '''
CREATE TABLE IF NOT EXISTS tb_ai_sessions (
  id TEXT PRIMARY KEY,
  title TEXT,
  service TEXT NOT NULL DEFAULT '',
  model TEXT NOT NULL DEFAULT '',
  bookId INTEGER,
  bookTitle TEXT,
  chapterTitle TEXT,
  chapterHref TEXT,
  readingMode TEXT,
  analysisDepth TEXT,
  frameworks TEXT NOT NULL DEFAULT '[]',
  outputTemplate TEXT,
  readingGoal TEXT,
  analysisResult TEXT,
  contextSnapshot TEXT,
  agentTraces TEXT NOT NULL DEFAULT '[]',
  citations TEXT NOT NULL DEFAULT '[]',
  messages TEXT NOT NULL DEFAULT '[]',
  completed INTEGER NOT NULL DEFAULT 0,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
)
''';

const createReadingGuidesSQL = '''
CREATE TABLE IF NOT EXISTS tb_reading_guides (
  book_id INTEGER PRIMARY KEY,
  status TEXT NOT NULL DEFAULT 'notStarted',
  topic_choice TEXT,
  goal_choice TEXT,
  note TEXT,
  report TEXT,
  answers TEXT NOT NULL DEFAULT '{}',
  updated_at INTEGER NOT NULL
)
''';

const createReadingQuizzesSQL = '''
CREATE TABLE IF NOT EXISTS tb_reading_quizzes (
  id TEXT PRIMARY KEY,
  book_id INTEGER NOT NULL,
  chapter_href TEXT NOT NULL,
  chapter_title TEXT,
  questions TEXT NOT NULL DEFAULT '[]',
  answers TEXT NOT NULL DEFAULT '{}',
  mastery TEXT,
  completed INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
)
''';

const createReadingDifficultiesSQL = '''
CREATE TABLE IF NOT EXISTS tb_reading_difficulties (
  id TEXT PRIMARY KEY,
  book_id INTEGER NOT NULL,
  cfi TEXT NOT NULL,
  selected_text TEXT NOT NULL,
  chapter_href TEXT,
  chapter_title TEXT,
  context TEXT,
  difficulty_type TEXT NOT NULL DEFAULT 'later',
  status TEXT NOT NULL DEFAULT 'unresolved',
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE(book_id, cfi, selected_text)
)
''';

const createReadingCoachIndexesSQL = '''
CREATE INDEX IF NOT EXISTS idx_reading_quizzes_book_chapter
ON tb_reading_quizzes(book_id, chapter_href);
CREATE INDEX IF NOT EXISTS idx_reading_difficulties_book_status
ON tb_reading_difficulties(book_id, status)
''';

const createReadingMemorySQL = '''
CREATE TABLE IF NOT EXISTS tb_reading_memory_sources (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, source_type TEXT NOT NULL,
  source_ref TEXT, chapter_href TEXT, chapter_title TEXT, cfi TEXT,
  text_snapshot TEXT NOT NULL, content_hash TEXT NOT NULL, created_at INTEGER NOT NULL,
  UNIQUE(book_id, source_type, content_hash)
);
CREATE TABLE IF NOT EXISTS tb_reading_memory_topics (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, title TEXT NOT NULL,
  summary TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'suggested',
  batch_id TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS tb_reading_topic_sources (
  topic_id TEXT NOT NULL, source_id TEXT NOT NULL,
  PRIMARY KEY(topic_id, source_id)
);
CREATE TABLE IF NOT EXISTS tb_reading_knowledge_cards (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, topic_id TEXT NOT NULL,
  question TEXT NOT NULL, answer TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'suggested', review_stage INTEGER NOT NULL DEFAULT 1,
  next_review_at INTEGER NOT NULL, hard_count INTEGER NOT NULL DEFAULT 0,
  remembered_count INTEGER NOT NULL DEFAULT 0, mastered_count INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS tb_reading_card_sources (
  card_id TEXT NOT NULL, source_id TEXT NOT NULL,
  PRIMARY KEY(card_id, source_id)
);
CREATE TABLE IF NOT EXISTS tb_reading_card_reviews (
  id TEXT PRIMARY KEY, card_id TEXT NOT NULL, book_id INTEGER NOT NULL,
  rating TEXT NOT NULL, previous_stage INTEGER NOT NULL, next_stage INTEGER NOT NULL,
  previous_review_at INTEGER NOT NULL, next_review_at INTEGER NOT NULL,
  reviewed_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_memory_sources_book ON tb_reading_memory_sources(book_id);
CREATE INDEX IF NOT EXISTS idx_memory_topics_book_status ON tb_reading_memory_topics(book_id, status);
CREATE INDEX IF NOT EXISTS idx_memory_cards_book_due ON tb_reading_knowledge_cards(book_id, status, next_review_at);
CREATE INDEX IF NOT EXISTS idx_memory_reviews_book_time ON tb_reading_card_reviews(book_id, reviewed_at DESC)
''';

const createReadingNotesWorkspaceSQL = '''
CREATE TABLE IF NOT EXISTS tb_reading_notes (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, title TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'active', capture_kind TEXT NOT NULL DEFAULT 'manual',
  is_favorite INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL, deleted_at INTEGER
);
CREATE TABLE IF NOT EXISTS tb_reading_note_blocks (
  id TEXT PRIMARY KEY, note_id TEXT NOT NULL, block_type TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '', sort_order INTEGER NOT NULL DEFAULT 0,
  origin TEXT NOT NULL DEFAULT 'user', created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS tb_reading_note_sources (
  note_id TEXT NOT NULL, source_type TEXT NOT NULL, source_ref TEXT NOT NULL,
  chapter_href TEXT, chapter_title TEXT, cfi TEXT, text_snapshot TEXT NOT NULL DEFAULT '',
  metadata TEXT NOT NULL DEFAULT '{}', created_at INTEGER NOT NULL,
  PRIMARY KEY(note_id, source_type, source_ref)
);
CREATE TABLE IF NOT EXISTS tb_reading_tags (
  id TEXT PRIMARY KEY, name TEXT NOT NULL, normalized_name TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS tb_reading_note_tags (
  note_id TEXT NOT NULL, tag_id TEXT NOT NULL, PRIMARY KEY(note_id, tag_id)
);
CREATE TABLE IF NOT EXISTS tb_reading_note_revisions (
  id TEXT PRIMARY KEY, note_id TEXT NOT NULL, title TEXT NOT NULL DEFAULT '',
  body TEXT NOT NULL DEFAULT '', tags TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL, created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_reading_notes_book_status
ON tb_reading_notes(book_id, status, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_reading_note_blocks_note
ON tb_reading_note_blocks(note_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_reading_note_sources_ref
ON tb_reading_note_sources(source_type, source_ref);
CREATE INDEX IF NOT EXISTS idx_reading_note_tags_note
ON tb_reading_note_tags(note_id);
CREATE INDEX IF NOT EXISTS idx_reading_note_revisions_note
ON tb_reading_note_revisions(note_id, created_at DESC)
''';

const createReadingNoteAiOrganizerSQL = '''
ALTER TABLE tb_reading_note_blocks ADD COLUMN metadata TEXT NOT NULL DEFAULT '{}';
CREATE TABLE IF NOT EXISTS tb_reading_note_ai_batches (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, scope TEXT NOT NULL,
  source_snapshot TEXT NOT NULL DEFAULT '[]', status TEXT NOT NULL DEFAULT 'pending',
  provider_id TEXT, model TEXT, used_fallback INTEGER NOT NULL DEFAULT 0,
  total_count INTEGER NOT NULL DEFAULT 0, remaining_count INTEGER NOT NULL DEFAULT 0,
  error TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS tb_reading_note_ai_suggestions (
  id TEXT PRIMARY KEY, batch_id TEXT NOT NULL, book_id INTEGER NOT NULL,
  source_type TEXT NOT NULL, source_ref TEXT NOT NULL, content_hash TEXT NOT NULL,
  suggested_title TEXT NOT NULL DEFAULT '', suggested_body TEXT NOT NULL DEFAULT '',
  suggested_tags TEXT NOT NULL DEFAULT '[]', existing_topic_ids TEXT NOT NULL DEFAULT '[]',
  new_topics TEXT NOT NULL DEFAULT '[]', selected_fields TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'pending', before_snapshot TEXT,
  applied_hash TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_note_ai_batches_book_status
ON tb_reading_note_ai_batches(book_id, status, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_note_ai_suggestions_batch_status
ON tb_reading_note_ai_suggestions(batch_id, status);
CREATE INDEX IF NOT EXISTS idx_note_ai_suggestions_source
ON tb_reading_note_ai_suggestions(book_id, source_type, source_ref)
''';

const createReadingAgentSQL = '''
CREATE TABLE IF NOT EXISTS tb_reading_goals (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, title TEXT NOT NULL,
  range_json TEXT NOT NULL DEFAULT '{}', time_budget_minutes INTEGER,
  criteria_json TEXT NOT NULL DEFAULT '[]', progress REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'active', created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  CHECK(status IN ('active', 'completed', 'abandoned')),
  CHECK(progress >= 0 AND progress <= 1)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_reading_goals_one_active_book
ON tb_reading_goals(book_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_reading_goals_book_updated
ON tb_reading_goals(book_id, updated_at DESC);
CREATE TABLE IF NOT EXISTS tb_reader_profile_items (
  profile_key TEXT PRIMARY KEY, value_json TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'candidate', confidence REAL NOT NULL DEFAULT 0,
  evidence_count INTEGER NOT NULL DEFAULT 0,
  evidence_sessions_json TEXT NOT NULL DEFAULT '[]', rejected_until INTEGER,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
  CHECK(status IN ('candidate', 'confirmed', 'rejected')),
  CHECK(confidence >= 0 AND confidence <= 1), CHECK(evidence_count >= 0)
);
CREATE INDEX IF NOT EXISTS idx_reader_profile_status_updated
ON tb_reader_profile_items(status, updated_at DESC);
CREATE TABLE IF NOT EXISTS tb_agent_actions (
  id TEXT PRIMARY KEY, action_type TEXT NOT NULL, target_id TEXT NOT NULL,
  book_id INTEGER, before_snapshot TEXT, after_snapshot TEXT,
  after_hash TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'applied',
  session_id TEXT NOT NULL, created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL, undone_at INTEGER,
  CHECK(action_type IN ('goal', 'profile', 'note', 'difficulty', 'memory')),
  CHECK(status IN ('applied', 'undone', 'conflict'))
);
CREATE INDEX IF NOT EXISTS idx_agent_actions_recent
ON tb_agent_actions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_agent_actions_target
ON tb_agent_actions(action_type, target_id, created_at DESC)
''';

const createReadingClosureSQL = '''
ALTER TABLE tb_agent_actions RENAME TO tb_agent_actions_v16;
CREATE TABLE tb_agent_actions (
  id TEXT PRIMARY KEY, action_type TEXT NOT NULL, target_id TEXT NOT NULL,
  book_id INTEGER, before_snapshot TEXT, after_snapshot TEXT,
  after_hash TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'applied',
  session_id TEXT NOT NULL, created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL, undone_at INTEGER,
  CHECK(action_type IN ('goal', 'profile', 'note', 'difficulty', 'memory')),
  CHECK(status IN ('applied', 'undone', 'conflict'))
);
INSERT INTO tb_agent_actions SELECT * FROM tb_agent_actions_v16;
DROP TABLE tb_agent_actions_v16;
CREATE INDEX IF NOT EXISTS idx_agent_actions_recent
ON tb_agent_actions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_agent_actions_target
ON tb_agent_actions(action_type, target_id, created_at DESC);
CREATE TABLE IF NOT EXISTS tb_reading_checkpoints (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, chapter_href TEXT NOT NULL,
  chapter_title TEXT NOT NULL DEFAULT '', progress REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending', reflection TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
  CHECK(status IN ('pending', 'completed', 'skipped')),
  UNIQUE(book_id, chapter_href)
);
CREATE INDEX IF NOT EXISTS idx_reading_checkpoints_pending
ON tb_reading_checkpoints(book_id, status, updated_at DESC);
CREATE TABLE IF NOT EXISTS tb_reading_mastery (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, chapter_href TEXT,
  topic TEXT NOT NULL, level TEXT NOT NULL DEFAULT 'unknown',
  score REAL NOT NULL DEFAULT 0, next_review_at INTEGER, updated_at INTEGER NOT NULL,
  CHECK(level IN ('unknown', 'emerging', 'familiar', 'mastered')),
  CHECK(score >= 0 AND score <= 1)
);
CREATE INDEX IF NOT EXISTS idx_reading_mastery_book
ON tb_reading_mastery(book_id, updated_at DESC);
CREATE TABLE IF NOT EXISTS tb_knowledge_cards (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, front TEXT NOT NULL,
  back TEXT NOT NULL, chapter_href TEXT, due_at INTEGER,
  interval_days INTEGER NOT NULL DEFAULT 1, repetitions INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'active', created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
  CHECK(status IN ('active', 'suspended'))
);
CREATE INDEX IF NOT EXISTS idx_knowledge_cards_due
ON tb_knowledge_cards(book_id, status, due_at);
CREATE TABLE IF NOT EXISTS tb_reading_memory_documents (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, title TEXT NOT NULL,
  markdown TEXT NOT NULL DEFAULT '', source_refs_json TEXT NOT NULL DEFAULT '[]',
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_reading_memory_book
ON tb_reading_memory_documents(book_id, updated_at DESC)
''';

const createReadingExperienceModulesSQL = '''
ALTER TABLE tb_agent_actions RENAME TO tb_agent_actions_v17;
CREATE TABLE tb_agent_actions (
  id TEXT PRIMARY KEY, action_type TEXT NOT NULL, target_id TEXT NOT NULL,
  book_id INTEGER, before_snapshot TEXT, after_snapshot TEXT,
  after_hash TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'applied',
  session_id TEXT NOT NULL, created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL, undone_at INTEGER,
  CHECK(action_type IN ('goal', 'profile', 'note', 'difficulty', 'memory', 'artifact')),
  CHECK(status IN ('applied', 'undone', 'conflict'))
);
INSERT INTO tb_agent_actions SELECT * FROM tb_agent_actions_v17;
DROP TABLE tb_agent_actions_v17;
CREATE INDEX IF NOT EXISTS idx_agent_actions_recent
ON tb_agent_actions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_agent_actions_target
ON tb_agent_actions(action_type, target_id, created_at DESC);
CREATE TABLE IF NOT EXISTS tb_book_reading_profiles (
  book_id INTEGER PRIMARY KEY, primary_module_id TEXT NOT NULL,
  facets_json TEXT NOT NULL DEFAULT '[]', confidence REAL NOT NULL DEFAULT 0,
  pinned INTEGER NOT NULL DEFAULT 0, match_source TEXT NOT NULL DEFAULT 'metadata',
  schema_version INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  CHECK(confidence >= 0 AND confidence <= 1), CHECK(pinned IN (0, 1))
);
CREATE INDEX IF NOT EXISTS idx_book_reading_profiles_module
ON tb_book_reading_profiles(primary_module_id, updated_at DESC);
CREATE TABLE IF NOT EXISTS tb_reading_artifacts (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, module_id TEXT NOT NULL,
  artifact_kind TEXT NOT NULL, schema_version INTEGER NOT NULL DEFAULT 1,
  payload_json TEXT NOT NULL DEFAULT '{}', epistemic_status TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active', source_start_cfi TEXT,
  source_end_cfi TEXT, source_text_snapshot TEXT NOT NULL DEFAULT '',
  chapter_href TEXT, chapter_title TEXT, discovered_at_cfi TEXT,
  discovered_progress REAL NOT NULL DEFAULT 0, session_id TEXT,
  created_by TEXT NOT NULL DEFAULT 'user', created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  CHECK(epistemic_status IN ('textFact', 'userReflection', 'agentInference', 'externalFact')),
  CHECK(status IN ('active', 'resolved', 'retracted')),
  CHECK(discovered_progress >= 0 AND discovered_progress <= 1)
);
CREATE INDEX IF NOT EXISTS idx_reading_artifacts_book_kind
ON tb_reading_artifacts(book_id, artifact_kind, status, discovered_progress);
CREATE INDEX IF NOT EXISTS idx_reading_artifacts_module_updated
ON tb_reading_artifacts(module_id, updated_at DESC)
''';

const createReadingCoverageSQL = '''
ALTER TABLE tb_reading_artifacts RENAME TO tb_reading_artifacts_v18;
CREATE TABLE tb_reading_artifacts (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, module_id TEXT NOT NULL,
  artifact_kind TEXT NOT NULL, schema_version INTEGER NOT NULL DEFAULT 1,
  payload_json TEXT NOT NULL DEFAULT '{}', epistemic_status TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active', source_start_cfi TEXT,
  source_end_cfi TEXT, source_text_snapshot TEXT NOT NULL DEFAULT '',
  chapter_href TEXT, chapter_title TEXT, discovered_at_cfi TEXT,
  source_progress REAL NOT NULL DEFAULT 0,
  visible_from_progress REAL NOT NULL DEFAULT 0,
  ingested_at INTEGER NOT NULL, ingestion_mode TEXT NOT NULL DEFAULT 'live',
  session_id TEXT, created_by TEXT NOT NULL DEFAULT 'user',
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
  CHECK(epistemic_status IN ('textFact', 'userReflection', 'agentInference', 'externalFact')),
  CHECK(status IN ('active', 'resolved', 'retracted')),
  CHECK(source_progress >= 0 AND source_progress <= 1),
  CHECK(visible_from_progress >= 0 AND visible_from_progress <= 1),
  CHECK(ingestion_mode IN ('live', 'backfill', 'imported', 'synced'))
);
INSERT INTO tb_reading_artifacts (
  id, book_id, module_id, artifact_kind, schema_version, payload_json,
  epistemic_status, status, source_start_cfi, source_end_cfi,
  source_text_snapshot, chapter_href, chapter_title, discovered_at_cfi,
  source_progress, visible_from_progress, ingested_at, ingestion_mode,
  session_id, created_by, created_at, updated_at
)
SELECT id, book_id, module_id, artifact_kind, schema_version, payload_json,
  epistemic_status, status, source_start_cfi, source_end_cfi,
  source_text_snapshot, chapter_href, chapter_title, discovered_at_cfi,
  discovered_progress, discovered_progress, created_at, 'live',
  session_id, created_by, created_at, updated_at
FROM tb_reading_artifacts_v18;
DROP TABLE tb_reading_artifacts_v18;
CREATE INDEX IF NOT EXISTS idx_reading_artifacts_book_kind
ON tb_reading_artifacts(book_id, artifact_kind, status, visible_from_progress);
CREATE INDEX IF NOT EXISTS idx_reading_artifacts_module_updated
ON tb_reading_artifacts(module_id, updated_at DESC);
CREATE TABLE IF NOT EXISTS tb_book_reading_coverage (
  book_id INTEGER PRIMARY KEY, safe_knowledge_boundary REAL NOT NULL,
  artifact_coverage_start REAL NOT NULL, artifact_coverage_end REAL NOT NULL,
  setup_status TEXT NOT NULL DEFAULT 'pending',
  initialized_at_progress REAL NOT NULL, created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  CHECK(safe_knowledge_boundary >= 0 AND safe_knowledge_boundary <= 1),
  CHECK(artifact_coverage_start >= 0 AND artifact_coverage_start <= 1),
  CHECK(artifact_coverage_end >= 0 AND artifact_coverage_end <= 1),
  CHECK(setup_status IN ('pending', 'fromHere', 'backfilled', 'imported'))
);
CREATE INDEX IF NOT EXISTS idx_book_reading_coverage_status
ON tb_book_reading_coverage(setup_status, updated_at DESC)
''';

const createReadingAgentSyncSQL = '''
CREATE TABLE IF NOT EXISTS tb_book_device_positions (
  book_id INTEGER NOT NULL, device_id TEXT NOT NULL, cfi TEXT NOT NULL DEFAULT '',
  progress REAL NOT NULL DEFAULT 0, chapter_href TEXT, chapter_title TEXT,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY(book_id, device_id),
  CHECK(progress >= 0 AND progress <= 1)
);
CREATE INDEX IF NOT EXISTS idx_book_device_positions_progress
ON tb_book_device_positions(book_id, progress DESC);
CREATE TABLE IF NOT EXISTS tb_reading_sync_tombstones (
  entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, book_id INTEGER NOT NULL,
  device_id TEXT NOT NULL, deleted_at INTEGER NOT NULL,
  PRIMARY KEY(entity_type, entity_id, device_id)
);
CREATE INDEX IF NOT EXISTS idx_reading_sync_tombstones_book
ON tb_reading_sync_tombstones(book_id, deleted_at DESC)
''';

const createReadingTasksSQL = '''
CREATE TABLE IF NOT EXISTS tb_reading_tasks (
  id TEXT PRIMARY KEY, task_type TEXT NOT NULL, book_id INTEGER,
  priority TEXT NOT NULL DEFAULT 'normal',
  persistence TEXT NOT NULL DEFAULT 'ephemeral',
  status TEXT NOT NULL DEFAULT 'queued', payload_json TEXT NOT NULL DEFAULT '{}',
  checkpoint_json TEXT NOT NULL DEFAULT '{}', progress REAL NOT NULL DEFAULT 0,
  can_pause INTEGER NOT NULL DEFAULT 1, attempts INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
  started_at INTEGER, finished_at INTEGER, error TEXT,
  CHECK(priority IN ('background', 'normal', 'userInitiated', 'critical')),
  CHECK(persistence IN ('ephemeral', 'durable')),
  CHECK(status IN ('queued', 'running', 'paused', 'completed', 'failed', 'cancelled')),
  CHECK(progress >= 0 AND progress <= 1), CHECK(can_pause IN (0, 1))
);
CREATE INDEX IF NOT EXISTS idx_reading_tasks_schedulable
ON tb_reading_tasks(status, priority, created_at);
CREATE INDEX IF NOT EXISTS idx_reading_tasks_book_updated
ON tb_reading_tasks(book_id, updated_at DESC)
''';

const createBookWikiSQL = '''
CREATE TABLE IF NOT EXISTS tb_book_wikis (
  book_id INTEGER PRIMARY KEY, version INTEGER NOT NULL DEFAULT 1,
  generation_scope TEXT NOT NULL DEFAULT 'read_boundary',
  safe_knowledge_boundary REAL NOT NULL DEFAULT 0,
  coverage_start REAL NOT NULL DEFAULT 0, coverage_end REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'empty', last_generated_at INTEGER,
  updated_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS tb_book_wiki_entries (
  id TEXT PRIMARY KEY, book_id INTEGER NOT NULL, kind TEXT NOT NULL,
  title TEXT NOT NULL, summary TEXT NOT NULL DEFAULT '',
  content_markdown TEXT NOT NULL DEFAULT '', parent_id TEXT, sort_key TEXT NOT NULL DEFAULT '',
  source_artifact_ids_json TEXT NOT NULL DEFAULT '[]', visible_from_progress REAL NOT NULL DEFAULT 0,
  epistemic_status TEXT NOT NULL DEFAULT 'agentInference', created_by TEXT NOT NULL DEFAULT 'agent',
  version INTEGER NOT NULL DEFAULT 1, status TEXT NOT NULL DEFAULT 'active', user_corrected INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_book_wiki_entries_book ON tb_book_wiki_entries(book_id, status, visible_from_progress, sort_key);
CREATE TABLE IF NOT EXISTS tb_book_wiki_entry_sources (
  id TEXT PRIMARY KEY, entry_id TEXT NOT NULL, book_id INTEGER NOT NULL, artifact_id TEXT,
  chapter_href TEXT, chapter_title TEXT, cfi TEXT, text_snapshot TEXT NOT NULL DEFAULT '',
  source_progress REAL NOT NULL DEFAULT 0, created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_book_wiki_sources_entry ON tb_book_wiki_entry_sources(entry_id, source_progress);
CREATE TABLE IF NOT EXISTS tb_book_wiki_revisions (
  id TEXT PRIMARY KEY, entry_id TEXT NOT NULL, book_id INTEGER NOT NULL, base_version INTEGER NOT NULL,
  revision_kind TEXT NOT NULL, correction TEXT NOT NULL DEFAULT '', before_snapshot TEXT NOT NULL DEFAULT '{}',
  after_snapshot TEXT NOT NULL DEFAULT '{}', device_id TEXT NOT NULL, created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_book_wiki_revisions_entry ON tb_book_wiki_revisions(entry_id, created_at DESC)
''';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;
  static bool updatedDB = false;

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    int dbVersion = currentDbVersion;
    switch (AnxPlatform.type) {
      case AnxPlatformEnum.macos:
      case AnxPlatformEnum.android:
      case AnxPlatformEnum.ohos:
        final databasePath = await getAnxDataBasesPath();
        final path = join(databasePath, 'app_database.db');
        return await openDatabase(
          path,
          version: dbVersion,
          onCreate: (db, version) async {
            await onUpgradeDatabase(db, 0, version);
          },
          onUpgrade: onUpgradeDatabase,
        );
      case AnxPlatformEnum.ios:
      case AnxPlatformEnum.windows:
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;

        final databasePath = await getAnxDataBasesPath();
        AnxLog.info('Database: database path: $databasePath');
        final path = join(databasePath, 'app_database.db');

        return await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: dbVersion,
            onCreate: (db, version) async {
              await onUpgradeDatabase(db, 0, version);
            },
            onUpgrade: onUpgradeDatabase,
          ),
        );
    }
  }

  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Checkpoint WAL to merge data into main database file
  /// Returns true if checkpoint was successful or not needed
  static Future<bool> checkpointWal() async {
    try {
      final db = await DBHelper().database;
      // Use rawQuery instead of execute for PRAGMA wal_checkpoint
      // because it returns a result row which can cause issues with execute()
      await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
      AnxLog.info('Database: WAL checkpoint completed');
      return true;
    } catch (e) {
      AnxLog.warning('Database: WAL checkpoint failed: $e');
      return false;
    }
  }

  /// Get the path to the WAL file for a database
  static String getWalPath(String dbPath) => '$dbPath-wal';

  /// Get the path to the SHM file for a database
  static String getShmPath(String dbPath) => '$dbPath-shm';

  /// Check if WAL files exist for a database and have content
  static bool hasWalFiles(String dbPath) {
    final walFile = File(getWalPath(dbPath));
    return walFile.existsSync() && walFile.lengthSync() > 0;
  }

  /// Delete WAL auxiliary files
  static Future<void> cleanupWalFiles(String dbPath) async {
    try {
      final walFile = File(getWalPath(dbPath));
      final shmFile = File(getShmPath(dbPath));
      if (walFile.existsSync()) await walFile.delete();
      if (shmFile.existsSync()) await shmFile.delete();
      AnxLog.info('Database: WAL files cleaned up');
    } catch (e) {
      AnxLog.warning('Database: Failed to cleanup WAL files: $e');
    }
  }

  /// Create a snapshot of the database for upload using VACUUM INTO
  /// This avoids closing the database or locking it for long periods
  static Future<String> prepareUploadSnapshot() async {
    try {
      final db = await DBHelper().database;
      final cacheDir = await getAnxCacheDir();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final snapshotPath = join(cacheDir.path, 'snapshot_aaaa_$timestamp.db');

      // Ensure any existing file is removed
      final snapshotFile = File(snapshotPath);
      if (snapshotFile.existsSync()) {
        await snapshotFile.delete();
      }

      // VACUUM INTO creates a transactionally consistent copy
      // It works even if the DB is in WAL mode and open
      try {
        // Use string interpolation instead of binding for VACUUM INTO
        // as some SQLite wrappers/versions don't support bindings in VACUUM statements
        final escapedPath = snapshotPath.replaceAll("'", "''");
        await db.execute("VACUUM INTO '$escapedPath'");
      } catch (e) {
        AnxLog.warning('Database: VACUUM INTO failed ($e)');

        // Fallback strategy for platforms with older SQLite versions
        // (SQLite 3.27.0+ required for VACUUM INTO support)
        AnxLog.info('Database: Using fallback strategy (Checkpoint+Copy)');

        // 1. Force Checkpoint to ensure all WAL data is written to main DB file
        await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');

        // 2. Copy file manually
        final databasePath = await getAnxDataBasesPath();
        final dbPath = join(databasePath, 'app_database.db');
        await File(dbPath).copy(snapshotPath);
      }

      AnxLog.info('Database: Created snapshot at $snapshotPath');

      // Ensure the snapshot has a clean header (Legacy mode)
      // This guarantees the uploaded file is compatible with all platforms
      await fixDatabaseHeader(snapshotPath);

      return snapshotPath;
    } catch (e) {
      AnxLog.severe('Database: Failed to create snapshot: $e');
      rethrow;
    }
  }

  /// Directly patch the database file header to switch from WAL mode to Legacy mode
  /// WAL mode sets the file format byte (offset 18) and version byte (offset 19) to 2
  /// We need to reset them to 1 (Legacy) to allow opening without -wal file
  static Future<void> fixDatabaseHeader(String dbPath) async {
    try {
      final file = File(dbPath);
      if (!file.existsSync()) return;

      // 1. Check header first to avoid expensive read/write if not needed
      bool needsPatch = false;
      final raf = await file.open(mode: FileMode.read);
      try {
        if (await raf.length() > 20) {
          await raf.setPosition(18);
          final writeVersion = await raf.readByte();
          final readVersion = await raf.readByte();

          if (writeVersion == 2 || readVersion == 2) {
            needsPatch = true;
            AnxLog.info(
                'Database: Detected WAL mode in header (v$writeVersion/v$readVersion), patching to Legacy mode');
          }
        }
      } finally {
        await raf.close();
      }

      // 2. Patch if needed logic (Read-Modify-Write)
      if (needsPatch) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 20) {
          bytes[18] = 1; // Write version: 1 (Legacy)
          bytes[19] = 1; // Read version: 1 (Legacy)

          await file.writeAsBytes(bytes, flush: true);
          AnxLog.info('Database: patched header 18, 19 to 1 successfully');
        }
      }
    } catch (e) {
      AnxLog.warning('Database: Failed to patch database header: $e');
    }
  }

  /// Get the latest modification time including WAL file
  /// This ensures we detect changes even if they're only in the WAL
  static DateTime getLatestModTime(String dbPath) {
    final dbFile = File(dbPath);
    final walFile = File(getWalPath(dbPath));

    DateTime dbTime = dbFile.existsSync()
        ? dbFile.lastModifiedSync()
        : DateTime.fromMillisecondsSinceEpoch(0);

    if (walFile.existsSync()) {
      DateTime walTime = walFile.lastModifiedSync();
      if (walTime.isAfter(dbTime)) {
        return walTime;
      }
    }

    return dbTime;
  }

  Future<void> onUpgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    AnxLog.info('Database: upgrade database from $oldVersion to $newVersion');
    switch (oldVersion) {
      case 0:
        AnxLog.info('Database: create database version $newVersion');
        await db.execute(createBookSQL);
        await db.execute(createNoteSQL);
        await db.execute(createThemeSQL);
        await db.execute(createStyleSQL);
        await db.execute(createReadingTimeSQL);
        await db.execute(primaryTheme1);
        await db.execute(primaryTheme2);
        continue case1;
      case1:
      case 1:
        // add a column (rating) to tb_books
        await db.execute('ALTER TABLE tb_books ADD COLUMN rating REAL');
        // remove '/data/user/0/com.anxcye.anx_reader/app_flutter/' from file_path & cover_path
        await db.execute(
            "UPDATE tb_books SET file_path = REPLACE(file_path, '/data/user/0/com.anxcye.anx_reader/app_flutter/', '')");
        await db.execute(
            "UPDATE tb_books SET cover_path = REPLACE(cover_path, '/data/user/0/com.anxcye.anx_reader/app_flutter/', '')");
        continue case2;
      case2:
      case 2:
        // replave ' ' with '_' in db and cut file name to 25
        await db.execute(
            "UPDATE tb_books SET file_path = REPLACE(file_path, ' ', '_')");
        await db.execute(
            "UPDATE tb_books SET cover_path = REPLACE(cover_path, ' ', '_')");
        await db.execute(
            "UPDATE tb_books SET file_path = SUBSTR(file_path, 0, 25)");
        await db.execute(
            "UPDATE tb_books SET cover_path = SUBSTR(cover_path, 0, 25)");
        await db
            .execute("UPDATE tb_books SET file_path = file_path || '.epub'");
        await db
            .execute("UPDATE tb_books SET cover_path = cover_path || '.png'");

        final basePath = getBasePath('');
        final fileDir = Directory('$basePath/file');
        final coverDir = Directory('$basePath/cover');
        fileDir.listSync().forEach((element) {
          if (element is File) {
            final path = element.path;
            String pathAfterReplace = path.replaceAll(' ', '_');
            int endIndex =
                (pathAfterReplace.length < 72) ? pathAfterReplace.length : 72;
            final newPath = '${pathAfterReplace.substring(0, endIndex)}.epub';
            element.rename(newPath);
          }
        });
        coverDir.listSync().forEach((element) {
          if (element is File) {
            final path = element.path;
            String pathAfterReplace = path.replaceAll(' ', '_');
            int endIndex =
                (pathAfterReplace.length < 72) ? pathAfterReplace.length : 72;
            final newPath = '${pathAfterReplace.substring(0, endIndex)}.png';
            element.rename(newPath);
          }
        });
        continue case3;
      case3:
      case 3:
        // remove former book style
        Prefs().removeBookStyle();
        final books = (await db.query('tb_books')).map(Book.fromDb);
        for (final book in books) {
          if (!File(book.coverFullPath).existsSync()) {
            resetBookCover(book);
          }
        }
        continue case4;
      case4:
      case 4:
        // add a column (group_id) to tb_books, and set all group_id to 0 default
        await db.execute("ALTER TABLE tb_books ADD COLUMN group_id INTEGER");
        await db.execute("UPDATE tb_books SET group_id = 0");
        continue case5;
      case5:
      case 5:
        // add a column (reader_note) to tb_notes, null default
        await db.execute("ALTER TABLE tb_notes ADD COLUMN reader_note TEXT");
        continue case6;
      case6:
      case 6:
        // create groups table and migrate existing data
        await db.execute(createGroupSQL);
        // add a column (file_md5) to tb_books
        await db.execute("ALTER TABLE tb_books ADD COLUMN file_md5 TEXT");

        // Insert root group
        await db.execute(
            "INSERT INTO tb_groups (id, name, parent_id, create_time, update_time) VALUES (0, 'Root', NULL, datetime('now'), datetime('now'))");

        // Get all unique group_ids from books
        final List<Map<String, dynamic>> uniqueGroups = await db.rawQuery('''
          SELECT DISTINCT group_id 
          FROM tb_books 
          WHERE group_id IS NOT NULL AND group_id != 0
''');

        // Create groups for existing group_ids
        for (var i = 0; i < uniqueGroups.length; i++) {
          final groupId = uniqueGroups[i]['group_id'];
          await db.execute('''
            INSERT INTO tb_groups (id, name, parent_id, create_time, update_time)
            VALUES (?, '...', 0, datetime('now'), datetime('now'))
          ''', [groupId]);
        }
        continue case7;
      case7:
      case 7:
        await db.execute(createVocabularySQL);
        await db.execute(createVocabularyReviewIndexSQL);
        continue case8Migration;
      case8Migration:
      case 8:
        await _addColumnIfMissing(
          db,
          'tb_vocabulary',
          'source_sentence_translation',
          'TEXT',
        );
        await _addColumnIfMissing(
          db,
          'tb_vocabulary',
          'contextual_definition',
          'TEXT',
        );
        await _addColumnIfMissing(
          db,
          'tb_vocabulary',
          'example_sentence',
          'TEXT',
        );
        await _addColumnIfMissing(
          db,
          'tb_vocabulary',
          'example_translation',
          'TEXT',
        );
        continue case9Migration;
      case9Migration:
      case 9:
        await db.execute(createAiSessionsSQL);
        continue case10Migration;
      case10Migration:
      case 10:
        await _addColumnIfMissing(
          db,
          'tb_ai_sessions',
          'analysisDepth',
          'TEXT',
        );
        await _addColumnIfMissing(
          db,
          'tb_ai_sessions',
          'frameworks',
          "TEXT NOT NULL DEFAULT '[]'",
        );
        await _addColumnIfMissing(
          db,
          'tb_ai_sessions',
          'outputTemplate',
          'TEXT',
        );
        await _addColumnIfMissing(
          db,
          'tb_ai_sessions',
          'readingGoal',
          'TEXT',
        );
        await _addColumnIfMissing(
          db,
          'tb_ai_sessions',
          'analysisResult',
          'TEXT',
        );
        continue case11Migration;
      case11Migration:
      case 11:
        await db.execute(createReadingGuidesSQL);
        await db.execute(createReadingQuizzesSQL);
        await db.execute(createReadingDifficultiesSQL);
        for (final statement in createReadingCoachIndexesSQL.split(';')) {
          if (statement.trim().isNotEmpty) await db.execute(statement);
        }
        continue case12Migration;
      case12Migration:
      case 12:
        for (final statement in createReadingMemorySQL.split(';')) {
          if (statement.trim().isNotEmpty) await db.execute(statement);
        }
        continue case13Migration;
      case13Migration:
      case 13:
        for (final statement in createReadingNotesWorkspaceSQL.split(';')) {
          if (statement.trim().isNotEmpty) await db.execute(statement);
        }
        continue case14Migration;
      case14Migration:
      case 14:
        for (final statement in createReadingNoteAiOrganizerSQL.split(';')) {
          if (statement.trim().isNotEmpty) await db.execute(statement);
        }
        continue case15Migration;
      case15Migration:
      case 15:
        for (final statement in createReadingAgentSQL.split(';')) {
          if (statement.trim().isNotEmpty) await db.execute(statement);
        }
        continue case16Migration;
      case16Migration:
      case 16:
        for (final statement in createReadingClosureSQL.split(';')) {
          if (statement.trim().isNotEmpty) await db.execute(statement);
        }
        continue case17Migration;
      case17Migration:
      case 17:
        for (final statement in createReadingExperienceModulesSQL.split(';')) {
          if (statement.trim().isNotEmpty) await db.execute(statement);
        }
        continue case18Migration;
      case18Migration:
      case 18:
        for (final statement in createReadingCoverageSQL.split(';')) {
          if (statement.trim().isNotEmpty) await db.execute(statement);
        }
        await _migrateArtifactActionSnapshots(db);
        continue case19Migration;
      case19Migration:
      case 19:
        for (final statement in createReadingAgentSyncSQL.split(';')) {
          if (statement.trim().isNotEmpty) await db.execute(statement);
        }
        continue case20Migration;
      case20Migration:
      case 20:
        for (final statement in createReadingTasksSQL.split(';')) {
          if (statement.trim().isNotEmpty) await db.execute(statement);
        }
        continue case21Migration;
      case21Migration:
      case 21:
        await _migrateWikiActionType(db);
        for (final statement in createBookWikiSQL.split(';')) {
          if (statement.trim().isNotEmpty) await db.execute(statement);
        }
    }

    if (oldVersion != 0 && Prefs().webdavStatus) {
      updatedDB = true;
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> _migrateWikiActionType(Database db) async {
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='tb_agent_actions'");
    if (tables.isNotEmpty) {
      await db.execute(
          'ALTER TABLE tb_agent_actions RENAME TO tb_agent_actions_v21');
    }
    await db.execute('''CREATE TABLE tb_agent_actions (
      id TEXT PRIMARY KEY, action_type TEXT NOT NULL, target_id TEXT NOT NULL,
      book_id INTEGER, before_snapshot TEXT, after_snapshot TEXT,
      after_hash TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'applied',
      session_id TEXT NOT NULL, created_at INTEGER NOT NULL,
      expires_at INTEGER NOT NULL, undone_at INTEGER,
      CHECK(action_type IN ('goal', 'profile', 'note', 'difficulty', 'memory', 'artifact', 'wiki')),
      CHECK(status IN ('applied', 'undone', 'conflict'))
    )''');
    if (tables.isNotEmpty) {
      await db.execute(
          'INSERT INTO tb_agent_actions SELECT * FROM tb_agent_actions_v21');
      await db.execute('DROP TABLE tb_agent_actions_v21');
    }
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_agent_actions_recent ON tb_agent_actions(created_at DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_agent_actions_target ON tb_agent_actions(action_type, target_id, created_at DESC)');
  }

  Future<void> _migrateArtifactActionSnapshots(Database db) async {
    final actions = await db.query(
      'tb_agent_actions',
      columns: ['id', 'before_snapshot', 'after_snapshot'],
      where: "action_type = 'artifact'",
    );
    for (final action in actions) {
      Map<String, dynamic>? migrate(Object? raw) {
        if (raw == null) return null;
        final decoded = jsonDecode(raw.toString());
        if (decoded is! Map) return null;
        final value = Map<String, dynamic>.from(decoded);
        final progress = value.remove('discovered_progress') ?? 0;
        value['source_progress'] = progress;
        value['visible_from_progress'] = progress;
        value['ingested_at'] = value['created_at'] ?? 0;
        value['ingestion_mode'] = ReadingArtifactIngestionMode.live.name;
        return value;
      }

      final before = migrate(action['before_snapshot']);
      final after = migrate(action['after_snapshot']);
      await db.update(
        'tb_agent_actions',
        {
          'before_snapshot': before == null ? null : jsonEncode(before),
          'after_snapshot': after == null ? null : jsonEncode(after),
          'after_hash': _canonicalHash(after),
        },
        where: 'id = ?',
        whereArgs: [action['id']],
      );
    }
  }
}
