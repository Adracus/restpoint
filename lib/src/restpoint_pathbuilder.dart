library restpoint.pathbuilder;

import 'dart:async' show Future;
import 'dart:mirrors' show MirrorSystem;

import 'restpoint_client.dart';
import 'restpoint_http.dart';
import 'restpoint_structure.dart' show Entity;


@proxy
class PathBuilder {
  Uri uri;
  RestClient client;
  
  PathBuilder(this.uri, this.client);
  
  PathBuilder id(id) {
    return resolve(id.toString());
  }
  
  PathBuilder resolve(arg) {
    if (arg is Symbol) {
      arg = MirrorSystem.getName(arg);
    }
    uri = appendToUri(uri, arg);
    return this;
  }
  
  String get lastResource {
    var segments = uri.pathSegments;
    if (null != client.getResource(segments.last)) return segments.last;
    if (segments.length == 1) throw new Exception("Could not resolve resource");
    var preLast = segments[segments.length - 2];
    if (null != client.getResource(preLast)) return preLast;
    throw new Exception("Could not resolve resource");
  }
  
  PathBuilder slash(name) => resolve(name.toString());
  
  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      return resolve(invocation.memberName);
    }
    if (invocation.isMethod) {
      if (#call != invocation.memberName) resolve(invocation.memberName);
      var args = invocation.positionalArguments;
      if (args.isEmpty) // All case
        return Function.apply(all, [], invocation.namedArguments);
      if (1 == args.length) { // Id case
        resolve(args.single.toString());
        return Function.apply(one, [], invocation.namedArguments);
      }
    }
    throw new ArgumentError('Cannot resolve invocation');
  }
  
  Future<List<Entity>> all({Map<String, dynamic> headers}) {
    var resource = client.getResource(lastResource);
    return resource.all(uri, headers: headers);
  }
  
  Future<Entity> one({Map<String, dynamic> headers}) {
    var resource = client.getResource(lastResource);
    return resource.one(uri, headers: headers);
  }
  
  Future delete({Map<String, String> headers}) {
    var resource = client.getResource(lastResource);
    return resource.delete(uri, headers: headers);
  }
  
  Future<Entity> create({Map<String, dynamic> body, Map<String, dynamic> headers}) {
    var resource = client.getResource(lastResource);
    return resource.create(uri, body: body, headers: headers);
  }
  
  Future<Entity> patch({Map<String, dynamic> body, Map<String, dynamic> headers}) {
    var resource = client.getResource(lastResource);
    return resource.patch(uri, body: body, headers: headers);
  }
  
  Future<Entity> update({Map<String, dynamic> body, Map<String, dynamic> headers}) {
    var resource = client.getResource(lastResource);
    return resource.update(uri, body: body, headers: headers);
  }
}