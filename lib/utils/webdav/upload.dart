import 'package:webdav_client/webdav_client.dart';

Future<void> initClient() async {
  var client = newClient(
    'http://localhost:6688/',
    user: 'flyzero',
    password: '123456',
    debug: true,
  );
  client.setHeaders({'accept-charset': 'utf-8'});

  client.setConnectTimeout(8000);

  client.setSendTimeout(8000);

  client.setReceiveTimeout(8000);

  try {
    await client.ping();
  } catch (e) {
    print('$e');
  }

}


void uploadData(){


}