import 'package:dart_action/dart_action.dart';
import 'package:test/test.dart';

void main() {
  test('parse XML test', () async {
     final resultCode = await parseXML(["",]);
     expect(resultCode, 0);
  });
}
