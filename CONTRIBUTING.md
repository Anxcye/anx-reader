[English](#contributing-to-anx-reader) | [简体中文](#让安读更好) | [Русский](#вклад-в-anx-reader)

# Contributing to Anx Reader

Anx Reader is an open-source project, and we welcome any contributions from you. You can help by translating, fixing bugs, adding new features, writing documentation, and more. If you want to contribute, the following guide may be helpful.

Let's get started!

### Running
- Install [Flutter](https://flutter.dev).
- Clone and navigate to the project directory.
Execute the following commands:
```bash
flutter pub get
flutter gen-l10n
dart run build_runner watch
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

#### Better Debugging Experience
For a better debugging experience, the project provides a `debug.html` file. Here's how to use it:
```bash
cd assets/foliate-js
npm install
npm run debug
```
Open your browser and navigate to `http://localhost:3000/debug.html`

 - Use the control buttons in the top right corner of the page to test the page-turning functionality
 - View console output and debug information in the browser developer tools
 - Modify `mockParams` in `debug.html` to test different styles and parameters

To adjust the rendering of books, you can modify the `getCSS` function in the `book.js` file. These CSS styles will be applied to the book.

The main part of the communication between `js` and `dart` is in [epub_player.dart](lib/page/book_player/epub_player.dart), where you'll find the code that handles `js` communication. The webview interface is also loaded here.

After re-commenting the code in `book.js`, rerun the application.

#### Building and Integrating
1. **Development Debugging**:
   - Modify the source code in the `src/` directory
   - Use `debug.html` for debugging
2. **Building and Packaging**:
   ```bash
    cd assets/foliate-js
    npm install
    npm run build
    ```
    This will generate the `dist/bundle.js` file, which the `index.html` will load.
3. **Flutter Integration Testing**:
   After building, rerun the Flutter application to test the integration.

# 让安读更好
安读是一款开源项目，我们欢迎您的任何贡献，您可以对项目进行翻译、修复 bug、添加新功能，编写文档等。如果您想要贡献，以下内容可能会对您有所帮助。

让我们开始吧！

### 运行
- 安装 [Flutter](https://flutter.dev)。
- 克隆并进入项目目录。
执行以下命令：
```bash
flutter pub get
flutter gen-l10n
dart run build_runner watch
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

#### 更好地调试
为了更好的调试体验，项目提供了`debug.html`文件。使用方法如下：
```bash
cd assets/foliate-js
npm install
npm run debug
```
在浏览器中打开 `http://localhost:3000/debug.html`

 - 使用页面右上角的控制按钮测试翻页功能
 - 在浏览器开发者工具中查看控制台输出和调试信息
 - 修改 `debug.html` 中的 `mockParams` 来测试不同的样式和参数


如果想要调整书籍渲染效果可以修改`book.js`文件中的`getCSS`函数，这些css将会被应用到书籍中。

`js`与`dart`之间的通信的主要部分在[epub_player.dart](lib/page/book_player/epub_player.dart)中，您可以在这里找到与`js`通信的代码，wenview 界面也是在这里加载的。


#### 构建和集成
1. **开发调试**：
   - 修改 `src/` 目录下的源代码
   - 使用 `debug.html` 进行调试

2. **构建打包**：
   ```bash
   cd assets/foliate-js
   npm install
   npm run build
   ```
   这会生成 `dist/bundle.js` 文件，`index.html` 会加载这个打包后的文件。

3. **Flutter 集成测试**：
   构建完成后，重新运行 Flutter 应用程序来测试集成效果。

# Вклад в Anx Reader

Anx Reader — это проект с открытым исходным кодом, и мы приветствуем любой ваш вклад. Вы можете помочь с переводом, исправлением ошибок, добавлением новых функций, написанием документации и многим другим. Если вы хотите внести свой вклад, следующее руководство может оказаться полезным.

Давайте начнем!

### Запуск
- Установите [Flutter](https://flutter.dev).
- Клонируйте репозиторий и перейдите в каталог проекта.
Выполните следующие команды:
```
flutter pub get
flutter gen-l10n
dart run build_runner watch
flutter run # или нажмите кнопку запуска в вашей IDE
```

### Участие в разработке
1. Сделайте форк этого репозитория.
2. Создайте свою ветку для новой функции (`git checkout -b feature/AmazingFeature`).
3. Внесите изменения (например, добавление новых функций, исправление ошибок, перевод и т. д.).
4. Закоммитьте ваши изменения (`git commit -m 'Add some AmazingFeature'`).
5. Отправьте изменения в ветку (`git push origin feature/AmazingFeature`).
6. Создайте Pull Request.

### Сборка
Вам понадобится ключ подписи для создания APK. Вы можете сгенерировать новый или использовать опцию отладочной подписи.

Если вы хотите сгенерировать ключ подписи, пожалуйста, обратитесь к [этой инструкции](https://developer.android.com/studio/publish/app-signing).

Используя опцию отладочной подписи, вы можете изменить следующее в файле `android/app/build.gradle`:

```
android {
    // ...
    buildTypes {
      release {
        signingConfig signingConfigs.debug // использование отладочной подписи
      }
    }
    // ...
}
```


### Перевод
Если вы хотите, чтобы Anx Reader поддерживал ваш язык, давайте поработаем над переводом вместе!

Вы можете переводить документацию проекта или интерфейс приложения.

**Перевод документации**
В настоящее время у нас есть следующие документы, требующие перевода:
- [README.md](README.md)

Пожалуйста, скопируйте `README.md` как `README_код_языка.md`, переведите его и поместите переведенный файл в корневой каталог проекта. Затем добавьте ссылку на перевод вверху файла `README.md`.

**Перевод интерфейса приложения**
- Anx Reader использует [intl](https://pub.dev/packages/intl) для многоязычной поддержки. Файлы локализации находятся в каталоге `lib/l10n`. Пожалуйста, скопируйте `app_en.arb` в `app_код_языка.arb` и переведите его.
- Вы можете перевести недостающие поля или изменить существующие переводы.
- Поместите переведенный файл в каталог `lib/l10n` и выполните команду `flutter gen-l10n` для генерации файлов локализации.
- Добавьте `название вашего языка` и `код` на [странице настроек](lib/page/settings_page/appearance.dart#L83).
- Коды языков можно найти здесь: [locale](https://saimana.com/list-of-country-locale-code/).
- Убедитесь, что после перевода вы хотя бы раз запустили приложение, чтобы проверить, все ли работает корректно.
- Создайте Pull Request.

### Исправление ошибок и добавление новых функций
Anx Reader использует [Flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview) для отображения электронных книг, поэтому рендеринг электронных книг в проекте реализован с помощью `JavaScript`.

Код `JavaScript` находится в каталоге `assets/foliate-js`. Там вы найдете код, отвечающий за рендеринг электронных книг. Приложение загружает файл `index.html` из каталога `assets/foliate-js` с помощью [встроенного сервера](lib/service/book_player/book_player_server.dart).

#### Улучшение опыта отладки
Для улучшения опыта отладки в проекте предусмотрен файл `debug.html`. Вот как его использовать:
```
cd assets/foliate-js
npm install
npm run debug
```
Откройте браузер и перейдите по адресу `http://localhost:3000/debug.html`

- Используйте кнопки управления в правом верхнем углу страницы для тестирования функции перелистывания страниц.
- Просматривайте вывод консоли и отладочную информацию в инструментах разработчика вашего браузера.
- Изменяйте `mockParams` в `debug.html` для тестирования различных стилей и параметров.

Чтобы настроить рендеринг книг, вы можете изменить функцию `getCSS` в файле `book.js`. Эти стили CSS будут применены к книге.

Основная часть взаимодействия между `js` и `dart` находится в файле [epub_player.dart](lib/page/book_player/epub_player.dart). Там вы найдете код, который обрабатывает коммуникацию с `js`. Интерфейс webview также загружается здесь.

#### Сборка и интеграция
1. **Отладка в процессе разработки**:
   - Изменяйте исходный код в каталоге `src/`.
   - Используйте `debug.html` для отладки.
2. **Сборка и упаковка**:
   ```
    cd assets/foliate-js
    npm install
    npm run build
    ```
    Эта команда создаст файл `dist/bundle.js`, который будет загружаться файлом `index.html`.
3. **Интеграционное тестирование с Flutter**:
   После сборки перезапустите приложение Flutter для тестирования интеграции.
