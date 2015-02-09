library restpoint.client;

import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'restpoint_http.dart';
import 'restpoint_pathbuilder.dart';
import 'restpoint_resource.dart' show Resource;

import 'package:http/http.dart' as http;


@proxy
class RestClient {
  final Uri baseUri;
  Map<String, Resource> resources = {};
  
  RestClient(this.baseUri);
  
  noSuchMethod(Invocation invocation) {
    return new PathBuilder(baseUri, this).noSuchMethod(invocation);
  }
  
  PathBuilder slash(name) => new PathBuilder(baseUri, this).resolve(name.toString());
  
  Resource getResource(String name) => resources[name];
  
  Future<http.Response> put(String path, {Map<String, dynamic> body,
    Map<String, String> headers}) =>
        http.put(baseUri.resolve(path), body: JSON.encode(body),
            headers: appendToHeaders({"content-type": "application/json"}, headers));
  
  Future<http.Response> delete(String path, {Map<String, String> headers}) =>
      http.delete(baseUri.resolve(path), headers: headers);
  
  Future<http.Response> post(String path, {Map<String, dynamic> body,
    Map<String, String> headers}) =>
        http.post(baseUri.resolve(path), body: JSON.encode(body),
            headers: appendToHeaders({"content-type": "application/json"}, headers));
  
  Future<http.Response> get(String path, {Map<String, String> headers}) =>
      http.get(baseUri.resolve(path), headers: headers);
  
  void addResource(Resource resource) {
    resources[resource.name] = resource;
  }
}