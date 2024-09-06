[English](README.md) | **简体中文**

<p align="center">
  <img src="./docs/images/Anx-logo.jpg" alt="Anx-logo" width="100" />
</p>
<h1 align="center">安读 - 让阅读更专注</h1>

<p align="center">
  <a href="https://github.com/Anxcye/anx-reader/blob/main/LICENSE"><img src="https://img.shields.io/github/license/anxcye/anx-reader" alt="License" ></a>
  <a href="https://github.com/Anxcye/anx-reader/releases"><img src="https://img.shields.io/github/downloads/anxcye/anx-reader/total" alt="Downloads"></a>
  <a href="https://hellogithub.com/repository/819a2b3050204451bed552a8812114e5" target="_blank"><img src="https://abroad.hellogithub.com/v1/widgets/recommend.svg?rid=819a2b3050204451bed552a8812114e5&claim_uid=WBA1XOQirm2GRqs&theme=small" alt="Featured｜HelloGitHub"/></a>
  <a href="https://github.com/anxcye/anx-reader/stargazers"><img src="https://img.shields.io/github/stars/anxcye/anx-reader" alt="stars"></a>
</p>


安读是一款专注于阅读的应用，不包含任何在线推广内容，它可以帮助你更专注于阅读，提高阅读效率。

支持 **epub / mobi / azw3 / fb2**

![](./docs/images/9_zh.jpg)



- 更全面的同步功能。支持使用 WebDAV 同步阅读进度、笔记以及书籍文件。
- 丰富且可自定义的阅读配色，让您的阅读更舒适。
- 强大的阅读统计，记录您的每一次阅读。
- 丰富的阅读笔记功能，让您的阅读更深入。
- 适配手机、平板界面。



### TODO
- [X] UI 适配 Tab 端
- [X] 翻页动画
- [X] TTS 语音朗读
- [X] 阅读字体
- [ ] 翻译
- [ ] 支持更多文件类型（txt, pdf）
- [X] 支持 WebDAV 同步
- [ ] 支持 Windows，Linux


### 我遇到了问题，怎么办？
查看[故障排除](./docs/troubleshooting.md#简体中文)

提出一个[issue](https://github.com/Anxcye/anx-reader/issues/new/choose)，将会尽快回复。

Telegram 群组：[https://t.me/AnxReader](https://t.me/AnxReader)

## 构建
希望从源码构建安读？请参考以下步骤：
- 安装 [Flutter](https://flutter.dev)。
- 克隆并进入项目目录。
- 运行 `flutter pub get` 。
- 运行 `flutter gen-l10n` 生成多语言文件。
- 运行 `flutter run` 启动应用。

您可能遇到 Flutter 版本不兼容的问题，请参考 [Flutter 文档](https://flutter.dev/docs/get-started/install)。


