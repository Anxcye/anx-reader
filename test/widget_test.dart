// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:anx_reader/utils/webdav/convert_db_to_json.dart';



// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     int a = 1;
//     switch (a) {
//       case 1:
//         print('1');
//     continue go1;
//     go1:
//       case 2:
//         print('2');
//         break;
//       default:
//         print('default');
//     }
//   });
// }
void main() async {
  final json = await convertDbToJson();
  // print(json);
}
