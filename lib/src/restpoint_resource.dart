library restpoint.resource;

import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'restpoint_http.dart';
import 'restpoint_structure.dart';
import 'restpoint_client.dart' show RestClient;


class Resource {
  final String name;
  final RestClient client;
  final Definition definition;
  
  Resource(this.client, this.name, this.definition);
  
  Uri get resourceUri => appendToUri(client.baseUri, name);
  
  ClientFactory get http => client.http;
  
  Future<List<Entity>> all(Uri uri, {Map<String, String> headers}) {
    return http.get(uri, headers: headers).then((response) {
      checkResponse(response, 200);
      var entities = JSON.decode(response.body) as List<Map<String, dynamic>>;
      return entities.map(transformIn).toList();
    });
  }
  
  Future<Entity> create(Uri uri, {Map<String, dynamic> body,
                                  Map<String, String> headers}) {
    return http.post(uri,
        headers: appendToHeaders({"content-type": "application/json"}, headers),
        body: JSON.encode(body))
        .then((response) {
          checkResponse(response, 201);
          var entity = JSON.decode(response.body);
          return transformIn(entity);
    });
  }
  
  Future delete(Uri uri, {Map<String, String> headers}) {
    return http.delete(uri, headers: headers).then((response) {
      checkResponse(response, 204);
      return;
    });
  }
  
  Future update(Uri uri, {Map<String, dynamic> body,
                          Map<String, String> headers}) {
    return http.put(uri,
        headers: appendToHeaders({"content-type": "application/json"}, headers),
        body: JSON.encode(body))
        .then((response) {
          checkResponse(response, 200);
          var entity = JSON.decode(response.body);
          return transformIn(entity);
    });
  }
  
  Future patch(Uri uri, {Map<String, dynamic> body,
                            Map<String, String> headers}) {
    return http.patch(uri,
        headers: appendToHeaders({"content-type": "application/json"}, headers),
        body: JSON.encode(body))
        .then((response) {
          checkResponse(response, 200);
          var entity = JSON.decode(response.body);
          return transformIn(entity);
    });
  }
  
  Uri _resolve(Uri base) => base.resolve(name);
  
  Future<Entity> one(Uri uri, {Map<String, String> headers}) {
    return http.get(uri, headers: headers).then((response) {
      checkResponse(response, 200);
      var entity = JSON.decode(response.body) as Map<String, dynamic>;
      return transformIn(entity);
    });
  }
  
  Map<String, dynamic> transformOut(Entity entity) {
    var result = {};
    definition.properties.forEach((name, property) {
      var sym = new Symbol(name);
      if (null != entity[sym]) {
        result[name] = property.outTransformer(entity[sym]);
      }
    });
    return result;
  }
  
  Entity transformIn(Map<String, dynamic> item) {
    var result = {};
    definition.properties.forEach((name, property) {
      if (null != item[name]) {
        result[new Symbol(name)] = property.inTransformer(item[name]);
      }
    });
    definition.methods.forEach((name, method) =>
        result[new Symbol(name)] = method.function);
    return new Entity(result, this);
  }
}

class ResourceBuilder {
  Map<String, Field> _fields = {};
  final String _name;
  final RestClient client;
  
  ResourceBuilder(this.client, this._name);
  
  ResourceBuilder addField(Field field) {
    _fields[field.name] = field;
    return this;
  }
  
  ResourceBuilder addTypedProperty(String name, {type: String}) {
    addField(new Property.typed(name, type: type));
    return this;
  }
  
  ResourceBuilder addProperty(String name, {Transformer inTransformer,
    Transformer outTransformer}) {
      addField(new Property(name, inTransformer: inTransformer,
                                  outTransformer: outTransformer));
      return this;
  }
  
  ResourceBuilder addMethod(String name, Function function) {
    addField(new Method(name, function));
    return this;
  }
  
  Resource build() {
    var definition = new Definition(_fields);
    return new Resource(client, _name, definition);
  }
}
