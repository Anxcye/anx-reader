# Changelog

## Todo
- 选择时移动
- 自动背景色

## Unreleased
* Feat(Android): Import books through system sharing
* Feat(Windows): Drag to import books
* Fix: Fixed garbled text when importing txt files
* Fix: Optimized import efficiency

* 新增（Android）：通过系统分享导入书籍
* 新增（Windows）：拖拽导入书籍
* 修复：txt 文件导入时乱码问题(添加了 GBK 解码)
* 修复：大幅优化导入效率

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

