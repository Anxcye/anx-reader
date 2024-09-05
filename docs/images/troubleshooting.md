[English](#English)
[简体中文](#简体中文)

# English
## Unable to Import Books
- Ensure the book format is supported. Please check the supported formats in the [README](https://github.com/Anxcye/anx-reader/blob/main/README.md).
- Ensure the book file is not corrupted. You can try using other readers to confirm if the file is normal.
- Ensure the file path does not contain special characters (such as spaces, “/”, etc.).
- Check the device's webview version. If importing books fails, click the bottom right corner of the interface -> Settings -> More Settings -> Advanced -> Logs, scroll down, and in the last few entries, you can see something like `INFO^*^ 2024-08-09 17:51:22.573971^*^ [Webview: Mozilla/5.0 (Linux; Android 13; *** Build/TKQ1.220829.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/128.0.6613.25 Mobile Safari/537.36]:null`, where Chrome/128.0.6613.25 is the webview version. If the version number is relatively low, it may cause import failures. You can try upgrading the webview version.


# 简体中文
## 无法导入书籍

- 确保书籍格式支持，请从中查看支持的格式。
- 确保书籍文件没有损坏，可以尝试使用其他阅读器确认文件是否正常。
- 确保文件路径没有特殊字符(如空格、”/“ 等)。
- 检查设备 webview 版本，导入书籍失败后，点击界面右下角设置 -> 更多设置 -> 高级 -> 日志，向下滑动，在最后几条中可以看到类似`INFO^*^ 2024-08-09 17:51:22.573971^*^ [Webview: Mozilla/5.0 (Linux; Android 13; *** Build/TKQ1.220829.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/128.0.6613.25 Mobile Safari/537.36]:null` ，其中`Chrome/128.0.6613.25` 为 webview 版本，如果版本号较低，可能会导致导入失败，可以尝试升级到最新 webview 版本。
