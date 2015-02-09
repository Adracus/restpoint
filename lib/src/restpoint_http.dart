library restpoint.http;

import 'package:http/http.dart' as http;


Uri appendToUri(Uri uri, String append) {
  var str = uri.toString();
  str += str.endsWith('/') ? append : '/$append';
  return Uri.parse(str);
}

Map<String, String> appendToHeaders(Map<String, String> headers,
                                    Map<String, String> append) {
  if (null == headers) headers = {};
  if (null == append) append = {};
  return headers..addAll(append);
}

class StatusException {
  final int expected;
  final int actual;
  
  const StatusException(this.expected, this.actual);
  
  String toString() => "Expected $expected but got $actual";
}

void checkResponse(http.Response response, int expected) {
  if (expected != response.statusCode)
    throw new StatusException(expected, response.statusCode);
}