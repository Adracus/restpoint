library restpoint.base;

import 'dart:convert' show JSON, Encoding;
import 'dart:async' show Future;
import 'dart:mirrors' show MirrorSystem;

import 'package:http/http.dart' as http;

typedef Transformer(value);

appendToUri(Uri uri, String append) {
  var str = uri.toString();
  str += str.endsWith('/') ? append : '/$append';
  return Uri.parse(str);
}

@proxy
class PathBuilder {
  Uri uri;
  RestClient client;
  
  PathBuilder(this.uri, this.client);
  
  PathBuilder id(id) {
    return _resolve(id.toString());
  }
  
  PathBuilder _resolve(arg) {
    if (arg is Symbol) {
      arg = MirrorSystem.getName(arg);
    }
    uri = appendToUri(uri, arg);
    return this;
  }
  
  String get lastResource {
    var segments = uri.path.split("/");
    if (null != client.getResource(segments.last)) return segments.last;
    if (segments.length == 1) throw new Exception("Could not resolve resource");
    var preLast = segments[segments.length - 2];
    if (null != client.getResource(preLast)) return preLast;
    throw new Exception("Could not resolve resource");
  }
  
  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      return _resolve(invocation.memberName);
    }
    if (invocation.isMethod) {
      _resolve(invocation.memberName);
      var args = invocation.positionalArguments;
      if (args.isEmpty)
        return Function.apply(all, [], invocation.namedArguments);
      if (1 == args.length)
        return Function.apply(one, [], invocation.namedArguments);
    }
    throw new ArgumentError('Cannot resolve invocation');
  }
  
  Future all({Map<String, dynamic> headers}) {
    var resource = client.getResource(lastResource);
    return resource.all(uri, headers: headers);
  }
  
  Future one({Map<String, dynamic> headers}) {
    var resource = client.getResource(lastResource);
    return resource.one(uri, headers: headers);
  }
}

@proxy
class RestClient {
  final Uri baseUri;
  Map<String, Resource> resources = {};
  
  RestClient(this.baseUri);
  
  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      return new PathBuilder(baseUri, this)._resolve(invocation.memberName);
    }
  }
  
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

class Resource {
  final String name;
  final Definition definition;
  
  Resource(this.name, this.definition);
  
  Future<List<Entity>> all(Uri uri, {Map<String, dynamic> headers}) {
    return http.get(uri, headers: headers).then((response) {
      checkResponse(response, 200);
      var entities = JSON.decode(response.body) as List<Map<String, dynamic>>;
      return entities.map(transformIn).toList();
    });
  }
  
  Uri _resolve(Uri base) => base.resolve(name);
  
  Future<Entity> one(Uri uri, {Map<String, dynamic> headers}) {
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

@proxy
class Entity {
  Map<Symbol, dynamic> _fields;
  final Resource parent;
  
  Entity(this._fields, this.parent);
  
  noSuchMethod(Invocation invocation) {
    if (!_fields.containsKey(invocation.memberName))
      return super.noSuchMethod(invocation);
    if (invocation.isGetter) return _fields[invocation.memberName];
    if (invocation.isMethod)
      return Function.apply(_fields[invocation.memberName],
                            [this]..addAll(invocation.positionalArguments),
                            invocation.namedArguments);
  }
  
  String toJson() => JSON.encode(parent.transformOut(this));
  
  operator [](Symbol key) => _fields[key];
}

class Definition {
  final Map<String, Field> fields;
  
  Definition(this.fields);
  
  Map<String, Method> get methods {
    var result = {};
    fields.values.forEach((field) {
      if (field is Method) result[field.name] = field;
    });
    return result;
  }
  
  Map<String, Property> get properties {
    var result = {};
    fields.values.forEach((field) {
      if (field is Property) result[field.name] = field;
    });
    return result;
  }
}

abstract class Field {
  String get name;
}

class Property implements Field {
  final String name;
  final Transformer inTransformer;
  final Transformer outTransformer;
  
  Property(this.name, {Transformer inTransformer, Transformer outTransformer})
      : inTransformer =
            null == inTransformer ? TYPE_PARSERS["none"] : inTransformer,
        outTransformer =
            null == outTransformer ? TYPE_PARSERS["none"] :
              outTransformer;
  
  Property.typed(this.name, {Type type: String})
      : inTransformer = TYPE_PARSERS["in"][type],
        outTransformer = TYPE_PARSERS["out"][type];
  
  static final TYPE_PARSERS = {
    "none": (value) => value,
    "in": {
      int: (value) {
        if (value is int) return value;
        if (value is double) return value.toDouble();
        if (value is String) return int.parse(value);
        throw new ArgumentError.value(value);
      },
      String: (value) {
        if (value is String) return value;
        return value.toString();
      },
      DateTime: (value) {
        if (value is DateTime) return value;
        if (value is String) return DateTime.parse(value);
        if (value is int) return new DateTime.fromMillisecondsSinceEpoch(value);
        throw new ArgumentError.value(value);
      },
      double: (value) {
        if (value is double) return value;
        if (value is String) return double.parse(value);
        if (value is int) return value.toDouble();
        throw new ArgumentError.value(value);
      },
      bool: (value) {
        if (value is bool) return value;
        if (value is String) {
          if (0 == value.length) return false;
          return true;
        }
        if (value is num) {
          if (0 == value) return false;
          return false;
        }
        throw new ArgumentError.value(value);
      }
    },
    "out": {
      int: (value) => value.toString(),
      String: (value) => value.toString(),
      DateTime: (value) => value.toString(),
      double: (value) => value.toString(),
      bool: (value) => value.toString()
    }
  };
}

class Method implements Field {
  final String name;
  final Function function;
  
  Method(this.name, this.function);
}

class ResourceBuilder {
  Map<String, Field> _fields = {};
  String _name;
  
  ResourceBuilder(this._name);
  
  void addField(Field field) {
    _fields[field.name] = field;
  }
  
  void addTypedProperty(String name, {type: String}) =>
      addField(new Property.typed(name, type: type));
  
  void addProperty(String name, {Transformer inTransformer,
    Transformer outTransformer}) =>
        addField(new Property(name, inTransformer: inTransformer,
                                    outTransformer: outTransformer));
  
  void addMethod(String name, Function function) =>
      addField(new Method(name, function));
  
  Resource build() {
    var definition = new Definition(_fields);
    return new Resource(_name, definition);
  }
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