# Changelog

## Todo
- 选择时移动
* Feat: Add bionic reading mode(#49)
* 新增：仿生阅读(#49)

## 1.4.3
- Fix: TTS cannot play after resume from background(#196)
- 修复：TTS 无法在从后台恢复后播放(#196)

## 1.4.2
- Feat: add link icon
- Feat: AI chat regenerate and copy
- Feat: TTS integration
- Feat: Reading info custom
- Feat: Navigation bar custom
- Feat: Sync completed toast
- Fix: Some old versions of Webview cannot import books
- Fix: Footnotes cannot be displayed on some devices
- Fix: Image as link cannot be clicked
- Fix: Reading information does not follow style changes
- Fix: First line indent affects images
- Fix: Context menu position error when it exceeds the screen
- Fix: Optimize book opening speed
- Fix: some device cant open footnote
- Fix: Android click page turn button may return to previous page
- Fix: iOS blank screen after resume from background
- Fix: note input box may be covered by keyboard(#183)
- Fix: txt file with special characters cannot be imported
- Fix: some Android devices cannot export backup file

- 新增：添加更多社区链接
- 新增：AI 对话可重新生成和复制
- 新增：集成的 TTS
- 新增：阅读信息自定义
- 新增：导航栏自定义
- 新增：同步完成是否显示提示
- 修复：部分旧版本Webview无法导入图书
- 修复：部分设备无法显示脚注
- 修复：以图片作为脚注时无法点击
- 修复：阅读信息无法跟随样式变化
- 修复：首行缩进影响图片
- 修复：上下文菜单超出屏幕时位置错误
- 修复: 优化书籍打开速度
- 修复: 部分设备无法打开脚注
- 修复：Android 跨章节后无法点击翻页的问题
- 修复：iOS 设备从后台恢复后有时白屏的问题
- 修复：写想法的输入框有时被键盘遮挡(#183)
- 修复：部分含有特殊字符的 txt 文件无法导入的问题
- 修复：部分 Android 设备无法导出备份文件

## 1.4.1
- Feat: excerpt AI chat
- Feat: add AI chat in reading page
- Feat: control webdav sync only when wifi is connected
- Feat: manage open book animation
- Feat: add text for context menu
- Feat: add text for slider(#48)
- Feat: add tips for AI configuration
- Feat: custom shelf cover width
- Feat: toc item scroll to current chapter(#141)
- Fix: save image on iOS
- Fix: click page turn button may return to previous page
- Fix: scroll page turn cannot set margin(#139)

- 新增：划线 AI 对话
- 新增：阅读界面可以与 AI 对话
- 新增：控制 WebDAV 是否仅在 WiFi 下同步
- 新增：管理打开书的动画
- 新增：上下文菜单文字提示
- 新增：样式调节滑块的文字说明(#48)
- 新增：AI 配置提示
- 新增：自定义书架封面宽度
- 新增：目录项滚动到当前章节(#141)
- 修复：iOS 端保存图片
- 修复：有时点击翻页会返回上一页
- 修复：滚动翻页无法设置上下边距(#139)

## 1.3.1
> MacOs 版本处于测试阶段
> MacOS version in beta

- Fix: Some Android devices cannot import txt format books
- 修复：部分安卓设备无法导入 txt 格式的书籍

## 1.3.0

> MacOs 版本处于测试阶段
> MacOS version in beta

- Feat: Add font weight slider
- Fix: AI answer cache(#124)
- Feat: Expand the range of custom font size
- Feat: Add volume key page turn switch
- Feat: Add custom Gemini api url
- Fix: Android TTS slider value not updating
- Fix: Txt file chapter title detection(#107)
- Fix: DeepSeek default model name(#123)
- Fix: Sync problem(#94，#89)

- 新增：调整字体粗细
- 新增：AI 回答缓存
- 新增：扩大自定义字体大小范围
- 新增：音量键翻页开关
- 新增：自定义 Gemini api url
- 修复：Android TTS 滑块数值不更新
- 修复：txt 文件章节标题检测(#107)
- 修复：DeepSeek 默认模型名称(#123)
- 修复：无法同步的问题(#94，#89)

## 1.2.6
- Fix: Fix ai stream error
- 修复：修复 AI 流错误
  
## 1.2.5
- Feat: Add volume key page turn(#95)
- Feat: Add auto background color(#78)
- Feat: Add OpenAI、Claude、DeepSeek AI models(#100)
- Perf: Optimize txt file import speed
- UI: Optimize multiple UI interfaces

- 新增：音量键翻页(#95)
- 功能：自动背景色(#78)
- 功能：接入 OpenAI、Claude、DeepSeek 等多个 AI 模型
- 性能：大幅提高了 txt 文件的导入速度
- UI: 优化多个 UI 界面

## 1.2.4 2025-01-21
* Feat: Remember last window position and size(#67)
* Feat: Color picker input hex code(#69)
* Feat: Export notes in CSV format(#71)
* Feat: Add TTS stop timer(#81)
* Feat: Add heat map to show reading time(#69)
* Feat: Import progress prompt(#61)
* Feat： Add statistics chart switch time
* Fix: some Windows systems cannot import books(#75)
* Fix: enhance Webdav sync stability
* Fix: Reading settings interface is incomplete on some devices(#70)

* 新增：记忆上次窗口位置和大小(#67)
* 新增：选择颜色时能够输入十六进制代码(#69)
* 新增：以 CSV 格式导出笔记(#71)
* 新增：TTS 定时停止(#81)
* 新增：用热力图展示阅读时长(#69)
* 新增：导入进度提示(#61)
* 新增：统计图表切换时间
* 修复：部分 Windows 系统下无法导入图书(#75)
* 修复：增强 Webdav 同步稳定性
* 修复：部分设备下阅读设置界面显示不完整(#70)

## 1.2.3 2024-12-26
* Feat: Reader could add notes
* Feat: Search books
* Feat(Android): Display TTS control buttons in the notification screen
* Feat(Android): Import books through system sharing
* Feat(Windows): Drag to import books
* Feat(Windows): Webview2 check and prompt
* Fix: Fixed garbled text when importing txt files
* Fix: Optimized import efficiency
* Fix(Windows)：Fixed crash issue when opening books on some Windows devices

* 新增：读者添加批注
* 新增：书籍搜索
* 新增（Android）：在通知栏中显示 TTS 控制按钮
* 新增（Android）：通过系统分享导入书籍
* 新增（Windows）：拖拽导入书籍
* 新增(Windows)：Webview2 检查和提示
* 修复：txt 文件导入时乱码问题(添加了 GBK 解码)
* 修复：大幅优化导入效率
* 修复（Windows）：部分Windows 端打开书时闪退问题

## 1.2.2 2024-12-02
🚀 Support txt files now!
🚀 支持了 txt 文件导入

- Feat: Setting reading column count
- Feat: Import txt format books
- Fix: Book progress record is not timely
- Fix: Windows import book error

- 新增：设置阅读栏数
- 新增：导入 txt 格式书籍
- 修复：书籍进度记录不及时
- 修复：Windows 端部分设备无法导入书籍

## 1.2.1 2024-11-23
- Feat: Drag to group books
- Fix: Bottom navigation bar covers menu bar
- Fix: Windows no longer deletes original files when importing
- Fix: Books with single quotes cannot be opened

- 新增：拖拽实现书籍分组
- 修复：底部导航栏覆盖菜单栏
- 修复: Windows 端导入时删除原文件的问题
- 修复: 包含单引号的书籍无法打开

## 1.2.0 2024-11-17
❗Anx-Reader has changed the Android version signature, please back up and reinstall Anx-Reader❗
❗安读更换了 Android 版本的签名, 请做好备份重新安装安读❗

🚀You can now use Anx-Reader on Windows!
🚀现在可以在 Windows 上使用安读了！

- Feat: Translate selected content
- Feat: Note add time
- Feat: Webview version check
- Feat: convert chinese mode
- UI: Optimized the statistic card
- Fix: Context menu cannot be closed once
- Fix: Cannot correctly judge the version when checking for updates

- 新增：翻译选中内容
- 新增：简繁转换
- 新增：Webview版本检查
- 新增：显示笔记添加时间
- UI：优化了统计卡片
- 修复：上下文菜单不能一次关闭
- 修复: 检查更新时不能正确判断版本

## 1.1.8 2024-10-23

- Added: Modify import/export file structure
- Fixed: Book font size cannot maintain relative relationship
- Fixed: Can be used in lower webview versions (about 92.0.0.0 and above)

- 修改：修改了导入导出的文件结构
- 修复：书籍字体大小不能保持相对关系
- 修复：能够在较低的 webview 版本中使用(约92.0.0.0及以上)

Windows version is coming soon!
Windows端即将发布，敬请期待！

## 1.1.7 2024-09-11
- Backup: Export/import all data
- Ability to click and view large images
- Convenient back arrow after navigation
- Multiple pop-up annotations within a pop-up annotation
- Customizable text indentation size
- Text selection within pop-up annotations
- Optimization of status bar and navigation key areas to avoid obstruction by navigation keys
- Fixed white screen issue when opening files
- Fixed issue with importing font files with Chinese filenames
- Shortened TTS reading intervals, especially when using TTS-Server

- 备份：导出/导入全部数据
- 能够点击查看大图了
- 跳转后能够有方便地返回箭头
- 弹注中多次弹注
- 弹注字体跟随设置
- 自定义文本缩进大小
- 弹注中选择文字
- 状态栏和导航键区域优化，避免了被导航键遮盖
- 修复打开文件白屏
- 修复字体文件中中文文件名无法导入
-  缩短了TTS朗读间隔，尤其是使用TTS-Server时
- 根据弹注内容调整弹注框大小


## 1.1.6 2024-09-03
This release includes a number of new features and improvements, as well as bug fixes.
Feature: Added support for importing books in mobi, azw3, and fb2 formats
Feature: Added TTS (Text-to-Speech) voice reading functionality
Feature: Added filter, sort, and open book at the note location features in the note list
Feature: Added more page-turning methods
Feature: Added support for importing custom fonts
Feature: Added full-text search functionality
Fix: Resolved issues where book styles were not applied (#24, #28)
Other: For more new features and bug fixes

众多新增功能！
功能：新增mobi、azw3、fb2格式书籍导入
功能：新增TTS语音朗读
功能：笔记列表可筛选、排序、打开书到笔记的位置
功能：新增更多翻页方式
功能：导入自定义字体
功能：全文搜索
修复：书籍样式不生效 #24，#28
以及其他众多新功能和修复

