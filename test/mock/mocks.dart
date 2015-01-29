library restpoint.test.mocks;

import 'dart:async' show Future;
import 'package:restpoint/restpoint.dart';
import 'package:mock/mock.dart';

@proxy
class ResourceMock extends Mock implements Resource {
  String name;
  Map<String, Function> callbacks = {};
  
  ResourceMock(this.name);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  
  Future one(Uri uri, {Map<String, dynamic> headers}) =>
      Function.apply(callbacks["one"], [uri], {#headers: headers});
  
  Future all(Uri uri, {Map<String, dynamic> headers}) =>
      Function.apply(callbacks["all"], [uri], {#headers: headers});
}