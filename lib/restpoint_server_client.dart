library restpoint.server.client;

import 'src/restpoint_http.dart' show ClientFactory;

import 'package:http/http.dart';

class ServerClientFactory extends Object with ClientFactory {
  Client createClient() => new Client();
}