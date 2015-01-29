library restpoint.base;

import 'dart:convert' show JSON;
import 'dart:async' show Future;
import 'dart:mirrors' show MirrorSystem;

import 'package:http/http.dart';

typedef Transformer(value);

@proxy
class PathBuilder {
  Uri uri;
  
  PathBuilder(this.uri);
  
  PathBuilder id(id) => _resolve(id);
  
  PathBuilder _resolve(arg) {
    if (arg is Symbol) arg = MirrorSystem.getName(arg);
    var uri = this.uri.toString();
    uri += uri.endsWith('/') ? arg : '/$arg';
    this.uri = Uri.parse(uri);
    return this;
  }
  
  PathBuilder noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      return _resolve(invocation.memberName);
    }
    throw new ArgumentError('Cannot resolve non-getters');
  }
}

@proxy
class RestClient {
  final Uri baseUri;
  Map<Symbol, Resource> resources = {};
  
  RestClient(this.baseUri);
  
  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      if (null != resources[invocation.memberName])
        return resources[invocation.memberName]._resolve(baseUri);
      var name = MirrorSystem.getName(invocation.memberName);
      return baseUri.resolve(name);
    }
  }
  
  void addResource(Resource resource) {
    resources[new Symbol(resource.name)] = resource;
  }
}

class Resource {
  final String name;
  final Definition definition;
  
  Resource(this.name, this.definition);
  
  Future<List<Entity>> _all(Uri baseUri, {Map<String, dynamic> headers}) {
    var uri = baseUri.resolve(name);
    return get(uri, headers: headers).then((response) {
      checkResponse(response, 200);
      var entities = JSON.decode(response.body) as List<Map<String, dynamic>>;
      return entities.map(transformIn).toList();
    });
  }
  
  Uri _resolve(Uri base) => base.resolve(name);
  
  Future<Entity> _one(Uri baseUri, id, {Map<String, dynamic> headers}) {
    var uri = baseUri.resolve(name).resolve(id);
    return get(uri, headers: headers).then((response) {
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
    if (invocation.isGetter) return _fields[invocation.memberName];
    if (invocation.isMethod)
      return Function.apply(_fields[invocation.memberName],
                            [this]..addAll(invocation.positionalArguments),
                            invocation.namedArguments);
  }
  
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

void checkResponse(Response response, int expected) {
  if (expected != response.statusCode)
    throw new StatusException(expected, response.statusCode);
}