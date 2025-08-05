[English](#english) | [Русский](#русский)

### English

# Changelog

## Todo

## 1.6.2
- UI: Modify bottom navigation bar style
- Feat: Import previously deleted files and automatically associate notes, progress, etc.
- Feat: Support preventing duplicate file imports
- Feat: Support calculating feature values of existing files to prevent duplicate imports
- Feat: Support custom CSS styles
- Fix: Fix sync failure when WebDAV is empty
- Fix: Fix issue where txt files could not be correctly judged as duplicates

- UI: 修改底部导航栏样式
- Feat: 导入曾经删除的文件时自动关联笔记、进度等信息
- Feat: 支持防止文件重复导入
- Feat：支持计算已有文件特征值，用于防止重复导入
- Feat: 支持自定义 CSS 样式
- Fix: WebDAV 为空时同步失败的问题
- Fix: 修复 txt 文件无法正确判断是否重复的问题

## 1.6.1
- Feat: Support following book indentation
- Feat: Support choosing whether to enable auto-sync
- Feat: Add a guide page for first-time users
- Feat: Show update log after updating
- Feat: Support restoring old versions from history after downloading and overwriting the local database from remote (experimental feature)
- Fix: Some Android devices cannot select text and pop up context menu
- Fix: Compatibility with older WebView versions, now it may run on WebView version 70 and above
- Fix: WebDAV configuration changes now take effect immediately after saving
- Fix: Improved sync logic to replace the current database only after confirming the integrity of the new database
- Fix: Preserve historical versions when replacing the local database
- Fix: PDF files could not be read in the previouo version
- Fix: covers could not be synced
- Fix: files with uppercase extensioos could not be imported
- Fix: books could not be imported on somo Windows devices
- Fix: Fixed issue where user notes were lost after changing highlight style
- Fix: Fixed issue where PDF files could not be imported
- Chore: Prepare for supporting more sync protocols
- Build: Optimize build number

- Feat: 支持跟随书籍缩进
- Feat: 支持选择是否开启自动同步功能
- Feat: 添加首次启动的引导页
- Feat：更新后能够展示更新日志
- Feat: 从远端下载数据库覆盖本地后，能够从历史版本中选择旧版本恢复（实验性功能）
- Fix: 部分安卓设备无法在选择文段后弹出上下文菜单
- Fix: 兼容较旧的 WebView 版本，现在或许可以在 WebView 70 以上的版本上运行了
- Fix: 修复保存 WebDAV 配置信息后未能立即生效的问题
- Fix: 修复同步逻辑，能够在判断新数据库完整后再替换当前数据库
- Fix: 在替换本地数据库时能够保留历史版本
- Fix: 修复上一版本中 PDF 无法阅读的问题
- Fix: 修复封面无法同步的问题
- Fix: 修复大写扩展名的文件无法导入的问题
- Fix: 部分情况下 Windows 端无法导入书籍
- Fix: 修复修改划线样式后用户笔记丢失的问题
- Fix: pdf 无法导入的问题
- Chore: 为更多同步协议做好准备
- Build: 优化构建号

## 1.6.0
‼️If WebDAV sync is enabled, please upgrade all devices to this version, otherwise the book notes list will not be displayed‼️
‼️如果启用了 WebDAV 同步，需要将各端都升级至此版本，否则书籍笔记列表将无法显示‼️

- Feat: Support locating the current chapter in the table of contents
- Feat: Custom page header and footer position
- Feat: Support displaying page numbers in the table of contents
- Feat: Support running JavaScript in books
- Feat: Support pull up to exit reading page
- Feat: Support adding bookmarks by pulling down
- Feat: Support opening the menu bar by pulling up
- Feat: Support adding/removing bookmarks via the bookmark button
- Feat: Show bookmark list in the table of contents page
- Feat: Support deleting the current bookmark by pulling down
- Feat: Support choosing whether to display bookmarks when filtering
- Feat: Display book name in two lines
- Feat: Add two background image in share card
- Feat: Opening a book from the note list will not record reading progress
- Fix: Fix inaccurate click position recognition in vertical scroll layout
- Fix: Optimize page-turning animation stuttering
- Fix: improve version comparison logic in update check
- Fix: Better app icon for Android
- Fix: Optimize the timing of the context menu popup on Android devices
- Dx: Improved JS debugging process for easier debugging

- Feat: 在目录上定位当前章节
- Feat: 自定义页眉和页脚的位置
- Feat: 在目录上显示页码 
- Feat: 支持运行Epub书中的 JavaScript
- Feat: 支持上划退出阅读页面
- Feat: 支持下拉添加书签
- Feat: 支持上拉呼出菜单栏
- Feat: 支持通过书签按钮添加/删除书签
- Feat: 在目录页显示书签列表
- Feat: 支持下拉删除当前书签
- Feat: 支持在笔记列表筛选时选择是否显示书签
- Feat: 书名显示为两行
- Feat: 分享卡片新增两个背景图
- Feat: 从笔记列表打开书不会记录阅读进度
- Fix: 修复竖向滚动排版点击位置识别不准确的问题
- Fix: 优化翻页动画卡顿的问题
- Fix: 优化检查更新时版本比较逻辑
- Fix: 优化 Android 端应用图标
- Fix: 优化 Android 设备上下文菜单弹出时机
- Dx: 修改js的调试流程，更方便调试

## 1.5.3
- Feat: Support AI translation and dictionary(#145, #249)
- Feat: Support setting DeepL URL
- Feat: Show data update time while choosing sync direction
- Feat: Add Crimean Tatar translation support
- Feat: Support modifying the original text content in the note editing diaglog
- Feat: Support import books via share
- Feat: Add this app to open with
- Fix: adjust margin icons in style settings
- Fix: TTS may get stuck on punctuation
- Fix: Fix garbled text when importing some TXT files
- Fix: Fix excessive spacing between some file segments(#325)
- UI: Update background and button styles in BookDetail
- Fix: Fix inaccurate click position in pdf files
- Fix: macOS Launchpad icon edge anomaly(#331)
- Fix: Fix issue where short TXT files cannot be imported(#329)
- Fix: Fix DeepL translation error(#327)

- 新增：支持 AI 翻译和词典(#145, #249)
- 新增：支持设置 DeepL URL
- 新增：在选择同步方向时提示两端的数据更新时间
- 新增：添加克里米亚鞑靼语翻译支持
- 新增：支持在笔记编辑界面中修改笔记的原文内容
- 新增：iOS 支持通过分享的方式导入图书
- 新增：支持 打开方式 中选择本App
- 修复：修改样式设置中的边距图标
- 修复：TTS 有时会被标点符号卡住
- 修复：部分 TXT 文件导入乱码的问题
- 修复：部分文件段间距过大(#325)
- UI: 修改书籍详情页背景和按钮样式
- 修复：pdf 文件点击位置不准确的问题
- 修复：macOS 启动台中图标边缘异常(#331)
- 修复：内容较短的 TXT 文件无法导入的问题(#329)
- 修复：DeepL 翻译出错(#327)

## 1.5.2
- Feat: iOS dark and tinted icons
- Feat: Custom reading background image
- Feat: Import any custom reading background
- Feat: Custom writing direction(Horizontal, Vertical)
- Fix: WebDAV sync may override cloud data(#274)
- Fix: TTS may stop when encountering some punctuation(#291)
- Fix: Background image stretched in scroll mode
- Fix: Hide scrollbar in scroll mode
- Fix: Vertical margin prompt is not clear in vertical mode
- Fix: Click position cannot be recognized in vertical mode
- Fix: WebDAV sync may override cloud data with special characters
- Fix: Reduce TTS reading interval time
- Fix: Some interfaces are difficult to identify in E-ink mode
- Fix: Book status icon not updated after releasing space
- Fix: WebDAV sync error Not Found and Conflict

- 新增：iOS 深色、着色图标
- 新增：设置阅读背景图片
- 新增：导入任意自定义阅读背景
- 新增：可以选择文字方向（横排、竖排）
- 修复：WebDAV 同步时可能会覆盖云端数据(#274)
- 修复：遇到部分标点时朗读停止(#291)
- 修复：滚动模式下，背景图片被拉伸
- 修复：在滚动模式下隐藏滚动条
- 修复：竖排模式下，边距调节提示不够明确
- 修复：竖排模式下，点击位置无法正确识别
- 修复：包含特殊字符的文件名无法通过 WebDAV 同步
- 修复：减小 TTS 朗读间隔时间
- 修复：E-ink 模式下，部分界面难以辨认
- 修复：释放空间后，书籍状态图标不更新
- 修复：WebDAV 同步时报错 Not Found 和 Conflict 的问题

## 1.5.1
- Fix: Can't open book note list in some cases
- Fix: WebDAV sync show Not Found
- Fix: Context menu is difficult to distinguish in e-ink mode
- L10n: Optimized Arabic translation
- 修复：某些特殊情况下笔记列表无法显示
- 修复：某些情况下 WebDAV 同步时显示 Not Found 的问题
- 修复：E-ink 模式下上下文菜单难以辨认
- L10n: 优化阿拉伯语部分翻译

## 1.5.0
- Feat: Cache in-app purchase status(#281, #242)
- Feat: Name a group
- Feat: E-ink mode(#264)
- Feat: Add DeepL translation service(#223, #145)
- Feat: Edit notes in list
- Feat: Download all books
- L10n: Add Arabic and German language
- Feat: Download remote files on demand
- Feat: Release local space(#269)
- Feat: Add share excerpt card(#263)
- Feat: Notes in list can be shared as cards
- Fix: Incorrect click position detection on macOS
- Fix: Sort menu sometimes fails to open
- Fix: WebDAV Unauthorized(#273)
- Fix: Optimize book opening speed
- Fix: Touchpad cannot scroll(#271, #261)
- Fix: Edge TTS when network exception, it will stop reading

- 新增：缓存内购状态(#281, #242)
- 新增：书籍分组支持命名
- 新增：E-ink 模式(#264)
- 新增：DeepL 翻译服务(#223, #145)
- 新增：笔记列表可以编辑笔记
- 新增：下载所有书籍文件
- L10n: 新增阿拉伯语和德语
- 新增：按需下载远程的文件
- 新增：释放本地空间功能(#269)
- 新增：通过卡片的方式分享划线笔记(#263)
- 新增：笔记列表的笔记可以以卡片的形式分享
- 修复：macOS 端无法正确判断点击位置的问题
- 修复：排序菜单有时无法打开的问题
- 修复：WebDAV提示未授权(#273)
- 修复：优化打开书籍速度
- 修复：触摸板无法滚动(#271, #261)
- 修复：Edge TTS 朗读时，网络异常时会停止朗读的问题

## 1.4.4
- Feat: Import pdf files
- Feat: Sort books
- Feat: More available fonts
- Feat: Delete reading records of a book
- Feat: Add webdav sync direction dialog
- Feat: Add font delete
- Fix: Webdav sync aborted dialog content
- Fix: if webdav is empty, sync will upload
- Fix: avoid image following paragraph indent
- Fix: optimize book loading speed
- Fix: sync custom book cover

- 新增：导入 pdf 文件
- 新增：书架排序功能
- 新增：更多可选字体
- 新增：删除一本书的阅读记录
- 新增：添加 WebDAV 同步方向对话框
- 新增：添加字体删除功能
- 修复：WebDAV 同步中止对话框内容
- 修复：如果 WebDAV 为空，则同步时默认上传
- 修复：避免图片跟随段落缩进
- 修复：提升图书加载速度
- 修复：同步自定义的书籍封面

## 1.4.3
- Feat: Storage space management
- Feat: Add auto translate selection switch in translate settings(#217)
- Feat: Handle txt files with failed chapter division by word count
- Feat: Import txt file with utf-16 or utf-32 encoding
- Feat: recover system TTS(#197)
- Fix: TTS cannot play after resume from background(#196)
- Fix: TTS cannot play when encountering images or cross-chapter
- Fix: System TTS continuous backward movement(#197)
- Fix: Copy translated text instead of original text(#190)
- Fix: Cross-segment highlight cannot be displayed immediately
- Fix: Highlight only the first word of the selection on Android(#189)
- Fix: Scroll page turn cannot be used in scroll mode(#201)

- 新增：存储空间查看和管理
- 新增：翻译设置页增加自动翻译开关(#217)
- 新增：按字数对分章失败的txt文件进行处理
- 新增：支持导入UTF-16、UTF-32编码的txt文件
- 新增：重新引入了系统 TTS(#197)
- 修复：TTS 无法在从后台恢复后播放(#196)
- 修复：集成 TTS 遇到图片或跨章节时无法播放
- 修复：系统 TTS 连续向后移动
- 修复：复制翻译内容而不是原文(#190)
- 修复：跨段划线无法立即显示
- 修复：安卓设备有时划线只能显示第一个字词(#189)
- 修复：滚动翻页模式下，鼠标滚轮翻页一次翻一整页的问题(#201)

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

### Русский

# Журнал изменений

## Планируемое (Todo)

## 1.6.1
- Функция: Поддержка отступов в соответствии с книгой
- Функция: Возможность выбора включения автоматической синхронизации
- Функция: Добавлена страница-путеводитель для новых пользователей
- Функция: Показать журнал обновлений после обновления
- Функция: Поддержка восстановления старых версий из истории после загрузки и перезаписи локальной базы данных с удалённого источника (экспериментальная функция)
- Исправлено: На некоторых устройствах Android нельзя выделять текст и вызывать контекстное меню
- Исправлено: Совместимость со старыми версиями WebView, теперь работает с версиями WebView 70 и выше
- Исправлено: Изменения конфигурации WebDAV вступают в силу сразу после сохранения
- Исправлено: Улучшена логика синхронизации — замена базы данных происходит только после подтверждения её целостности
- Исправлено: Сохраняются исторические версии при замене локальной базы данных
- Исправлено: В предыдущей версии была проблема с чтением PDF-файлов
- Исправлено: Не синхронизировались обложки книг
- Исправлено: Не импортировались файлы с заглавными расширениями
- Исправлено: Не импортировались книги на некоторых устройствах Windows
- Исправлено: Исправлена потеря пользовательских заметок после изменения стиля выделения текста
- Исправлено: Проблемы с импортом PDF-файлов
- Техническое: Подготовка к поддержке дополнительных протоколов синхронизации
- Сборка: Оптимизация номера сборки

## 1.6.0
‼️Если включена синхронизация WebDAV, необходимо обновить все устройства до этой версии, иначе список заметок в книгах отображаться не будет‼️

- Функция: Позиционирование текущей главы в оглавлении
- Функция: Настройка расположения заголовка и подвала страницы
- Функция: Отображение номеров страниц в оглавлении
- Функция: Запуск JavaScript в книгах
- Функция: Выход с экрана чтения свайпом вверх
- Функция: Добавление закладок свайпом вниз
- Функция: Вызов меню свайпом вверх
- Функция: Добавление и удаление закладок через кнопку закладок
- Функция: Отображение списка закладок на странице оглавления
- Функция: Удаление текущей закладки свайпом вниз
- Функция: Выбор отображения закладок при фильтрации заметок
- Функция: Отображение названия книги в две строки
- Функция: Добавлено два фоновых изображения для карточки шаринга
- Функция: Открытие книги из списка заметок не сохраняет прогресс чтения
- Исправлено: Некорректное распознавание позиции клика в вертикальной прокрутке
- Исправлено: Оптимизация анимации перелистывания страниц
- Исправлено: Улучшена логика сравнения версий при проверке обновлений
- Исправлено: Улучшена иконка приложения для Android
- Исправлено: Оптимизировано время появления контекстного меню на Android
- Улучшено: Упрощена отладка JavaScript-кода

## 1.5.3
- Функция: Поддержка AI-перевода и словаря (#145, #249)
- Функция: Возможность настройки URL DeepL
- Функция: Отображение времени обновления данных при выборе направления синхронизации
- Функция: Добавлена поддержка крымскотатарского языка
- Функция: Возможность изменять исходный текст в диалоге редактирования заметок
- Функция: Импорт книг через функцию «Поделиться»
- Функция: Добавление данного приложения в список приложений для открытия файлов
- Исправлено: Корректировка иконок отступов в настройках стилей
- Исправлено: Решена проблема с зависанием TTS на знаках препинания
- Исправлено: Исправлены искажённые символы при импорте некоторых TXT файлов
- Исправлено: Исправлены избыточные промежутки между сегментами файлов (#325)
- UI: Обновлены фоновые изображения и стили кнопок на странице информации о книге
- Исправлено: Неточное определение позиции кликов в PDF файлах
- Исправлено: Аномалия с краями иконки Launchpad в macOS (#331)
- Исправлено: Проблема с импортом коротких TXT файлов (#329)
- Исправлено: Ошибка перевода DeepL (#327)

## 1.5.2
- Функция: Тёмная и с оттенком иконки для iOS
- Функция: Пользовательский фон для чтения
- Функция: Импорт любого пользовательского фона для чтения
- Функция: Пользовательское направление чтения (горизонтальное, вертикальное)
- Исправлено: Синхронизация WebDAV могла перезаписывать облачные данные (#274)
- Исправлено: TTS мог останавливаться на некоторых знаках препинания (#291)
- Исправлено: Фоновое изображение растягивалось в режиме прокрутки
- Исправлено: Скрытие полосы прокрутки в режиме прокрутки
- Исправлено: Неясные подсказки по вертикальным отступам в вертикальном режиме
- Исправлено: Нерзко распознавалась позиция клика в вертикальном режиме
- Исправлено: Синхронизация WebDAV могла перезаписывать облачные данные с особыми символами
- Исправлено: Уменьшен интервал времени чтения TTS
- Исправлено: Некоторые интерфейсы трудно распознаются в режиме E-ink
- Исправлено: Иконка статуса книги не обновлялась после освобождения места
- Исправлено: Ошибки синхронизации WebDAV: Not Found и Conflict

## 1.5.1
- Исправлено: В некоторых случаях не удаётся открыть список заметок книги
- Исправлено: Синхронизация WebDAV показывала ошибку Not Found
- Исправлено: Контекстное меню трудно различить в режиме E-ink
- Локализация: Оптимизирован перевод на арабский язык

## 1.5.0
- Функция: Кэширование статуса покупок внутри приложения (#281, #242)
- Функция: Возможность задавать имя для группы
- Функция: Режим E-ink (#264)
- Функция: Добавлена поддержка сервиса перевода DeepL (#223, #145)
- Функция: Редактирование заметок в списке
- Функция: Загрузка всех книг
- Локализация: Добавлены арабский и немецкий языки
- Функция: Загрузка удалённых файлов по запросу
- Функция: Освобождение локального пространства (#269)
- Функция: Добавлена карточка для шаринга выдержек (#263)
- Функция: Заметки из списка можно делиться в виде карточек
- Исправлено: Некорректное определение позиции кликов на macOS
- Исправлено: Иногда меню сортировки не открывалось
- Исправлено: Ошибка «Неавторизован» в WebDAV (#273)
- Исправлено: Оптимизирована скорость открытия книг
- Исправлено: Нет прокрутки на тачпаде (#271, #261)
- Исправлено: В Edge TTS останавливался при сетевых ошибках

## 1.4.4
- Функция: Импорт PDF-файлов
- Функция: Сортировка книг
- Функция: Добавлено больше шрифтов
- Функция: Удаление истории чтения книги
- Функция: Диалог выбора направления синхронизации WebDAV
- Функция: Возможность удаления шрифтов
- Исправлено: Исправлено содержимое диалога при прерывании синхронизации WebDAV
- Исправлено: Если WebDAV пуст, при синхронизации происходит загрузка
- Исправлено: Избежание смещения изображений вследствие отступа абзацев
- Исправлено: Оптимизирована скорость загрузки книг
- Исправлено: Синхронизация пользовательских обложек книг

## 1.4.3
- Функция: Управление местом на диске
- Функция: Добавлен переключатель автоматического перевода выделения в настройках перевода (#217)
- Функция: Обработка txt-файлов с неудачным разделением по главам на основе подсчёта слов
- Функция: Импорт txt-файлов с кодировками utf-16 или utf-32
- Функция: Восстановление системного TTS (#197)
- Исправлено: TTS не проигрывается после возврата из фонового режима (#196)
- Исправлено: TTS не работает при столкновении с изображениями или переходами между главами
- Исправлено: Системный TTS сдвигается назад при воспроизведении (#197)
- Исправлено: Копируется переведённый текст вместо оригинала (#190)
- Исправлено: Подсветка, охватывающая несколько сегментов, не отображается сразу
- Исправлено: На Android выделяется только первое слово в выделении (#189)
- Исправлено: В режиме прокрутки нельзя использовать прокрутку для перелистывания страниц (#201)

## 1.4.2
- Функция: Добавлена иконка ссылки
- Функция: AI-чат с возможностью регенерации и копирования
- Функция: Интеграция TTS
- Функция: Настройка информации о чтении
- Функция: Настройка панели навигации
- Функция: Уведомление о завершении синхронизации
- Исправлено: Некоторые старые версии WebView не могут импортировать книги
- Исправлено: На некоторых устройствах не отображаются сноски
- Исправлено: По изображениям-ссылкам нельзя кликать
- Исправлено: Информация о чтении не меняется при смене стиля
- Исправлено: Отступ первой строки влияет на изображения
- Исправлено: Неправильная позиция контекстного меню, когда оно выходит за границы экрана
- Исправлено: Оптимизирована скорость открытия книг
- Исправлено: Некоторые устройства не могут открыть сноски
- Исправлено: Кнопка перелистывания на Android может возвращать на предыдущую страницу
- Исправлено: Появление пустого экрана на iOS после возврата из фона
- Исправлено: Поле ввода заметок может быть закрыто клавиатурой (#183)
- Исправлено: Не импортируются txt-файлы с особыми символами
- Исправлено: Некоторые устройства Android не могут экспортировать резервную копию

## 1.4.1
- Функция: AI-чат по выделенному тексту
- Функция: Добавлен AI-чат на экран чтения
- Функция: Синхронизация WebDAV только при подключении к Wi-Fi
- Функция: Управление анимацией открытия книги
- Функция: Добавлен текст в контекстное меню
- Функция: Добавлен текст для ползунка настроек (#48)
- Функция: Добавлены подсказки для настройки AI
- Функция: Настройка ширины обложки на полке
- Функция: Прокрутка элемента оглавления к текущей главе (#141)
- Исправлено: Сохранение изображений на iOS
- Исправлено: Кнопка перелистывания страниц может возвращать назад
- Исправлено: В режиме прокрутки можно установить отступы

## 1.3.1
- Исправлено: Некоторые устройства Android не могут импортировать книги в формате txt

## 1.3.0
- Функция: Добавлен ползунок жирности шрифта
- Исправлено: Кэш ответов AI (#124)
- Функция: Расширены возможности выбора размера шрифта
- Функция: Добавлен переключатель для перелистывания страниц кнопками громкости
- Функция: Добавлен пользовательский URL Gemini API
- Исправлено: Значение ползунка TTS на Android не обновляется
- Исправлено: Обнаружение заголовков глав в txt-файлах (#107)
- Исправлено: Название модели DeepSeek по умолчанию (#123)
- Исправлено: Проблемы с синхронизацией (#94, #89)

## 1.2.6
- Исправлено: Ошибка AI-стрима

## 1.2.5
- Функция: Добавлен переключатель перелистывания страниц кнопками громкости (#95)
- Функция: Автоматический выбор цвета фона (#78)
- Функция: Добавлены AI-модели OpenAI, Claude, DeepSeek (#100)
- Оптимизация: Ускорен импорт txt-файлов
- UI: Оптимизация нескольких интерфейсов

## 1.2.4 (2025-01-21)
- Функция: Запоминание последнего положения и размера окна (#67)
- Функция: Ввод шестнадцатеричного кода в палитре цветов (#69)
- Функция: Экспорт заметок в формате CSV (#71)
- Функция: Таймер остановки TTS (#81)
- Функция: Добавлена тепловая карта для отображения времени чтения (#69)
- Функция: Индикатор прогресса импорта (#61)
- Функция: Переключение времени на статистической диаграмме
- Исправлено: Некоторые версии Windows не могут импортировать книги (#75)
- Исправлено: Повышена стабильность синхронизации WebDAV
- Исправлено: В некоторых устройствах интерфейс настроек чтения отображается не полностью (#70)

## 1.2.3 (2024-12-26)
- Функция: Читатели могут добавлять заметки
- Функция: Поиск книг
- Функция (Android): Отображение кнопок управления TTS в уведомлениях
- Функция (Android): Импорт книг через системный обмен
- Функция (Windows): Импорт книг перетаскиванием
- Функция (Windows): Проверка и оповещение Webview2
- Исправлено: Исправлены искажения текста при импорте txt
- Исправлено: Оптимизирована эффективность импорта
- Исправлено (Windows): Исправлено падение при открытии книг на некоторых устройствах

## 1.2.2 (2024-12-02)
- Функция: Поддержка импорта txt-файлов
- Исправлено: Запись прогресса книги происходит с задержкой
- Исправлено: Ошибки при импорте книг в Windows

## 1.2.1 (2024-11-23)
- Функция: Перетаскивание для группировки книг
- Исправлено: Нижняя навигационная панель перекрывает меню
- Исправлено: При импорте в Windows не удаляются исходные файлы
- Исправлено: Не открываются книги с одинарными кавычками в названии

## 1.2.0 (2024-11-17)
❗ Anx-Reader сменил подпись Android-версии, пожалуйста, сделайте резервную копию и переустановите приложение ❗

🚀 Теперь Anx-Reader доступен для Windows!

- Функция: Перевод выделенного текста
- Функция: Отображение времени добавления заметки
- Функция: Проверка версии WebView
- Функция: Конвертация между упрощённым и традиционным китайским
- UI: Оптимизация статистической карты
- Исправлено: Контекстное меню не закрывается одним нажатием
- Исправлено: Некорректное определение версии при проверке обновлений

## 1.1.8 (2024-10-23)
- Изменено: Структура импортируемых и экспортируемых файлов
- Исправлено: Размер шрифта книг не сохранялся в относительных пропорциях
- Исправлено: Приложение работает на старых версиях WebView (примерно 92.0.0.0 и выше)

Скоро выйдет версия для Windows! Следите за новостями!

## 1.1.7 (2024-09-11)
- Резервное копирование: экспорт и импорт всех данных
- Возможность просмотра увеличенных изображений по клику
- Удобная кнопка «назад» после перехода
- Вложенные всплывающие аннотации
- Настройка размера отступов текста
- Выделение текста в всплывающих аннотациях
- Оптимизация областей статус-бара и навигационных клавиш, чтобы избежать перекрытия
- Исправлено: Белый экран при открытии файлов
- Исправлено: Проблемы с импортом шрифтов с китайскими именами файлов
- Сокращены интервалы чтения TTS, особенно при использовании TTS-Server
- Автоматическая подстройка размера всплывающих окон под содержимое

## 1.1.6 (2024-09-03)
Этот релиз включает множество новых функций, улучшений и исправлений ошибок.
- Функция: Добавлена поддержка импорта книг в форматах mobi, azw3 и fb2
- Функция: Добавлена поддержка озвучивания текста (TTS)
- Функция: Добавлены функции фильтрации, сортировки и открытия книг в месте заметки в списке заметок
- Функция: Добавлены дополнительные способы перелистывания страниц
- Функция: Добавлена поддержка импорта пользовательских шрифтов
- Функция: Добавлен полнотекстовый поиск
- Исправлено: Решены проблемы с неприменением стилей к книгам (#24, #28)
- И многое другое — новые функции и исправления
