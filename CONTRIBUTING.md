[English](#Contributing-to-Anx-Reader) | [简体中文](#让安读更好)

# Contributing to Anx Reader

Anx Reader is an open-source project, and we welcome any contributions from you. You can help by translating, fixing bugs, adding new features, writing documentation, and more. If you want to contribute, the following guide may be helpful.

Let's get started!

### Running
- Install [Flutter](https://flutter.dev).
- Clone and navigate to the project directory.
Execute the following commands:
```bash
flutter pub get
flutter run # or click the run button in your IDE
```

### Contributing to Development
1. Fork this repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Make changes (e.g., adding new features, fixing bugs, translating, etc.)
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Submit a Pull Request

### Building
You will need a signing key to generate an APK. You can generate one or use the debug signing option

If you want to generate a signing key, please refer to [here](https://developer.android.com/studio/publish/app-signing).

Using the debug signing option, you can modify the following in the `android/app/build.gradle` file:

```gradle
android {
    // ...
    buildTypes {
      release {
        signingConfig signingConfigs.debug // using debug signing
      }
    }
    // ...
}
```


### Translation
If you'd like Anx Reader to support your language, let's work together on the translation!

You can translate project documentation or the app interface.

**Translate Documentation**
Currently, we have the following documents that need translation:
- [README.md](README.md)

Please copy README.md as README_language_code.md, translate it, and place the translated file in the project root directory. Then, add a link to the translation at the top of the README.md.

**Translate the App Interface**
- Anx Reader uses [intl](https://pub.dev/packages/intl) for multilingual support. You can find the localization files in the `lib/l10n` directory. Please copy `app_en.arb` to `app_language_code.arb`, and then translate it.
- You can translate missing fields or modify existing translations.
- Place the translated file in the `lib/l10n` directory and run `flutter gen-l10n` to generate the localization files.
- Add your `language name` and `code` to the [Settings Page](lib/page/settings_page/appearance.dart#L83).
- Refer to [locale](https://saimana.com/list-of-country-locale-code/) for language codes.
- Make sure to run the app at least once after translation to ensure everything works fine.
- Submit a Pull Request.

### Fixing Bugs and Adding New Features
Anx Reader uses [Flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview) to render eBooks, so the project relies on `JavaScript` to handle eBook rendering.

The `JavaScript` code can be found in the `assets/foliate-js` directory, where you'll find the code responsible for rendering eBooks. The app loads the `index.html` file from the `assets/foliate-js` directory using a [built-in server](lib/service/book_player/book_player_server.dart).

When debugging the `js`, you can find some commented code at the top of `book.js` in the `assets/foliate-js` directory. You can uncomment this code, place a test book in the `assets/local` directory, modify `book.js` with `let url = '../local/***.epub'`, and open the `index.html` file in your browser to see the result.

To adjust the rendering of books, you can modify the `getCSS` function in the `book.js` file. These CSS styles will be applied to the book.

The main part of the communication between `js` and `dart` is in [epub_player.dart](lib/page/book_player/epub_player.dart), where you'll find the code that handles `js` communication. The webview interface is also loaded here.

After re-commenting the code in `book.js`, rerun the application.

Please submit a Pull Request after re-commenting the code in `book.js`.

# 让安读更好
安读是一款开源项目，我们欢迎您的任何贡献，您可以对项目进行翻译、修复 bug、添加新功能，编写文档等。如果您想要贡献，以下内容可能会对您有所帮助。

让我们开始吧！

### 运行
- 安装 [Flutter](https://flutter.dev)。
- 克隆并进入项目目录。
执行以下命令：
```bash
flutter pub get
flutter run # 或点击IDE运行按钮
```


### 参与开发
1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 在这里做些更改（如添加新功能、修复 bug、翻译等）
4. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
5. 推送到分支 (`git push origin feature/AmazingFeature`)
6. 提交一个 Pull Request

### 编译
您将需要签名密钥来生成 APK。您可以生成一个或使用调试签名选项

如果您想要生成一个签名密钥，请参考 [这里](https://developer.android.com/studio/publish/app-signing)。

使用调试签名选项，您可以在 `android/app/build.gradle` 文件中修改这些内容：

```gradle
android {
    // ...
    buildTypes {
      release {
        signingConfig signingConfigs.debug // using debug signing
      }
    }
    // ...
}
```

### 翻译
想要让安读支持您的语言，让我们一起来翻译吧！

您可以翻译项目文档，也可以翻译应用程序的界面。

**翻译文档**
目前，我们有以下文档需要翻译：
- [README.md](README.md)

请复制 README.md 为 README_语言代码.md，然后进行翻译，翻译后的文件请放在项目根目录下，然后在 README.md 头部添加链接。

**翻译应用程序界面**
- 安读使用 [intl](https://pub.dev/packages/intl) 进行多语言支持，您可以在`lib/l10n`目录下找到多语言文件，请复制`app_en.arb`为`app_语言代码.arb`，然后进行翻译。
- 您可以翻译缺失的字段，或者对现有翻译进行修改。
- 翻译后的文件请放在`lib/l10n`目录下，然后运行`flutter gen-l10n`生成多语言文件。
- 在[设置界面](lib/page/settings_page/appearance.dart#L83)添加您的`语言名称`和`代码`。
- 关于语言代码，请参考 [locale](https://saimana.com/list-of-country-locale-code/)
- 请确保翻译后您至少运行一次应用程序，以确保翻译没有问题。
- 提交一个 Pull Request。

### 修复 bug 和添加新功能
安读使用 [Flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview) 来渲染电子书，因此项目在渲染电子书的部分使用`JavaScript`编写。

`JavaScript`代码位于`assets/foliate-js`目录下，您可以在这里找到渲染电子书的代码。软件通过 [内置服务器](lib/service/book_player/book_player_server.dart) 加载`assets/foliate-js`目录下的`index.html`文件。

在调试`js`时，您可以在`assets/foliate-js`目录下的`book.js`头部看到一些被注释的代码，您可以取消注释这些代码，然后将测试书籍放入`assets/local`目录下，修改`book.js`中的`let url = '../local/***.epub'`然后在浏览器中打开`index.html`文件，即可看到效果。

如果想要调整书籍渲染效果可以修改`book.js`文件中的`getCSS`函数，这些css将会被应用到书籍中。

`js`与`dart`之间的通信的主要部分在[epub_player.dart](lib/page/book_player/epub_player.dart)中，您可以在这里找到与`js`通信的代码，wenview 界面也是在这里加载的。

在重新注释`book.js`中的代码后，重新运行应用程序即可。

请在重新注释`book.js`中的代码后提交 Pull Request。