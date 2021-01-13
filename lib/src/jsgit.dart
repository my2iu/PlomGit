import 'dart:async';
import 'dart:ffi';
import 'package:flutter_jscore/flutter_jscore.dart';
import 'package:flutter_jscore/binding/js_context_ref.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:typed_data';
import 'dart:io';

class JsForGit {
  static Map<Pointer, JsForGit> ctxToJsForGit = Map<Pointer, JsForGit>();
  // For synchronizing access to JavaScriptCore
  static Future<dynamic> synchronizer;
  // Not really necessary to use all this promise and Completer stuff
  // because it seems that JavaScriptCore is executing all the promises
  // before returning from evaluate(). So having complicated code to call
  // a callback when a JS promise finishes ends up being unnecessary, but
  // we'll do it to be safe anyway
  Completer<dynamic> completer;

  // JS VM for running JS Git code
  JSContext jsContext;

  // Path to the repository location
  Uri repositoryUri;

  JsForGit(Uri repositoryUri) {
    this.repositoryUri = repositoryUri;
    configureJs();
  }

  JsForGit.forNewDirectory(Uri repositoryUri) {
    Directory.fromUri(repositoryUri).createSync(recursive: true);
    this.repositoryUri = repositoryUri;
    configureJs();
  }

  void configureJs() {
    jsContext = JSContext.createInGroup();
    ctxToJsForGit[jsContext.pointer] = this;

    // Set up self and window properties to point to global object
    jsContext.globalObject.setProperty(
        'window',
        jsContext.globalObject.toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    jsContext.globalObject.setProperty('self', jsContext.globalObject.toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);

    // Create an object to hold callbacks from JS to Dart
    JSObject flutterNamespace = JSObject.make(jsContext, JSClass(nullptr));
    jsContext.globalObject.setProperty('flutter', flutterNamespace.toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    // Set-up functions for calling from JS back into Dart for doing stuff
    flutterNamespace.setProperty(
        'httpFetch',
        JSObject.makeFunctionWithCallback(
                jsContext, 'httpFetch', Pointer.fromFunction(_jsHttpFetch))
            .toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    flutterNamespace.setProperty(
        'fsOperation',
        JSObject.makeFunctionWithCallback(
                jsContext, 'fsOperation', Pointer.fromFunction(_jsFsOperation))
            .toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    flutterNamespace.setProperty(
        'signalCompletion',
        JSObject.makeFunctionWithCallback(jsContext, 'signalCompletion',
                Pointer.fromFunction(_jsSignalCompletion))
            .toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    flutterNamespace.setProperty(
        'signalError',
        JSObject.makeFunctionWithCallback(
                jsContext, 'signalError', Pointer.fromFunction(_jsSignalError))
            .toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    flutterNamespace.setProperty(
        'log',
        JSObject.makeFunctionWithCallback(
                jsContext, 'log', Pointer.fromFunction(_jsLog))
            .toValue(),
        JSPropertyAttributes.kJSPropertyAttributeNone);

    // Load in the JS code for git
    synchronizer =
        rootBundle.loadString('assets/js/isomorphic-git.js').then((js) {
      print('1' + jsContext.evaluate(js).string);
      return rootBundle.loadString('assets/js/isomorphic-git-http.js');
    }).then((js) {
      print('2' + jsContext.evaluate(js).string);
      return rootBundle.loadString('assets/js/fs.js');
    }).then((js) {
      print('3' + jsContext.evaluate(js).string);
    });
  }

  void release() {
    ctxToJsForGit.remove(jsContext.pointer);
  }

  Future<dynamic> clone(String name, String url) {
    synchronizer = synchronizer.whenComplete(() {
      completer = new Completer<dynamic>();
      var fun = jsContext.evaluate("(function(name, url) {" +
          "git.clone({fs:fs, http:http, dir:'', url: url})" +
          ".then(function(val) {flutter.signalCompletion(val);})" +
          ".catch(function(err) { if (err instanceof Error) flutter.signalError(err.message); else flutter.signalError(err);});" +
          "})");
      var exception = JSValuePointer();
      fun.toObject().callAsFunction(
          JSObject(jsContext, nullptr),
          JSValuePointer.array([
            JSValue.makeString(jsContext, name),
            JSValue.makeString(jsContext, url)
          ]),
          exception: exception);
      return completer.future;
    });
    return synchronizer;
  }

  Future<dynamic> init(String name) {
    synchronizer = synchronizer.whenComplete(() {
      completer = new Completer<dynamic>();
      var fun = jsContext.evaluate("(function(name) {" +
          "git.init({fs:fs, dir:''})" +
          ".then(function(val) {flutter.signalCompletion(val);})" +
          ".catch(function(err) { if (err instanceof Error) flutter.signalError(err.message); else flutter.signalError(err);});" +
          "})");
      var exception = JSValuePointer();
      fun.toObject().callAsFunction(JSObject(jsContext, nullptr),
          JSValuePointer.array([JSValue.makeString(jsContext, name)]),
          exception: exception);
      return completer.future;
    });
    return synchronizer;
  }

  Pointer _signalCompletion(
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount > 0) {
      completer.complete(JSValue(jsContext, arguments[0]).string);
    } else {
      completer.complete(null);
    }
    return nullptr;
  }

  Pointer _signalError(Pointer function, Pointer thisObject, int argumentCount,
      Pointer<Pointer> arguments, Pointer<Pointer> exception) {
    if (argumentCount > 0) {
      completer.completeError(JSValue(jsContext, arguments[0]).string);
    } else {
      completer.completeError(null);
    }
    return nullptr;
  }

  JSValue _createFsError(String msg, String errCode) {
    final err = jsContext.globalObject
        .getProperty('Error')
        .toObject()
        .callAsConstructor(
            JSValuePointer.array([JSValue.makeString(jsContext, msg)]));
    err.setProperty('code', JSValue.makeString(jsContext, errCode),
        JSPropertyAttributes.kJSPropertyAttributeNone);
    return err.toValue();
  }

  void _callFsCallbackWithException(
      JSValue callback, String msg, String errCode) {
    var exception = JSValuePointer();
    callback.toObject().callAsFunction(JSObject(jsContext, nullptr),
        JSValuePointer.array([_createFsError(msg, errCode)]),
        exception: exception);
  }

  final fsLogger = new Logger("plomgit.fs");

  Pointer _fsOperation(Pointer function, Pointer thisObject, int argumentCount,
      Pointer<Pointer> arguments, Pointer<Pointer> exception) {
    var operation = JSValue(jsContext, arguments[0]).string;
    try {
      switch (operation) {
        case 'readFile':
          var path = JSValue(jsContext, arguments[1]).string;
          var options = JSValue(jsContext, arguments[2]);
          var callback = JSValue(jsContext, arguments[3]);
          if (callback.isNull || callback.isUndefined) {
            callback = options;
            options = null;
          }
          bool readString = false;
          if (options != null) {
            if (options.isString) {
              readString = true;
            } else if (options.isObject) {
              var encoding = options.toObject().getProperty("encoding");
              if (!encoding.isNull && !encoding.isUndefined) readString = true;
            }
          }
          File f = File.fromUri(
              repositoryUri.replace(path: repositoryUri.path + path));
          fsLogger.fine('readFile ' + path);
          var reader;
          if (readString) {
            reader = f.readAsString().then((str) {
              var exception = JSValuePointer();
              fsLogger.fine('readFile string exiting');
              callback.toObject().callAsFunction(
                  JSObject(jsContext, nullptr),
                  JSValuePointer.array([
                    JSValue.makeNull(jsContext),
                    JSValue.makeString(jsContext, str)
                  ]),
                  exception: exception);
            });
          } else {
            reader = f.readAsBytes().then((bytes) {
              var exception = JSValuePointer();
              JSObject jsData = JSObject.makeTypedArray(jsContext,
                  JSTypedArrayType.kJSTypedArrayTypeUint8Array, bytes.length,
                  exception: exception);
              Pointer<Uint8> intPointer =
                  Pointer.fromAddress(jsData.typedArrayBytes().pointer.address);
              intPointer.asTypedList(bytes.length).setAll(0, bytes);
              fsLogger.fine('readFile arraybuffer exiting');
              callback.toObject().callAsFunction(
                  JSObject(jsContext, nullptr),
                  JSValuePointer.array(
                      [JSValue.makeNull(jsContext), jsData.toValue()]),
                  exception: exception);
            });
          }
          reader.catchError((err) {
            fsLogger.fine('readFile error exiting ' + err.toString());
            _callFsCallbackWithException(
                callback, "Error when reading file", "");
          });
          return nullptr;
        case 'writeFile':
          var file = JSValue(jsContext, arguments[1]).string;
          var data = JSValue(jsContext, arguments[2]);
          var options = JSValue(jsContext, arguments[3]);
          var callback = JSValue(jsContext, arguments[4]);
          if (callback.isNull || callback.isUndefined) {
            callback = options;
            options = null;
          }
          File f = File.fromUri(
              repositoryUri.replace(path: repositoryUri.path + file));
          fsLogger.fine('writeFile ' + file);
          Future<File> writer;
          if (data.isString) {
            writer = f.writeAsString(data.string);
          } else {
            var typedArrayType = data.getTypedArrayType();
            if (typedArrayType == JSTypedArrayType.kJSTypedArrayTypeNone) {
              _callFsCallbackWithException(callback,
                  "Unsupported value written to file", "ERR_INVALID_ARG_VALUE");
              return nullptr;
            }
            JSObject typedArrayObj = data.toObject();
            Bytes backingStore = typedArrayObj.typedArrayBytes();
            var offset = typedArrayObj.typedArrayByteOffset();
            var len = typedArrayObj.typedArrayByteLength();
            Pointer<Uint8> intPointer =
                Pointer.fromAddress(backingStore.pointer.address);
            var dataList = Uint8List.fromList(
                intPointer.asTypedList(offset + len).sublist(offset));
            writer = f.writeAsBytes(dataList);
          }
          writer.then((f) {
            var exception = JSValuePointer();
            callback.toObject().callAsFunction(JSObject(jsContext, nullptr),
                JSValuePointer.array([JSValue.makeNull(jsContext)]),
                exception: exception);
          }).catchError((err) {
            _callFsCallbackWithException(
                callback, "Error when writing file", "");
          });
          return nullptr;
        case 'unlink':
          var path = JSValue(jsContext, arguments[1]).string;
          var callback = JSValue(jsContext, arguments[2]);

          fsLogger.fine('unlink ' + path);

          // isomorphic-git expects us to return ENOENT if we delete a file that
          // doesn't exist, so we need to specifically test for that
          File f = File.fromUri(
              repositoryUri.replace(path: repositoryUri.path + path));

          f.exists().then((exists) {
            if (!exists) {
              _callFsCallbackWithException(
                  callback, 'File not found', 'ENOENT');
            } else {
              f.delete().then((f) {
                var exception = JSValuePointer();
                callback.toObject().callAsFunction(JSObject(jsContext, nullptr),
                    JSValuePointer.array([JSValue.makeNull(jsContext)]),
                    exception: exception);
              }).catchError((err) {
                _callFsCallbackWithException(
                    callback, "File could not be deleted", "");
              });
            }
          }).catchError((err) {
            _callFsCallbackWithException(
                callback, "File information could be gathered", "");
          });
          return nullptr;
        case 'readdir':
          var dirpath = JSValue(jsContext, arguments[1]).string;
          var options = JSValue(jsContext, arguments[2]);
          var callback = JSValue(jsContext, arguments[3]);
          if (callback.isNull || callback.isUndefined) {
            callback = options;
            options = null;
          }
          if (options != null && !options.isNull && !options.isUndefined) {
            _callFsCallbackWithException(
                callback, "Cannot handle options in readdir", "");
            return nullptr;
          }

          fsLogger.fine('readdir ' + dirpath);

          Uri uri = repositoryUri.replace(path: repositoryUri.path + dirpath);

          File.fromUri(uri).stat().then((filestat) {
            if (filestat.type == FileSystemEntityType.notFound) {
              _callFsCallbackWithException(callback,
                  "readdir called on non-existent directory", "ENOENT");
              return;
            } else if (filestat.type != FileSystemEntityType.directory) {
              // Make sure that the path refers to a directory since isomorphic-git
              // seems to specifically check for this
              _callFsCallbackWithException(callback,
                  "readdir called on a path that isn't a directory", "ENOTDIR");
              return;
            }
            Directory.fromUri(uri)
                .list()
                .map((entry) => path.basename(entry.path))
                .toList()
                .then((list) {
              var entryArray = JSObject.makeArray(
                  jsContext,
                  JSValuePointer.array(list
                      .map((nameStr) => JSValue.makeString(jsContext, nameStr))
                      .toList()));
              var exception = JSValuePointer();
              callback.toObject().callAsFunction(
                  JSObject(jsContext, nullptr),
                  JSValuePointer.array(
                      [JSValue.makeNull(jsContext), entryArray.toValue()]),
                  exception: exception);
            }).catchError((err) {
              _callFsCallbackWithException(
                  callback, "Error during readdir", "");
            });
          }).catchError((err) {
            _callFsCallbackWithException(
                callback, "Error during stat inside readdir", "");
          });
          return nullptr;
        case 'mkdir':
          var path = JSValue(jsContext, arguments[1]).string;
          var mode = JSValue(jsContext, arguments[2]);
          var callback = JSValue(jsContext, arguments[3]);
          if (callback.isNull || callback.isUndefined) {
            callback = mode;
            mode = null;
          }
          fsLogger.fine('mkdir ' + path);
          Directory.fromUri(
                  repositoryUri.replace(path: repositoryUri.path + path))
              .create()
              .then((dir) {
            // Note: in Flutter, creation will succeed if directory already exists
            var exception = JSValuePointer();
            callback.toObject().callAsFunction(JSObject(jsContext, nullptr),
                JSValuePointer.array([JSValue.makeNull(jsContext)]),
                exception: exception);
          }).catchError((err) {
            // We can't tell the type of exception, so we'll just assume that
            // it's an exception for can't find parent directory
            _callFsCallbackWithException(
                callback,
                "Directory creation failed, possibly due to missing parent directory",
                "ENOENT");
          });
          return nullptr;
        case 'rmdir':
          var path = JSValue(jsContext, arguments[1]);
          var callback = JSValue(jsContext, arguments[2]);
          break;
        case 'stat':
          var path = JSValue(jsContext, arguments[1]).string;
          var options = JSValue(jsContext, arguments[2]);
          var callback = JSValue(jsContext, arguments[3]);
          if (callback.isNull || callback.isUndefined) {
            callback = options;
            options = null;
          }
          File f = File.fromUri(
              repositoryUri.replace(path: repositoryUri.path + path));
          fsLogger.fine('stat ' + path);
          // Treating stat and lstat identically for now
          f.stat().then((filestat) {
            if (filestat.type == FileSystemEntityType.notFound) {
              _callFsCallbackWithException(
                  callback, 'File not found', 'ENOENT');
            } else {
              var exception = JSValuePointer();
              var jsFileStat = jsContext.globalObject
                  .getProperty('fs')
                  .toObject()
                  .getProperty('createFileStat')
                  .toObject()
                  .callAsFunction(
                      JSObject(jsContext, nullptr),
                      JSValuePointer.array([
                        JSValue.makeBoolean(jsContext,
                            filestat.type == FileSystemEntityType.directory),
                        JSValue.makeNumber(jsContext, filestat.size.toDouble()),
                        JSValue.makeNumber(jsContext,
                            filestat.modified.millisecondsSinceEpoch.toDouble())
                      ]),
                      exception: exception);
              callback.toObject().callAsFunction(
                  JSObject(jsContext, nullptr),
                  JSValuePointer.array(
                      [JSValue.makeNull(jsContext), jsFileStat]),
                  exception: exception);
            }
          });
          return nullptr;
        case 'lstat':
          var path = JSValue(jsContext, arguments[1]).string;
          var options = JSValue(jsContext, arguments[2]);
          var callback = JSValue(jsContext, arguments[3]);
          if (callback.isNull || callback.isUndefined) {
            callback = options;
            options = null;
          }

          File f = File.fromUri(
              repositoryUri.replace(path: repositoryUri.path + path));
          fsLogger.fine('lstat ' + path);
          // Treating stat and lstat identically for now
          f.stat().then((filestat) {
            if (filestat.type == FileSystemEntityType.notFound) {
              _callFsCallbackWithException(
                  callback, 'File not found', 'ENOENT');
            } else {
              var exception = JSValuePointer();
              var jsFileStat = jsContext.globalObject
                  .getProperty('fs')
                  .toObject()
                  .getProperty('createFileStat')
                  .toObject()
                  .callAsFunction(
                      JSObject(jsContext, nullptr),
                      JSValuePointer.array([
                        JSValue.makeBoolean(jsContext,
                            filestat.type == FileSystemEntityType.directory),
                        JSValue.makeNumber(jsContext, filestat.size.toDouble()),
                        JSValue.makeNumber(jsContext,
                            filestat.modified.millisecondsSinceEpoch.toDouble())
                      ]),
                      exception: exception);
              callback.toObject().callAsFunction(
                  JSObject(jsContext, nullptr),
                  JSValuePointer.array(
                      [JSValue.makeNull(jsContext), jsFileStat]),
                  exception: exception);
            }
          });
          return nullptr;
        case 'readlink':
          var path = JSValue(jsContext, arguments[1]);
          var options = JSValue(jsContext, arguments[2]);
          var callback = JSValue(jsContext, arguments[3]);
          if (callback.isNull || callback.isUndefined) {
            callback = options;
            options = null;
          }
          // Not implemented
          break;
        case 'symlink':
          var target = JSValue(jsContext, arguments[1]);
          var path = JSValue(jsContext, arguments[2]);
          var type = JSValue(jsContext, arguments[3]);
          var callback = JSValue(jsContext, arguments[4]);
          if (callback.isNull || callback.isUndefined) {
            callback = type;
            type = null;
          }
          // Not implemented
          break;
        case 'chmod':
          var path = JSValue(jsContext, arguments[1]);
          var mode = JSValue(jsContext, arguments[2]);
          var callback = JSValue(jsContext, arguments[3]);
          // Not used
          break;
        default:
          break;
      }
      // Throw an exception for all operations that we don't handle. Isomorphic-git
      // requires that we throw an actual Error object and not an arbitrary object
      // like a string.
      print('fsOperation ' + operation);
      exception[0] = _createFsError("Not supported", "").pointer;
    } catch (err) {
      exception[0] =
          _createFsError("Error during fs marshalling " + err.toString(), "")
              .pointer;
    }
    return nullptr;
  }

  final httpLogger = new Logger("plomgit.http");

  void _callHttpFetchCallbackWithException(JSValue callback, String msg) {
    var exception = JSValuePointer();
    final err = jsContext.globalObject
        .getProperty('Error')
        .toObject()
        .callAsConstructor(
            JSValuePointer.array([JSValue.makeString(jsContext, msg)]));
    callback.toObject().callAsFunction(
        JSObject(jsContext, nullptr), JSValuePointer.array([err.toValue()]),
        exception: exception);
  }

  Pointer _httpFetch(Pointer function, Pointer thisObject, int argumentCount,
      Pointer<Pointer> arguments, Pointer<Pointer> exception) {
    try {
      var url = JSValue(jsContext, arguments[0]).string;
      var method = JSValue(jsContext, arguments[1]).string;
      var headers = JSValue(jsContext, arguments[2]).toObject();
      var body = JSValue(jsContext, arguments[3]);
      var resolveCallback = JSValue(jsContext, arguments[4]);
      var rejectCallback = JSValue(jsContext, arguments[5]);

      httpLogger.fine('fetch ' + method + ' ' + url);

      Map<String, String> requestHeaders;
      var headerNames = headers.copyPropertyNames();
      if (headerNames.count != 0) {
        requestHeaders = Map();
        for (var i = 0; i < headerNames.count; i++) {
          var key = headerNames.propertyNameArrayGetNameAtIndex(i);
          requestHeaders[key] = headers.getProperty(key).string;
        }
      }
      var request;
      if (method == "GET") {
        if (!body.isNull && !body.isUndefined) {
          _callHttpFetchCallbackWithException(
              rejectCallback, "Not expecting a body with GET fetch");
          return nullptr;
        }
        request = http.get(url, headers: requestHeaders);
      } else if (method == "POST") {
        var bodyList;
        if (!body.isNull && !body.isUndefined) {
          var bytes = body.toObject().typedArrayBytes();
          var offset = body.toObject().typedArrayByteOffset();
          var len = body.toObject().typedArrayByteLength();
          Pointer<Uint8> intPointer =
              Pointer.fromAddress(bytes.pointer.address);
          bodyList = Uint8List.fromList(
              intPointer.asTypedList(offset + len).sublist(offset));
        }
        request = http.post(url, headers: requestHeaders, body: bodyList);
      } else {
        _callHttpFetchCallbackWithException(rejectCallback,
            "Fetch called with unsupported method type " + method);
        return nullptr;
      }
      request.then((response) {
        var responseJs = JSObject.make(jsContext, JSClass(nullptr));
        responseJs.setProperty("url", JSValue.makeString(jsContext, url),
            JSPropertyAttributes.kJSPropertyAttributeNone);
        responseJs.setProperty("method", JSValue.makeString(jsContext, method),
            JSPropertyAttributes.kJSPropertyAttributeNone);
        responseJs.setProperty(
            "status",
            JSValue.makeNumber(jsContext, response.statusCode.toDouble()),
            JSPropertyAttributes.kJSPropertyAttributeNone);
        responseJs.setProperty(
            "statusText",
            JSValue.makeString(jsContext, response.statusCode.toString()),
            JSPropertyAttributes.kJSPropertyAttributeNone);

        var headersJs = JSObject.make(jsContext, JSClass(nullptr));
        for (var entry in response.headers.entries) {
          headersJs.setProperty(
              entry.key,
              JSValue.makeString(jsContext, entry.value),
              JSPropertyAttributes.kJSPropertyAttributeNone);
        }
        responseJs.setProperty("headers", headersJs.toValue(),
            JSPropertyAttributes.kJSPropertyAttributeNone);

        JSObject dataJs = JSObject.makeTypedArray(
            jsContext,
            JSTypedArrayType.kJSTypedArrayTypeUint8Array,
            response.bodyBytes.length);
        var intPointer = Pointer<Uint8>.fromAddress(
            dataJs.typedArrayBytes().pointer.address);
        intPointer
            .asTypedList(dataJs.typedArrayBytes().length)
            .setAll(0, response.bodyBytes);
        responseJs.setProperty("body", dataJs.toValue(),
            JSPropertyAttributes.kJSPropertyAttributeNone);

        var exception = JSValuePointer();
        resolveCallback.toObject().callAsFunction(JSObject(jsContext, nullptr),
            JSValuePointer.array([responseJs.toValue()]),
            exception: exception);
      }).catchError((err) {
        _callHttpFetchCallbackWithException(
            rejectCallback, "Error during fetch " + err.toString());
      });
    } catch (err) {
      exception[0] =
          _createFsError("Error during fetch code " + err.toString(), "")
              .pointer;
    }
    return nullptr;
  }
}

Pointer _jsSignalCompletion(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return js._signalCompletion(
      function, thisObject, argumentCount, arguments, exception);
}

Pointer _jsSignalError(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return js._signalError(
      function, thisObject, argumentCount, arguments, exception);
}

Pointer _jsFsOperation(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return js._fsOperation(
      function, thisObject, argumentCount, arguments, exception);
}

Pointer _jsHttpFetch(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  return js._httpFetch(
      function, thisObject, argumentCount, arguments, exception);
}

Pointer _jsLog(Pointer ctx, Pointer function, Pointer thisObject,
    int argumentCount, Pointer<Pointer> arguments, Pointer<Pointer> exception) {
  JsForGit js = JsForGit.ctxToJsForGit[jSContextGetGlobalContext(ctx)];
  print(JSValue(js.jsContext, arguments[0]).string);
  return nullptr;
}
