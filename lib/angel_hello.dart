import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/hooks.dart' as hooks;
import 'package:angel_mustache/angel_mustache.dart';
import 'package:angel_validate/server.dart';
import 'package:angel_websocket/server.dart';
import 'validators.dart';

/// A simple class used in this project as an example of dependency injection.
class Project {
  final String title;

  Project(this.title);

  Map<String, dynamic> toJson() {
    return {'title': title};
  }
}

/// Creates and configures a server.
Future<Angel> createServer() async {
  var app = new Angel();

  // Create a singleton of the Project class. Now, whenever we
  // call for a `Project` in a request handler, we will receive this instance.
  //
  // Read more about dependency injection:
  // https://github.com/angel-dart/angel/wiki/Dependency-Injection
  app.container.singleton(new Project('Angel Hello'));

  // The following are routes.
  //
  // For best results, read the corresponding documentation:
  // * https://github.com/angel-dart/angel/wiki/Basic-Routing
  // * https://github.com/angel-dart/angel/wiki/Requests-&-Responses
  // * https://github.com/angel-dart/angel/wiki/Middleware
  // * https://github.com/angel-dart/angel/wiki/Request-Lifecycle
  app.get('/', (RequestContext req, ResponseContext res) async {
    // Write content directly to the response.
    //
    // The content is buffered, and sent all at once by Angel.
    res.write('Hello, world!');
  });

  app.get('/no-params', (req, res) async {
    // You can return anything from a request handler.
    // This Map will be serialized to JSON.
    return {'message': 'I hate you!'};
  });

  // Notice that this request handler doesn't take any parameters, since it doesn't use any.
  // Angel's dependency injection system has no problem running this:
  //
  // https://github.com/angel-dart/angel/wiki/Dependency-Injection
  app.get('/no-params', () {
    return {'message': 'Hello, world!'};
  });

  app.post('/greet', (RequestContext req, ResponseContext res) async {
    // You can interact with the request body.
    // Angel can parse both `application/json` and `application/x-www-form-url-encoded` bodies out-of-the-box.
    if (req.body.containsKey('message')) {
      // Do something...
      var message = req.body['message'] as String;
      return {
        'received': {'message': message}
      };
    } else {
      // You can throw HTTP exceptions if the user didn't act in a way you were prepared for.
      //
      // https://github.com/angel-dart/angel/wiki/Error-Handling
      throw new AngelHttpException.badRequest();
    }
  });

  // Route groups can be infinitely nested.
  app.group('/library', (router) {
    List<Map> books = [
      {'title': 'War and Peace', 'author': 'Leo Tolstoy'},
      {'title': 'Atlas Shrugged', 'author': 'Ayn Rand'}
    ];

    router.get('/books', () => books);

    // Angel's dependency injection can inject parameters from the route path.
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

  // Or, you can inject something by type.
  //
  // In this case, we get our Project singleton.
  // It is injected by its type here, so the name of the parameter is unimportant.
  // Thus, `poop`.
  app.get('/project', (Project poop) {
    return poop;
  });

  // Attach all our plug-ins and controllers.
  //
  // https://github.com/angel-dart/angel/wiki/Using-Plug-ins
  await app.configure(new MyController());
  await app.configure(new AngelWebSocket());
  await app.configure(new MyWebSocketController());
  await app.configure(printMessage('Hello, plug-ins!'));
  await app.configure(mustache(new Directory('views')));

  // Renders a mustache template.
  app.get('/template', (req, ResponseContext res) async {
    await res.render('hello', {'message': 'Hello, plug-ins!'});
  });

  // Mount an in-memory service.
  //
  // Read more:
  // * https://medium.com/the-angel-framework/instant-rest-apis-and-more-an-introduction-to-angel-services-b843f3187f67
  // * https://github.com/angel-dart/angel/wiki/Service-Basics
  // * https://github.com/angel-dart/angel/wiki/In-Memory
  app.use('/items', new MapService());

  // Get a reference to the service, so that we can modify its functionality using hooks.
  //
  // https://github.com/angel-dart/angel/wiki/Hooks
  var itemService = app.service('items') as HookedService;

  // Create an entry in the in-memory store.
  await itemService.create({'foo': 'bar'});

  // Before creating an item:
  // * Validate that it fits a rigid schema
  // * Apply some variable functionality (see the hookPrintMessage function below)
  //
  // We use `hooks.chainListeners` just for the purpose of saving keystrokes.
  // Instead of having to call `itemService.beforeCreated.listen(...)` twice, we can call it just once.
  //
  // As per its name, it just runs the given listeners in sequence.
  itemService.beforeCreated.listen(hooks.chainListeners(
      [validateEvent(CREATE_ITEM), hookPrintMessage('Hello!!!')]));

  // After any interaction with the items service, print a message to the console.
  itemService.afterAll(hookPrintMessage('Bye!!!!'));

  return app;
}

/// A service hook that changes its functionality depending on whether it is run *before* or *after* an action.
///
/// Read more about services and hooks:
/// * https://medium.com/the-angel-framework/instant-rest-apis-and-more-an-introduction-to-angel-services-b843f3187f67?source=collection_home---6------1-----------
/// * https://github.com/angel-dart/angel/wiki/Service-Basics
/// * https://github.com/angel-dart/angel/wiki/Hooks
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

/// A simple handler that prints information about a car.
returnHonda() => {'model': 'Odyssey'};

/// A controller is an alternative way to create route groups with shared functionality.
///
/// Read more:
/// https://github.com/angel-dart/angel/wiki/Controllers
@Expose('/cars')
class MyController extends Controller {
  /// Mounts a route at `/cars/mazda`. We've added a middleware, though, so the actual
  /// return value will describe a Honda Odysset.
  @Expose('/mazda', middleware: const [returnHonda])
  mazda() {
    return {'model': 'CX9'};
  }

  /// Mounted at `/cars/ferrari`.
  @Expose('/ferrari')
  ferrari() => {'model': 'Aventador'};
}

/// Similar to a normal controller, but can also handle WebSocket events.
///
/// Read more:
/// https://github.com/angel-dart/websocket
@Expose('/boats')
class MyWebSocketController extends WebSocketController {
  /// A normal REST/HTTP route.
  @Expose('/')
  boats() => [];

  /// This function will be invoked whenever a user sends a 'get-boat' message.
  @ExposeWs('get_boat')
  getBoat(WebSocketContext socket) {
    // We can send something back.
    socket.send('got_boat', {'model': 'CX9'});
  }
}

/// A simple plug-in that prints a message on every incoming request.
///
/// Read more about plug-ins:
/// https://github.com/angel-dart/angel/wiki/Using-Plug-ins
AngelConfigurer printMessage(String message) {
  return (Angel app) async {
    /// Add a global middleware.
    ///
    /// Read more:
    /// * https://github.com/angel-dart/angel/wiki/Middleware
    /// * https://github.com/angel-dart/angel/wiki/Request-Lifecycle
    app.before.add(() {
      print(message);
    });
  };
}

/// A basic service. Mounts an instant REST API, and can be interacted with via WebSockets.
///
/// Read more:
/// * https://medium.com/the-angel-framework/instant-rest-apis-and-more-an-introduction-to-angel-services-b843f3187f67
/// * https://github.com/angel-dart/angel/wiki/Service-Basics
class MyService extends Service {
  final List items = [
    {'foo': 'bar'}
  ];

  /// Get all resources.
  @override
  Future index([Map params]) async {
    return items;
  }

  /// Find a specific resource.
  @override
  Future read(id, [Map params]) async {
    try {
      // Try to parse the ID as an integer.
      var index = int.parse(id);

      // Throw a 404 if the index is out of range.
      if (index < 0 || index >= items.length)
        throw new AngelHttpException.notFound();

      // Otherwise, return the item, which will be auto-serialized.
      return item[index];
    } on AngelHttpException {
      // In case we encounter an `AngelHttpException` (specifically the ones we throw above),
      // rethrow them, so that they can be handled by our error-handler plug-in.
      //
      // Read more:
      // https://github.com/angel-dart/angel/wiki/Error-Handling
      rethrow;
    } catch (e) {
      // Throw a 400 if the ID is not an integer.
      throw new AngelHttpException.badRequest();
    }
  }
}
