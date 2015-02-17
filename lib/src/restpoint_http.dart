library restpoint.http;

import 'dart:convert' show Encoding;
import 'dart:async' show Future;

import 'package:http/http.dart';
import 'package:stack_trace/stack_trace.dart';

export 'package:http/http.dart' show Response;


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
  final Response response;
  
  const StatusException(this.expected, this.response);
  
  int get actual => response.statusCode;
  
  String toString() => "Expected $expected but got $actual";
}

void checkResponse(Response response, int expected) {
  if (expected != response.statusCode)
    throw new StatusException(expected, response);
}

abstract class ClientFactory {
  Future<Response> get(url, {Map<String, String> headers}) {
    var client = createClient();
    return client.get(url, headers: headers)
                 .whenComplete(() => client.close());
  }
  
  Future<Response> post(url, {Map<String, String> headers, body, Encoding encoding}) {
    var client = createClient();
    return client.post(url, headers: headers, body: body, encoding: encoding)
                 .whenComplete(() => client.close());
  }
  
  Future<Response> delete(url, {Map<String, String> headers}) {
    var client = createClient();
    return client.delete(url, headers: headers)
                 .whenComplete(() => client.close());
  }
  
  Future<Response> put(url, {Map<String, String> headers, body, Encoding encoding}) {
    var client = createClient();
    return client.put(url, headers: headers, body: body, encoding: encoding)
                 .whenComplete(() => client.close());
  }
  
  Future<Response> patch(url, {body, Map<String, String> headers, Encoding encoding}) {
    var client = createClient();
    return syncFuture(() {
      if (url is String) url = Uri.parse(url);
      var request = new Request("PATCH", url);

      if (headers != null) request.headers.addAll(headers);
      if (encoding != null) request.encoding = encoding;
      if (body != null) {
        if (body is String) {
          request.body = body;
        } else if (body is List) {
          request.bodyBytes = body;
        } else if (body is Map) {
          request.bodyFields = body;
        } else {
          throw new ArgumentError('Invalid request body "$body".');
        }
      }

      return client.send(request);
    }).then(Response.fromStream)
      .whenComplete(() => client.close());
  }
  
  /// Like [Future.sync], but wraps the Future in [Chain.track] as well.
  Future syncFuture(callback()) => Chain.track(new Future.sync(callback));
  
  Client createClient();
}