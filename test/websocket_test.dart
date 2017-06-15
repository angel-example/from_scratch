import 'package:angel_hello/angel_hello.dart';
import 'package:angel_hello/validators.dart';
import 'package:angel_test/angel_test.dart';
import 'package:angel_websocket/angel_websocket.dart';
import 'package:test/test.dart';

main() async {
  // All we need to test our server is `package:angel_test`.
  TestClient client;

  setUp(() async {
    var app = await createServer();
    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('websocket.boats', () async {
    // Connect a WebSocket.
    var socket = await client.websocket();

    // Trigger our WebSocketController (see ../angel_hello.dart#L202)
    socket.send('get_boat', new WebSocketAction());

    // Listen for the first 'got_boat' event, sent in response to 'get_boat'.
    //
    // This is functionality we wrote in ../angel_hello.dart.
    await socket.on['got_boat'].first.then((e) {
      // Print info about the data sent by the server.
      print('Got boat: ${e.data}');
    });
  });

  test('websocket.index', () async {
    // We can interact with services over WebSockets as well.
    var socket = await client.websocket();
    var itemService = socket.service('items');

    // This happens asynchronously.
    itemService.index();

    await itemService.onIndexed.first.then((e) {
      print('Items on server: ${e.data}');
    });
  });

  test('rest.index', () async {
    // We can also interact with services via REST.
    //
    // https://medium.com/the-angel-framework/instant-rest-apis-and-more-an-introduction-to-angel-services-b843f3187f67?source=collection_home---6------1-----------
    var itemService = client.service('items');
    var items = await itemService.index();
    print('RESTful items on server: ${items}');
    expect(items, everyElement(ITEM));
  });
}
