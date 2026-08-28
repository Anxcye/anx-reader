import 'package:anx_reader/service/ai/reading_skills.dart';
import 'package:flutter/material.dart';

class ReadingAgentHelpPage extends StatelessWidget {
  const ReadingAgentHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _HelpScaffold(
      title: '阅读 Agent 使用方法',
      intro: '它会记住当前阅读现场和本书目标，把一次次阅读连接成可恢复、可复习的闭环，同时尽量不打断你。',
      icon: Icons.auto_awesome_outlined,
      sections: [
        const _HelpSection(
          title: '四步完成一次阅读闭环',
          icon: Icons.route_outlined,
          children: [
            _StepItem(
                number: 1,
                title: '创建一个本书目标',
                body: '例如“理解本章”或“读完第 1–3 章”。每本书同时只有一个活跃目标。'),
            _StepItem(
                number: 2,
                title: '像平常一样阅读',
                body: '翻页、停留和回看只更新本地状态，不会自动请求 AI。'),
            _StepItem(
                number: 3,
                title: '保存真正重要的内容',
                body: '划线后可保存笔记或难点；明确要求保存时直接执行，并提供撤销。'),
            _StepItem(
                number: 4,
                title: '完成检查并查看成果',
                body: '章节结束后，从状态胶囊进入检查；掌握度、问题、复习卡和 Markdown 记忆会汇总到“本书阅读成果”。'),
          ],
        ),
        const _HelpSection(
          title: '三套阅读闭环',
          icon: Icons.all_inclusive,
          children: [
            _FactItem(
              icon: Icons.theater_comedy_outlined,
              title: '小说沉浸闭环',
              body: '默认不做掌握度测试或复习卡。章节只静默积累为可回顾内容，按需记录人物、伏笔、悬念和感受，并严格防剧透。',
            ),
            _FactItem(
              icon: Icons.account_tree_outlined,
              title: '经济／知识论证闭环',
              body: '围绕主张、证据、隐含假设、反例和适用边界检查理解，复习卡默认关闭、由你选择。',
            ),
            _FactItem(
              icon: Icons.psychology_outlined,
              title: '心理学概念与反思闭环',
              body: '检查概念边界、例子和反例；一次最多提供一个可选反思，不诊断、不评判。',
            ),
            _FactItem(
              icon: Icons.tune_outlined,
              title: '自动匹配，也可按书固定',
              body: '系统根据阅读模式和书籍信息在本地匹配；你可以在阅读 Agent 面板或本书成果页切换。',
            ),
          ],
        ),
        const _HelpSection(
          title: '什么时候会调用 AI？',
          icon: Icons.cloud_outlined,
          children: [
            _FactItem(
                icon: Icons.check_circle_outline,
                title: '会调用',
                body: '你主动提问、要求分析、生成回顾或自测时。'),
            _FactItem(
                icon: Icons.block_outlined,
                title: '不会调用',
                body: '普通翻页、长时间停留、回看、章节切换或打开成果页时。'),
            _FactItem(
                icon: Icons.touch_app_outlined,
                title: '主动建议先确认',
                body: 'Agent 根据阅读行为提出的笔记、记忆或目标，只显示建议，不会静默写入。'),
          ],
        ),
        const _HelpSection(
          title: '状态胶囊怎么用？',
          icon: Icons.notifications_none_outlined,
          children: [
            _FactItem(
                icon: Icons.flag_outlined,
                title: '短信息，不抢阅读',
                body: '只有目标、待处理事项或刚完成动作时出现，并随阅读控制栏一起隐藏。'),
            _FactItem(
                icon: Icons.inbox_outlined,
                title: '点击后再处理',
                body: '章节检查、复习卡和未解决问题都由你点击后开始，不会自动弹窗。'),
            _FactItem(
                icon: Icons.visibility_off_outlined,
                title: '随时隐藏',
                body: '可隐藏本次会话的胶囊，也可在 AI 设置中关闭阅读 Agent Beta。'),
          ],
        ),
        const _HelpSection(
          title: '写入、撤销与隐私',
          icon: Icons.shield_outlined,
          children: [
            _FactItem(
                icon: Icons.undo_outlined,
                title: 'AI 写入都可撤销',
                body: '即时 Snackbar 可撤销；最近 30 天动作记录中也可再次撤销。'),
            _FactItem(
                icon: Icons.source_outlined,
                title: '笔记必须有来源',
                body: 'AI 笔记要关联当前选区、章节和位置，避免无法追溯的内容。'),
            _FactItem(
                icon: Icons.storage_outlined,
                title: '阅读事件本地处理',
                body: '不保存完整翻页轨迹，也不会把整本书默认上传给模型。'),
          ],
        ),
        _HelpSection(
          title: '和 Reading Skill 配合',
          icon: Icons.auto_stories_outlined,
          children: [
            const _FactItem(
                icon: Icons.psychology_alt_outlined,
                title: 'Agent 管闭环，Skill 管方法',
                body: 'Agent 负责目标、状态、写入和恢复；Reading Skill 决定 AI 如何分析当前内容。'),
            _PageLink(
              label: '查看 Reading Skill 使用方法',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ReadingSkillHelpPage(),
              )),
            ),
          ],
        ),
      ],
    );
  }
}

class ReadingSkillHelpPage extends StatelessWidget {
  const ReadingSkillHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _HelpScaffold(
      title: 'Reading Skill 使用方法',
      intro: 'Reading Skill 是 AI 陪你阅读时采用的方法。它不是工具开关，也不会因为翻页而运行。',
      icon: Icons.auto_stories_outlined,
      sections: [
        const _HelpSection(
          title: '快速上手',
          icon: Icons.play_circle_outline,
          children: [
            _StepItem(
                number: 1,
                title: '先用自动匹配',
                body: '系统根据书名、简介、阅读模式和本次问题，在本地选择一个主方法。'),
            _StepItem(
                number: 2,
                title: '需要时按书固定',
                body: '在阅读工作区点击“阅读方法”，可为当前书固定一种方法，之后也能恢复自动匹配。'),
            _StepItem(
                number: 3,
                title: '直接说出你的任务',
                body: '例如“拆解这段论证”“不要剧透，整理人物关系”“用问题检查我是否理解”。明确意图会优先匹配。'),
            _StepItem(
                number: 4,
                title: '把结果放进阅读闭环',
                body: '确认后可形成掌握度、未解决问题、复习卡或 Markdown 记忆，并在本书成果页查看。'),
          ],
        ),
        const _HelpSection(
          title: '适合你的三类阅读',
          icon: Icons.recommend_outlined,
          children: [
            _FactItem(
                icon: Icons.people_alt_outlined,
                title: '小说',
                body: '推荐“小说人物关系追踪”。只使用当前进度以前的信息，区分文本事实、推测和伏笔，默认不剧透。'),
            _FactItem(
                icon: Icons.account_tree_outlined,
                title: '经济学',
                body: '先用“论证结构拆解”识别主张、证据和假设；涉及估值、现金流或投资时改用“财务假设验证”。'),
            _FactItem(
                icon: Icons.psychology_outlined,
                title: '心理学',
                body: '推荐“苏格拉底式概念教学”，用一个问题或最小例子逐步检查定义、边界和应用。'),
          ],
        ),
        const _HelpSection(
          title: '渐进加载意味着什么？',
          icon: Icons.layers_outlined,
          children: [
            _FactItem(
                icon: Icons.list_alt_outlined,
                title: '目录层',
                body: '选择页面只显示方法名称和一句说明。'),
            _FactItem(
                icon: Icons.short_text_outlined,
                title: '摘要层',
                body: '普通 AI 提问只加入当前主方法的短约束，避免提示词膨胀。'),
            _FactItem(
                icon: Icons.manage_search_outlined,
                title: '完整层',
                body: '只有明确调用方法、发起深度分析或主动打开章节回顾时才加载；每轮最多一个完整方法。'),
          ],
        ),
        _HelpSection(
          title: '全部阅读方法',
          icon: Icons.library_books_outlined,
          children: [
            for (final skill in ReadingSkillRegistry.definitions)
              _SkillItem(skill: skill),
          ],
        ),
        _HelpSection(
          title: '和阅读 Agent 配合',
          icon: Icons.all_inclusive,
          children: [
            const _FactItem(
                icon: Icons.verified_user_outlined,
                title: '方法输出不是掌握事实',
                body: 'AI 可以提出总结和检查问题，但“能解释、能应用”等掌握度仍由你确认。'),
            const _FactItem(
                icon: Icons.edit_note_outlined,
                title: '保存仍遵循权限规则',
                body: '主动建议需确认；明确保存可直接执行；所有 AI 写入继续支持撤销。'),
            _PageLink(
              label: '查看阅读 Agent 使用方法',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ReadingAgentHelpPage(),
              )),
            ),
          ],
        ),
      ],
    );
  }
}

class _HelpScaffold extends StatelessWidget {
  const _HelpScaffold(
      {required this.title,
      required this.intro,
      required this.icon,
      required this.sections});

  final String title;
  final String intro;
  final IconData icon;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Semantics(
            header: true,
            child: Card.filled(
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 32, color: colors.onPrimaryContainer),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Text(intro,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: colors.onPrimaryContainer))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...sections,
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection(
      {required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleMedium))
              ]),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );
}

class _StepItem extends StatelessWidget {
  const _StepItem(
      {required this.number, required this.title, required this.body});
  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(radius: 15, child: Text('$number')),
        title: Text(title),
        subtitle: Text(body),
      );
}

class _FactItem extends StatelessWidget {
  const _FactItem(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(body),
      );
}

class _SkillItem extends StatelessWidget {
  const _SkillItem({required this.skill});
  final ReadingSkillDefinition skill;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: Text(skill.title),
        subtitle: Text(skill.description),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
                '可形成：${skill.closureContributions.map(_outputLabel).join('、')}'),
          ),
        ],
      );

  String _outputLabel(String value) => switch (value) {
        'checkpoint' => '章节检查',
        'mastery' => '掌握度',
        'difficulty' => '未解决问题',
        'knowledgeCard' => '复习卡',
        'markdownMemory' => 'Markdown 记忆',
        'goal' => '阅读目标',
        _ => value,
      };
}

class _PageLink extends StatelessWidget {
  const _PageLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.help_outline),
          label: Text(label),
        ),
      );
}
