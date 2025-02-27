**English** | [简体中文](README_zh.md) | [Türkçe](README_tr.md)

<br>

<p align="center">
  <img src="./docs/images/Anx-logo.jpg" alt="Anx-logo" width="100" />
</p>
<h1 align="center">Anx Reader</h1>
<p align="center">
  <a href="https://github.com/Anxcye/anx-reader/blob/main/LICENSE"><img src="https://img.shields.io/github/license/anxcye/anx-reader" alt="License" ></a>
  <a href="https://github.com/Anxcye/anx-reader/releases"><img src="https://img.shields.io/github/downloads/anxcye/anx-reader/total" alt="Downloads"></a>
  <a href="https://hellogithub.com/repository/819a2b3050204451bed552a8812114e5" target="_blank"><img src="https://abroad.hellogithub.com/v1/widgets/recommend.svg?rid=819a2b3050204451bed552a8812114e5&claim_uid=WBA1XOQirm2GRqs&theme=small" alt="Featured｜HelloGitHub"/></a>
  <a href="https://github.com/anxcye/anx-reader/stargazers"><img src="https://img.shields.io/github/stars/anxcye/anx-reader" alt="stars"></a>
</p>

Anx Reader, a thoughtfully crafted e-book reader for book lovers. Featuring powerful AI capabilities and supporting various e-book formats, it makes reading smarter and more focused. With its modern interface design, we're committed to delivering pure reading pleasure.


![](./docs/images/9.jpg)


📚 **Rich Format Support**
- Support for major e-book formats: EPUB, MOBI, AZW3, FB2, TXT
- Perfect parsing for optimal reading experience

☁️ **Seamless Sync**
- Cross-device synchronization of reading progress, notes, and books via WebDAV
- Continue your reading journey anywhere, anytime

🤖 **Smart AI Assistant**
- Integration with leading AI services: OpenAI, DeepSeek, Claude, Gemini
- Intelligent content summarization and reading position recall for enhanced efficiency

🎨 **Personalized Reading Experience**
- Carefully designed theme colors with customization options
- Switch freely between scrolling and pagination modes
- Import custom fonts to create your personal reading space

📊 **Professional Reading Analytics**
- Comprehensive reading statistics
- Weekly, monthly, and yearly reading reports
- Intuitive reading heatmap to track every moment of your reading journey

📝 **Powerful Note System**
- Flexible text annotation features
- Export options in TXT, CSV, and Markdown formats
- Easily organize and share your reading insights

🛠️ **Practical Tools**
- Smart TTS reading to rest your eyes
- Full-text search for quick content location
- Instant word translation to enhance reading efficiency

💻 **Cross-Platform Support**
- Seamless experience on Android and Windows
- Consistent user interface across devices

### TODO
- [X] UI adaptation for tablets
- [X] Page-turning animation
- [X] TTS voice reading
- [X] Reading fonts
- [X] Translation
- [ ] Full-text translation
- [ ] Support for more file types (pdf)
- [X] Support for WebDAV synchronization
- [ ] Support for Linux, MacOS

### I Encountered a Problem, What Should I Do?
Check [Troubleshooting](./docs/troubleshooting.md#English)

Submit an [issue](https://github.com/Anxcye/anx-reader/issues/new/choose), and we will respond as soon as possible.

Telegram Group: [https://t.me/AnxReader](https://t.me/AnxReader)

### Screenshots
| ![](./docs/images/windows_main.png)**windows** | ![](./docs/images/2wen.png) **Android Tablet**|
|:--:|:-:|
| ![](./docs/images/1wen.png) | ![](./docs/images/3wen.png) |

| ![](./docs/images/5men.jpg) | ![](./docs/images/1men.jpg) |![](./docs/images/7men.jpg)|
|:--:|:--:|:--:|
| ![](./docs/images/10men.jpg) | ![](./docs/images/9men.jpg) | ![](./docs/images/8men.jpg)|

## Donations
If you like Anx Reader, please consider supporting the project by donating. Your donation will help me maintain and improve the project.

❤️ [Donate](https://anxcye.com/home/7)

## Building
Want to build Anx Reader from source? Please follow these steps:
- Install [Flutter](https://flutter.dev).
- Clone and enter the project directory.
- Run `flutter pub get`.
- Run `flutter gen-l10n` to generate multi-language files.
- Run `dart run build_runner build --delete-conflicting-outputs` to generate the Riverpod code.
- Run `flutter run` to launch the application.

You may encounter Flutter version incompatibility issues. Please refer to the [Flutter documentation](https://flutter.dev/docs/get-started/install).

## Code signing policy
- Committers and reviewers: [Members team](https://github.com/anxcye/anx-reader/graphs/contributors)
- Approvers: [Owners](https://github.com/anxcye)


Free code signing on Windows provided by [SignPath.io](https://about.signpath.io/),certficate by [SignPath Foundation](https://signpath.org/)

## License
This project is licensed under the [MIT License](./LICENSE).

Starting from version 1.1.4, the open source license for the Anx Reader project has been changed from the MIT License to the GNU General Public License version 3 (GPLv3).

After version 1.2.6, the selection and highlight feature has been rewritten, and the open source license has been changed from the GPL-3.0 License to the MIT License. All contributors agree to this change(#116).

## Thanks
[foliate-js](https://github.com/johnfactotum/foliate-js), which is MIT licensed, it used as the ebook renderer. Thanks to the author for providing such a great project.

[foliate](https://github.com/johnfactotum/foliate), which is GPL-3.0 licensed, selection and highlight feature is inspired by this project. But since 1.2.6, the selection and highlight feature has been rewritten.

And many [other open source projects](./pubspec.yaml), thanks to all the authors for their contributions.

