// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library restpoint.test;

import 'dart:async' show Future;

import 'mock/mocks.dart';
import 'restpoint_pathbuilder_test.dart' as pathbuilder;

import 'package:unittest/unittest.dart';
import 'package:restpoint/restpoint.dart';

main() {
  pathbuilder.defineTests();
  
  group("RestClient", () {
  });
  
  group("ResourceBuilder", () {
    group("build", () {
      test("simple", () {
        var builder = new ResourceBuilder(null, "users");
        var function = (Entity self) => null;
        builder.addMethod("myMethod", function);
        builder.addProperty("name");
        var resource = builder.build();
        
        expect(resource.name, equals("users"));
        var builtMethod = resource.definition.methods["myMethod"];
        expect(builtMethod.name, equals("myMethod"));
        expect(builtMethod.function, equals(function));
        var builtProperty = resource.definition.properties["name"];
        expect(builtProperty.name, equals("name"));
      });
    });
    
    group("parse", () {
      group("Types only", () {
        var builder = new ResourceBuilder(null, "users");
        var function = (Entity self) => self.name + " and Olaf";
        builder.addMethod("myMethod", function);
        builder.addProperty("name");
        var resource = builder.build();
        
        var entity = resource.transformIn({"name": "Guenther"});
        expect(entity.name, equals("Guenther"));
        expect(entity.myMethod(), equals("Guenther and Olaf"));
      });
    });
  });
  
  group("Definition", () {
    test("getters (methods, properties)", () {
      var method = new Method("test", (Entity self) => null);
      var property = new Property("name");
      var fields = {
        "name": property,
        "test": method
      };
      var definition = new Definition(fields);
      expect(definition.methods, equals({"test": method}));
      expect(definition.properties, equals({"name": property}));
      expect(definition.fields, equals(fields));
    });
  });
  
  group("Property", () {
    group("TYPE_PARSERS", () {
      group("in", () {
        var inParsers = Property.TYPE_PARSERS["in"];
        
        test("int", () {
          var parser = inParsers[int];
          
          expect(parser(1), equals(1));
          expect(parser(1.0), equals(1));
          expect(parser("23"), equals(23));
          expect(() => parser(#test), throws);
        });
        
        test("String", () {
          var parser = inParsers[String];
          
          expect(parser("Test"), equals("Test"));
          expect(parser(true), equals(true.toString()));
        });
        
        test("DateTime", () {
          var parser = inParsers[DateTime];
          var now = new DateTime.now();
          
          expect(parser(now.toString()), equals(now));
          expect(parser(now.millisecondsSinceEpoch), equals(now));
          expect(parser(now), equals(now));
          expect(() => parser(1.0), throws);
        });
        
        test("double", () {
          var parser = inParsers[double];
          
          expect(parser(1.3), equals(1.3));
          expect(parser("1.23"), equals(1.23));
          expect(parser(1), equals(1.0));
          expect(() => parser(new DateTime.now()), throws);
        });
      });
    });
  });
}
