library restpoint.structure;

import 'dart:async' show Future;
import 'dart:mirrors' show MirrorSystem;

import 'restpoint_resource.dart';
import 'restpoint_http.dart';

typedef Transformer(value);

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
  
  get(String name) => _fields[new Symbol(name)];
  
  bool containsKey(String key) => _fields.containsKey(new Symbol(key));
  
  Future<Entity> full({String uriAddition, Map<String, dynamic> headers}) {
    var uri = parent.resourceUri;
    if (null != uriAddition) uri = appendToUri(uri, uriAddition);
    return parent.one(uri, headers: headers);
  }
  
  Future delete({String uriAddition, String idName: "id",
                 Map<String, dynamic> headers}) {
    var uri = parent.resourceUri;
    if (null != uriAddition) uri = appendToUri(uri, uriAddition);
    uri = appendToUri(uri, _fields[new Symbol(idName)]);
    return parent.delete(uri, headers: headers);
  }
  
  String toJson() => JSON.encode(parent.transformOut(this));
  
  String toString() {
    if (_fields[#toString] is Function) return _fields[#toString](this);
    var result = [];
    _fields.forEach((name, value) {
      if (value is! Function)
        result.add(MirrorSystem.getName(name) + " " + value.toString());
    });
    return result.join("\n");
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