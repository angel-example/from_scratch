import 'dart:io';
import 'package:angel_hello/angel_hello.dart';

main() async {
  var app = await createServer();
  var server = await app.startServer(InternetAddress.ANY_IP_V4, 8080);
  print('Listening at http://${server.address.address}:${server.port}');
}