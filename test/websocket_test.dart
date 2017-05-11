import 'package:angel_framework/angel_framework.dart';
import 'package:angel_hello/angel_hello.dart';
import 'package:angel_hello/validators.dart';
import 'package:angel_test/angel_test.dart';
import 'package:angel_websocket/angel_websocket.dart';
import 'package:test/test.dart';

main() async {
  Angel app;
  TestClient client;

  setUp(() async {
    app = await createServer();
    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('websocket.boats', () async {
    var socket = await client.websocket();
    socket.send('get_boat', new WebSocketAction());

    await socket.on['got_boat'].first.then((e) {
      print('Got boat: ${e.data}');
    });
  });

  test('websocket.index', () async {
    var socket = await client.websocket();
    var itemService = socket.service('items');
    itemService.index();
    await itemService.onIndexed.first.then((e) {
      print('Items on server: ${e.data}');
    });
  });

  test('rest.index', () async {
    var itemService = client.service('items');
    var items = await itemService.index();
    print('RESTful items on server: ${items}');
    expect(items, everyElement(ITEM));
  });
}
