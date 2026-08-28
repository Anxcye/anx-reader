# Anx Reader 功能地图（供 AI 开发前必读）

> 状态：实现事实索引。更新日期：2026-08-25。  
> 目的：让后续开发先复用已有能力、数据模型和入口，避免重复造轮子或绕过权限/同步规则。  
> 产品决策以仓库根目录 [`DESIGN.md`](../../DESIGN.md) 为准；本文是“代码在哪里、已经做到什么、哪些还没有”的导航，不替代源码和测试。

小说 Story Atlas 的 `track`、`stage`、`relationType` 使用稳定的
namespaced string ID（`story.*`、`stage.*`、`relation.*`）；旧短 ID 在读取
和整理时由 taxonomy 兼容层归一。叙述层以 `narrative.outer/inner` 区分
框架叙述者与故事内人物第一人称叙述。`BookReadingProfile.defaultStoryTrack`
按书籍特征选择案件线、家庭线、历史线、科幻世界观线或人物成长线；对应轨道尚无数据时，
时间线安全回退为全部故事线。

## 0. AI 开发前的强制检查顺序

1. 先查本地图对应的“代码入口”和“已有服务”，不要在页面直接访问数据库、直接创建模型客户端或新增平行状态。
2. 再查本文的“边界/禁止事项”和 [`docs/todo/`](../todo/README.md)，确认需求不是已有能力或未实现 TODO。
3. 涉及产品交互、低打扰、剧透、权限、撤销、同步冲突时，先读 [`DESIGN.md`](../../DESIGN.md) 对应章节。
4. 领域逻辑放在 service/model/repository，页面只渲染 ViewModel；新增书籍类型必须通过注册表/声明式配置扩展，不增加阅读页类型分支。
5. 修改后至少运行对应目录测试、`flutter analyze` 和 `git diff --check`；涉及数据库/同步/写入时补冲突、撤销和旧数据测试。

## 1. 总体边界图

```text
阅读页事件 ──> ReadingAgentRuntime ──> ReadingWorldState
     │                 │                      │
     │                 ├─> ReadingTaskScheduler（长任务）
     │                 └─> ReadingEventBus（本地、低打扰）
     │
     ├─> AI 工作台 ──> ContextAssembler ──> Orchestrator ──> Provider
     │                                      │
     │                                      ├─> Reading Skill（阅读方法）
     │                                      ├─> Closure Policy（成果定义）
     │                                      └─> Tool Registry（可执行工具）
     │
     └─> 阅读成果 ──> FictionStoryAtlasService ──> 图谱/时间线 ViewModel

  所有持久化 AI 写入 ──> AgentActionService ──> SQLite ──> WebDAV/CloudBase 增量同步
```

核心原则：普通翻页/停留/回看/打开图谱不调用模型；模型只由用户问答、明确分析或用户确认的整理动作触发。

## 2. 能力总表

| 能力 | 当前状态 | 用户入口 | 代码入口 | 持久化/同步 | 不要重复实现 |
|---|---|---|---|---|---|
| AI 对话工作台 | 已实现 | 阅读页 AI 按钮、划线 AI | `lib/widgets/ai/ai_reading_workspace.dart`、`lib/providers/ai_workspace.dart` | `tb_ai_sessions`，随现有同步 | 页面不得创建 Provider/client |
| 上下文预算 | 已实现 | 所有 AI 请求内部使用 | `lib/service/ai/ai_context_assembler.dart` | 摘要/缓存本地 | 不要在页面拼完整历史 |
| 专家编排 | 已实现 | 深度分析/复杂任务 | `reading_agent_orchestrator.dart` | Agent trace/Evidence | 不要把专家长文直接拼回 prompt |
| Reading Agent Runtime | 已实现 | 阅读 Agent Beta | `lib/service/ai/reading_agent_runtime.dart` | 目标、画像、动作、覆盖表 | 普通阅读事件不得调用模型 |
| Reading Skill | 已实现 | AI 工作台 Skill、设置/帮助 | `lib/service/ai/reading_skills.dart` | 按书配置/数据库 | Skill 是方法，不是工具集合 |
| 阅读闭环 | 已实现 | 阅读成果页/Agent | `reading_closure_policy.dart` | 目标、checkpoint、成果、mastery | 不按小说/心理硬编码页面 |
| 小说档案 | 已实现 | 阅读成果 > 故事档案 | `fiction_backfill_service.dart`、`fiction_story_atlas_service.dart` | `tb_reading_artifacts` | 图谱/时间线不直接查 DAO |
| 故事时间线 P0/P1 | 已实现 | 故事事件时间线 | `fiction_story_timeline_page.dart` | Artifact 投影 | 不新增独立时间线表 |
| 人物关系图 | 已实现 | 人物关系图 | `fiction_character_graph_page.dart` | Artifact 投影 | 不生成/下载人物肖像 |
| Agent 动作与撤销 | 已实现 | 明确指令/建议确认卡/动作记录 | `agent_action_service.dart`、`reading_agent_tools.dart` | 30 天/最多 200 条 | 不直接写业务表 |
| 阅读进度多设备同步 | 已实现 | 同步按钮/自动同步/最远进度提示 | `lib/service/sync/reading_agent_sync_service.dart`、`lib/service/sync/sync_request_gate.dart` | per-device package | 不自动覆盖本地位置/不自动跳转 |
| CloudBase Sync | 已实现 | 设置 > CloudBase | `lib/service/sync/cloudbase_reading_sync_coordinator.dart`、`cloudbase_reading_sync_transport.dart` | 账号 session + 增量包 | 不把管理员 Key 放进 App |
| WebDAV 同步 | 已实现 | 设置/同步按钮 | `service/sync/` | 整库兼容 + Agent 包 | 入口必须走 single-flight gate |
| E-INK/OLED 配置 | 已实现 | 设置 > 外观 | `device_display_profile.dart`、`shared_preference_provider.dart` | 设备本地，不备份 | 不把 E-INK 当普通主题 |
| Token 用量 | 已实现 | 设置 > AI | `ai_token_usage_service.dart` | 本机诊断计数 | 不把估算值当服务端精确值 |
| 轻量提取/摘要引擎 | 已实现 | 设置 > AI > 轻量提取与摘要引擎 | `ai_extraction_engine.dart`、`fiction_hybrid_extraction_service.dart` | Provider 角色设备本地；Artifact 正常同步 | 定位为本地候选提取器 + 证据筛选器；不在失败时静默上传整章 |
| 阅读成果页 | 已实现 | 阅读页 > 本书阅读成果 | `reading_outcomes_page.dart` | 读取闭环/Atlas/记忆 | 不在成果页自动整理 |
| 书籍 Wiki | 已实现（一期） | 阅读页 AI 旁、书籍详情 | `book_wiki_page.dart`、`book_wiki_service.dart` | `tb_book_wikis`/entries/sources/revisions，进入 Agent 增量同步 | 打开页面不扫描正文；详情页不启动隐藏阅读器 |
| 阅读分块与证据解析 | 已实现 | 用户确认的 Wiki/Story Atlas 整理任务 | `reading_chunker.dart`、`reading_evidence_resolver.dart` | ReadingChunk 为任务中间产物；证据回到原文 offset | 不持久化完整 chunk；普通阅读不触发 |

## 3. AI 底座与上下文

### 3.1 正确调用链

```text
页面/工具入口
  -> AiChat / aiGenerateStream / aiGenerateText
  -> ContextAssembler（预算、最近消息、滚动摘要、缓存）
  -> ReadingAgentOrchestrator（是否需要专家）
  -> ReadingSkillMatcher + ReadingClosurePolicy
  -> AI Tool Registry / LangChainRunner
  -> Provider Registry（OpenAI-compatible / Claude / Gemini）
```

不要做的事：在 Widget 中 new provider、把整本书/完整历史塞进上下文、让阅读事件触发云模型、让搜索失败伪造 citation。

### 3.2 Skill、Closure、Tool 的区别

| 概念 | 作用 | 能否直接写库 | 能否调用模型 |
|---|---|---:|---:|
| Reading Skill | 采用什么阅读方法（苏格拉底、论证、人物追踪等） | 否 | 由 AI 请求按需加载 |
| Closure Policy | 本书什么算成果（目标、checkpoint、mastery、卡片） | 否 | 否 |
| Tool | Agent 可执行的查询/动作 | 通过授权服务 | 工具本身不决定调用时机 |

普通请求只加载 Skill summary；明确方法意图/深度分析才加载 full guidance。Skill 不能被当成 MCP 工具集合。

## 4. Reading Agent Runtime 与写入权限

### 4.1 现场状态

`ReadingWorldState` 保存当前书、章节、稳定 CFI、进度、选区、会话时长、目标、难点、最近动作和已确认 Reader Profile。`onRelocated` 经 750ms 去抖/去重后才形成稳定位置事件；原始翻页只留内存。

事件类型包括：`sessionStarted`、`sessionEnded`、`locationSettled`、`chapterChanged`、`selectionCreated`、`selectionCleared`、`goalChanged`、`agentActionApplied`、`agentActionUndone`。

### 4.2 权限表

| 动作 | 明确用户指令 | Agent 主动建议 | 是否撤销 |
|---|---|---|---|
| 导航到当前书合法 CFI/Href | 直接执行 | 只能建议 | 导航本身不入撤销日志，可返回原位置 |
| 创建来源笔记 | 直接执行 | 必须确认 | 是 |
| 保存/重新打开难点 | 直接执行 | 必须确认 | 是，恢复前状态 |
| 设置阅读目标 | 先预览再确认 | 先建议 | 是，冲突保护 |
| 写入 Artifact/Markdown/画像 | 直接指令可写 | 必须确认 | 是，30 天 |

统一入口：`AgentActionService` 事务写业务表和前后快照。禁止页面或工具直接 `insert/update` 后声称可撤销。

### 4.3 低打扰约束

- Beta 默认关闭；状态胶囊仅在有目标、候选画像或刚完成动作时显示。
- 章节结束只增加待处理数量，不弹 Banner/Dialog，不自动展开 AI。
- 退出阅读不弹确认；保存目标进度，下次胶囊恢复。
- 打开成果、图谱、时间线不会自动整理或调用模型。

## 5. 阅读闭环与 Reading Skill 注册

### 已有闭环 ID

- `fiction.immersion`：小说沉浸。关注人物、悬念、故事事件、恢复上下文；不强制 mastery/复习卡。
- `knowledge.argument`：经济/知识论证。关注主张、证据、假设、反例、应用；mastery 必须用户确认。
- `psychology.reflection`：心理学概念与反思。关注定义、边界、例子、反例、应用；反思不等于诊断事实。

悬疑书不新增页面分支：`BookReadingProfile` 仍以
`fiction.immersion` 为主闭环，并附加稳定 facet
`fiction.suspense`、`processing.volume_case_scene`、
`entities.character_case_clue_evidence`、`relationships.durable_only`。
这些 facet 让同一套 Story Atlas 按册/案件作用域处理，并保留小说沉浸体验。

闭环 ID 是稳定字符串，旧 enum 只作兼容层。扩展闭环必须注册声明：目标模板、checkpoint、mastery、成果 Section、快捷问题、能力和文案。

### Reading Skill 注册规则

内置方法包括：苏格拉底式概念教学、论证结构拆解、历史史料核查、小说人物追踪、学术批判阅读、外语语境学习、财务假设验证、章节回顾、考试复习、阅读到行动计划。

按书匹配优先级：用户固定 > 明确任务意图 > 书籍元数据/阅读模式 > 默认。新增 Skill 只需注册声明和匹配关键词，不修改阅读页核心流程。

## 6. 小说 Story Atlas（最近功能的完整地图）

### 数据事实

复用 `tb_reading_artifacts`，当前稳定类型：

```text
fiction.character       人物
fiction.relationship    人物关系及关系历史
fiction.event           故事事件
fiction.scene           场景
fiction.clue            线索
fiction.mystery         悬念
fiction.resume_context  恢复上下文
fiction.backfill_checkpoint  增量整理 checkpoint
```

合集 EPUB 使用 `workId -> volumeId -> arcId -> sceneId` 四级作用域。顶层
TOC 作品节点建立稳定的 href 派生 `workId`；Artifact 与回填 checkpoint 都
携带该字段，查询时先过滤作品、再过滤案件，避免同一个 `bookId` 下相邻
小说互相污染。普通“第一章/第二章”在作品内只作为 scene，不被误判为案件。
对于 NCX 只包含分册而真实章节位于 spine 的 EPUB（如科幻合集），用户主动
整理时才读取不含正文的 spine 章节清单；普通翻页和打开成果页不会触发扫描或
模型调用。罗马数字分册标题会形成独立 `workId`，避免相邻分册互相污染。

科幻书使用 `fiction.science_fiction`、`entities.worldbuilding` 和
`timeline.default.worldbuilding` facet，默认展示 `story.worldbuilding`。
提取阶段以稳定 `entity.*` 类型区分人物、智能非人角色、组织、概念、技术、
物种和地点：只有人物与具备稳定身份的智能非人角色可进入人物档案/关系端点；
其余内容通过世界观事件表达，并继续要求逐字原文证据。

每个 Artifact 必须保留 `sourceProgress`（正文发生位置）、`visibleFromProgress`（剧透展示边界）、`ingestedAt`（进入系统时间）、`ingestionMode`、正文快照、章节和创建者。后文 Artifact 即使今天同步到设备，回到早期位置仍不可见。

### 查询投影

`FictionStoryAtlasService` 是唯一图谱/时间线查询层：

- `timelineChapters`：按章节聚合并支持 compact/standard/complete 密度、类型和人物筛选。
- `storyStages`：最多 5 个阶段总览，按正文进度划分，不推断世界年代。
- `mysteryThreads`：悬念及其带 `mysteryId` 等关联字段的线索。
- `relationshipTimeline`：关系历史按来源进度排序。
- `fromArtifacts`：应用剧透过滤、人物规范化、关系最新状态和时间线正文顺序。
- `fromArtifacts(..., arcId:)`：在剧透过滤后按当前案件 `arcId` 投影；无作用域的旧
  Artifact 保持兼容，明确 global/main_character 人物可跨案件显示。未提供 arcId 时
  服务按当前 `sourceProgress` 推断最近遇到的案件。

页面只消费这些 ViewModel，不能自行拼接 Artifact 字段。

### 当前页面能力

`FictionStoryTimelinePage`：故事主线、悬念线索、人物故事线、关系变化四种视图；章节折叠；三档密度；人物/类型筛选；每页 20 个章节；阶段导航；上次查看位置恢复；上次整理边界和“整理新增”入口。

`FictionCharacterGraphPage`：故事人物档案、人物即时回忆、简洁/完整模式、关系历史详情、来源跳转、首字头像占位。小型人物集默认简洁模式，仅展示主角局部关系；完整关系图需用户主动切换，模式按书按设备保存。E-INK 通过 `MediaQuery.disableAnimations` 关闭 GraphView 布局/镜头动画和详情过渡；OLED/LCD 保留动画。禁止网络头像。

### 整理和增量

整理流程：成果页显示预览 -> 用户确认 -> `FictionBackfillService` 只读取当前设备安全边界内已读章节 -> 按 checkpoint/hash 跳过未变化章节 -> 通过 AgentActionService 写入。手动整理上限永远是当前设备当前位置，不是多设备全局最远进度；下限默认 0%，除非用户明确选择“从这里开始”。

## 7. 同步与多设备

- 阅读位置按 `(bookId, deviceId)` 保存，设备重新打开默认恢复自己的位置。
- 全局最远进度只用于提示“继续当前位置/跳转到最远进度”，默认继续当前位置，不自动跳转。
- Agent 增量包按书和设备隔离；稳定 ID 用 LWW，终态优先，Artifact 采用更保守的展示边界，目标每本最多一个 active。
- CloudBase 是可选 Reading Agent transport；登录注册后多设备共用账号。同步不触发 AI、不扩大剧透边界。
- WebDAV/CloudBase 所有手动和自动入口走 single-flight gate；重复点击复用在途请求，避免重复任务和 ANR。

## 8. E-INK/OLED 显示配置

`deviceDisplayProfile` 是设备硬件配置：`standard` 或 `eink`；`themeMode` 是配色配置，两者不能混为一个主题。

E-INK 有效覆盖：浅色高对比、无翻页动画、无背景图、无代码高亮、`MediaQuery.disableAnimations=true`。设备配置不进入偏好备份，切换回 OLED/LCD 恢复原主题/阅读样式。页面动画必须读取 `MediaQuery.disableAnimationsOf(context)`，不要只判断主题名称。

## 9. 已实现但容易误认为未实现的入口

| 用户需求 | 正确入口 |
|---|---|
| 查看本书 AI 成果 | 阅读页工具栏 > 本书阅读成果 |
| 整理小说档案 | 阅读成果 > 整理/更新故事档案，确认后才调用 AI |
| 看人物关系 | 阅读成果 > 人物关系图 |
| 看故事时间线 | 阅读成果 > 故事时间线 |
| 看悬念/人物/关系变化 | 故事时间线顶部视图切换 |
| 恢复多设备最远进度 | 阅读页 AI 入口旁同步按钮，或打开书后主动提示 |
| 看 AI 用量 | 设置 > AI 设置 > Token 用量 |
| 配置 CloudBase | 设置 > CloudBase，注册/登录/测试；无单独保存按钮 |
| 区分墨水屏/OLED | 设置 > 外观 > 当前设备显示配置 |
| 学习如何使用 Agent/Skill | 设置/AI 入口中的帮助与教学页 |

## 10. 明确未实现 / 不要假设已经存在

以下不是当前能力，新增需求应先更新 TODO，再实现：

- 悬念自动语义归并、人物合并、错误纠正和 Artifact 字段编辑。
- 故事世界绝对年代轴的可靠推断。
- 跨书知识图谱、后台定时唤醒、自动 Skill 学习。
- 自动把小说章节变成 mastery 分数或强制复习卡。
- CloudBase 服务端管理员控制台、邀请制和跨设备撤销保证。
- 自动扫描未读后文、以全局最远设备进度替代当前设备整理上限。
- 页面直接编辑 AI 产物而不经过动作日志/来源校验。
- Wiki 整页自由编辑；一期仅支持隐藏与带版本的局部纠正。

## 11. 扩展契约（新增类型/书类时）

实现新的第四种书类或 Artifact kind 时，应满足：

1. 使用稳定 namespaced string ID，不修改旧 enum 的语义。
2. 注册 BookReadingProfile/Closure Policy/Skill 声明和 ViewModel 映射。
3. 复用 Artifact、AgentAction、同步包和 `visibleFromProgress`；未知 kind 必须可同步、可安全忽略。
4. 阅读页、成果页、同步核心流程不增加该类型硬编码分支。
5. 加入“注册假第四种书类后页面无需修改即可显示”的契约测试。
