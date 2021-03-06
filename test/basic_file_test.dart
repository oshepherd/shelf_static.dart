library shelf_static.basic_file_test;

import 'dart:io';
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'package:shelf_static/shelf_static.dart';
import 'test_util.dart';

void main() {
  setUp(() {
    var tempDir;
    schedule(() {
      return Directory.systemTemp.createTemp('shelf_static-test-').then((dir) {
        tempDir = dir;
        d.defaultRoot = tempDir.path;
      });
    });

    d.file('root.txt', 'root txt').create();
    d.dir('files', [
        d.file('test.txt', 'test txt content'),
        d.file('with space.txt', 'with space content')
    ]).create();

    currentSchedule.onComplete.schedule(() {
      d.defaultRoot = null;
      return tempDir.delete(recursive: true);
    });
  });

  test('access root file', () {
    schedule(() {
      var handler = getHandler(d.defaultRoot);

      return makeRequest(handler, '/root.txt').then((response) {
        expect(response.statusCode, HttpStatus.OK);
        expect(response.headers[HttpHeaders.CONTENT_LENGTH], '8');
        expect(response.readAsString(), completion('root txt'));
      });
    });
  });

  test('access root file with space', () {
    schedule(() {
      var handler = getHandler(d.defaultRoot);

      return makeRequest(handler, '/files/with%20space.txt').then((response) {
        expect(response.statusCode, HttpStatus.OK);
        expect(response.headers[HttpHeaders.CONTENT_LENGTH], '18');
        expect(response.readAsString(), completion('with space content'));
      });
    });
  });

  test('access root file with unencoded space', () {
    schedule(() {
      var handler = getHandler(d.defaultRoot);

      return makeRequest(handler, '/files/with space.txt').then((response) {
        expect(response.statusCode, HttpStatus.FORBIDDEN);
      });
    });
  });

  test('access file under directory', () {
    schedule(() {
      var handler = getHandler(d.defaultRoot);

      return makeRequest(handler, '/files/test.txt').then((response) {
        expect(response.statusCode, HttpStatus.OK);
        expect(response.headers[HttpHeaders.CONTENT_LENGTH], '16');
        expect(response.readAsString(), completion('test txt content'));
      });
    });
  });

  test('file not found', () {
    schedule(() {
      var handler = getHandler(d.defaultRoot);

      return makeRequest(handler, '/not_here.txt').then((response) {
        expect(response.statusCode, HttpStatus.NOT_FOUND);
      });
    });
  });

  // getHandler for non-existant directory

  // evil URL fixes

  // hosted via other path: success, fail

  // no sym links
}
