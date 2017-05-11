import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/hooks.dart' as hooks;
import 'package:angel_mustache/angel_mustache.dart';
import 'package:angel_validate/server.dart';
import 'package:angel_websocket/server.dart';
import 'validators.dart';

class Project {
  final String title;

  Project(this.title);

  Map<String, dynamic> toJson() {
    return {'title': title};
  }
}

Future<Angel> createServer() async {
  var app = new Angel();

  app.container.singleton(new Project('Angel Hello'));

  app.get('/', (RequestContext req, ResponseContext res) async {
    res.write('Hello, world!');
  });

  app.get('/no-params', (req, res) async {
    return {'message': 'I hate you!'};
  });

  app.get('/no-params', () {
    return {'message': 'Hello, world!'};
  });

  app.post('/greet', (RequestContext req, ResponseContext res) async {
    if (req.body.containsKey('message')) {
      // Do something...
      var message = req.body['message'] as String;
      return {
        'received': {'message': message}
      };
    } else {
      throw new AngelHttpException.badRequest();
    }
  });

  app.group('/library', (router) {
    List<Map> books = [
      {'title': 'War and Peace', 'author': 'Leo Tolstoy'},
      {'title': 'Atlas Shrugged', 'author': 'Ayn Rand'}
    ];

    router.get('/books', () => books);

    router.get('/books/:id', (String id) {
      try {
        var index = int.parse(id);

        if (index < 0 || index >= books.length)
          throw new AngelHttpException.notFound();

        return books[index];
      } on AngelHttpException {
        rethrow;
      } catch (e) {
        throw new AngelHttpException.badRequest();
      }
    });
  });

  app.get('/project', (Project poop) {
    return poop;
  });

  await app.configure(new MyController());
  await app.configure(new AngelWebSocket());
  await app.configure(new MyWebSocketController());
  await app.configure(printMessage('Hello, plug-ins!'));
  await app.configure(mustache(new Directory('views')));

  app.get('/template', (req, ResponseContext res) async {
    await res.render('hello', {'message': 'Hello, plug-ins!'});
  });

  app.use('/items', new MapService());

  var itemService = app.service('items') as HookedService;
  await itemService.create({'foo': 'bar'});

  itemService.beforeCreated.listen(hooks.chainListeners(
      [validateEvent(CREATE_ITEM), hookPrintMessage('Hello!!!')]));
  itemService.afterAll(hookPrintMessage('Bye!!!!'));

  return app;
}

HookedServiceEventListener hookPrintMessage(String message) {
  return (HookedServiceEvent e) async {
    if (e.isBefore) {
      e.data['hooked'] = true;
    } else {
      print(message);
      print(e.result);
    }
  };
}

returnHonda() => {'model': 'Odyssey'};

@Expose('/cars')
class MyController extends Controller {
  @Expose('/mazda', middleware: const [returnHonda])
  mazda() {
    return {'model': 'CX9'};
  }

  @Expose('/ferrari')
  ferrari() => {'model': 'Aventador'};
}

@Expose('/boats')
class MyWebSocketController extends WebSocketController {
  @Expose('/')
  boats() => [];

  @ExposeWs('get_boat')
  getBoat(WebSocketContext socket) {
    socket.send('got_boat', {'model': 'CX9'});
  }
}

AngelConfigurer printMessage(String message) {
  return (Angel app) async {
    app.before.add(() {
      print(message);
    });
  };
}

class MyService extends Service {
  final List items = [
    {'foo': 'bar'}
  ];

  @override
  Future index([Map params]) async {
    return items;
  }

  @override
  Future read(id, [Map params]) async {
    try {
      var index = int.parse(id);

      if (index < 0 || index >= items.length)
        throw new AngelHttpException.notFound();

      return item[index];
    } on AngelHttpException {
      rethrow;
    } catch (e) {
      throw new AngelHttpException.badRequest();
    }
  }
}
