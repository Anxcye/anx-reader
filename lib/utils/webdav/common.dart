import 'package:webdav_client/webdav_client.dart';

Future<void> testWebdav(Map webdavInfo) async {
  var client = newClient(
    webdavInfo['url'],
    user: webdavInfo['username'],
    password: webdavInfo['password'],
    debug: true,
  );
  client.setHeaders({'accept-charset': 'utf-8'});

  client.setConnectTimeout(8000);

  client.setSendTimeout(8000);

  client.setReceiveTimeout(8000);

  try {
    await client.ping();
    print('Connection successful');
  } catch (e) {
    print('$e');
  }
}