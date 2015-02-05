library restpoint.client;

import 'dart:async' show Future;

import 'restpoint_pathbuilder.dart';
import 'restpoint_resource.dart' show Resource;

import 'package:http/http.dart' as http;


@proxy
class RestClient {
  final Uri baseUri;
  Map<String, Resource> resources = {};
  
  RestClient(this.baseUri);
  
  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      return new PathBuilder(baseUri, this).resolve(invocation.memberName);
    }
  }
  
  PathBuilder operator/(name) => slash(name);
  PathBuilder slash(name) => new PathBuilder(baseUri, this).resolve(name.toString());
  
  Resource getResource(String name) => resources[name];
  
  Future<http.Response> put(String path, {Map<String, dynamic> body,
    Map<String, String> headers: const {}}) =>
        http.put(baseUri.resolve(path), body: JSON.encode(body),
            headers: {"content-type": "application/json"}..addAll(headers));
  
  Future<http.Response> delete(String path, {Map<String, String> headers}) =>
      http.delete(baseUri.resolve(path), headers: headers);
  
  Future<http.Response> post(String path, {Map<String, dynamic> body,
    Map<String, String> headers: const{}}) =>
        http.post(baseUri.resolve(path), body: JSON.encode(body),
            headers: {"content-type": "application/json"}..addAll(headers));
  
  void addResource(Resource resource) {
    resources[resource.name] = resource;
  }
}