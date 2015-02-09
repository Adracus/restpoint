library restpoint.test.pathbuilder;

import 'dart:async' show Future;

import 'mock/mocks.dart';

import 'package:restpoint/restpoint_server_client.dart';
import 'package:restpoint/restpoint.dart';
import 'package:unittest/unittest.dart';


main() => defineTests();

defineTests() {
  group("PathBuilder", () {
    test("Uri building", () {
      var uri = Uri.parse("http://www.example.org");
      var resolved1 = new PathBuilder(uri, null).users.id(1).notes;
      var expectedUri = Uri.parse("http://www.example.org/users/1/notes");
      expect(resolved1.uri, equals(expectedUri));
    });
    
    group("One", () {
      test("Zero level", () {
        var uri = Uri.parse("http://www.example.org");
        var client = new RestClient(uri, new ServerClientFactory());
        var resource = new ResourceMock("users");
        var headers = {"a": 1};
        resource.callbacks["one"] = (Uri uri, {Map<String, String> headers}) {
          expect(headers, equals(headers));
          expect(uri.toString(), equals("http://www.example.org/users/12"));
          return new Future.value("awesome");
        };
        client.addResource(resource);
        client.users(12).then(expectAsync((value) =>
            expect(value, equals("awesome"))));
      });
      
      test("nested", () {
        var uri = Uri.parse("http://www.example.org");
        var client = new RestClient(uri, new ServerClientFactory());
        var resource = new ResourceMock("users");
        var headers = {"a": 1};
        resource.callbacks["one"] = (Uri uri, {Map<String, String> headers}) {
          expect(headers, equals(headers));
          expect(uri.toString(), equals("http://www.example.org/persons/users/12"));
          return new Future.value("awesome");
        };
        client.addResource(resource);
        
        Future.wait([client.persons.users(12, headers: headers),
                     client.persons.users.id(12).one(headers: headers)])
        .then(expectAsync((values) {
          values.forEach((value) => expect(value, equals("awesome")));
        }));
      });
    });
      
    group("All", () {
      test("nested", () {
        var uri = Uri.parse("http://www.example.org");
        var client = new RestClient(uri, new ServerClientFactory());
        var resource = new ResourceMock("users");
        var headers = {"a": 1};
        resource.callbacks["all"] = (Uri uri, {Map<String, String> headers}) {
          expect(headers, equals(headers));
          expect(uri.toString(), equals("http://www.example.org/persons/users"));
          return new Future.value("awesome");
        };
        client.addResource(resource);
        
        Future.wait([client.persons.users(headers: headers),
                     client.persons.users.all(headers: headers)])
        .then(expectAsync((values) {
          values.forEach((value) => expect(value, equals("awesome")));
        }));
      });
      
      test("simple", () {
        var uri = Uri.parse("http://www.example.org");
        var client = new RestClient(uri, new ServerClientFactory());
        var resource = new ResourceMock("users");
        var headers = {"a": 1};
        resource.callbacks["all"] = (Uri uri, {Map<String, String> headers}) {
          expect(headers, equals(headers));
          expect(uri.toString(), equals("http://www.example.org/users"));
          return new Future.value("awesome");
        };
        client.addResource(resource);
        
        Future.wait([client.users(headers: headers),
                     client.users.all(headers: headers)])
        .then(expectAsync((values) {
          values.forEach((value) => expect(value, equals("awesome")));
        }));
      });
    });
    
    group("delete", () {
      test("simple", () {
        var uri = Uri.parse("http://www.example.org");
        var client = new RestClient(uri, new ServerClientFactory());
        var resource = new ResourceMock("users");
        var headers = {"a": 1};
        resource.callbacks["delete"] = (Uri uri, {Map<String, String> headers}) {
          expect(headers, equals(headers));
          expect(uri.toString(), equals("http://www.example.org/users"));
          return new Future.value("awesome");
        };
        client.addResource(resource);
        
        client.users.delete(headers: headers).then(expectAsync((value) {
          expect(value, equals("awesome"));
        }));
      });
      
      test("nested", () {
        var uri = Uri.parse("http://www.example.org");
        var client = new RestClient(uri, new ServerClientFactory());
        var resource = new ResourceMock("users");
        var headers = {"a": 1};
        resource.callbacks["delete"] = (Uri uri, {Map<String, String> headers}) {
          expect(headers, equals(headers));
          expect(uri.toString(), equals("http://www.example.org/persons/users"));
          return new Future.value("awesome");
        };
        client.addResource(resource);
        
        client.persons.users.delete(headers: headers).then(expectAsync((value) {
          expect(value, equals("awesome"));
        }));
      });
    });
  });
}