library restpoint.client.client;

import 'src/restpoint_http.dart';

import 'package:http/http.dart';
import 'package:http/browser_client.dart';

class ClientClientFactory extends Object with ClientFactory {
  Client createClient() => new BrowserClient();
}