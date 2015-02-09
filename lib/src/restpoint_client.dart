library restpoint.client;

import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'restpoint_http.dart';
import 'restpoint_pathbuilder.dart';
import 'restpoint_resource.dart' show Resource;


@proxy
class RestClient {
  final Uri baseUri;
  final ClientFactory http;
  Map<String, Resource> resources = {};
  
  RestClient(this.baseUri, this.http);
  
  noSuchMethod(Invocation invocation) {
    return new PathBuilder(baseUri, this).noSuchMethod(invocation);
  }
  
  PathBuilder slash(name) => new PathBuilder(baseUri, this).resolve(name.toString());
  
  Resource getResource(String name) => resources[name];
  
  Future<Response> put(String path, {Map<String, dynamic> body,
    Map<String, String> headers}) =>
        http.put(appendToUri(baseUri, path), body: JSON.encode(body),
            headers: appendToHeaders({"content-type": "application/json"}, headers));
  
  Future<Response> delete(String path, {Map<String, String> headers}) =>
      http.delete(appendToUri(baseUri, path), headers: headers);
  
  Future<Response> post(String path, {Map<String, dynamic> body,
    Map<String, String> headers}) =>
        http.post(appendToUri(baseUri, path), body: JSON.encode(body),
            headers: appendToHeaders({"content-type": "application/json"}, headers));
  
  Future<Response> get(String path, {Map<String, String> headers}) =>
      http.get(appendToUri(baseUri, path), headers: headers);
  
  void addResource(Resource resource) {
    resources[resource.name] = resource;
  }
}