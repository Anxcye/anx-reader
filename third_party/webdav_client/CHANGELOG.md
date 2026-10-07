# Changelog

### [1.2.2]
- 302 redirect: redirect to the real link. Thanks [@cmlanche](https://github.com/flymzero/webdav_client/pull/46)

### [1.2.1]
- Dio Dependency Update

### [1.2.0]
- fix PROPFIND method with request data by utf8.encode again

### [1.1.9]
- Bumped version to **1.1.9** ! Thanks [erdemyerebasmaz](https://github.com/erdemyerebasmaz)
- Updated dependencies to latest
  -  [dio](https://pub.dev/packages/dio/changelog) had breaking changes as explained [here](https://pub.dev/packages/dio/changelog#500). The ones that applied to this plugin were:
     - Improve DioErrors. There are now more cases in which the inner original stacktrace is supplied.
     - connectTimeout, sendTimeout, and receiveTimeout are now Durations.
     - Null Safety changes
  - There were no breaking changes according to their changelogs published on pub.dev for these plugins:
    - [xml](https://pub.dev/packages/xml/changelog)
    - [convert](https://pub.dev/packages/convert/changelog)

## [1.1.8]
- Dependency Update
 
## [1.1.7]
- Remove unnecessary dependency on flutter

## [1.1.6]

- Web platform support. (see [stackoverflow](https://stackoverflow.com/questions/65630743/how-to-solve-flutter-web-api-cors-error-only-with-dart-code) for CORSB problems needing attention)
- Dependency Update

## [1.1.2]

- Upload and download support progress, modified method parameters(read, read2File, write, writeFromFile)
- update dio 4.0.0 > 4.0.1

## [1.1.1]

- `writeFromFile` streams file content instead of reading it into memory.(thanks `@István Soós`)
- fix auth error when root directory is not supported by webdav(thanks `@dutsky`)

## [1.1.0]

- Fix no authorization when uploading and downloading 
- Related dependencies updated to the latest version

## [1.0.0]

- support null-safety

## [0.0.2] 

- fix when server nonce expired, add recertification Logic.

## [0.0.1] 

* common settings
* read dir
* make dir
* delete
* rename
* copy
* download file
* cancel request
