# Vendored webdav_client

Source: https://github.com/Anxcye/webdav_client.git @ 3c6d0eb

Local patch on top of that commit:
- Follow HTTP 301/307/308 redirects in `lib/src/webdav_dio.dart` in addition to 302
  (needed for AList WebDAV redirect strategies; see Anxcye/anx-reader#345).

This tree is vendored because the release token could not push to
Anxcye/webdav_client. Prefer replacing with a git `ref` once the fork
commit is published.
