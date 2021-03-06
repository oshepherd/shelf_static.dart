// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf_static.test_util;

import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_static/src/util.dart';

final p.Context _ctx = p.url;

/// Makes a simple GET request to [handler] and returns the result.
Future<Response> makeRequest(Handler handler, String path,
    {String scriptName}) {
  var rootedHandler = _rootHandler(scriptName, handler);
  return syncFuture(() => rootedHandler(_fromPath(path)));
}

Request _fromPath(String path) =>
    new Request('GET', Uri.parse('http://localhost' + path));

Handler _rootHandler(String scriptName, Handler handler) {
  if (scriptName == null || scriptName.isEmpty) {
    return handler;
  }

  if (!scriptName.startsWith('/')) {
    throw new ArgumentError('scriptName must start with "/" or be empty');
  }

  return (Request request) {
    if (!_ctx.isWithin(scriptName, request.requestedUri.path)) {
      return new Response.notFound('not found');
    }
    assert(request.scriptName.isEmpty);

    var relativePath = _ctx.relative(request.requestedUri.path,
        from: scriptName);

    assert(!relativePath.startsWith('/'));

    relativePath = '/' + relativePath;

    var url = new Uri(path: relativePath, query: request.url.query,
        fragment: request.url.fragment);
    var relativeRequest = _copy(request, scriptName, url);

    return handler(relativeRequest);
  };
}

// TODO: until we have on https://code.google.com/p/dart/issues/detail?id=18453
Request _copy(Request r, String scriptName, Uri url) {
  return new Request(r.method, r.requestedUri,
      protocolVersion: r.protocolVersion, headers: r.headers, url: url,
      scriptName: scriptName, body: r.read(), context: r.context);
}
